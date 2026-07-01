
FROM ghcr.io/cirruslabs/flutter:3.22.3 AS builder
WORKDIR /app

COPY . .

RUN flutter build web --release

FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]