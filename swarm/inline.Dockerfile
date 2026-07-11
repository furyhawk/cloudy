FROM node:20-alpine AS builder
WORKDIR /app
COPY ./nodepad/package*.json ./
RUN npm install
COPY ./nodepad .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/next.config.mjs ./

EXPOSE 3000
CMD ["npm", "run", "start"]
