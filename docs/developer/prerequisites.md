# Developer Prerequisites and Infrastructure

This document covers the infrastructure components required for HMIS Warehouse development. While these instructions are macOS-focused, the concepts can be adapted to other platforms.

The development environment requires several infrastructure components:

1. **Container Runtime**: Docker environment (Colima or Docker Desktop)
2. **DNS Resolution**: Wildcard DNS for development domains
3. **Reverse Proxy**: Traefik for routing and SSL termination
4. **SSL Certificates**: Self-signed certificates for HTTPS
5. **Mail Service**: MailHog for development email capture
6. **Environment Management**: direnv for environment variables

## System Requirements

- **Operating System**: macOS (Intel or Apple Silicon)
- **Memory**: 8GB+ RAM (32GB recommended)
- **Disk Space**: 10GB+ free space
- **Ports**: 80, 443, 1025, 8025, 8080 must be available
- **Tools**: Xcode Command Line Tools

## Automated Setup

The recommended approach is using the automated installation script:

```bash
bin/developer/install.sh
```

This script handles all prerequisites automatically. The sections below detail what the automation does for manual setup or troubleshooting.

## Manual Infrastructure Setup

### Container Runtime (Docker)

The warehouse requires Docker for containerized development. You can use either Colima (lightweight) or Docker Desktop.

#### Option 1: Colima (Recommended)

```bash
# Install Colima and dependencies
brew install lima colima docker docker-compose

# Configure Docker CLI plugins
mkdir -p ~/.docker/cli-plugins
ln -sfn /opt/homebrew/bin/docker-compose ~/.docker/cli-plugins/docker-compose

# Create optimized Colima configuration
colima template > ~/.colima/default.yaml
# Edit to set: cpu: 8, memory: 16, vmType: vz, rosetta: true, mountType: virtiofs

# Start Colima
colima start
```

#### Option 2: Docker Desktop

If you prefer Docker Desktop, install it from [docker.com](https://www.docker.com/products/docker-desktop). The installer will only install direnv in this case.

### Environment Management

```bash
# Install and configure direnv
brew install direnv

# Add to shell profile (zsh)
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

### DNS Resolution

Wildcard DNS resolution allows all subdomains of your development domain (e.g., `*.dev.test`) to automatically resolve to localhost without manual `/etc/hosts` entries.

```bash
# Install dnsmasq
brew install dnsmasq

# Configure wildcard DNS for dev.test
echo "address=/.dev.test/127.0.0.1" | sudo tee -a $(brew --prefix)/etc/dnsmasq.conf

# Set up system resolver
sudo mkdir -p /etc/resolver
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/dev.test

# Add Docker compatibility
echo "127.0.0.1 host.docker.internal" | sudo tee -a /etc/hosts

# Start dnsmasq service
sudo brew services start dnsmasq

# Test DNS resolution
nslookup hmis-warehouse.dev.test 127.0.0.1
```

#### Custom Domains

To use a different domain (e.g., `example.local`):

```bash
# Replace dev.test with your domain in the commands above
echo "address=/.example.local/127.0.0.1" | sudo tee -a $(brew --prefix)/etc/dnsmasq.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/example.local
```

### SSL Certificates

Self-signed SSL certificates enable HTTPS access for development sites.

```bash
# Create certificate directory
mkdir -p ~/Sites/traefik/traefik/tools/certs
cd ~/Sites/traefik/traefik/tools/certs

# Generate SSL certificate with multiple domains
cat > openssl.cnf <<-EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = *.dev.test
[v3_req]
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.dev.test
DNS.2 = dev.test
DNS.3 = *.hmis-warehouse.dev.test
EOF

# Create certificate and private key
openssl req \
  -new \
  -newkey rsa:2048 \
  -sha256 \
  -days 3650 \
  -nodes \
  -x509 \
  -keyout dev.test.key \
  -out dev.test.crt \
  -config openssl.cnf

# Clean up configuration file
rm openssl.cnf

# Add certificate to system keychain
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain dev.test.crt
```

#### Certificate Trust

After installation, the certificate should be automatically trusted. If needed, you can manually trust it:

1. Open Keychain Access
2. Search for `dev.test`
3. Double-click the certificate
4. Expand "Trust" section
5. Set "When using this certificate" to "Always Trust"

### Reverse Proxy (Traefik)

Traefik provides automatic HTTPS routing and load balancing for development services.

```bash
# Create traefik directory structure
mkdir -p ~/Sites/traefik/traefik/tools/traefik
cd ~/Sites/traefik/traefik

# Copy configuration files (adjust source path as needed)
cp /path/to/hmis-warehouse/docs/sample_files/traefik/docker-compose.sample.yml docker-compose.yml
cp /path/to/hmis-warehouse/docs/sample_files/traefik/tools/traefik/config.sample.yml tools/traefik/config.yml

# Create development network
docker network create development

# Start traefik
docker compose up -d reverse-proxy
```

#### Traefik Configuration

The Traefik configuration automatically:
- Routes HTTP traffic to HTTPS
- Provides SSL termination using generated certificates
- Discovers services via Docker labels
- Exposes dashboard at http://localhost:8080

### Mail Service (MailHog)

MailHog captures all emails sent by the application for development testing.

```bash
# Create mailhog directory
mkdir -p ~/Sites/mailhog
cd ~/Sites/mailhog

# Copy configuration
cp /path/to/hmis-warehouse/docs/sample_files/mailhog/docker-compose.sample.yml docker-compose.yml

# Start mailhog
docker compose up -d
```

MailHog provides:
- SMTP server on port 1025
- Web interface at https://mailhog.dev.test
- Email storage and viewing for development

## Infrastructure Validation

Validate your infrastructure setup:

```bash
# Run system validation
bin/developer/system_check.sh

# Test individual components
nslookup hmis-warehouse.dev.test 127.0.0.1  # DNS
curl -k https://hmis-warehouse.dev.test      # SSL (after app is running)
curl http://localhost:8080                   # Traefik dashboard
```

## Network Architecture

The development environment uses this network flow:

```
Browser → DNS Resolution (dnsmasq) → Traefik (SSL termination) → Docker Services
```

- **DNS**: `*.dev.test` → `127.0.0.1`
- **Traefik**: Routes based on Host headers
- **Services**: Connected via `development` Docker network

## Troubleshooting Infrastructure

### DNS Issues

```bash
# Check dnsmasq status
brew services list | grep dnsmasq

# Restart dnsmasq
sudo brew services restart dnsmasq

# Flush DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### Certificate Issues

```bash
# Verify certificate
openssl x509 -in dev.test.crt -text -noout

# Check keychain
security find-certificate -c "*.dev.test" -p /Library/Keychains/System.keychain
```

### Docker Issues

```bash
# Check Colima status
colima status

# Restart Colima
colima restart

# Check Docker networks
docker network ls
```

### Port Conflicts

```bash
# Check what's using required ports
lsof -i :80 -i :443 -i :1025 -i :8025 -i :8080
```

## Custom Configuration

### Different Domain

To use `example.local` instead of `dev.test`:

1. Update DNS configuration
2. Regenerate SSL certificates
3. Update Traefik and MailHog configurations
4. Update warehouse environment files

### Different Installation Paths

Services can be installed in custom locations by adjusting paths in the configuration files and Docker volumes.

## Cleanup

To remove the infrastructure:

```bash
# Use the uninstall script
bin/developer/uninstall.sh

# Or manually:
docker compose down  # In each service directory
docker network rm development
sudo brew services stop dnsmasq
# Remove DNS and certificate configurations
```
