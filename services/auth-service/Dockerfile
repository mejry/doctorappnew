# ============================================================
# Educenter Backend — Production-Ready Multi-Stage Dockerfile
# Base: node:20-alpine | Target image size: < 200 MB
# ============================================================

# ---- Stage 1: Dependencies ----
FROM node:20-alpine AS deps

WORKDIR /app

# Install only production dependencies first (cache layer)
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --legacy-peer-deps && \
    cp -R node_modules /prod_modules

# Install all dependencies (including dev) for build
RUN npm ci --legacy-peer-deps

# ---- Stage 2: Build ----
FROM node:20-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json package-lock.json ./
COPY src/ ./src/

# Inject build environment (staging vs production)
ARG BUILD_ENV=production
ENV NODE_ENV=${BUILD_ENV}

RUN npm run build

# ---- Stage 3: Production ----
FROM node:20-alpine AS runner

# Security: install curl for healthcheck, then clean up
RUN apk add --no-cache curl tini

WORKDIR /app

# Security: non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S educenter -u 1001 -G nodejs

# Set environment
ENV NODE_ENV=production
ENV PORT=3000

# Copy production dependencies only (no devDependencies)
COPY --from=deps /prod_modules ./node_modules

# Copy built application
COPY --from=builder /app/dist ./dist
COPY package.json ./

# Create uploads directory with correct ownership
RUN mkdir -p uploads tmp && \
    chown -R educenter:nodejs /app

# Switch to non-root user
USER educenter

# Expose application port
EXPOSE 3000

# Healthcheck — K8s probes are preferred, but this is a safety net
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:5000/api/health || exit 1

# Use tini as PID 1 for proper signal handling (SIGTERM)
ENTRYPOINT ["tini", "--"]

# Start the application
CMD ["node", "dist/server.js"]
