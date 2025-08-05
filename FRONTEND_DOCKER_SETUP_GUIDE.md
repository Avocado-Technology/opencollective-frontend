# OpenCollective Frontend Docker Development Setup Guide

This guide provides step-by-step instructions for setting up the OpenCollective Frontend with Docker to connect to your local API development environment.

## 🎯 Overview

This setup allows you to:

- Run the frontend in a Docker container with hot reload
- Connect to your local API running on the host machine
- Use shared database and services through Docker networking
- Maintain a consistent development environment

## 📋 Prerequisites

### 1. API Setup

- OpenCollective API must be running locally on **port 3060**
- Navigate to your API directory and start the development server:
  ```bash
  cd ../opencollective-api
  npm run dev
  ```
- Verify API is accessible: `curl http://localhost:3060/graphql`

### 2. Docker Requirements

- Docker and Docker Compose installed
- At least 4GB RAM available for Docker

## 🚀 Quick Start

### Step 1: Prepare the Environment

```bash
# Navigate to the frontend directory
cd /path/to/opencollective-frontend

# Create the Docker network (if it doesn't exist)
docker network create opencollective-dev 2>/dev/null || echo "Network already exists"
```

### Step 2: Start the Development Environment

```bash
# Build and start all services
docker-compose -f docker-compose.dev.yml up --build

# Or run in background
docker-compose -f docker-compose.dev.yml up --build -d
```

### Step 3: Access Your Application

- **Frontend**: http://localhost:3000
- **Email Testing (Mailpit)**: http://localhost:1080
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## 📁 Project Structure

```
opencollective-frontend/
├── docker-compose.dev.yml     # Docker Compose configuration
├── Dockerfile.dev            # Development Dockerfile
├── FRONTEND_DOCKER_SETUP_GUIDE.md  # This guide
└── ...rest of your project
```

## 🔧 Configuration Details

### Environment Variables

The setup automatically configures these key variables:

```env
# API Connection
API_URL=http://host.docker.internal:3060
INTERNAL_API_URL=http://host.docker.internal:3060
REST_URL=http://host.docker.internal:3060

# Development Settings
NODE_ENV=development
OC_ENV=development
API_KEY=dvl-1510egmf4a23d80342403fb599qd

# Services
WEBSITE_URL=http://localhost:3000
GRAPHQL_BENCHMARK=true
```

### Services Included

| Service    | Container Name          | Port      | Purpose                    |
| ---------- | ----------------------- | --------- | -------------------------- |
| Frontend   | opencollective-frontend | 3000      | Next.js development server |
| PostgreSQL | opencollective-postgres | 5432      | Database                   |
| Redis      | opencollective-redis    | 6379      | Caching & sessions         |
| Mailpit    | opencollective-mailpit  | 1080/1025 | Email testing              |

## 💻 Development Workflow

### Hot Reload

- Source code is mounted as a volume
- Changes to files automatically trigger rebuilds
- No need to restart containers for code changes

### Viewing Logs

```bash
# Frontend logs only
docker-compose -f docker-compose.dev.yml logs -f frontend

# All service logs
docker-compose -f docker-compose.dev.yml logs -f

# Specific service logs
docker-compose -f docker-compose.dev.yml logs -f postgres
```

### Running Commands Inside Container

```bash
# Get a shell inside the frontend container
docker-compose -f docker-compose.dev.yml exec frontend bash

# Run npm commands
docker-compose -f docker-compose.dev.yml exec frontend npm run test

# Install new packages
docker-compose -f docker-compose.dev.yml exec frontend npm install package-name
```

## 🛠 Common Commands

### Starting Services

```bash
# Start all services
docker-compose -f docker-compose.dev.yml up

# Start in background
docker-compose -f docker-compose.dev.yml up -d

# Start with rebuild
docker-compose -f docker-compose.dev.yml up --build

# Start specific service
docker-compose -f docker-compose.dev.yml up frontend
```

