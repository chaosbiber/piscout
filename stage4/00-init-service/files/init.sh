#!/bin/bash

cd $HOME

CONFIGDIR="$HOME/.piscout"

function wait_for_network {
  CHECK_HNs=$(hostname --all-fqdns)
  CHECK_IPs=$(hostname --all-ip-addresses)
  while [ -z "$CHECK_HNs" -o -z "$CHECK_IPs" ];
  do
    sleep 1
    CHECK_HNs=$(hostname --all-fqdns)
    CHECK_IPs=$(hostname --all-ip-addresses)
  done;
}

function create_config_dir {
  if [ ! -d "$CONFIGDIR" ]; then
    mkdir $CONFIGDIR
  fi
}

function create_or_read_mongo_pw {
  create_config_dir
  if [ -s "${CONFIGDIR}/mongopw.env" ]; then
    source ${CONFIGDIR}/mongopw.env
  else
    MONGO_PW=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)
    echo "MONGO_PW=$MONGO_PW" > $CONFIGDIR/mongopw.env
    chmod 600 $CONFIGDIR/mongopw.env
  fi
}

function create_or_read_apisecret {
  create_config_dir
  if [ -s "${CONFIGDIR}/apisecret.env" ]; then
    source $CONFIGDIR/apisecret.env
  else
    API_SECRET=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)
    echo "API_SECRET=$API_SECRET" > $CONFIGDIR/apisecret.env
    chmod 600 $CONFIGDIR/apisecret.env
  fi
}

function run_once {
  if [ -f "${CONFIGDIR}/run_once" ]; then
    exit 0
  fi
}

function read_last_ipv4 {
  create_config_dir
  if [ -s "${CONFIGDIR}/last_ipv4.env" ]; then
    source $CONFIGDIR/last_ipv4.env
  else
    LAST_IPV4=""
  fi
}

function read_current_ipv4 {
  CURRENT_IPV4=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
}

wait_for_network

# check ip address and update self-signed cert
read_last_ipv4
read_current_ipv4

printf "[req]\ndefault_bits = 2048\ndistinguished_name = req_distinguished_name\nreq_extensions = req_ext\n[req_distinguished_name]\n[req_ext]\nsubjectAltName = @alt_names\n[alt_names]\nDNS.1 = localhost\nDNS.2 = `hostname -f`\nIP.1 = 127.0.0.1\nIP.2 = ${CURRENT_IPV4}\n" > /tmp/extfile.cnf

function generate_ca {
  sudo openssl req -nodes -x509 -newkey rsa:2048 -keyout /etc/nginx/localhost-ca.key -out /etc/nginx/localhost-ca.crt -subj "/C=DE/ST=unicorn country/L=unicorn city/O=nightscout/CN=`hostname -f`" -days 365
}

function generate_csr {
  sudo openssl req -nodes -newkey rsa:2048 -keyout /etc/nginx/localhost.key -out /etc/nginx/localhost.csr -subj "/C=DE/ST=unicorn country/L=unicorn city/O=nightscout/CN=`hostname -f`" -config /tmp/extfile.cnf
}

function generate_crt {
  sudo openssl x509 -req -in /etc/nginx/localhost.csr -CA /etc/nginx/localhost-ca.crt -CAkey /etc/nginx/localhost-ca.key -CAcreateserial -out /etc/nginx/localhost.crt  -extensions req_ext -extfile /tmp/extfile.cnf -days 365
}

if [ "$LAST_IPV4" != "$CURRENT_IPV4" ]; then
  if ! { [ -f "/etc/nginx/localhost-ca.key" ] && [ -f "/etc/nginx/localhost-ca.crt" ]; }; then
    generate_ca
  fi
  generate_csr
  generate_crt
  echo "LAST_IPV4=$CURRENT_IPV4" > $CONFIGDIR/last_ipv4.env
  sudo systemctl reload nginx
fi

if openssl x509 -checkend 604800 -noout -in /etc/nginx/localhost-ca.crt
then
  echo "Certificate is good for another week"
else
  generate_ca
  generate_csr
  generate_crt
  echo "LAST_IPV4=$CURRENT_IPV4" > $CONFIGDIR/last_ipv4.env
  sudo systemctl reload nginx
fi

run_once

create_or_read_mongo_pw
create_or_read_apisecret

# mongo needs to initialize, some seconds should suffice
sleep 30

mongo --eval "db.dropUser(\"nightscoutuser\")" nightscout
mongo --eval "db.createUser({user: \"nightscoutuser\",pwd: \"$MONGO_PW\",roles: [{role: \"readWrite\", db: \"nightscout\"}]})" nightscout

sudo systemctl enable nightscout.service
sudo systemctl enable nginx.service
sudo systemctl start nightscout.service
sudo systemctl start nginx.service

touch "${CONFIGDIR}/run_once"