#!/bin/sh

C=US
O=StrongSwan
CA_CN=strongswan.org
SERVER_CN=moon.strongswan.org
SERVER_SAN=moon.strongswan.org
CLIENT_CN="carol@strongswan.org"

CONFIG_DIR=$PWD/config/ipsec.d
IPSEC="docker run -it --rm=true -v $CONFIG_DIR:/etc/ipsec.d strongswan"

mkdir -p $CONFIG_DIR/aacerts \
         $CONFIG_DIR/acerts \
         $CONFIG_DIR/cacerts \
         $CONFIG_DIR/certs \
         $CONFIG_DIR/crls \
         $CONFIG_DIR/ocspcerts \
         $CONFIG_DIR/private

eval $IPSEC pki --gen --outform pem > $CONFIG_DIR/private/caKey.pem
eval $IPSEC pki --self --in /etc/ipsec.d/private/caKey.pem --dn \"C=$C, O=$O, CN=$CA_CN\" --ca --outform pem > $CONFIG_DIR/cacerts/caCert.pem

eval $IPSEC pki --gen --outform pem > $CONFIG_DIR/private/serverKey.pem
eval $IPSEC pki --issue --in /etc/ipsec.d/private/serverKey.pem --type priv --cacert /etc/ipsec.d/cacerts/caCert.pem --cakey /etc/ipsec.d/private/caKey.pem --dn \"C=$C, O=$O, CN=$SERVER_CN\" --san=\"$SERVER_SAN\" --flag serverAuth --flag ikeIntermediate --outform pem > $CONFIG_DIR/certs/serverCert.pem

eval $IPSEC pki --gen --outform pem > $CONFIG_DIR/private/clientKey.pem
eval $IPSEC pki --issue --in /etc/ipsec.d/private/clientKey.pem --type priv --cacert /etc/ipsec.d/cacerts/caCert.pem --cakey /etc/ipsec.d/private/caKey.pem --dn \"C=$C, O=$O, CN=$CLIENT_CN\" --san=\"$CLIENT_CN\" --outform pem > $CONFIG_DIR/certs/clientCert.pem
openssl pkcs12 -export -inkey $CONFIG_DIR/private/clientKey.pem -in $CONFIG_DIR/certs/clientCert.pem -name \"$CLIENT_CN\" -certfile $CONFIG_DIR/cacerts/caCert.pem -caname \"$CA_CN\" -out $CONFIG_DIR/clientCert.p12

