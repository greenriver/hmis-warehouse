# Developer Setup for Docker Networking and Local Email

This document is specific to the Mac environment, since that's generally what Green River uses, but most of the steps are platform agnostic, and the concepts can be extended to any environment.

The following three items will make development much more seamless.

1. Setup DNS resolution for a set of domains to be used for development to point to your local development machine.

2. Create and trust a self-signed certificate to allow for development access over SSL.

3. Setup of an nginx-proxy server to route requests to the appropriate docker container.

## DNS setup
These instructions are loosely based on https://gist.github.com/jed/6147872

If you don't have [Homebrew](http://brew.sh/) installed yet, follow the [instructions on that site](http://brew.sh/).

* Install dnsmasq to route DNS requests for `*.dev.test` to your local machine
```
brew install dnsmasq
mkdir -pv $(brew --prefix)/etc
sudo mkdir -pv /etc/resolver
echo "address=/.test/127.0.0.1" | sudo tee -a $(brew --prefix)/etc/dnsmasq.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/dev.test
sudo brew services start dnsmasq
```

It can be very helpful to add the following lines to your `/etc/hosts` file to allow non-docker development to work in conjunction with dockerized workflows.

```
# Docker Compose mirror so we can leave our .env files alone
127.0.0.1 host.docker.internal
```

## Certificate
We'll generate a self-signed certificates for traefik to serve our site over ssl. Before you begin this, make sure you have an installation of the [traefik proxy](http://traefik.io) up and running. 
```
cd <path_to_traefik_installation>/tools/certs  
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

rm openssl.cnf
open dev.test.crt
```

When prompted to add the certificate to your Keychain, choose the System keychain.  After verifying that you are an administrator, search for `dev.test` in Keychain Access and double click the certificate.  Open the Trust section and in the top drop-down select Always Trust.

# Traefik proxy

Update the Virtual-Machine repo's `.tools/traefik/config.yml` file to reference these certificates.

Once the certificates are setup and in place, turn on the traefik network and bring up the traefik docker container
```
docker network create traefik
docker compose up -d reverse-proxy
```

### DIRENV

If not already set up, install DIRENV. You will need to allow the changes after updating the file.

```
brew install direnv
direnv allow
```

Append your `.envrc` with the following 

```
export FQDN=hmis-warehouse.dev.test
export TRAEFIK_ENABLED=true
```

Allow the file changes through direnv
```
direnv allow
```
For direnv to work properly it needs to be hooked into the shell. Each shell has its own extension mechanism. Complete the [setup instructions](https://direnv.net/docs/hook.html) for  your shell.
