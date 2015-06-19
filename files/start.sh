#!/bin/bash
VOLUME=/volume
CLIENTS_DIR=$VOLUME/config/clients
PASSWD_FILE=$CLIENTS_DIR/passwd

if [ ! -d $VOLUME ]
then
   echo MISSING VOLUME. Please start container with mounted $VOLUME directory!
   exit 1;
fi

mkdir -p $VOLUME/data
mkdir -p $VOLUME/log
mkdir -p $VOLUME/config/conf.d

# Provide an initial Mosquitto config if nothing is there yet.
if [ ! -f $VOLUME/config/mosquitto.conf ]
then
   cp /tmp/mosquitto.conf.default $VOLUME/config/mosquitto.conf
fi

# Create a minimal CA-infrastructure with a server and 10 client certs if not there yet
if [ ! -d $VOLUME/config/tls ]
then
   mkdir -p $VOLUME/config/tls
   cd $VOLUME/config/tls
   /tmp/generate-CA.sh
   for ((i=1;i<=10;i++)); do
      /tmp/generate-CA.sh client$i
      PASSWORD=`pwgen --no-capitalize --numerals --ambiguous 14 1`
      echo client$i:$PASSWORD >> PASSWD_FILE
   done
   ln -s `hostname -f`.crt server.crt
   ln -s `hostname -f`.key server.key
fi

# Generate some client authentication tokens and configuration files.
if [ ! -d $CLIENTS_DIR ]
then
   mkdir -p $CLIENTS_DIR
   touch $PASSWD_FILE
   cd $CLIENTS_DIR
   for ((i=1;i<=10;i++)); do
      PASSWORD=`pwgen --no-capitalize --numerals --ambiguous 14 1`
      echo "Username client$i with Password $PASSWORD" >> $PASSWD_FILE.cleartext
      mosquitto_passwd -b $PASSWD_FILE client$i $PASSWORD
   done
fi

chown -R mosquitto:root $VOLUME/*
chmod -R g+wr $VOLUME/*

supervisord -n -c /etc/supervisord.conf -e debug
