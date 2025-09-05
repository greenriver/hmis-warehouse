# Developer Setup

This document provides instructions for setting up the Open Path Warehouse for local development. The warehouse uses a complete development stack with Docker, reverse proxy, DNS resolution, and mail capture.

Once you have the application running, you may find the [developer data guide](data.md) and [developer FAQ](faq.md) useful in gaining more familiarity with the application.

The warehouse application consists of three main parts:
1. The Rails Application Code
2. The Rails Application Database
3. The Warehouse Database

## Quick Start (Automated Installation)

For macOS users, we provide a comprehensive installation script that handles all setup automatically:

1. Clone the git repository
```bash
git clone git@github.com:greenriver/hmis-warehouse.git
cd hmis-warehouse
```

2. Run the automated installer
```bash
bin/developer/install.sh
```

The installer will:
- Validate your system environment
- Install prerequisites (Homebrew, Colima, etc.)
- Set up DNS resolution for development domains
- Configure Traefik reverse proxy with SSL certificates
- Set up MailHog for development email
- Initialize the HMIS Warehouse application

3. Start the application
```bash
docker compose run --rm web
```

Your application will be available at `https://hmis-warehouse.dev.test`

## Manual Setup (Alternative)

If you prefer manual setup or are on a different platform, follow the detailed instructions in [prerequisites.md](prerequisites.md) for setting up:

1. **Infrastructure Prerequisites** - Docker environment, DNS resolution, SSL certificates, reverse proxy, and mail service
2. **HMIS Warehouse Configuration** - Application-specific setup (covered below)

### Configure HMIS Warehouse

Once the infrastructure is set up (see [prerequisites.md](prerequisites.md)), configure the warehouse application:

```bash
cd /path/to/hmis-warehouse

# Copy environment files
cp sample.env .env.development.local
cp docs/sample_files/envrc.sample .envrc
touch .env.local

# Configure direnv
direnv allow .

# Fix permissions and run setup
docker compose run -u 0 shell chown -R app-user:app-user /bundle /app
docker compose run --rm shell bin/setup
docker compose run -u 0 shell bash -c 'chown -R app-user:app-user /bundle /app && if [ -d /node_modules ]; then chown -R app-user:app-user /node_modules; fi'
```

### Start the Application

```bash
docker compose run --rm web
```

## Accessing the Site

Once setup is complete, your development environment provides:

- **HMIS Warehouse**: [https://hmis-warehouse.dev.test](https://hmis-warehouse.dev.test)
- **MailHog (Email)**: [https://mailhog.dev.test](https://mailhog.dev.test)
- **Traefik Dashboard**: [http://localhost:8080](http://localhost:8080)

All emails sent by the application are captured by MailHog for development testing.

## Loading Data

At this point, you'll probably want to [load some sample HMIS data](data.md).

## Customization

### Using Different Domains

To use a custom domain (e.g., `example.local` instead of `dev.test`):

```bash
# For automated installation
bin/developer/install.sh --domain example.local

# For manual setup, replace 'dev.test' with your domain in:
# - DNS configuration
# - SSL certificate generation
# - Traefik and MailHog configurations
# - Environment files (.env.development.local, .envrc)
```

### Custom Installation Paths

```bash
# Specify custom paths for services
bin/developer/install.sh --traefik-path ~/custom/traefik --mailhog-path ~/custom/mailhog
```

## Troubleshooting

### Permission Issues

If you encounter permission issues with Docker containers:

```bash
docker compose run -u 0 --entrypoint='' web chown -R app-user:app-user /node_modules /bundle /app /log /tmp
```

### Infrastructure Issues

For DNS, SSL, port conflicts, and other infrastructure issues, see the comprehensive troubleshooting guide in [prerequisites.md](prerequisites.md#troubleshooting-infrastructure).

### System Validation

Run the system check to validate your environment:

```bash
bin/developer/system_check.sh
```

## Uninstallation

To completely remove the development environment:

```bash
bin/developer/uninstall.sh
```

This will:
- Stop all Docker services
- Clean up DNS configuration
- Remove SSL certificates
- Clean up installation directories
- Optionally remove installed packages
