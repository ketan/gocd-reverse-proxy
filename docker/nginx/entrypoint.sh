#!/bin/sh

openssl version
java -version

# export private key from `keystore` to p12 format
rm -rf /ssl-export
mkdir -p /ssl-export/go-server /ssl-export/go-agent

keytool -importkeystore \
  -srckeystore /gocd-server-data/config/keystore \
  -destkeystore /ssl-export/go-server/keystore.p12 \
  -srcalias cruise \
  -srcstoretype jks \
  -deststoretype pkcs12 \
  -srcstorepass serverKeystorepa55w0rd \
  -deststorepass serverKeystorepa55w0rd

# export keystore from p12 to pem
openssl pkcs12 \
        -in /ssl-export/go-server/keystore.p12 \
        -out /ssl-export/go-server/keystore.webserver.private.key.with.passphrase.pem \
        -passin pass:serverKeystorepa55w0rd \
        -passout pass:serverKeystorepa55w0rd \
        -password pass:serverKeystorepa55w0rd

openssl rsa \
  -in /ssl-export/go-server/keystore.webserver.private.key.with.passphrase.pem \
  -out /ssl-export/go-server/keystore.webserver.private.key.no.passphrase.pem \
  -passin pass:serverKeystorepa55w0rd

openssl x509 \
  -in /ssl-export/go-server/keystore.webserver.private.key.with.passphrase.pem \
  -out /ssl-export/go-server/keystore.webserver.cert.chain.pem

# export the agent cert + private key (to be used by proxy to authenticate with gocd)
keytool -importkeystore \
  -srckeystore /gocd-agent-data/config/agent.jks \
  -destkeystore /ssl-export/go-agent/agent.p12 \
  -srcalias agent \
  -srcstoretype jks \
  -deststoretype pkcs12 \
  -srcstorepass agent5s0repa55w0rd \
  -deststorepass agent5s0repa55w0rd

openssl pkcs12 \
        -in /ssl-export/go-agent/agent.p12 \
        -out /ssl-export/go-agent/agent.private.key.with.passphrase.pem \
        -passin pass:agent5s0repa55w0rd \
        -passout pass:agent5s0repa55w0rd \
        -password pass:agent5s0repa55w0rd

openssl rsa \
  -in /ssl-export/go-agent/agent.private.key.with.passphrase.pem \
  -out /ssl-export/go-agent/agent.private.key.no.passphrase.pem \
  -passin pass:agent5s0repa55w0rd

openssl x509 \
  -in /ssl-export/go-agent/agent.private.key.with.passphrase.pem \
  -out /ssl-export/go-agent/agent.cert.pem

exec nginx -g 'daemon off;'
