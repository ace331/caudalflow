# Build the frontend (React + Vite)
FROM node:22-slim AS build
WORKDIR /app

# Install dependencies first so this layer caches independently of source changes
COPY package.json package-lock.json ./
RUN npm ci

# Copy only what the type-check + Vite build need
COPY tsconfig*.json vite.config.ts index.html ./
COPY public ./public
COPY src ./src

RUN npm run build

# Serve the static bundle and reverse-proxy /api/* to the BFF
FROM nginx:1.29-alpine
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
