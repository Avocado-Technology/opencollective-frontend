#!/bin/bash

# Optimized Deployment Script with Health Checks
# Usage: ./deploy-health-check.sh <compose-file> <health-url> <container-name>

set -e

COMPOSE_FILE="${1:-docker-compose.yml}"
HEALTH_URL="${2:-http://localhost}"
CONTAINER_NAME="${3:-app}"
MAX_RETRIES=60  # Increased from 30 to accommodate longer health checks
RETRY_INTERVAL=5
SSL_MAX_RETRIES=20
SSL_RETRY_INTERVAL=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"
}

# Function to check if container is healthy
check_container_health() {
    local container=$1
    local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not_found")
    
    if [[ "$status" == "running" ]]; then
        # Check if container has health check defined
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")
        if [[ "$health" == "healthy" ]]; then
            return 0
        elif [[ "$health" == "none" ]]; then
            # No health check defined, just check if running
            return 0
        fi
    fi
    return 1
}

# Function to wait for container to be healthy
wait_for_container() {
    local container=$1
    local retries=0
    
    log "Waiting for container '$container' to be healthy..."
    
    while [[ $retries -lt $MAX_RETRIES ]]; do
        if check_container_health "$container"; then
            success "Container '$container' is healthy"
            return 0
        fi
        
        retries=$((retries + 1))
        log "Container health check attempt $retries/$MAX_RETRIES..."
        sleep $RETRY_INTERVAL
    done
    
    error "Container '$container' failed to become healthy after $MAX_RETRIES attempts"
    return 1
}

# Function to check URL health
check_url_health() {
    local url=$1
    local response=$(curl -s -I "$url" -k --connect-timeout 10 --max-time 20 2>/dev/null || echo "FAILED")
    
    if echo "$response" | grep -q "HTTP/.*[23][0-9][0-9]\|HTTP/.*301\|HTTP/.*302"; then
        return 0
    fi
    return 1
}

# Function to wait for URL to be accessible
wait_for_url() {
    local url=$1
    local retries=0
    local max_retries=$2
    local interval=${3:-$RETRY_INTERVAL}
    
    log "Waiting for URL '$url' to be accessible..."
    
    while [[ $retries -lt $max_retries ]]; do
        if check_url_health "$url"; then
            success "URL '$url' is accessible"
            return 0
        fi
        
        retries=$((retries + 1))
        log "URL health check attempt $retries/$max_retries..."
        sleep $interval
    done
    
    warning "URL '$url' not accessible after $max_retries attempts (may still be initializing)"
    return 1
}

# Function for zero-downtime deployment
zero_downtime_deploy() {
    local compose_file=$1
    
    log "Starting zero-downtime deployment..."
    
    # Check if containers are already running
    if docker-compose -f "$compose_file" ps -q | grep -q .; then
        log "Existing containers found, performing rolling update..."
        
        # Pull latest images first
        docker-compose -f "$compose_file" pull
        
        # Recreate only the application container, keep other services running
        docker-compose -f "$compose_file" up -d --force-recreate opencollective-frontend
        
        # Clean up any orphaned containers
        docker-compose -f "$compose_file" up -d --remove-orphans
    else
        log "No existing containers, performing fresh deployment..."
        docker-compose -f "$compose_file" up -d --remove-orphans
    fi
}

# Main deployment function
main() {
    log "🚀 Starting optimized deployment with health checks..."
    log "📄 Compose file: $COMPOSE_FILE"
    log "🌐 Health URL: $HEALTH_URL"
    log "📦 Container: $CONTAINER_NAME"
    
    # Perform zero-downtime deployment
    zero_downtime_deploy "$COMPOSE_FILE"
    
    # Wait for application container to be healthy
    if ! wait_for_container "$CONTAINER_NAME"; then
        error "Deployment failed: Container health check failed"
        log "📋 Container logs:"
        docker-compose -f "$COMPOSE_FILE" logs --tail=50 "$CONTAINER_NAME" || true
        exit 1
    fi
    
    # Wait for application URL to be accessible (quick check)
    wait_for_url "$HEALTH_URL" 15 $RETRY_INTERVAL
    
    # If HTTPS URL, wait longer for SSL certificate generation
    if [[ "$HEALTH_URL" == https* ]]; then
        log "🔒 HTTPS detected, waiting for SSL certificate generation..."
        if ! wait_for_url "$HEALTH_URL" $SSL_MAX_RETRIES $SSL_RETRY_INTERVAL; then
            warning "SSL certificate may still be generating. Deployment completed but HTTPS may take a few more minutes."
        else
            success "HTTPS is working correctly"
        fi
    fi
    
    # Show final status
    log "📊 Final container status:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    # Cleanup old images (non-blocking)
    log "🧹 Cleaning up old images..."
    docker image prune -f --filter "dangling=true" 2>/dev/null || true
    
    success "🎉 Deployment completed successfully!"
}

# Error handling
trap 'error "Deployment failed with exit code $?"; exit 1' ERR

# Run main function
main "$@"