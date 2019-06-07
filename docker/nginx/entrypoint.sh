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

# export `agentkeystore` contents
keytool -importkeystore \
  -srckeystore /gocd-server-data/config/agentkeystore \
  -destkeystore /ssl-export/go-server/agent-ca-intermediate.p12 \
  -srcalias ca-intermediate \
  -srcstoretype jks \
  -deststoretype pkcs12 \
  -srcstorepass Crui3CertSigningPassword \
  -deststorepass Crui3CertSigningPassword

openssl pkcs12 \
        -in /ssl-export/go-server/agent-ca-intermediate.p12 \
        -out /ssl-export/go-server/agent-ca-intermediate.private.key.with.passphrase.pem \
        -passin pass:Crui3CertSigningPassword \
        -passout pass:Crui3CertSigningPassword \
        -password pass:Crui3CertSigningPassword

openssl rsa \
  -in /ssl-export/go-server/agent-ca-intermediate.private.key.with.passphrase.pem \
  -out /ssl-export/go-server/agent-ca-intermediate.private.key.no.passphrase.pem \
  -passin pass:Crui3CertSigningPassword

openssl x509 \
  -in /ssl-export/go-server/agent-ca-intermediate.private.key.with.passphrase.pem \
  -out /ssl-export/go-server/agent-ca-intermediate.cert.pem

# export ca-cert from agentkeystore
keytool -importkeystore \
  -srckeystore /gocd-server-data/config/agentkeystore \
  -destkeystore /ssl-export/go-server/agent-ca-cert.p12 \
  -srcalias ca-cert \
  -srcstoretype jks \
  -deststoretype pkcs12 \
  -srcstorepass Crui3CertSigningPassword \
  -deststorepass Crui3CertSigningPassword

openssl pkcs12 \
        -in /ssl-export/go-server/agent-ca-cert.p12 \
        -passin pass:Crui3CertSigningPassword \
        -passout pass:Crui3CertSigningPassword \
        -password pass:Crui3CertSigningPassword | openssl x509 \
            -out /ssl-export/go-server/agent-ca-cert.pem

cat /ssl-export/go-server/agent-ca-intermediate.cert.pem /ssl-export/go-server/agent-ca-cert.pem > /ssl-export/go-server/agent-ca.cert.chain.pem

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
