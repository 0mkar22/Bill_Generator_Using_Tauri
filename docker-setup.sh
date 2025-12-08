#!/bin/bash
# This script helps set up the Docker environment for Bill Generator

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "   Bill Generator - Docker Setup Script"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo "Please install Docker from https://docs.docker.com/get-docker/"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    echo "Please install Docker Compose from https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker Compose is installed${NC}"
echo ""

# Check project structure
echo -e "${BLUE}Checking project structure...${NC}"

if [ ! -d "backend" ]; then
    echo -e "${RED}✗ backend/ directory not found${NC}"
    exit 1
fi

if [ ! -d "frontend" ]; then
    echo -e "${RED}✗ frontend/ directory not found${NC}"
    exit 1
fi

if [ ! -f "backend/package.json" ]; then
    echo -e "${RED}✗ backend/package.json not found${NC}"
    exit 1
fi

if [ ! -f "frontend/package.json" ]; then
    echo -e "${RED}✗ frontend/package.json not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Project structure is correct${NC}"
echo ""

# Function to build Docker image
build_image() {
    echo -e "${BLUE}Building Docker image...${NC}"
    docker build -t bill-generator:latest .
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Docker image built successfully${NC}"
    else
        echo -e "${RED}✗ Failed to build Docker image${NC}"
        exit 1
    fi
}

# Function to start services
start_services() {
    echo ""
    echo -e "${BLUE}Starting services with docker-compose...${NC}"
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Services started successfully${NC}"
        echo ""
        echo "Waiting for services to be ready..."
        sleep 5
        
        echo -e "${BLUE}Service Status:${NC}"
        docker-compose ps
        
        echo ""
        echo -e "${GREEN}✓ All services are running!${NC}"
        echo ""
        echo "Access your application:"
        echo "  Frontend:    http://localhost:3000"
        echo "  Backend:     http://localhost:5000"
        echo "  Database:    mongodb://localhost:27017"
        echo ""
        echo "View logs:"
        echo "  docker-compose logs -f [service_name]"
        echo ""
        echo "Stop services:"
        echo "  docker-compose down"
    else
        echo -e "${RED}✗ Failed to start services${NC}"
        exit 1
    fi
}

# Function to run tests
run_tests() {
    echo ""
    echo -e "${BLUE}Running health checks...${NC}"
    
    echo -n "Checking MongoDB... "
    if docker-compose exec -T database mongosh --eval "db.adminCommand('ping')" &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
    
    echo -n "Checking Backend... "
    if curl -s http://localhost:5000/health &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠ (waiting for startup)${NC}"
    fi
    
    echo -n "Checking Frontend... "
    if curl -s http://localhost:3000 &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠ (waiting for startup)${NC}"
    fi
}

# Main menu
echo -e "${BLUE}What would you like to do?${NC}"
echo ""
echo "1) Build Docker image and start all services"
echo "2) Build Docker image only"
echo "3) Start services (image must exist)"
echo "4) View service logs"
echo "5) Stop all services"
echo "6) Run health checks"
echo "7) Clean up (remove containers & volumes)"
echo ""

read -p "Enter your choice (1-7): " choice

case $choice in
    1)
        build_image
        start_services
        ;;
    2)
        build_image
        ;;
    3)
        start_services
        ;;
    4)
        echo ""
        echo "Available services: database, backend, frontend"
        read -p "Enter service name (or 'all'): " service_name
        
        if [ "$service_name" = "all" ]; then
            docker-compose logs -f
        else
            docker-compose logs -f "$service_name"
        fi
        ;;
    5)
        echo -e "${BLUE}Stopping services...${NC}"
        docker-compose down
        echo -e "${GREEN}✓ Services stopped${NC}"
        ;;
    6)
        run_tests
        ;;
    7)
        echo -e "${YELLOW}⚠ This will remove all containers and volumes!${NC}"
        read -p "Are you sure? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            docker-compose down -v
            echo -e "${GREEN}✓ Cleanup complete${NC}"
        else
            echo "Cleanup cancelled"
        fi
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"
