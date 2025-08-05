#!/bin/bash

# OpenCollective Frontend Migration Script
# Handles any migration tasks for deployments

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
    error "Usage: $0 <environment> (dev|staging|prod)"
fi

ENVIRONMENT=$1

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    error "Invalid environment. Use: dev, staging, or prod"
fi

info "🔄 Running migrations for OpenCollective Frontend ($ENVIRONMENT)..."

# Load environment variables
ENV_FILE=".env.$ENVIRONMENT"
if [ -f "$ENV_FILE" ]; then
    info "📋 Loading environment variables from $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
fi

# Frontend-specific migrations (if any)
# For now, this mainly handles cache clearing and static asset updates

info "🧹 Clearing Next.js cache..."
rm -rf .next/cache || true

info "🗂️  Clearing any old static assets..."
rm -rf .next/static || true

# If in Docker environment, run migrations inside container
DOCKER_COMPOSE_FILE="docker-compose.$ENVIRONMENT.yml"
if [ -f "$DOCKER_COMPOSE_FILE" ]; then
    CONTAINER_NAME="opencollective-frontend-$ENVIRONMENT"
    
    # Check if container is running
    if docker ps | grep -q "$CONTAINER_NAME"; then
        info "🔧 Running cache clear inside container..."
        docker exec "$CONTAINER_NAME" rm -rf .next/cache || true
        docker exec "$CONTAINER_NAME" rm -rf .next/static || true
        
        # Restart the container to pick up changes
        info "🔄 Restarting container to apply changes..."
        docker-compose -f "$DOCKER_COMPOSE_FILE" restart
    else
        warning "Container $CONTAINER_NAME is not running"
    fi
fi

success "Migration completed for $ENVIRONMENT environment!"