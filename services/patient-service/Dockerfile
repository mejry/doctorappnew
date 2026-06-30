FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --omit=dev --legacy-peer-deps

COPY . .

EXPOSE 8002

CMD ["node", "src/server.js"]