#dBuild with: docker build -t gearmand --force-rm .

FROM alpine:3.7
MAINTAINER Thanh Nguyen <btnguyen2k@gmail.com>

COPY patches/libhashkit-common.h.patch /libhashkit-common.h.patch
COPY patches/libtest-cmdline.cc.patch /libtest-cmdline.cc.patch
COPY gearmand.conf /etc/gearmand.conf

ENV GEARMAND_VERSION 1.1.18
RUN addgroup -S gearman && adduser -G gearman -S -D -H -s /bin/false -g "Gearman Server" gearman \
    && apk add --no-cache --virtual .build-deps \
		wget \
		tar \
		ca-certificates \
		boost-dev \
		libevent-dev \
		gperf \
		util-linux-dev \
		alpine-sdk \
	&& wget -O gearmand.tar.gz "https://github.com/gearman/gearmand/releases/download/$GEARMAND_VERSION/gearmand-$GEARMAND_VERSION.tar.gz" \
	&& mkdir -p /usr/src/gearmand \
	&& tar -xzf gearmand.tar.gz -C /usr/src/gearmand --strip-components=1 \
	&& rm gearmand.tar.gz \
	&& cd /usr/src/gearmand \
	&& patch -p1 < /libhashkit-common.h.patch \
    && patch -p1 < /libtest-cmdline.cc.patch \
	&& ./configure \
	    --sysconfdir=/etc \
	    --localstatedir=/var \
	&& make \
	&& make install \
	&& rm -rf /usr/src/gearmand && rm -rf /*.patch \
	&& runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --virtual .gearmand-rundeps $runDeps \
    && apk del .build-deps \
    && gearmand --version

USER gearman
EXPOSE 4730
CMD ["gearmand"]
