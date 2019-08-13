#!/bin/sh
set -e

function echo_log {
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP --> $*"
}

CURRENT_PUID=$(id -u rtorrent)
CURRENT_PGID=$(id -G rtorrent)

if [ ! -z ${PUID+x} ] && [ $PUID != $CURRENT_PUID ]; then
    echo_log "INFO Changing rtorrent PUID to ${PUID}"
    usermod -u $PUID rtorrent
    find /home/ -user $CURRENT_PUID -exec chown -h rtorrent {} \;
else
    echo_log "INFO PUID et set to $CURRENT_PUID"
fi

if [ ! -z ${PGID+x} ] && [ $PGID != $CURRENT_PGID ]; then
    echo_log "INFO Changing rtorrent PGID to ${PGID}"
    groupmod -g $PGID rtorrent
    find /home/ -group $CURRENT_PGID -exec chgrp -h rtorrent {} \;
else
    echo_log "INFO PGID et set to $CURRENT_PGID"
fi

echo_log "INFO Starting rtorrent..."
supervisorctl start rtorrent

# ENABLE_SCGI
if [ "$ENABLE_SCGI" = "true" ]; then
    echo_log "INFO Starting lighttpd.."
    supervisorctl start lighttpd
else
    echo_log "INFO Lighttpd is not enabled, not starting it.."
fi
