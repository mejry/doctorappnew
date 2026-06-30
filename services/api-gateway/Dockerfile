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
ENV PORT=8090

EXPOSE 8090

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "const port=process.env.GATEWAY_PORT||process.env.PORT||8090; require('http').get({host:'127.0.0.1',port,path:'/'}, r => process.exit(r.statusCode < 500 ? 0 : 1)).on('error', () => process.exit(1))"

ENTRYPOINT ["tini", "--"]

CMD ["node", "server.js"]
