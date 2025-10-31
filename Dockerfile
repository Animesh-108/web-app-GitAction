### STAGE 1: Builder ###
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

### STAGE 2: Final Image ###
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/package*.json ./
RUN npm install --production
COPY --from=builder /app/server.js ./
EXPOSE 8080
CMD ["node", "server.js"]