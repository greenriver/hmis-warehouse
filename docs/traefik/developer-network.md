# Local Proxy
To make accessing the Warehouse and CAS sites easier, we use a local reverse proxy called [Traefik](http://traefik.io)

## Traefik Setup
1. Create a `traefik` directory outside of the Warehouse and CAS repository folders
2. Copy the everything in the [traefik directory](./traefik) into the new `traefik` directory you just created
3. Within the new `traefik` directory, [setup the SSL certificates](#SSL-Setup) as noted below
4. Add the certificates to your browser or keychain to avoid the self-signed certificate warnings
5. Add the `traefik` docker network `docker network create traefik`
5. Start `traefik` with `docker-compose up -d`

## SSL Setup
```
cd tools/certs
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
  DNS.4 = *.boston-cas.dev.test
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
cd ../../
```














Once the certificates are setup and in place, turn on the traefik network and bring up the traefik docker container
```
docker network create traefik
docker compose up -d reverse-proxy
```
