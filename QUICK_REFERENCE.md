# Quick Reference - Docker Commands

Quick copy-paste commands for common tasks.

---

## 🚀 Getting Started

### Build Image
```bash
docker build -t bill-generator:latest .
```

### Start Everything
```bash
docker-compose up -d
```

### Check Status
```bash
docker-compose ps
```

### View Logs
```bash
docker-compose logs -f
```

### Stop Everything
```bash
docker-compose down
```

---

## 📋 Service Management

### Start Individual Service
```bash
docker-compose up -d database
docker-compose up -d backend
docker-compose up -d frontend
```

### Restart Service
```bash
docker-compose restart backend
docker-compose restart database
docker-compose restart frontend
```

### Stop Service
```bash
docker-compose stop backend
docker-compose stop database
docker-compose stop frontend
```

### Remove Service
```bash
docker-compose rm -f backend
```

---

## 🔍 Troubleshooting

### View Service Logs
```bash
docker-compose logs backend        # Last 100 lines
docker-compose logs -f backend     # Follow in real-time
docker-compose logs --tail=50 backend    # Last 50 lines
docker-compose logs -f --timestamps backend  # With timestamps
```

### Inspect Service
```bash
docker-compose ps                  # Show running containers
docker-compose config              # Show resolved config
docker stats                        # Resource usage
docker inspect [container-id]       # Detailed info
```

### Test Connectivity

**Backend Health**
```bash
curl http://localhost:5000/health
```

**Frontend**
```bash
curl http://localhost:3000
```

**MongoDB from CLI**
```bash
docker-compose exec database mongosh
```

**From Container**
```bash
# Backend can reach MongoDB?
docker-compose exec backend curl http://database:27017

# Frontend can reach Backend?
docker-compose exec frontend curl http://backend:5000
```

---

## 🛠️ Debugging

### Execute Command in Container
```bash
docker-compose exec backend npm list
docker-compose exec backend npm install express
docker-compose exec database mongosh
docker-compose exec frontend ls -la
```

### Access Container Shell
```bash
docker-compose exec backend /bin/sh
docker-compose exec frontend /bin/sh
docker-compose exec database /bin/sh
```

### View Environment Variables
```bash
docker-compose exec backend env
docker-compose exec frontend env | grep REACT_APP
```

### View Container Network
```bash
docker network ls
docker network inspect bill-network
```

### View Volumes
```bash
docker volume ls
docker volume inspect mongodb_data
```

---

## 🔧 Building & Rebuilding

### Build Without Cache
```bash
docker build --no-cache -t bill-generator:latest .
```

### Rebuild via Docker Compose
```bash
docker-compose build --no-cache
docker-compose up -d
```

### Clear Dangling Images
```bash
docker image prune -a
```

---

## 💾 Data Management

### Backup MongoDB Data
```bash
docker-compose exec database mongodump --archive=/backup.archive
docker cp bill-generator-db:/backup.archive ./backup.archive
```

### Restore MongoDB Data
```bash
docker cp ./backup.archive bill-generator-db:/backup.archive
docker-compose exec database mongorestore --archive=/backup.archive
```

### View Database Files
```bash
docker volume inspect mongodb_data
# Shows mountpoint, check that directory on host
```

### Remove All Data
```bash
docker-compose down -v
```

---

## 📦 Image Management

### List Images
```bash
docker images
docker images bill-generator
```

### Tag Image
```bash
docker tag bill-generator:latest bill-generator:v1.0.0
```

### Push to Registry
```bash
docker tag bill-generator:latest your-registry/bill-generator:latest
docker push your-registry/bill-generator:latest
```

### Remove Image
```bash
docker image rm bill-generator:latest
docker rmi bill-generator
```

---

## 🐳 Container Management

### List All Containers
```bash
docker ps                    # Running only
docker ps -a                 # All containers
docker ps --filter "name=bill"
```

### Inspect Container
```bash
docker inspect bill-generator-backend
docker logs bill-generator-backend
docker top bill-generator-backend
```

### View Port Mappings
```bash
docker port bill-generator-backend
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

### Remove Containers
```bash
docker-compose down          # Remove all
docker rm bill-generator-backend  # Remove specific
docker container prune       # Remove stopped containers
```

---

## 🌐 Network Management

### List Networks
```bash
docker network ls
```

### Inspect Network
```bash
docker network inspect bill-network
```

### Connect Container to Network
```bash
docker network connect bill-network container-name
```

### Test Network Connectivity
```bash
docker-compose exec backend ping database
docker-compose exec backend nslookup database
```

---

## 📊 Monitoring

### View Resource Usage
```bash
docker stats                                    # All containers
docker stats bill-generator-backend             # Specific container
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### View Events
```bash
docker events --filter 'container=bill-generator-backend'
```

