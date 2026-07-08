FROM node:20-alpine

WORKDIR /app

# Install deps first for better layer caching
COPY package*.json ./
RUN npm install

# Source is bind-mounted in docker-compose.yml for hot reload,
# but we copy it here too so the image also works standalone.
COPY . .

EXPOSE 5173

CMD ["npm", "run", "dev"]
