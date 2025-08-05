#!/bin/bash

# OpenCollective Frontend Setup Script
# Initializes the development environment

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

echo "🚀 Setting up OpenCollective Frontend development environment..."
echo "=================================================="

# Check prerequisites
info "🔍 Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    error "Node.js is not installed. Please install Node.js 20+ and try again."
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
    warning "Node.js version $NODE_VERSION detected. Node.js 20+ is recommended."
fi

# Check npm
if ! command -v npm &> /dev/null; then
    error "npm is not installed. Please install npm and try again."
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker and try again."
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running. Please start Docker and try again."
fi

success "Prerequisites check passed!"

# Install dependencies
info "📦 Installing dependencies..."
npm install

# Create environment files
info "📝 Creating environment files..."

# Development environment
if [ ! -f ".env.dev" ]; then
    cat > .env.dev << EOF
NODE_ENV=development
API_URL=http://localhost:3060
INTERNAL_API_URL=http://localhost:3060
IMAGES_URL=https://images.opencollective.com
WEBSITE_URL=http://localhost:3000
EOF
    success "Created .env.dev"
else
    info ".env.dev already exists"
fi

# Staging environment
if [ ! -f ".env.staging" ]; then
    cat > .env.staging << EOF
NODE_ENV=production
API_URL=https://api-staging.opencollective.com
INTERNAL_API_URL=https://api-staging.opencollective.com
IMAGES_URL=https://images-staging.opencollective.com
WEBSITE_URL=https://staging.opencollective.com
# Add your domain configuration here
FRONTEND_DOMAIN=frontend-staging.avcd.tech
EOF
    success "Created .env.staging"
else
    info ".env.staging already exists"
fi

# Production environment
if [ ! -f ".env.prod" ]; then
    cat > .env.prod << EOF
NODE_ENV=production
API_URL=https://api.opencollective.com
INTERNAL_API_URL=https://api.opencollective.com
IMAGES_URL=https://images.opencollective.com
WEBSITE_URL=https://opencollective.com
# Add your domain configuration here
FRONTEND_DOMAIN=frontend.avcd.tech
EOF
    success "Created .env.prod"
else
    info ".env.prod already exists"
fi

# Create local environment for development
if [ ! -f ".env.local" ]; then
    cp .env.dev .env.local
    success "Created .env.local"
else
    info ".env.local already exists"
fi

# Build the application
info "🏗️  Building the application..."
npm run build

success "🎉 Setup completed successfully!"
echo ""
info "Next steps:"
info "1. Review and update environment variables in .env.dev, .env.staging, and .env.prod"
info "2. Run 'npm run deploy:dev' to start the development environment"
info "3. Visit http://localhost:3000 to access the frontend"
echo ""
info "Available commands:"
info "• npm run deploy:dev     - Deploy to development environment"
info "• npm run deploy:staging - Deploy to staging environment"
info "• npm run deploy:prod    - Deploy to production environment"
info "• npm run dev            - Start development server (traditional mode)"