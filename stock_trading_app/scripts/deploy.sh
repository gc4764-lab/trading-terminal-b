#!/bin/bash

# Stock Trading Application Deployment Script

set -e

echo "🚀 Starting deployment of Stock Trading Application"

# Configuration
APP_NAME="stock-trading-app"
ENV=${1:-production}
VERSION=$(git describe --tags --always)
DEPLOY_DIR="/opt/$APP_NAME"
BACKUP_DIR="/opt/backups/$APP_NAME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    command -v docker >/dev/null 2>&1 || error "Docker is required but not installed"
    command -v docker-compose >/dev/null 2>&1 || error "Docker Compose is required but not installed"
    command -v go >/dev/null 2>&1 || warning "Go is not installed. Backend build may fail"
    command -v flutter >/dev/null 2>&1 || warning "Flutter is not installed. Frontend build may fail"
    
    log "✅ Prerequisites check completed"
}

# Backup existing installation
backup() {
    log "Creating backup of current installation..."
    
    if [ -d "$DEPLOY_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
        tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$DEPLOY_DIR" .
        log "✅ Backup created: $BACKUP_NAME.tar.gz"
    else
        log "No existing installation found"
    fi
}

# Build backend
build_backend() {
    log "Building backend..."
    
    cd backend
    
    # Run tests
    go test ./... || warning "Tests failed, continuing anyway"
    
    # Build binary
    GOOS=linux GOARCH=amd64 go build -o stock-trading-backend -ldflags="-X main.Version=$VERSION" main.go
    
    # Build Docker image
    docker build -t "$APP_NAME-backend:$VERSION" -f Dockerfile .
    
    cd ..
    log "✅ Backend build completed"
}

# Build frontend
build_frontend() {
    log "Building frontend..."
    
    cd frontend
    
    # Get dependencies
    flutter pub get
    
    # Run tests
    flutter test || warning "Tests failed, continuing anyway"
    
    # Build for web
    flutter build web --release --base-href="/"
    
    # Build desktop versions
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        flutter build linux --release
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        flutter build macos --release
    elif [[ "$OSTYPE" == "msys" ]]; then
        flutter build windows --release
    fi
    
    cd ..
    log "✅ Frontend build completed"
}

# Deploy to production
deploy() {
    log "Deploying to $ENV environment..."
    
    # Create deployment directory
    sudo mkdir -p "$DEPLOY_DIR"
    sudo chown -R $USER:$USER "$DEPLOY_DIR"
    
    # Copy configuration
    cp .env.$ENV "$DEPLOY_DIR/.env"
    
    # Copy docker-compose file
    cp docker-compose.$ENV.yml "$DEPLOY_DIR/docker-compose.yml"
    
    # Copy built artifacts
    cp -r backend/stock-trading-backend "$DEPLOY_DIR/"
    cp -r frontend/build "$DEPLOY_DIR/frontend-build"
    
    cd "$DEPLOY_DIR"
    
    # Stop existing containers
    docker-compose down || true
    
    # Pull latest images
    docker-compose pull
    
    # Start new containers
    docker-compose up -d
    
    # Run database migrations
    docker-compose exec backend ./migrate
    
    # Wait for services to be ready
    sleep 10
    
    # Check health
    if curl -f http://localhost:8080/health; then
        log "✅ Health check passed"
    else
        error "Health check failed"
    fi
    
    cd -
    log "✅ Deployment completed"
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring..."
    
    cd "$DEPLOY_DIR"
    
    # Deploy Prometheus
    docker-compose -f docker-compose.monitoring.yml up -d
    
    # Configure Grafana
    sleep 5
    curl -X POST -H "Content-Type: application/json" -d '{
        "name": "Prometheus",
        "type": "prometheus",
        "url": "http://prometheus:9090",
        "access": "proxy"
    }' http://admin:admin@localhost:3000/api/datasources
    
    cd -
    log "✅ Monitoring setup completed"
}

# Validate deployment
validate() {
    log "Validating deployment..."
    
    # Check backend
    if ! curl -f http://localhost:8080/health; then
        error "Backend health check failed"
    fi
    
    # Check frontend
    if ! curl -f http://localhost:80; then
        error "Frontend health check failed"
    fi
    
    # Check WebSocket
    if ! wscat -c ws://localhost:8080/ws -x '{"action":"ping"}'; then
        warning "WebSocket connection may be problematic"
    fi
    
    # Check database
    if ! docker-compose exec postgres pg_isready; then
        error "Database connection failed"
    fi
    
    log "✅ Validation completed successfully"
}

# Rollback on failure
rollback() {
    error "Deployment failed. Rolling back..."
    
    if [ -d "$BACKUP_DIR" ]; then
        LATEST_BACKUP=$(ls -t "$BACKUP_DIR" | head -1)
        cd "$DEPLOY_DIR"
        docker-compose down
        rm -rf "$DEPLOY_DIR"/*
        tar -xzf "$BACKUP_DIR/$LATEST_BACKUP" -C "$DEPLOY_DIR"
        docker-compose up -d
        log "✅ Rollback completed to $LATEST_BACKUP"
    else
        error "No backup found for rollback"
    fi
}

# Main execution
main() {
    trap rollback ERR
    
    check_prerequisites
    backup
    build_backend
    build_frontend
    deploy
    setup_monitoring
    validate
    
    log "🎉 Deployment of $APP_NAME version $VERSION to $ENV completed successfully!"
}

# Run main function
main "$@"