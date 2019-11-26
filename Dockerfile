ARG NODE_VERSION=10.15.3
FROM node:${NODE_VERSION}
ARG GITHUB_ACCOUNT=ging
ARG GITHUB_REPOSITORY=fiware-idm
ARG DOWNLOAD_TYPE=latest

ENV GITHUB_ACCOUNT=${GITHUB_ACCOUNT}
ENV GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
ENV DOWNLOAD_TYPE=${DOWNLOAD_TYPE}

MAINTAINER FIWARE Identity Manager Team. DIT-UPM

WORKDIR /opt

ENV IDM_HOST="http://localhost:3000" \
    IDM_PORT="3000" \
    IDM_PDP_LEVEL="basic" \
    IDM_DB_HOST="localhost" \
    IDM_DB_NAME="idm" \
    IDM_DB_DIALECT="mysql" \
    IDM_EMAIL_HOST="localhost" \
    IDM_EMAIL_PORT="25" \
    IDM_EMAIL_ADDRESS="noreply@localhost"

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential python debconf-utils curl git netcat  && \
    echo "postfix postfix/mailname string ${IDM_EMAIL_ADDRESS}" | debconf-set-selections && \
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    apt-get install -y --no-install-recommends postfix mailutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    sed -i 's/inet_interfaces = all/inet_interfaces = loopback-only/g' /etc/postfix/main.cf

RUN apt-get update && \
    apt-get install -y  --no-install-recommends unzip && \
    wget https://github.com/ging/fiware-idm/archive/FIWARE_7.7.zip && \
    unzip FIWARE_7.7.zip && \
    mv fiware-idm-FIWARE_7.7 /opt/fiware-idm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt/fiware-idm

RUN rm -rf doc extras  && \
    npm cache clean -f   && \
    npm install --production  && \
    rm -rf /root/.npm/cache/* && \
    mkdir certs && \
    openssl genrsa -out idm-2018-key.pem 2048 && \
    openssl req -new -sha256 -key idm-2018-key.pem -out idm-2018-csr.pem -batch && \
    openssl x509 -req -in idm-2018-csr.pem -signkey idm-2018-key.pem -out idm-2018-cert.pem && \
    mv idm-2018-key.pem idm-2018-cert.pem idm-2018-csr.pem certs/

COPY config_database.js extras/docker/config_database.js
COPY config.js.template config.js

COPY docker-entrypoint.sh /opt/fiware-idm/docker-entrypoint.sh
RUN chmod 755 docker-entrypoint.sh

ENTRYPOINT ["/opt/fiware-idm/docker-entrypoint.sh"]

EXPOSE ${IDM_PORT}
