FROM node:20-alpine
WORKDIR /app

RUN npm install -g pm2

# ── auth-service ──────────────────────────────────────────────────────────────
COPY auth-service/package*.json ./auth-service/
RUN cd auth-service && npm install --production=false
COPY auth-service/ ./auth-service/
RUN cd auth-service && npm run build

# ── user-service ──────────────────────────────────────────────────────────────
COPY user-service/package*.json ./user-service/
RUN cd user-service && npm install --production=false
COPY user-service/ ./user-service/
RUN cd user-service && npm run build

# ── product-service ───────────────────────────────────────────────────────────
COPY product-service/package*.json ./product-service/
RUN cd product-service && npm install --production=false
COPY product-service/ ./product-service/
RUN cd product-service && npm run build

# ── order-service ─────────────────────────────────────────────────────────────
COPY order-service/package*.json ./order-service/
RUN cd order-service && npm install --production=false
COPY order-service/ ./order-service/
RUN cd order-service && npm run build

# ── logistics-service ─────────────────────────────────────────────────────────
COPY logistics-service/package*.json ./logistics-service/
RUN cd logistics-service && npm install --production=false
COPY logistics-service/ ./logistics-service/
RUN cd logistics-service && npm run build

# ── notification-service ──────────────────────────────────────────────────────
COPY notification-service/package*.json ./notification-service/
RUN cd notification-service && npm install --production=false
COPY notification-service/ ./notification-service/
RUN cd notification-service && npm run build

# ── chat-service ──────────────────────────────────────────────────────────────
COPY chat-service/package*.json ./chat-service/
RUN cd chat-service && npm install --production=false
COPY chat-service/ ./chat-service/
RUN cd chat-service && npm run build

# ── review-service ────────────────────────────────────────────────────────────
COPY review-service/package*.json ./review-service/
RUN cd review-service && npm install --production=false
COPY review-service/ ./review-service/
RUN cd review-service && npm run build

# ── payment-service ───────────────────────────────────────────────────────────
COPY payment-service/package*.json ./payment-service/
RUN cd payment-service && npm install --production=false
COPY payment-service/ ./payment-service/
RUN cd payment-service && npm run build

# ── api-gateway ───────────────────────────────────────────────────────────────
COPY api-gateway/package*.json ./api-gateway/
RUN cd api-gateway && npm install --production=false
COPY api-gateway/ ./api-gateway/
RUN cd api-gateway && npm run build

COPY ecosystem.config.js .

EXPOSE 3000
CMD ["pm2-runtime", "ecosystem.config.js"]
