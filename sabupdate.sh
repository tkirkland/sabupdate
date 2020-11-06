#!/bin/bash

SAB="/usr/lib/sabnzbd/bin/SABnzbd.py"
REPO="https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest"
URL=$(curl -s $REPO | grep "browser_download_url.*src\.tar\.gz" | cut -d : -f 2,3 | tr -d \ | tr -d \")
FILENAME=$(cut -d / -f 9 <<< "$URL")

# test for file presence
[[ ! -f "$SAB" ]] && {
    echo "SABnzbd.py not found! Please edit line 3 of this file..."
    exit 1
    }
# get/set versions
printf "One moment while version checking completes...\n"
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
printf "Grabbing lattest Github source from the following URL into /tmp:\n\n%s" "\"$URL\""
curl -Lo "/tmp/$FILENAME" "$URL"
