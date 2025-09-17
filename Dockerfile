# Use Node LTS
FROM node:18-slim

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json* ./
RUN npm install --production || npm install --production

# Copy source
COPY server.js ./

# Expose port
EXPOSE 3000

# Start the server
CMD ["npm", "start"]
