# syntax=docker/dockerfile:1
# hadolint global ignore=DL3008,DL3015
FROM debian:12-slim

LABEL org.opencontainers.image.source="https://github.com/0xfossman/znuny-docker"
LABEL org.opencontainers.image.description="Docker image for Znuny ITSM"
LABEL org.opencontainers.image.licenses="GPL-3.0"

ARG DEBIAN_FRONTEND=noninteractive
ARG ZNUNY_MAJOR=6.5

RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    mariadb-client \
    cpanminus \
    libapache2-mod-perl2 \
    libdbd-mysql-perl \
    libtimedate-perl \
    libnet-dns-perl \
    libnet-ldap-perl \
    libio-socket-ssl-perl \
    libpdf-api2-perl \
    libsoap-lite-perl \
    libtext-csv-xs-perl \
    libjson-xs-perl \
    libapache-dbi-perl \
    libxml-libxml-perl \
    libxml-libxslt-perl \
    libyaml-perl \
    libarchive-zip-perl \
    libcrypt-eksblowfish-perl \
    libencode-hanextra-perl \
    libmail-imapclient-perl \
    libtemplate-perl \
    libdatetime-perl \
    libmoo-perl \
    bash-completion \
    libyaml-libyaml-perl \
    libjavascript-minifier-xs-perl \
    libcss-minifier-xs-perl \
    libauthen-sasl-perl \
    libauthen-ntlm-perl \
    libhash-merge-perl \
    libical-parser-perl \
    libspreadsheet-xlsx-perl \
    libcrypt-jwt-perl \
    libcrypt-openssl-x509-perl \
    libcpan-audit-perl \
    libdata-uuid-perl \
    libdbd-odbc-perl \
    libdbd-pg-perl \
    wget \
    jq \
    sudo \
    cron \
    ca-certificates && \
    rm -rf /var/lib/apt/lists

RUN set -eux; \
    mkdir -p /opt/otrs; \
    wget "https://download.znuny.org/releases/znuny-latest-${ZNUNY_MAJOR}.tar.gz" -O /tmp/znuny.tar.gz; \
    tar -xzf /tmp/znuny.tar.gz --strip-components=1 -C /opt/otrs; \
    rm -f /tmp/znuny.tar.gz

RUN useradd -d /opt/otrs -c 'Znuny user' -g www-data -s /bin/bash -M -N otrs && \
    cp /opt/otrs/Kernel/Config.pm.dist /opt/otrs/Kernel/Config.pm && \
    /opt/otrs/bin/otrs.SetPermissions.pl && \
    cpanm --notest Jq || true

RUN ln -sfn /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/conf-available/zzz_znuny.conf && \
    a2enconf zzz_znuny

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
