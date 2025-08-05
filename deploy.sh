#!/bin/bash

# OpenCollective Frontend Deployment Script
# Based on the Traefik deployment model

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

info "🚀 Deploying OpenCollective Frontend to $ENVIRONMENT environment..."

# Load environment variables
ENV_FILE=".env.$ENVIRONMENT"
if [ ! -f "$ENV_FILE" ]; then
    warning "Environment file $ENV_FILE not found. Using defaults."
else
    info "📋 Loading environment variables from $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
fi

# Set Docker Compose file based on environment
DOCKER_COMPOSE_FILE="docker-compose.$ENVIRONMENT.yml"

if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    error "Docker Compose file $DOCKER_COMPOSE_FILE not found"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running. Please start Docker and try again."
fi

# Create network if it doesn't exist
NETWORK_NAME="opencollective-$ENVIRONMENT"
if [ "$ENVIRONMENT" != "dev" ]; then
    NETWORK_NAME="traefik-$ENVIRONMENT"
fi

if ! docker network inspect "$NETWORK_NAME" > /dev/null 2>&1; then
    info "🌐 Creating Docker network: $NETWORK_NAME"
    docker network create "$NETWORK_NAME" || warning "Network may already exist"
fi

# Stop and remove existing containers
info "🛑 Stopping existing containers..."
docker-compose -f "$DOCKER_COMPOSE_FILE" down || true

# Clean up old images (optional)
if [ "$ENVIRONMENT" = "dev" ]; then
    info "🧹 Cleaning up old development images..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down --rmi local || true
fi

# Build and start services
info "🏗️  Building and starting services..."
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d --build

# Wait for services to start
info "⏳ Waiting for services to start..."
sleep 10

# Show container status
info "📊 Container status:"
docker-compose -f "$DOCKER_COMPOSE_FILE" ps

# Health check
info "🏥 Performing health check..."
if [ "$ENVIRONMENT" = "dev" ]; then
    if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
        success "Health check passed!"
    else
        warning "Health check failed, but deployment completed"
    fi
fi

success "OpenCollective Frontend deployed successfully to $ENVIRONMENT!"

# Show helpful information
if [ "$ENVIRONMENT" = "dev" ]; then
    info "🌐 Frontend available at: http://localhost:3000"
    info "🔍 To check logs: docker-compose -f $DOCKER_COMPOSE_FILE logs -f"
    info "🛑 To stop: docker-compose -f $DOCKER_COMPOSE_FILE down"
fi