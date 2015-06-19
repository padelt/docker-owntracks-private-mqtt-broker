FROM debian:jessie

MAINTAINER Philipp Adelt <autosort-github@philipp.adelt.net>

ADD files/mosquitto-jessie.list /etc/apt/sources.list.d/mosquitto-jessie.list
ADD files/mosquitto-repo.gpg.key /tmp/mosquitto-repo.gpg.key
RUN apt-key add /tmp/mosquitto-repo.gpg.key

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y mosquitto supervisor openssl pwgen

RUN adduser --system --disabled-password --disabled-login mosquitto

RUN bash -c 'echo alias ll=\"ls -l\" >> /root/.bashrc'

COPY files/start.sh /start.sh
RUN chmod +x /start.sh
COPY files/mosquitto.conf.default /tmp/mosquitto.conf.default
COPY files/supervisord.conf /etc/supervisord.conf

# 'generate-CA.sh' is local copy of https://github.com/owntracks/tools/blob/master/TLS/generate-CA.sh
COPY files/generate-CA.sh /tmp/generate-CA.sh
RUN chmod +x /tmp/generate-CA.sh
VOLUME ["/volume"]

EXPOSE 1883 9001

CMD ["/bin/bash", "/start.sh"]
