# Use a base image
FROM node:22-alpine
FROM mongo:latest
FROM ivangabriele/tauri:fedora-40-20-nightly

# Set the working directory inside the container
WORKDIR /app

# Copy application files from your local machine to the image
COPY . .

# Install dependencies (this runs a command during the build process)
RUN yarn install --production

# Define the command to run when the container starts
CMD ["node", "./src/index.js"]
