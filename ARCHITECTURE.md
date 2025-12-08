# Bill Generator - Docker Architecture

## System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER / BROWSER                           │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       │ HTTP/HTTPS
                       ↓
┌─────────────────────────────────────────────────────────────────┐
│                   DOCKER HOST MACHINE                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    bill-network                            │ │
│  │  (Docker bridge network for inter-container communication) │ │
│  │                                                            │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │ │
│  │  │  Frontend    │  │   Backend    │  │    Database      │  │ │
│  │  │  Container   │  │  Container   │  │   Container      │  │ │
│  │  │              │  │              │  │                  │  │ │
│  │  │ React/Tauri  │  │  Express.js  │  │   MongoDB        │  │ │
│  │  │  Port 3000   │◄─┤  Port 5000   │◄─┤  Port 27017      │  │ │
│  │  │              │  │              │  │                  │  │ │
│  │  │ - Routes     │  │ - API routes │  │ - Collections    │  │ │
│  │  │ - Components │  │ - Middleware │  │ - Indexes        │  │ │
│  │  │ - State      │  │ - Controllers│  │ - Replication    │  │ │
│  │  │              │  │              │  │                  │  │ │
│  │  │ Volume:      │  │ Volume:      │  │ Volume:          │  │ │
│  │  │ ./frontend   │  │ ./backend    │  │ mongodb_data     │  │ │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │ │
│  │        ▲                   ▲                   ▲           │ │
│  │        │                   │                   │           │ │
│  │        └───────────────────┴───────────────────┘           │ │
│  │               bill-network (bridge)                        | │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ All containers use the same Docker image: bill-generator:latest │
└─────────────────────────────────────────────────────────────────┘
```

## Container Details

### Frontend Container
```
┌─────────────────────────────────┐
│      Frontend Container         │
├─────────────────────────────────┤
│ Image: bill-generator:latest    │
│ Command: npm start              │
│ Working Dir: /app/frontend      │
├─────────────────────────────────┤
│ Ports:                          │
│   - 3000:3000 (HTTP)            │
├─────────────────────────────────┤
│ Environment:                    │
│   - REACT_APP_API_URL           │
│   - REACT_APP_ENV               │
├─────────────────────────────────┤
│ Volumes:                        │
│   - ./frontend:/app/frontend    │
│   - /app/frontend/node_modules  │
├─────────────────────────────────┤
│ Network: bill-network           │
│ Depends on: backend (healthy)   │
└─────────────────────────────────┘
```

### Backend Container
```
┌─────────────────────────────────┐
│      Backend Container          │
├─────────────────────────────────┤
│ Image: bill-generator:latest    │
│ Command: npm start              │
│ Working Dir: /app/backend       │
├─────────────────────────────────┤
│ Ports:                          │
│   - 5000:5000 (HTTP)            │
├─────────────────────────────────┤
│ Environment:                    │
│   - NODE_ENV=production         │
│   - MONGODB_URI                 │
│   - RUST_LOG=info               │
│   - PORT=5000                   │
├─────────────────────────────────┤
│ Volumes:                        │
│   - ./backend:/app/backend      │
│   - /app/backend/node_modules   │
├─────────────────────────────────┤
│ Network: bill-network           │
│ Depends on: database (healthy)  │
│ Health Check: /health endpoint  │
└─────────────────────────────────┘
```

### Database Container
```
┌─────────────────────────────────┐
│     Database Container          │
├─────────────────────────────────┤
│ Image: bill-generator:latest    │
│ Command: mongod                 │
│ Bind IP: 0.0.0.0                │
├─────────────────────────────────┤
│ Ports:                          │
│   - 27017:27017 (MongoDB)       │
├─────────────────────────────────┤
│ Environment:                    │
│   - MONGO_INITDB_DATABASE       │
├─────────────────────────────────┤
│ Volumes:                        │
│   - mongodb_data:/data/db       │
│   - mongodb_config:/data/confdb │
├─────────────────────────────────┤
│ Network: bill-network           │
│ Health Check: mongo ping        │
└─────────────────────────────────┘
```

## Communication Flow

### 1. User Opens Frontend
```
User Browser (localhost:3000)
        ↓
   Frontend Container
   - React app loads
   - Makes API calls to backend
        ↓
   Backend: http://localhost:5000 (from browser)
   or
   Backend: http://backend:5000 (from within container)
```

### 2. Frontend Calls Backend
```
Frontend Container
        ↓
   (network: bill-network)
        ↓
Backend Container (service name: backend)
   - Express server
   - Parses requests
   - Validates data
        ↓
   (network: bill-network)
        ↓
Database Container (service name: database)
   - MongoDB
   - Stores/retrieves data
        ↓
Response flows back through same path
```

### 3. Data Persistence
```
Application runs
    ↓
MongoDB writes data
    ↓
mounted to volume: mongodb_data:/data/db
    ↓
Stored on host machine
    ↓
Container stops
    ↓
Data persists on host
    ↓
Container restarts
    ↓
Data is still there
```

## Network Configuration

### Bridge Network: `bill-network`

```
Services within network can communicate via service name:

