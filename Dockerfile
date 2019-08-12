#####################################
####      Build Environment      ####
#####################################

FROM alpine:3.10 as build

RUN NB_CORES=${BUILD_CORES-$(getconf _NPROCESSORS_CONF)} \
  && apk -U upgrade \
  && apk add --no-cache build-base git libtool automake autoconf tar xz binutils curl curl-dev cppunit-dev libressl-dev zlib-dev linux-headers ncurses-dev libxml2-dev

  # compile xmlrpc-c
RUN cd /tmp \
  && curl -L -O https://netix.dl.sourceforge.net/project/xmlrpc-c/Xmlrpc-c%20Super%20Stable/1.39.13/xmlrpc-c-1.39.13.tgz \
  && tar zxvf xmlrpc-c-1.39.13.tgz \
  && cd xmlrpc-c-1.39.13 \
  && ./configure --enable-libxml2-backend --disable-cgi-server --disable-libwww-client --disable-wininet-client --disable-abyss-server \
  && make -j ${NB_CORES} \
  && make install \
  && make -C tools -j ${NB_CORES} \
  && make -C tools install

  # compile libtorrent
RUN cd /tmp \
  && git clone https://github.com/rakshasa/libtorrent.git \
  && cd /tmp/libtorrent \
  && ./autogen.sh \
  && ./configure \
  && make -j ${NB_CORES} \
  && make install

  # compile rtorrent
RUN cd /tmp \
  && git clone https://github.com/rakshasa/rtorrent.git \
  && cd /tmp/rtorrent \
  && ./autogen.sh \
  && ./configure --with-xmlrpc-c \
  && make -j ${NB_CORES} \
  && make install

  # Strip that shit
RUN strip -s /usr/local/bin/rtorrent \
  && strip -s /usr/local/lib/libtorrent.so \
  && strip -s /usr/local/bin/xmlrpc

#####################################
####     Runtime Environment     ####
#####################################

FROM alpine:3.10

ENV UID=991
ENV GID=991

COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/lib /usr/local/lib

RUN apk -U upgrade \
  && apk add --no-cache curl supervisor su-exec libstdc++ libgcc libxml2 lighttpd \
  && rm -rf /var/cache/apk/* \
  && addgroup -g ${GID} rtorrent \
  && adduser -h /home/rtorrent -s /bin/sh -G rtorrent -D -u ${UID} rtorrent \
  && mkdir /home/rtorrent/rtorrent-session \
  && chown ${UID}:${GID} /home/rtorrent/rtorrent-session \
  && mkdir /etc/supervisor.d \
  && mkdir /downloads && chown ${UID}:${GID} /downloads \
  && mkdir /watch && chown ${UID}:${GID} /watch

COPY assets/rtorrent-supervisord.ini /etc/supervisor.d/rtorrent-supervisord.ini
COPY assets/lighttpd.conf /etc/lighttpd/lighttpd.conf
COPY assets/init.sh /usr/local/bin/init.sh
COPY assets/start-rtorrent.sh /usr/local/bin/start-rtorrent.sh
COPY assets/start-lighttpd.sh /usr/local/bin/start-lighttpd.sh
COPY assets/rtorrent.rc /home/rtorrent/rtorrent.rc

RUN chown ${UID}:${GID} /home/rtorrent/rtorrent.rc

VOLUME /watch
VOLUME /downloads

EXPOSE 80/tcp
EXPOSE 5000/tcp
EXPOSE 51001/tcp

CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]