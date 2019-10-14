# Dockerfile for a Docker image to build Java projects.
# by Thanh Nguyen <btnguyen2k@gmail.com>
# version: 11.0.4-slim-d19.03.3-m3.6.2-n12.12.0-s1.2.8 (2019-10-14)
# Content:
#   - OpenJDK 11 (11.0.4-jdk-slim)
#   - Docker-in-Docker engine v19.xx.y
#   - Maven v3.x.y
#   - NodeJS v12.x.y with RequireJS
#   - Sbt v1.2.x
# Build with command:
#   $ docker build --squash --force-rm -t <tag> <path/to/Dockerfile>
# Example:
#   $ docker build --squash --force-rm -t btnguyen2k/cicd-java11:11.0.4-slim-d19.03.3-m3.6.2-n12.12.0-s1.2.8 -f slim-d19-m3-n12-s1.Dockerfile .

FROM openjdk:11.0.4-jdk-slim

MAINTAINER Thanh Nguyen <btnguyen2k@gmail.com>, version: 11.0.4-slim-d19.03.3-m3.6.2-n12.12.0-s1.2.8

# Init
#RUN apk add --no-cache bash
#RUN apk add --no-cache --virtual .build-deps \
#  curl \
#  wget \
#  tar \
#  procps

#for "slim":
RUN apt-get update && apt-get install -y wget curl

# Maven (ref https://github.com/carlossg/docker-maven/blob/05f4802aa5c253dcf75fe967c6f45b3fb1e2f26e/jdk-8-alpine/Dockerfile)
ARG MAVEN_VERSION="3.6.2"
ARG USER_HOME_DIR="/root"
ARG SHA="d941423d115cd021514bfd06c453658b1b3e39e6240969caf4315ab7119a77299713f14b620fb2571a264f8dff2473d8af3cb47b05acf0036fc2553199a5c1ee"
ARG BASE_URL="https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries"
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
ARG MAVEN_HOME="/usr/share/maven"
ARG MAVEN_CONFIG="$USER_HOME_DIR/.m2"

# Sbt (ref https://github.com/bigtruedata/docker-sbt/blob/master/0.13.15/2.12.2/Dockerfile)
ARG SBT_VERSION="1.2.8"
RUN wget -O- "https://sbt-downloads.cdnedge.bluemix.net/releases/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" \
    |  tar xzf - -C /usr/local --strip-components=1 \
    && sbt exit

# Docker-in-Docker (ref https://github.com/docker-library/docker/blob/91bbc4f7b06c06020d811dafb2266bcd7cf6c06d/18.09/Dockerfile)
# set up nsswitch.conf for Go's "netgo" implementation (which Docker explicitly uses)
# - https://github.com/docker/docker-ce/blob/v17.09.0-ce/components/engine/hack/make.sh#L149
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
# - docker run --rm debian:stretch grep '^hosts:' /etc/nsswitch.conf
RUN if [ ! -e /etc/nsswitch.conf ]; then echo 'hosts: files dns' > /etc/nsswitch.conf; fi
ARG DOCKER_CHANNEL="stable"
ARG DOCKER_VERSION="19.03.3"
# TODO ENV DOCKER_SHA256
# https://github.com/docker/docker-ce/blob/5b073ee2cf564edee5adca05eee574142f7627bb/components/packaging/static/hash_files !!
# (no SHA file artifacts on download.docker.com yet as of 2017-06-07 though)
# RUN set -eux; \
# 	\
# # this "case" statement is generated via "update.sh"
# 	apkArch="$(apk --print-arch)"; \
# 	case "$apkArch" in \
# 		x86_64) dockerArch='x86_64' ;; \
# 		armhf) dockerArch='armel' ;; \
# 		aarch64) dockerArch='aarch64' ;; \
# 		ppc64le) dockerArch='ppc64le' ;; \
# 		s390x) dockerArch='s390x' ;; \
# 		*) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;;\
# 	esac; \
# 	\
# 	if ! wget -O docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then \
# 		echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"; \
# 		exit 1; \
# 	fi; \
# 	\
# 	tar --extract \
# 		--file docker.tgz \
# 		--strip-components 1 \
# 		--directory /usr/local/bin/ \
# 	; \
# 	rm docker.tgz; \
# 	\
# 	dockerd --version; \
# 	docker --version

#for "slim":
ARG DOCKER_ARCH="x86_64"
RUN if ! wget -O docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz"; then \
		echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${DOCKER_ARCH}'"; \
		exit 1; \
	fi; \
	\
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /usr/local/bin/ \
	; \
	rm docker.tgz; \
	\
	dockerd --version; \
	docker --version

# NodeJS (ref https://github.com/nodejs/docker-node/blob/master/12/stretch-slim/Dockerfile)
ARG NODE_VERSION="12.12.0"
#for "slim":
RUN buildDeps='xz-utils' \
    && ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x64';; \
      ppc64el) ARCH='ppc64le';; \
      s390x) ARCH='s390x';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armv7l';; \
      i386) ARCH='x86';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && set -ex \
    && apt-get update && apt-get install -y ca-certificates curl wget gnupg dirmngr $buildDeps --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && for key in \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      FD3A5288F042B6850C66B31F09FE44734EB7990E \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      B9AE9905FFD7803F25714661B63B535A4C206CA9 \
      77984A986EBC2AA786BC0F66B01FBB92821C587A \
      8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
      4ED778F539E3634C779C87C6D7062848A1AB005C \
      A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
      B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    ; do \
      gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
      gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
      gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && apt-get purge -y --auto-remove $buildDeps \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs
RUN npm install -g requirejs

# Clean-up
# RUN apk del .build-deps \
#   && rm -rf /var/cache/apk/*

#for "slim":
#RUN apt-get remove -y wget curl && apt autoremove -y
RUN apt autoremove -y
