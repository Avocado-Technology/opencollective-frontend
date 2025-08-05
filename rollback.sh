#!/bin/bash

# OpenCollective Frontend Rollback Script
# Provides rollback functionality for deployments

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Check if environment is provided
if [ -z "$1" ]; then
    error "Usage: $0 <environment> [backup_tag] (dev|staging|prod)"
fi

ENVIRONMENT=$1
BACKUP_TAG=${2:-"previous"}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    error "Invalid environment. Use: dev, staging, or prod"
fi

info "🔄 Rolling back OpenCollective Frontend in $ENVIRONMENT environment..."

# Set Docker Compose file based on environment
DOCKER_COMPOSE_FILE="docker-compose.$ENVIRONMENT.yml"

if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    error "Docker Compose file $DOCKER_COMPOSE_FILE not found"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running. Please start Docker and try again."
fi

# Load environment variables
ENV_FILE=".env.$ENVIRONMENT"
if [ -f "$ENV_FILE" ]; then
    info "📋 Loading environment variables from $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
fi

CONTAINER_NAME="opencollective-frontend-$ENVIRONMENT"

# Create backup of current deployment
info "💾 Creating backup of current deployment..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/$ENVIRONMENT"
mkdir -p "$BACKUP_DIR"

# Stop current services
info "🛑 Stopping current services..."
docker-compose -f "$DOCKER_COMPOSE_FILE" down

# Check for previous backup or specific tag
if [ "$BACKUP_TAG" = "previous" ]; then
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/ 2>/dev/null | head -n1 || echo "")
    if [ -z "$LATEST_BACKUP" ]; then
        error "No previous backup found to rollback to"
    fi
    BACKUP_TAG="$LATEST_BACKUP"
fi

BACKUP_PATH="$BACKUP_DIR/$BACKUP_TAG"
if [ ! -d "$BACKUP_PATH" ]; then
    error "Backup not found: $BACKUP_PATH"
fi

info "🔄 Rolling back to backup: $BACKUP_TAG"

# Restore from backup
if [ -f "$BACKUP_PATH/docker-compose.$ENVIRONMENT.yml" ]; then
    cp "$BACKUP_PATH/docker-compose.$ENVIRONMENT.yml" "docker-compose.$ENVIRONMENT.yml"
    success "Restored Docker Compose configuration"
fi

if [ -f "$BACKUP_PATH/.env.$ENVIRONMENT" ]; then
    cp "$BACKUP_PATH/.env.$ENVIRONMENT" ".env.$ENVIRONMENT"
    success "Restored environment configuration"
fi

# Start services with rollback configuration
info "🚀 Starting services with rollback configuration..."
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d

# Wait for services to start
info "⏳ Waiting for services to start..."
sleep 15

# Health check
info "🏥 Performing health check..."
if [ "$ENVIRONMENT" = "dev" ]; then
    if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
        success "Health check passed!"
    else
        warning "Health check failed, manual verification needed"
    fi
fi

# Show container status
info "📊 Container status:"
docker-compose -f "$DOCKER_COMPOSE_FILE" ps

success "Rollback completed for $ENVIRONMENT environment!"
info "📝 Rolled back to: $BACKUP_TAG"

# Show helpful information
if [ "$ENVIRONMENT" = "dev" ]; then
    info "🌐 Frontend available at: http://localhost:3000"
fi