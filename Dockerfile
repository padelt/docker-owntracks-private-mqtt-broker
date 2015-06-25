FROM debian:jessie

MAINTAINER Philipp Adelt <autosort-github@philipp.adelt.net>

# Everthing for the MQTT Broker "mosquitto"
ADD files/mosquitto-jessie.list /etc/apt/sources.list.d/mosquitto-jessie.list
ADD files/mosquitto-repo.gpg.key /tmp/mosquitto-repo.gpg.key
RUN apt-key add /tmp/mosquitto-repo.gpg.key

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y mosquitto supervisor openssl pwgen

RUN adduser --system --disabled-password --disabled-login mosquitto

RUN bash -c 'echo alias ll=\"ls -l\" >> /root/.bashrc'

COPY files/mosquitto.conf.default /tmp/mosquitto.conf.default

# 'generate-CA.sh' is local copy of https://github.com/owntracks/tools/blob/master/TLS/generate-CA.sh
COPY files/generate-CA.sh /tmp/generate-CA.sh
RUN chmod +x /tmp/generate-CA.sh


# Postgresql for persistent storage via o2s
RUN apt-get install -y postgresql
# Allow all users from localhost
RUN echo "host all  all    127.0.0.0/8  md5" >> /etc/postgresql/9.4/main/pg_hba.conf

USER postgres
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker

USER root
COPY files/start.sh /start.sh
RUN chmod +x /start.sh
COPY files/supervisord.conf /etc/supervisord.conf

VOLUME ["/volume"]

EXPOSE 1883 9001 5432

CMD ["/bin/bash", "/start.sh"]
