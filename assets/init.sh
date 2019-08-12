#!/bin/sh
set -e

function echo_log {
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP $*"
}

if [ -z ${UID+x} ]; then
    OLD_UID=$(id -u rtorrent)
    usermod -u $UID rtorrent
    find / -user $OLD_UID -exec chown -h rtorrent {} \;
fi

if [ -z ${GID+x} ]; then
    OLD_GID=$(id -G rtorrent)
    usermod -G $GID rtorrent
    find / -group $OLD_GID -exec chgrp -h rtorrent {} \;
fi

echo_log "--> INFO Starting rtorrent..."
supervisorctl start rtorrent

# ENABLE_SCGI
if [ $ENABLE_SCGI = "true" ]; then
    echo_log "--> INFO Starting lighttpd.."
    supervisorctl start lighttpd
fi