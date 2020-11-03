#!/bin/bash

SAB="/usr/lib/sabnzbd/bin/SABnzbd.py"
REPO="https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest"
URL=$(curl -s $REPO | grep "browser_download_url.*src\.tar\.gz" | cut -d : -f 2,3 | tr -d \")

# test for file presence
[[ ! -f "$SAB" ]] && {
    echo "SABnzbd.py not found! Please edit line 3 of this file..."
    exit 1
    }
# get/set versions
CURRENT=$("$SAB" --version | head -2 | cut -d- -f2 -s)
LATEST=$(cut -d/ -f8 "$URL")

[[ "$LATEST" == "$CURRENT" ]] && {
    echo "No update needed! Congrats!"
    exit 0
}

# begin update
echo "Version info:"
echo 
echo -n "Current version: "
echo "$CURRENT"
echo -n " Latest version: "
echo "$LATEST"
echo
echo "Beginning update..."
echo
printf "Grabbing lattest Github source from the following URL:\n\"%s\"" "$URL"