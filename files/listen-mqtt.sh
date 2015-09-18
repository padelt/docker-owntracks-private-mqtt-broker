#!/bin/bash
USERNAME=client1
PASSWORD=`grep "$USERNAME " /volume/config/clients/passwd.cleartext  | sed "s/^.*Password \(.*\)$/\1/"`
mosquitto_sub -v -h 127.0.0.1 -p 8883 --cafile /volume/config/tls/ca.crt -u $USERNAME -P $PASSWORD --insecure -t "owntracks/#"
