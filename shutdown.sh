#!/usr/bin/env bash

# Enable debugging
# set -x

## TODO: Surely there's a better way to implement this?
##       Docker likely expects us to exit within 10 seconds tough,
##       so we can't exactly wait for 1+ minutes, like "announcerestart"
##       expects us to be able to, so what do we do? Custom announcements?
# Send a quick restart announcement to all the players
rcon announcerestart 0
sleep 5

# Tell the scheduler to terminate
kill -s INT `pgrep -nf scheduler_app/app.js`

## FIXME: This seems to instantly destroy it, without saving?!
# Tell the server to terminate
kill -s INT `pgrep -nf VRisingServer.exe`
