#!/bin/bash

SAB="/usr/lib/sabnzbd/bin/SABnzbd.py"
TMP=$(mktemp -d)
REPO="https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest"
URL=$(curl -s $REPO | grep "browser_download_url.*src\.tar\.gz" | cut -d : -f 2,3 | tr -d \  | tr -d \")
FILENAME=$(cut -d / -f 9 <<<"$URL")

cleanup_error () {
    rm -rf "$TMP"
    exit 1
}
cleanup () {
    rm -rf "$TMP"
    exit 0
}
service () {
    case $1 in
        "start")
            sudo systemctl is-active --quiet sabnzbd.service || {
                sudo systemctl start sabnzbd.service
            }
        ;;
        "stop")
            sudo systemctl is-active --quiet sabnzbd.service && {
                sudo systemctl stop sabnzbd.service
            }
        ;;
        "restart")
            sudo systemctl is-active --quiet sabnzbd.service && {
                service stop
                service start
            }
            sudo systemctl stop sabnzbd.service
        ;;
        *)
            echo "default"
        ;;
    esac
    
}
# test for file presence
[[ ! -f "$SAB" ]] && {
    echo "SABnzbd.py not found! Please edit line 3 of this file..."
    exit 1
}
# get/set versions
echo "One moment while version checking completes..."
CURRENT=$("$SAB" --version | head -2 | cut -d- -f2 -s)
LATEST=$(echo "$URL" | cut -d/ -f8)

[[ "$LATEST" == "$CURRENT" ]] && {
    echo "No update needed! Congrats!"
    exit 0
}

# begin update
echo
echo -n "Current version: "
echo "$CURRENT"
echo -n " Latest version: "
echo "$LATEST"
echo
echo "Beginning update..."
echo
printf "Grabbing latest Github source from the following URL into /tmp:\n\n%s" "\"$URL\""
echo
curl -Lo "$TMP/$FILENAME" "$URL"
cd "$TMP" || exit
echo
echo -n "Extracting archive..."
DIR=$(tar -xvzf "$FILENAME" | sed "s|/.*$||" | uniq)
echo "  Done."
echo
echo -n "Backing up existing install..."
SABPATH="$(dirname $SAB)"
cd "$SABPATH" || exit
tar -zcf "sabbackup-$(date '+%Y-%m-%d').tar.gz" "." || {
    echo "Creating backup failed!"
    cleanup_error
}
echo "  Done."  
# Check if sabservice is running if so exit
sudo systemctl is-active --quiet sabnzbd.service && sudo systemctl stop sabnzbd.service