### View Logs with Grep
```bash
docker-compose logs backend | grep "error"
docker-compose logs database | grep "warning"
```

### Check System Info
```bash
docker system info
docker version
docker-compose version
```

---

## 🧹 Cleanup

### Remove Unused Resources
```bash
docker system prune                 # Basic cleanup
docker system prune -a              # Remove all unused (including images)
docker system prune -a --volumes    # Including volumes
```

### Specific Cleanup
```bash
docker container prune              # Stopped containers
docker image prune -a               # Unused images
docker volume prune                 # Unused volumes
docker network prune                # Unused networks
```

### Full Reset
```bash
docker-compose down -v
docker image rm bill-generator:latest
docker system prune -a --volumes
```

---

## 📝 Common Workflows

### Development Workflow
```bash
# Start services
docker-compose up -d

# Make changes to code
# Changes hot-reload due to volume mounts
vim backend/index.js

# Check logs
docker-compose logs -f backend

# Stop when done
docker-compose down
```

### Debugging Workflow
```bash
# Start services
docker-compose up -d

# Check logs
docker-compose logs backend

# Execute commands
docker-compose exec backend npm install [package]

# Access shell
docker-compose exec backend /bin/sh

# Test connectivity
docker-compose exec backend curl http://database:27017
```

### Production Deployment
```bash
# Build fresh image
docker build -t bill-generator:v1.0.0 .

# Tag for registry
docker tag bill-generator:v1.0.0 your-registry/bill-generator:v1.0.0

# Push to registry
docker push your-registry/bill-generator:v1.0.0

# Pull on production server
docker pull your-registry/bill-generator:v1.0.0

# Update docker-compose.yml to use new version
# image: your-registry/bill-generator:v1.0.0

# Deploy
docker-compose up -d
```

### Database Backup
```bash
# Dump
docker-compose exec database mongodump \
  --archive=/tmp/backup.archive \
  --gzip

# Copy to host
docker cp bill-generator-db:/tmp/backup.archive ./backup.archive

# Restore
docker cp ./backup.archive bill-generator-db:/tmp/
docker-compose exec database mongorestore \
  --archive=/tmp/backup.archive \
  --gzip
```

---

## 🆘 Emergency Commands

### Force Stop All
```bash
docker-compose kill
```

### Remove Everything (⚠️ Data Loss)
```bash
docker-compose down -v
docker rmi bill-generator:latest
```

### Restart Docker Daemon
```bash
# Linux
sudo systemctl restart docker

# Mac
# Restart Docker Desktop app
```

### Check Disk Space
```bash
docker system df
docker system df -v
```

### Free Up Space
```bash
docker system prune -a --volumes --force
```

---

## 📚 Useful Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
# Docker
alias d='docker'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dlo='docker logs'

# Docker Compose
alias dc='docker-compose'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dcps='docker-compose ps'
alias dclog='docker-compose logs -f'
alias dcexec='docker-compose exec'

# Bill Generator Specific
alias bg-build='docker build -t bill-generator:latest .'
alias bg-up='docker-compose up -d'
alias bg-down='docker-compose down'
alias bg-logs='docker-compose logs -f'
alias bg-backend-logs='docker-compose logs -f backend'
alias bg-db-logs='docker-compose logs -f database'
```

Use:
```bash
bg-up
bg-logs
bg-backend-logs
```

---

## 🔗 Useful Resources

- [Docker Docs](https://docs.docker.com/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [MongoDB Docker Docs](https://hub.docker.com/_/mongo)
- [Node.js Docker Best Practices](https://docs.docker.com/language/nodejs/)

---

## 💡 Quick Tips

**Terminal Colors**
```bash
# Add colors to docker output
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

**Auto-completion**
```bash
# Install bash completion for docker
sudo apt-get install docker-compose-bash-completion

# Or copy bash completion manually
sudo curl https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose \
  -o /etc/bash_completion.d/docker-compose
```

**View Port Mappings**
```bash
docker-compose ps
# Shows PORT column

# Or detailed view
docker port bill-generator-backend
```

**Check if Port is Available**
```bash
# Linux/Mac
lsof -i :5000
lsof -i :3000
lsof -i :27017

# Kill process on port
kill -9 $(lsof -t -i :5000)
```

---

**Last Updated**: December 2025
**Tested With**: Docker 20.10+, Docker Compose 1.29+
