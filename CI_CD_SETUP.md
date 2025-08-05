# CI/CD Pipeline Setup for OpenCollective Frontend

This document describes the CI/CD pipeline setup for the OpenCollective Frontend project, based on the `educai-app` infrastructure pattern.

## Overview

The CI/CD pipeline consists of three main workflows:

1. **Build and Push** (`build-and-push.yml`) - Builds Docker images and pushes to GHCR
2. **Deploy** (`deploy.yml`) - Deploys to development and staging environments
3. **Release** (`release.yml`) - Handles semantic versioning and releases

## Infrastructure Setup

### Prerequisites

- GitHub Container Registry (GHCR) for Docker images
- Existing Traefik service running on your infrastructure
- Docker network named `microservices-network`
- Servers for development and staging environments

### Required GitHub Secrets

Configure the following secrets in your GitHub repository (minimal setup):

#### Development Environment

- `DEV_HOST` - Development server hostname/IP
- `DEV_USERNAME` - SSH username for development server
- `DEV_SSH_KEY` - SSH private key for development server

#### Staging Environment

- `STAGING_HOST` - Staging server hostname/IP
- `STAGING_USERNAME` - SSH username for staging server
- `STAGING_SSH_KEY` - SSH private key for staging server

**Note:** All other configuration values (API URLs, service URLs, API keys) are hardcoded in the workflows for simplicity.

## Workflow Triggers

### Build and Push

- **Automatic**: On push to `main` or `develop` branches
- **Automatic**: On pull requests to `main` or `develop` branches
- **Manual**: Via workflow dispatch

### Deploy

- **Automatic**: After successful build for `develop` branch → Deploy to Development
- **Automatic**: After successful build for `main` branch → Deploy to Staging
- **Automatic**: After semantic release → Deploy to Staging

### Release

- **Automatic**: On push to release branches (`main`, `develop`, `beta`, `alpha`, etc.)

## Deployment Process

### Development Deployment

1. Push to `develop` branch
2. Build and push workflow runs
3. On successful build, deploy workflow triggers
4. Application deploys to development environment
5. Available at: `https://dev.avcd.tech/frontend`

### Staging Deployment

1. Push to `main` branch OR semantic release completes
2. Build and push workflow runs
3. On successful build, deploy workflow triggers
4. Application deploys to staging environment
5. Available at: `https://staging.avcd.tech/frontend`

## Traefik Integration

The Docker Compose files are configured to work with your existing Traefik instance:

- **Network**: Uses external `microservices-network`
- **Labels**: Configured for proper routing through Traefik
- **SSL**: Automatic certificate generation via Let's Encrypt
- **Routing**:
  - Development: `dev.avcd.tech/frontend`
  - Staging: `staging.avcd.tech/frontend`

## Health Checks

The deployment includes comprehensive health checking:

1. **Container Health**: Verifies container is running and healthy
2. **URL Health**: Checks application responds to HTTP requests
3. **SSL Health**: For HTTPS URLs, waits for certificate generation
4. **Zero-downtime**: Rolling updates without service interruption

## File Structure

```
.github/workflows/
├── build-and-push.yml    # Build and push Docker images
├── deploy.yml            # Deploy to environments
└── release.yml           # Semantic release workflow

scripts/
└── deploy-health-check.sh # Deployment script with health checks

docker-compose.dev.yml     # Development environment
docker-compose.staging.yml # Staging environment
.releaserc.json           # Semantic release configuration
```

## Environment Variables

The following environment variables are used in deployments (most are hardcoded):

- `REGISTRY` - Docker registry (hardcoded: ghcr.io)
- `IMAGE_NAME` - Docker image name (from GitHub repository)
- `IMAGE_TAG` - Docker image tag (develop/main/latest)
- `NODE_ENV` - Node environment (development/production)
- `API_URL` - OpenCollective API URL (hardcoded: staging URLs)
- `INTERNAL_API_URL` - Internal API URL (hardcoded)
- `IMAGES_URL` - Images service URL (hardcoded)
- `PDF_SERVICE_V2_URL` - PDF service URL (hardcoded)
- `ML_SERVICE_URL` - ML service URL (hardcoded)
- `API_KEY` - API authentication key (hardcoded: staging key)

## Monitoring and Logs

- **Container Status**: Check with `docker-compose ps`
- **Application Logs**: `docker-compose logs -f opencollective-frontend`
- **Health Endpoint**: `/api/health`
- **Traefik Dashboard**: Available at your Traefik dashboard URL

## Troubleshooting

### Common Issues

1. **Container not starting**: Check environment variables and secrets
2. **SSL certificate issues**: Wait for Let's Encrypt certificate generation
3. **Network issues**: Ensure `microservices-network` exists
4. **Image pull failures**: Verify GHCR permissions and secrets

### Debugging Commands

```bash
# Check container status
docker-compose -f docker-compose.dev.yml ps

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Restart deployment
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.dev.yml up -d

# Check network
docker network ls | grep microservices
```

## Semantic Versioning

The project uses conventional commits and semantic release:

- `feat:` → Minor version bump
- `fix:` → Patch version bump
- `BREAKING CHANGE:` → Major version bump
- `chore:`, `docs:`, etc. → No version bump

### Commit Format

```
type(scope): description

[optional body]

[optional footer]
```

Example:

```
feat(auth): add OAuth integration

Add support for GitHub OAuth authentication
to improve user onboarding experience.

Closes #123
```

## Manual Deployment

If needed, you can manually deploy using the health check script:

```bash
# On the target server
cd /opt/opencollective-frontend
./scripts/deploy-health-check.sh docker-compose.dev.yml "https://dev.avcd.tech/frontend/api/health" "opencollective-frontend-dev"
```

## Security Notes

- All secrets are stored in GitHub Secrets
- SSH keys should use modern encryption (RSA 4096+ or Ed25519)
- Container runs as non-root user
- Multi-stage Docker build minimizes attack surface
- Network isolation through Docker networks