Frontend → Backend:    http://backend:5000
Backend → Database:    mongodb://database:27017
Frontend → Database:   (not recommended, goes through backend)

Services outside network can communicate via localhost:

Browser → Frontend:    http://localhost:3000
Browser → Backend:     http://localhost:5000
Tools → Database:      mongodb://localhost:27017
```

### DNS Resolution
```
Docker DNS (127.0.0.11:53)
    ↓
Inside container: curl http://backend:5000
    ↓
Docker DNS resolves "backend" to container IP
    ↓
Packet sent to backend container
```

## Volume Mapping

### Frontend Volumes
```
Host Machine              Container
./frontend ←────────────► /app/frontend
                         (dev: hot reload)

(no persistent data, can be deleted)
```

### Backend Volumes
```
Host Machine              Container
./backend ←────────────► /app/backend
                         (dev: hot reload)

(no persistent data, can be deleted)
```

### Database Volumes
```
Host Machine              Container
mongodb_data ←────────────► /data/db
mongodb_config ←────────────► /data/configdb

(PERSISTENT - survives container restart)
```

## Service Startup Sequence

```
docker-compose up -d

1. Database Container Starts
   ├─ Runs: mongod --bind_ip 0.0.0.0 --port 27017
   ├─ Creates: /data/db directory
   ├─ Waits: 30 seconds for startup
   ├─ Health Check: db.adminCommand('ping')
   └─ Status: ready ✓

2. Backend Container Starts
   ├─ Waits for: database.healthcheck == success
   ├─ Runs: npm start (executes index.js)
   ├─ Env: MONGODB_URI=mongodb://database:27017/bill_generator
   ├─ Connects to: MongoDB via network
   ├─ Health Check: curl http://localhost:5000/health
   └─ Status: ready ✓

3. Frontend Container Starts
   ├─ Waits for: backend.healthcheck == success
   ├─ Runs: npm start (React dev server)
   ├─ Env: REACT_APP_API_URL=http://localhost:5000
   ├─ Builds: React app
   ├─ Listens: 0.0.0.0:3000
   └─ Status: ready ✓

All services accessible
```

## Data Flow Example: Create Bill

```
1. User fills form in Frontend (localhost:3000)
2. Frontend validates input
3. Frontend sends POST request to Backend
   
   POST http://localhost:5000/api/bills
   {
     "billNumber": "BL-001",
     "customerId": "xyz123",
     "amount": 5000,
     "items": [...]
   }

4. Backend (localhost:5000) receives request
   ├─ Validates request
   ├─ Creates Bill model
   └─ Calls MongoDB

5. Backend connects to Database (mongodb://database:27017)
   ├─ Opens connection on bill-network
   ├─ Sends insert query
   └─ Waits for response

6. Database (MongoDB on bill-network)
   ├─ Receives insert request
   ├─ Writes to /data/db (persistent volume)
   ├─ Returns { _id: "...", billNumber: "BL-001", ... }
   └─ Closes connection

7. Backend receives response from Database
   ├─ Formats response
   └─ Sends 201 Created to Frontend

8. Frontend receives response
   ├─ Updates UI
   ├─ Shows success message
   └─ Refreshes bill list

9. Data persisted in mongodb_data volume on host
```

## Scaling Possibilities

### Horizontal Scaling (Multiple Instances)
```
Current:
database:1 instance
backend:1 instance
frontend:1 instance

Possible:
database:1 instance (replica set)
backend:3 instances (load balanced)
frontend:1 instance (CDN cached)
```

### Vertical Scaling (More Resources)
```
Add to docker-compose.yml:

services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### Orchestration (Kubernetes)
```
Future: Deploy to K8s
- Frontend Deployment (3 replicas)
- Backend Deployment (5 replicas)
- MongoDB StatefulSet (3 nodes)
- Services for networking
- Ingress for routing
```

## Environment-Specific Configurations

### Development
```yaml
volumes:
  - ./frontend:/app/frontend
  - ./backend:/app/backend
environment:
  - NODE_ENV=development
  - REACT_APP_ENV=development
```

### Staging
```yaml
volumes: [] # Remove volume mounts
environment:
  - NODE_ENV=staging
  - REACT_APP_ENV=staging
build:
  context: .
  cache_from:
    - bill-generator:latest
```

### Production
```yaml
volumes: [] # No dev mounts
image: bill-generator:vX.Y.Z # Pin version
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
environment:
  - NODE_ENV=production
  - REACT_APP_ENV=production
```

---

## Key Architectural Decisions

| Decision | Reason |
|----------|--------|
| Single Image | Simplicity, consistency, reduced overhead |
| Separate Containers | Isolation, independent scaling, clean separation |
| Bridge Network | Automatic DNS, service discovery |
| Volume Persistence | Data survives container restarts |
| Health Checks | Ensures dependencies ready before startup |
| Environment Variables | Configuration without code changes |
| Multi-stage Dockerfile | Smaller final image, faster deployment |

---

**Architecture Version**: 1.0
**Last Updated**: December 2025
**Status**: Production Ready
