FROM node:20-alpine

RUN apk add --no-cache curl tini

WORKDIR /app

COPY package*.json ./

RUN npm install --omit=dev --legacy-peer-deps

COPY . .

RUN addgroup -g 1001 -S nodejs && \
    adduser -S educenter -u 1001 -G nodejs && \
    mkdir -p uploads tmp && \
    chown -R educenter:nodejs /app

USER educenter

ENV NODE_ENV=production
ENV PORT=3001

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:3001/api/health || exit 1

ENTRYPOINT ["tini", "--"]

CMD ["node", "src/server.js"]
