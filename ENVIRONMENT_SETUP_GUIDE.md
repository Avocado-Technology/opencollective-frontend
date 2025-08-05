# OpenCollective Frontend - Multi-Environment Setup Guide

This guide explains how to set up and manage multiple environments for the OpenCollective Frontend using Docker.

## 🏗 Environment Structure

The project supports three distinct environments, each with its own configuration:

| Environment | Purpose                        | Docker Compose               | Dockerfile           | Env File       |
| ----------- | ------------------------------ | ---------------------------- | -------------------- | -------------- |
| **Local**   | Local container development    | `docker-compose.local.yml`   | `Dockerfile.local`   | `.env.local`   |
| **Dev**     | Remote development environment | `docker-compose.dev.yml`     | `Dockerfile.dev`     | `.env.dev`     |
| **Staging** | Pre-production testing         | `docker-compose.staging.yml` | `Dockerfile.staging` | `.env.staging` |

## 📁 Create Environment Files

Since `.env` files are git-ignored, you need to create them manually. Create these files in your project root:

### `.env.local` (Local Container Development)

```bash
# Create the local environment file
cat > .env.local << 'EOF'
# Local Container Development Environment
NODE_ENV=development
OC_ENV=local
PORT=3000

# API Configuration - Point to your local API
API_URL=http://host.docker.internal:3060
INTERNAL_API_URL=http://host.docker.internal:3060
REST_URL=http://host.docker.internal:3060

# Frontend Configuration
WEBSITE_URL=http://localhost:3000
HOSTNAME=localhost

# API Key for local development
API_KEY=dvl-1510egmf4a23d80342403fb599qd

# Services
IMAGES_URL=http://localhost:3000
PDF_SERVICE_V2_URL=http://localhost:3000
ML_SERVICE_URL=http://localhost:3000

# Development flags
DISABLE_MOCK_UPLOADS=true
API_PROXY=true
GRAPHQL_BENCHMARK=true
CAPTCHA_ENABLED=false
CLIENT_ANALYTICS_ENABLED=false
CLIENT_ANALYTICS_DOMAIN=localhost
DISABLE_CONTACT_FORM=false

# Payment providers (sandbox/test mode)
PAYPAL_ENVIRONMENT=sandbox
STRIPE_KEY=pk_test_VgSB4VSg2wb5LdAkz7p38Gw8
WISE_ENVIRONMENT=sandbox
WISE_PLATFORM_COLLECTIVE_SLUG=opencollective-host

# Feature flags
LEDGER_SEPARATE_TAXES_AND_PAYMENT_PROCESSOR_FEES=false
SENTRY_TRACES_SAMPLE_RATE=null

# External API keys (test/development keys)
GOOGLE_MAPS_API_KEY=AIzaSyAZJnIxtBw5bxnu2QoCUiLCjV1nk84Vnk0
RECAPTCHA_SITE_KEY=6LcyeXoUAAAAAFtdHDZfsxncFUkD9NqydqbIFcCK
HCAPTCHA_SITEKEY=10000000-ffff-ffff-ffff-000000000001
TURNSTILE_SITEKEY=0x4AAAAAAAS6okaJ_ThVJqYq
CAPTCHA_PROVIDER=HCAPTCHA

# Secrets
OC_SECRET=local-dev-secret-key-123456
OC_APPLICATION=frontend
EOF
```

### `.env.dev` (Remote Dev Environment)

