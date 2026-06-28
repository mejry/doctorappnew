
FROM node:20-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --legacy-peer-deps && \
    cp -R node_modules /prod_modules

RUN npm ci --legacy-peer-deps

FROM node:20-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json package-lock.json tsconfig.json ./
COPY src/ ./src/

ARG BUILD_ENV=production
ENV NODE_ENV=${BUILD_ENV}

RUN npm run build

FROM node:20-alpine AS runner

RUN apk add --no-cache curl tini

WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S educenter -u 1001 -G nodejs

ENV NODE_ENV=production
ENV PORT=3000

COPY --from=deps /prod_modules ./node_modules

COPY --from=builder /app/dist ./dist
COPY package.json ./

RUN mkdir -p uploads tmp && \
    chown -R educenter:nodejs /app

USER educenter

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

ENTRYPOINT ["tini", "--"]

CMD ["node", "dist/server.js"]
