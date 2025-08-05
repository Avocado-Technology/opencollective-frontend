# Local Pipeline Testing Guide

This guide shows you how to test the CI/CD pipeline locally before pushing to GitHub.

## 🎯 **Method 1: Using `act` (Recommended)**

### Install `act`

```bash
# macOS (with Homebrew)
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Windows (with Chocolatey)
choco install act-cli
```

### Test Workflows Locally

```bash
# Test the build-and-push workflow
act push --workflows .github/workflows/build-and-push.yml

# Test with specific branch simulation
act push -e .github/workflows/build-and-push.yml --eventpath /tmp/push-event.json

# Test deployment workflow (requires secrets file)
act workflow_run --workflows .github/workflows/deploy.yml --secret-file .secrets
```

### Create `.secrets` file for testing

```bash
# Create a secrets file (DON'T commit this!)
echo "DEV_HOST=your-dev-server.com" > .secrets
echo "DEV_USERNAME=your-username" >> .secrets
echo "DEV_SSH_KEY=your-ssh-key" >> .secrets
echo "STAGING_HOST=your-staging-server.com" >> .secrets
echo "STAGING_USERNAME=your-username" >> .secrets
echo "STAGING_SSH_KEY=your-ssh-key" >> .secrets
echo "GITHUB_TOKEN=your-github-token" >> .secrets
```

## 🐳 **Method 2: Manual Docker Testing**

### Test Docker Build

```bash
# Test the Docker build process
docker build -t opencollective-frontend:test .

# Test with build args (like the pipeline does)
docker build -t opencollective-frontend:test . \
  --build-arg API_URL=https://api-staging.opencollective.com \
  --build-arg INTERNAL_API_URL=https://api-staging-direct.opencollective.com \
  --build-arg IMAGES_URL=https://images-staging.opencollective.com \
  --build-arg PDF_SERVICE_V2_URL=https://pdf-staging.opencollective.com \
  --build-arg ML_SERVICE_URL=https://ml.opencollective.com \
  --build-arg API_KEY=09u624Pc9F47zoGLlkg1TBSbOl2ydSAq

# Test running the container
docker run -p 3000:3000 opencollective-frontend:test
```

### Test Docker Compose

```bash
# Create local environment variables
export REGISTRY=ghcr.io
export IMAGE_NAME=opencollective/opencollective-frontend
export IMAGE_TAG=test
export API_URL=https://api-staging.opencollective.com
export INTERNAL_API_URL=https://api-staging-direct.opencollective.com
export IMAGES_URL=https://images-staging.opencollective.com
export PDF_SERVICE_V2_URL=https://pdf-staging.opencollective.com
export ML_SERVICE_URL=https://ml.opencollective.com
export API_KEY=09u624Pc9F47zoGLlkg1TBSbOl2ydSAq

# Test development compose
docker-compose -f docker-compose.dev.yml config  # Validate syntax
docker-compose -f docker-compose.dev.yml up --build

# Test staging compose
docker-compose -f docker-compose.staging.yml config
docker-compose -f docker-compose.staging.yml up --build
```

## 🔧 **Method 3: Script Testing**

### Test Deployment Script

```bash
# Make script executable
chmod +x scripts/deploy-health-check.sh

# Test script with mock parameters
./scripts/deploy-health-check.sh \
  docker-compose.dev.yml \
  "http://localhost:3000/api/health" \
  "opencollective-frontend-dev"
```

### Test Individual Commands

```bash
# Test the commands that run in the pipeline

# 1. Install dependencies
npm ci

# 2. Build (like CI does)
npm run build

# 3. Run tests
npm run test:coverage

# 4. Run linting
npm run lint:quiet

# 5. Run prettier
npm run prettier:check

# 6. Type checking
npm run type:check
```

## 🌐 **Method 4: Network Testing**

### Create Docker Network

```bash
# Create the microservices network (like the pipeline does)
docker network create microservices-network
docker network ls | grep microservices
```

### Test with Traefik Labels

```bash
# If you have Traefik running locally, test the labels
docker-compose -f docker-compose.dev.yml up -d

# Check if Traefik picks up the service
curl -H "Host: dev.avcd.tech" http://localhost/frontend/api/health
```

## 🧪 **Method 5: Semantic Release Testing**

### Test Release Process

```bash
# Test semantic release locally (dry run)
npx semantic-release --dry-run

# Test with specific branch
npx semantic-release --dry-run --branches main
```

## 📋 **Testing Checklist**

### Before Pushing to GitHub:

- [ ] Docker image builds successfully
- [ ] Docker Compose files are valid
- [ ] Health check script executes without errors
- [ ] All npm scripts run successfully
- [ ] Network configuration is correct
- [ ] Environment variables are properly set

### Commands to Run:

```bash
# Full local test sequence
npm ci
npm run lint:quiet
npm run prettier:check
npm run type:check
npm run build
docker build -t test-image .
docker run --rm -p 3000:3000 test-image &
sleep 10
curl http://localhost:3000/api/health
docker stop $(docker ps -q --filter ancestor=test-image)
```

## 🚨 **Troubleshooting**

### Common Issues:

1. **`act` fails with permission errors**

   ```bash
   # Run with Docker sudo privileges
   sudo act push --workflows .github/workflows/build-and-push.yml
   ```

2. **Docker build fails**

   ```bash
   # Check build context
   docker build --no-cache -t test .
   ```

3. **Network issues**

   ```bash
   # Reset Docker networks
   docker network prune
   docker network create microservices-network
   ```

4. **Port conflicts**
   ```bash
   # Check what's running on port 3000
   lsof -i :3000
   # Kill process if needed
   kill -9 <PID>
   ```

## 🎯 **Quick Test Script**

Create a test script to automate the process:

```bash
#!/bin/bash
# save as test-pipeline.sh

echo "🧪 Testing CI/CD Pipeline Locally..."

echo "📦 1. Testing Docker build..."
docker build -t opencollective-frontend:test . || exit 1

echo "✅ 2. Testing npm scripts..."
npm ci || exit 1
npm run lint:quiet || exit 1
npm run prettier:check || exit 1
npm run type:check || exit 1

echo "🐳 3. Testing container..."
docker run -d -p 3000:3000 --name test-container opencollective-frontend:test
sleep 15

echo "🏥 4. Testing health endpoint..."
if curl -f http://localhost:3000/api/health; then
    echo "✅ Health check passed!"
else
    echo "❌ Health check failed!"
fi

echo "🧹 5. Cleanup..."
docker stop test-container
docker rm test-container

echo "🎉 Local testing complete!"
```

```bash
chmod +x test-pipeline.sh
./test-pipeline.sh
```

This gives you comprehensive local testing before pushing to GitHub!