```bash
# Create the dev environment file
cat > .env.dev << 'EOF'
# Development Environment Configuration
NODE_ENV=development
OC_ENV=development
PORT=3000

# API Configuration - Point to your dev API server
API_URL=https://api-dev.yourcollective.com
INTERNAL_API_URL=https://api-dev.yourcollective.com
REST_URL=https://rest-dev.yourcollective.com

# Frontend Configuration
WEBSITE_URL=https://dev.yourcollective.com
HOSTNAME=dev.yourcollective.com

# API Key for dev environment (replace with your dev key)
API_KEY=your-dev-api-key-here

# Services
IMAGES_URL=https://images-dev.yourcollective.com
PDF_SERVICE_V2_URL=https://pdf-dev.yourcollective.com
ML_SERVICE_URL=https://ml-dev.yourcollective.com

# Development flags
DISABLE_MOCK_UPLOADS=false
API_PROXY=false
GRAPHQL_BENCHMARK=true
CAPTCHA_ENABLED=true
CLIENT_ANALYTICS_ENABLED=true
CLIENT_ANALYTICS_DOMAIN=dev.yourcollective.com
DISABLE_CONTACT_FORM=false

# Payment providers (sandbox mode for dev)
PAYPAL_ENVIRONMENT=sandbox
STRIPE_KEY=pk_test_your_dev_stripe_key
WISE_ENVIRONMENT=sandbox
WISE_PLATFORM_COLLECTIVE_SLUG=opencollective-host

# Feature flags
LEDGER_SEPARATE_TAXES_AND_PAYMENT_PROCESSOR_FEES=false
SENTRY_TRACES_SAMPLE_RATE=0.1

# External API keys (your dev keys)
GOOGLE_MAPS_API_KEY=your-dev-google-maps-key
RECAPTCHA_SITE_KEY=your-dev-recaptcha-key
HCAPTCHA_SITEKEY=your-dev-hcaptcha-key
TURNSTILE_SITEKEY=your-dev-turnstile-key
CAPTCHA_PROVIDER=HCAPTCHA

# Secrets (generate secure random values)
OC_SECRET=your-dev-secret-key-here
OC_APPLICATION=frontend
EOF
```

### `.env.staging` (Staging Environment)

```bash
# Create the staging environment file
cat > .env.staging << 'EOF'
# Staging Environment Configuration
NODE_ENV=production
OC_ENV=staging
PORT=3000

# API Configuration - Point to your staging API
API_URL=https://api-staging.opencollective.com
INTERNAL_API_URL=https://api-staging-direct.opencollective.com
REST_URL=https://rest-staging.opencollective.com

# Frontend Configuration
WEBSITE_URL=https://staging.opencollective.com
HOSTNAME=staging.opencollective.com

# API Key for staging (replace with your staging key)
API_KEY=your-staging-api-key-here

# Services
IMAGES_URL=https://images-staging.opencollective.com
PDF_SERVICE_V2_URL=https://pdf-staging.opencollective.com
ML_SERVICE_URL=https://ml.opencollective.com

# Production-like flags
DISABLE_MOCK_UPLOADS=false
API_PROXY=false
GRAPHQL_BENCHMARK=false
CAPTCHA_ENABLED=true
CLIENT_ANALYTICS_ENABLED=true
CLIENT_ANALYTICS_DOMAIN=staging.opencollective.com
DISABLE_CONTACT_FORM=false

# Payment providers (sandbox for staging)
PAYPAL_ENVIRONMENT=sandbox
STRIPE_KEY=pk_test_your_staging_stripe_key
WISE_ENVIRONMENT=sandbox
WISE_PLATFORM_COLLECTIVE_SLUG=opencollective

# Feature flags
LEDGER_SEPARATE_TAXES_AND_PAYMENT_PROCESSOR_FEES=false
SENTRY_TRACES_SAMPLE_RATE=0.1

# External API keys (your staging keys)
GOOGLE_MAPS_API_KEY=your-staging-google-maps-key
RECAPTCHA_SITE_KEY=your-staging-recaptcha-key
HCAPTCHA_SITEKEY=your-staging-hcaptcha-key
TURNSTILE_SITEKEY=your-staging-turnstile-key
CAPTCHA_PROVIDER=HCAPTCHA

# Secrets (generate secure random values)
OC_SECRET=your-staging-secret-key-here
OC_APPLICATION=frontend
EOF
```

## 🚀 Usage Instructions

### Local Development (Containerized)

```bash
# Start your local API first
cd ../opencollective-api
npm run dev

# Start the containerized frontend
cd ../opencollective-frontend
docker-compose -f docker-compose.local.yml up --build

# Access: http://localhost:3000
```

### Dev Environment

