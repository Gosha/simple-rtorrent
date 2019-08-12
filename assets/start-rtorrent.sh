#!/bin/sh

# remove lock files
rm -f /home/rtorrent/rtorrent-session/rtorrent.lock

# run rtorrent
su-exec rtorrent /usr/local/bin/rtorrent -o system.daemon.set=true -o import=/home/rtorrent/rtorrent.rc