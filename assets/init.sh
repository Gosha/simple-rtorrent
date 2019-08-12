#!/bin/sh
set -e

function echo_log {
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP $*"
}

# IF UID/GID BLA

echo_log "--> INFO Starting rtorrent..."
supervisorctl start rtorrent

# IF
echo_log "--> INFO Starting lighttpd.."
supervisorctl start lighttpd