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
   echo "Setting default configuration mosquitto.conf. Feel free to improve!"
   cp /tmp/mosquitto.conf.default $VOLUME/config/mosquitto.conf
fi

# Create a minimal CA-infrastructure with a server and 10 client certs if not there yet
if [ ! -d $VOLUME/config/tls ]
then
   echo "Generating fresh TLS/SSL infrastructure. Don't forget to install ca.crt on your devices!"
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
   echo "Generating users and client configuration files (.otrc). Open one of those with the app."
   if [ -f $VOLUME/host.config ]
   then
      . $VOLUME/host.config
   fi

   if [ "x$HOSTNAME" == "x" ] || [ "x$PORT" == "x" ] 
   then
      echo "************ PLEASE FIX host.config, then remove the config/clients/ directory and run again! ************"
      HOSTNAME="THIS.WILL.NOT.WORK.PLEASE.FIX.HOST.CONFIG.FILE.example.org"
      PORT="1883"
   fi

   mkdir -p $CLIENTS_DIR
   touch $PASSWD_FILE
   cd $CLIENTS_DIR
   
   for ((i=1;i<=10;i++)); do
      PASSWORD=`pwgen --no-capitalize --numerals --ambiguous 14 1`
      USERNAME=client$i
      echo "Username $USERNAME with Password $PASSWORD" >> $PASSWD_FILE.cleartext
      mosquitto_passwd -b $PASSWD_FILE $USERNAME $PASSWORD
      cat > $USERNAME.otrc <<EOF
{
  "ranging" : false,
  "positions" : 50,
  "monitoring" : 1,
  "willTopic" : "",
  "deviceId" : "$USERNAME",
  "host" : "$HOSTNAME",
  "tid" : "$i",
  "_type" : "configuration",
  "keepalive" : 60,
  "pubTopicBase" : "",
  "cmd" : false,
  "allowRemoteLocation" : true,
  "subTopic" : "",
  "pubRetain" : true,
  "willRetain" : false,
  "updateAddressBook" : false,
  "waypoints" : [

  ],
  "port" : $PORT,
  "pubQos" : 1,
  "locatorInterval" : 300,
  "tls" : true,
  "auth" : true,
  "cleanSession" : true,
  "extendedData" : true,
  "clientId" : "$USERNAME",
  "willQos" : 1,
  "password" : "$PASSWORD",
  "locatorDisplacement" : 2000,
  "mode" : 0,
  "subQos" : 1,
  "username" : "$USERNAME"
}
EOF
      
   done
fi

chown -R mosquitto:root $VOLUME/*
chmod -R g+wr $VOLUME/*

supervisord -n -c /etc/supervisord.conf -e debug
