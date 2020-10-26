#!/bin/bash

REPO="https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest"
URL=$(curl -s $REPO | grep "browser_download_url.*src\.tar\.gz" | cut -d : -f 2,3 | tr -d \")

# get/set versions
CURRENT=$(./SABnzbd.py --version | head -2 |cut -d- -f2 -s)
LATEST=$(cut -d/ -f8 "$URL")

