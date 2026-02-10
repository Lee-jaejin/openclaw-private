FROM node:22-alpine

RUN npm install -g openclaw

RUN mkdir -p /home/node/.openclaw/sessions \
    && chown -R node:node /home/node/.openclaw

USER node
WORKDIR /home/node

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:18789/health || exit 1

CMD ["openclaw", "serve"]
