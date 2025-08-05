# OpenCollective Frontend Docker Development Setup

This guide explains how to run the OpenCollective Frontend in a Docker development environment that connects to your local API.

## Prerequisites

1. **API Setup**: Make sure your OpenCollective API is running locally on port 3060
   - Navigate to your `opencollective-api` directory
   - Run your API development setup (usually `npm run dev` or similar)
   - Verify the API is accessible at `http://localhost:3060/graphql`

2. **Docker Network**: The setup uses the `opencollective-dev` network created by the API's docker-compose
   - If you haven't run the API docker-compose yet, run it first:
     ```bash
     cd ../opencollective-api
     docker-compose -f docker-compose.dev.yml up -d
     ```

## Getting Started

1. **Build and Start the Frontend**:

   ```bash
   # In the opencollective-frontend directory
   docker-compose -f docker-compose.dev.yml up --build
   ```

2. **Access the Application**:
   - Frontend: http://localhost:3000
   - Mailpit (Email testing): http://localhost:1080
   - PostgreSQL: localhost:5432
   - Redis: localhost:6379

## Development Workflow

### Hot Reload

The setup includes volume mounts for hot reload:

- Source code changes will automatically trigger rebuilds
- No need to restart the container for code changes

### Environment Variables

Key environment variables configured for development:

- `API_URL=http://host.docker.internal:3060` - Points to your local API
- `NODE_ENV=development` - Development mode
- `API_KEY=dvl-1510egmf4a23d80342403fb599qd` - Development API key
- `GRAPHQL_BENCHMARK=true` - Enable GraphQL benchmarking

### Logs

View frontend logs:

```bash
docker-compose -f docker-compose.dev.yml logs -f frontend
```

View all service logs:

```bash
docker-compose -f docker-compose.dev.yml logs -f
```

## Services Included

### Frontend

- **Container**: `opencollective-frontend`
- **Port**: 3000
- **Command**: `npm run dev`
- **Volumes**: Source code mounted for hot reload

### Database Services

- **PostgreSQL**: Database for development data
- **Redis**: Caching and session storage
- **Mailpit**: Email testing interface

## Troubleshooting

### API Connection Issues

If the frontend can't connect to the API:

1. **Check API Status**:

   ```bash
   curl http://localhost:3060/graphql
   ```

2. **Verify Network**:

   ```bash
   docker network ls | grep opencollective-dev
   ```

3. **Check Container Logs**:
   ```bash
   docker-compose -f docker-compose.dev.yml logs frontend
   ```

### Port Conflicts

If you get port conflicts:

- Make sure no other services are running on ports 3000, 5432, 6379, 1080, 1025
- Or modify the ports in `docker-compose.dev.yml`

### Permission Issues

If you encounter permission issues with volumes:

```bash
sudo chown -R $USER:$USER .
```

## Useful Commands

### Start services

```bash
docker-compose -f docker-compose.dev.yml up -d
```

### Stop services

```bash
docker-compose -f docker-compose.dev.yml down
```

### Rebuild frontend

```bash
docker-compose -f docker-compose.dev.yml up --build frontend
```

### Shell into frontend container

```bash
docker-compose -f docker-compose.dev.yml exec frontend bash
```

### Clean up

```bash
# Stop and remove containers, networks, and volumes
docker-compose -f docker-compose.dev.yml down -v
```

## Network Architecture

```
┌─────────────────┐    ┌─────────────────────┐
│   Frontend      │    │       API           │
│   (Docker)      │────│   (Host Machine)    │
│   Port: 3000    │    │   Port: 3060        │
└─────────────────┘    └─────────────────────┘
         │
         │ opencollective-dev network
         │
┌─────────────────┐    ┌─────────────────────┐
│   PostgreSQL    │    │      Redis          │
│   (Docker)      │    │    (Docker)         │
│   Port: 5432    │    │   Port: 6379        │
└─────────────────┘    └─────────────────────┘
```

## Notes

- The API runs on the host machine and is accessed via `host.docker.internal:3060`
- All other services (database, redis, etc.) run in Docker containers
- The setup shares the `opencollective-dev` network with the API's supporting services
- Hot reload is enabled for rapid development iterations