```bash
# Deploy to dev environment
docker-compose -f docker-compose.dev.yml up --build -d

# View logs
docker-compose -f docker-compose.dev.yml logs -f frontend
```

### Staging Environment

```bash
# Deploy to staging (production-like build)
docker-compose -f docker-compose.staging.yml up --build -d

# Access staging frontend
# Configure your domain to point to the staging server
```

## 🔧 Environment-Specific Features

### Local Environment

- ✅ Hot reload enabled
- ✅ Volume mounts for development
- ✅ Connects to host machine API
- ✅ Full database stack included
- ✅ Email testing with Mailpit
- ✅ Debug flags enabled

### Dev Environment

- ✅ Hot reload enabled
- ✅ Connects to remote dev API
- ✅ Lightweight - minimal extra services
- ✅ Development optimizations
- ✅ Email testing available

### Staging Environment

- ✅ Production build
- ✅ Performance optimized
- ✅ Resource limits applied
- ✅ Optional nginx reverse proxy
- ✅ Production-like configuration
- ✅ No development tools

## 🛠 Common Commands

### Switch Between Environments

```bash
# Local development
docker-compose -f docker-compose.local.yml up

# Dev environment
docker-compose -f docker-compose.dev.yml up

# Staging environment
docker-compose -f docker-compose.staging.yml up
```

### Environment Management

```bash
# Stop specific environment
docker-compose -f docker-compose.local.yml down

# View logs for specific environment
docker-compose -f docker-compose.dev.yml logs -f

# Rebuild specific environment
docker-compose -f docker-compose.staging.yml build --no-cache

# Clean up all environments
docker-compose -f docker-compose.local.yml down -v
docker-compose -f docker-compose.dev.yml down -v
docker-compose -f docker-compose.staging.yml down -v
```

### Running Commands in Specific Environments

```bash
# Execute commands in local environment
docker-compose -f docker-compose.local.yml exec frontend npm test

# Execute commands in dev environment
docker-compose -f docker-compose.dev.yml exec frontend npm run lint

# Get shell access
docker-compose -f docker-compose.local.yml exec frontend bash
```

## 🔒 Security Considerations

### API Keys and Secrets

- **Never commit real API keys** to version control
- Use **different API keys** for each environment
- Generate **unique secrets** for each environment
- Store sensitive data in **environment-specific files**

### Environment Isolation

- Each environment uses **separate Docker networks**
- **Container names** are environment-specific
- **Ports** can be customized per environment
- **Volumes** are isolated per environment

## 🐛 Troubleshooting

### Environment File Issues

```bash
# Verify environment file exists
ls -la .env.*

# Check environment file content
cat .env.local

# Test environment loading
docker-compose -f docker-compose.local.yml config
```

### Network Issues

```bash
# Check Docker networks
docker network ls

# Create missing network
docker network create opencollective-dev

# Inspect network
docker network inspect opencollective-dev
```

### Container Issues

```bash
# Check container status
docker-compose -f docker-compose.local.yml ps

# View container logs
docker-compose -f docker-compose.local.yml logs frontend

# Restart specific service
docker-compose -f docker-compose.local.yml restart frontend
```

## 📊 Quick Reference

| Task      | Local                                           | Dev                                           | Staging                                           |
| --------- | ----------------------------------------------- | --------------------------------------------- | ------------------------------------------------- |
| **Start** | `docker-compose -f docker-compose.local.yml up` | `docker-compose -f docker-compose.dev.yml up` | `docker-compose -f docker-compose.staging.yml up` |
| **Build** | `--build`                                       | `--build`                                     | `--build`                                         |
| **Logs**  | `logs -f frontend`                              | `logs -f frontend`                            | `logs -f frontend`                                |
| **Shell** | `exec frontend bash`                            | `exec frontend bash`                          | `exec frontend bash`                              |
| **Stop**  | `down`                                          | `down`                                        | `down`                                            |

## 🔄 Migration from Old Setup

If you were using the old `docker-compose.dev.yml`:

1. It's now renamed to `docker-compose.local.yml`
2. Create the `.env.local` file as shown above
3. Use the new commands for local development

---

**Happy coding across all environments! 🚀**
