# Dockerfile (Root)

# Stage 1: Build the React application
FROM node:18-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve the app with Nginx
FROM nginx:alpine

# Copy built assets from Stage 1
COPY --from=build /app/dist /usr/share/nginx/html

# Copy custom Nginx configuration (we will create this next)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
EXPOSE 5000
CMD ["nginx", "-g", "daemon off;"]