FROM node:22.13-alpine AS deps

WORKDIR /backend
COPY package.json package-lock.json .
RUN npm i

WORKDIR /frontend
COPY frontend .
RUN npm i && npm run build


FROM node:22.13-alpine

WORKDIR /app
RUN npm i -g pm2
COPY . .
COPY --from=deps /backend /app
COPY --from=deps /frontend/dist /app/frontend/dist

CMD ["sh", "-c", "pm2 start -s ecosystem.config.cjs; pm2 logs"]
