FROM alpine:3.6

ENV ALPINE_VERSION=3.6

# Install needed packages. Notes:
#   * dumb-init: a proper init system for containers, to reap zombie children
#   * musl: standard C library
#   * linux-headers: commonly needed, and an unusual package name from Alpine.
#   * build-base: used so we include the basic development packages (gcc)
#   * bash: so we can access /bin/bash - REMOVED to use build in busybox instead
#   * ca-certificates: for SSL verification during Pip and easy_install
#   * python: the binaries themselves
#   * python-dev: are used for gevent e.g.
#   * py-setuptools: required only in major version 2, installs easy_install so we can install Pip.
#   * mysql: Mysql server.
#   * mysql-client: Required for django to use mysql as database.
#   * supervisor: To autostart and ensure services stay running.
#   * mariadb-dev: Required by - pip install mysqlclient.
#   * nginx: To serve Django static content and proxy connections back to Django.

ENV PACKAGES="\
  dumb-init \
  musl \
  linux-headers \
  build-base \
  ca-certificates \
  unzip \
  py-setuptools \
  mysql \ 
  mysql-client\
  supervisor \
  mariadb-dev \
  nginx \
"

RUN echo \
  # replacing default repositories with edge ones
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \

  # Add the packages, with a CDN-breakage fallback if needed
  && apk add --no-cache $PACKAGES || \
    (sed -i -e 's/dl-cdn/dl-4/g' /etc/apk/repositories && apk add --no-cache $PACKAGES) \

  # turn back the clock -- so hacky!
  && echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main/" > /etc/apk/repositories \
  # && echo "@edge-testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
  # && echo "@edge-community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  # && echo "@edge-main http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories 


# Add files
ADD files/my.cnf /etc/mysql/my.cnf
ADD files/nginx.conf /etc/nginx/nginx.conf

# Entrypoint
ADD start.sh /
RUN chmod u+x /start.sh
CMD /start.sh
