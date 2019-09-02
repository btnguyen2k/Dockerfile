# Dockerfile for a Docker image to build Java projects.
# by Thanh Nguyen <btnguyen2k@gmail.com>
# version: 11.0.4-slim-d19.03.1-m3.6.1-s1.2.8 (2019-09-01)
# Content:
#   - OpenJDK 11 (11.0.4-jdk-slim)
#   - Maven v3.x.y
#   - Sbt v1.x.y
#   - Docker-in-Docker engine v19.xx.y
# Build with command:
#   $ docker build --squash --force-rm -t <tag> <path/to/Dockerfile>
# Example:
#   $ docker build --squash --force-rm -t btnguyen2k/cicd-java11:11.0.4-slim-d19.03.1-m3.6.1-s1.2.8 -f slim-d19-m3-s1.Dockerfile .

FROM openjdk:11.0.4-jdk-slim

MAINTAINER Thanh Nguyen <btnguyen2k@gmail.com>, version: 11.0.4-slim-d19.03.1-m3.6.1-s1.2.8

# Init
#RUN apk add --no-cache bash
#RUN apk add --no-cache --virtual .build-deps \
#  curl \
#  wget \
#  tar \
#  procps

#for "slim":
RUN apt-get update && echo Y | apt-get install wget curl

# Maven (ref https://github.com/carlossg/docker-maven/blob/05f4802aa5c253dcf75fe967c6f45b3fb1e2f26e/jdk-8-alpine/Dockerfile)
ARG MAVEN_VERSION="3.6.1"
ARG USER_HOME_DIR="/root"
ARG SHA="b4880fb7a3d81edd190a029440cdf17f308621af68475a4fe976296e71ff4a4b546dd6d8a58aaafba334d309cc11e638c52808a4b0e818fc0fd544226d952544"
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
ARG DOCKER_VERSION="19.03.1"
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

# Clean-up
# RUN apk del .build-deps \
#   && rm -rf /var/cache/apk/*

#for "slim":
RUN echo Y | apt-get remove wget curl && echo Y | apt autoremove
