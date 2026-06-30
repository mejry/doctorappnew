# ------------------------------------------------------------------
#  Flutter web build → Nginx static server
# ------------------------------------------------------------------

# ---- Build stage ----
FROM ghcr.io/cirruslabs/flutter:3.22.3 AS builder
WORKDIR /app

# Copy the entire Flutter project
COPY . .

# Build the web assets (release mode)
RUN flutter build web --release

# ---- Serve stage ----
FROM nginx:alpine
# Copy the compiled web files into Nginx's document root
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose the standard HTTP port
EXPOSE 80

# Default command (nginx runs in foreground)
CMD ["nginx", "-g", "daemon off;"]