### Stopping Services

```bash
# Stop all services
docker-compose -f docker-compose.dev.yml down

# Stop and remove volumes
docker-compose -f docker-compose.dev.yml down -v

# Stop specific service
docker-compose -f docker-compose.dev.yml stop frontend
```

### Maintenance

```bash
# Rebuild specific service
docker-compose -f docker-compose.dev.yml build frontend

# Pull latest images
docker-compose -f docker-compose.dev.yml pull

# Remove unused containers and images
docker system prune -f
```

## 🐛 Troubleshooting

### Frontend Won't Start

1. **Check API Connection**:

   ```bash
   curl http://localhost:3060/graphql
   ```

2. **Verify Network**:

   ```bash
   docker network ls | grep opencollective-dev
   ```

3. **Check Container Status**:
   ```bash
   docker-compose -f docker-compose.dev.yml ps
   ```

### Port Conflicts

If you get "port already in use" errors:

1. **Find what's using the port**:

   ```bash
   lsof -i :3000  # Replace 3000 with the conflicting port
   ```

2. **Modify ports in docker-compose.dev.yml**:
   ```yaml
   ports:
     - '3001:3000' # Change host port
   ```

### Database Connection Issues

1. **Reset database**:

   ```bash
   docker-compose -f docker-compose.dev.yml down -v
   docker-compose -f docker-compose.dev.yml up postgres
   ```

2. **Check database logs**:
   ```bash
   docker-compose -f docker-compose.dev.yml logs postgres
   ```

### Performance Issues

1. **Increase Docker resources** (Docker Desktop → Settings → Resources)
2. **Clear build cache**:
   ```bash
   docker builder prune -f
   ```

### Permission Problems

```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Or for specific directories
sudo chown -R $USER:$USER node_modules .next
```

## 🔄 Updating Dependencies

### Update npm packages

```bash
# Stop services
docker-compose -f docker-compose.dev.yml down

# Rebuild with new dependencies
docker-compose -f docker-compose.dev.yml build --no-cache frontend

# Start services
docker-compose -f docker-compose.dev.yml up
```

## 📊 Health Checks

The setup includes health checks for all services:

```bash
# Check service health
docker-compose -f docker-compose.dev.yml ps

# Manual health check
curl -f http://localhost:3000/api/health
```

## 🌐 Network Architecture

```
Host Machine                    Docker Network (opencollective-dev)
┌─────────────────┐           ┌──────────────────────────────────┐
│                 │           │                                  │
│  API Server     │◄──────────│  Frontend Container              │
│  localhost:3060 │           │  opencollective-frontend:3000    │
│                 │           │                                  │
└─────────────────┘           │  ┌─────────────┬─────────────┐   │
                               │  │ PostgreSQL  │   Redis     │   │
                               │  │ :5432       │   :6379     │   │
                               │  └─────────────┴─────────────┘   │
                               │                                  │
                               │  ┌─────────────────────────────┐ │
                               │  │        Mailpit              │ │
                               │  │      :1080 / :1025          │ │
                               │  └─────────────────────────────┘ │
                               └──────────────────────────────────┘
```

## 📝 Notes

- **API Key**: Uses development key `dvl-1510egmf4a23d80342403fb599qd`
- **Network**: Connects to `opencollective-dev` external network
- **Volumes**: Source code, node_modules, and .next are mounted for optimal performance
- **Environment**: All services configured for development mode

## 🆘 Getting Help

If you encounter issues:

1. Check the logs for error messages
2. Verify your API is running and accessible
3. Ensure Docker has sufficient resources
4. Try rebuilding containers with `--no-cache`

## 🔄 Future Updates

To update this setup:

1. Modify `docker-compose.dev.yml` for service changes
2. Update `Dockerfile.dev` for build process changes
3. Update environment variables as needed
4. Rebuild containers after major changes

---

**Happy coding! 🚀**
