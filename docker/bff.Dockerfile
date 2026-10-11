# BFF runtime — serves apps/bff/src/server.ts with tsx from the root workspace
FROM node:22-slim
WORKDIR /app

COPY package.json package-lock.json ./
# tsx (the runtime) is a devDependency, so install everything
RUN npm ci

COPY apps/bff ./apps/bff

ENV PORT=4000
EXPOSE 4000
CMD ["./node_modules/.bin/tsx", "apps/bff/src/server.ts"]
