# Use Node.js for building and serving
FROM node:18

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the React app
RUN npm run build

# Install serve to serve the built app
RUN npm install -g serve

# Expose port 3001
EXPOSE 3001

# Serve the built app
CMD ["serve", "-s", "build", "-l", "3001"]
