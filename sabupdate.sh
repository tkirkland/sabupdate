#!/usr/bin/env bash

# Edit this to reflect SABnzb install path
SAB="/usr/lib/sabnzbd/bin/SABnzbd.py"

# DO NOT EDIT BELOW
ACTIVE_TTY=0
if [[ -t 0 ]]; then
    ACTIVE_TTY=1
fi
output_msg() {
    logger -t "$(basename "$0")" "$1"
    [[ $ACTIVE_TTY != 0 ]] && {
        [[ "$2" == "" && $# -gt 1 ]] && return
        echo "${2-$1}"
    }
}
# test for file presence
[[ ! -f "x$SAB" ]] && {
    output_msg "SABnzbd.py not found" "1SABnzbd.py not found! Please edit line 4 of this file..."
    exit 1
}

if [[ $UID -ne 0 ]]; then
    sudo -p 'Restarting as root.  Password: ' bash "$0" "$@"
    exit $?
fi

SERVICE="sabnzbd.service"
SABPATH="$(dirname $SAB)"
TMP=$(mktemp -d)
OWNER="$(stat -c '%U' $SAB)"
GROUP="$(stat -c '%G' $SAB)"
REPO="https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest"
URL=$(curl -s $REPO | grep "browser_download_url.*src\.tar\.gz" | cut -d : -f 2,3 | tr -d \  | tr -d \")
FILENAME=$(cut -d / -f 9 <<<"$URL")

cleanup_error() {
    rm -rf "$TMP"
    exit 1
}
cleanup() {
    rm -rf "$TMP"
    exit 0
}
chk_service() {
    case $1 in
        "start")
            sudo systemctl is-active --quiet "$SERVICE" || {
                sudo systemctl start "$SERVICE"
            }
            ;;
        "stop")
            sudo systemctl is-active --quiet "$SERVICE" && {
                sudo systemctl stop "$SERVICE"
            }
            ;;
        "restart")
            sudo systemctl is-active --quiet "$SERVICE" && {
                service stop
                service start
            }
            sudo systemctl stop "$SERVICE"
            ;;
        *)
            echo "default"
            ;;
    esac

}

# get/set versions
echo "One moment while version checking completes..."
CURRENT=$("$SAB" --version | head -2 | cut -d- -f2 -s)
LATEST=$(echo "$URL" | cut -d/ -f8)

[[ "$LATEST" == "$CURRENT" ]] && {
    echo "No update needed! Congrats!"
    cleanup
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
cd "$TMP" || cleanup_error
echo
echo -n "Extracting archive..."
DIR=$(tar -xvzf "$FILENAME" | sed "s|/.*$||" | uniq)
echo "  Done."
echo
# Check if sabservice is running if so exit
sudo systemctl is-active --quiet "$SERVICE" && {
    echo "Service \"$SERVICE\" appears active... Stopping before backup."
    echo
    chk_service stop "$SERVICE"
}
echo -n "Backing up existing install..."

cd "$SABPATH" || cleanup_error
tar -zcf "/usr/lib/sabnzbd/backups/sabbackup-$(date '+%Y-%m-%d').tar.gz" "." || {
    echo "Creating backup failed!"
    cleanup_error
}
echo "  Done."
echo
echo -n "Copying files to \"$SABPATH\"..."
sudo rsync -au "$TMP/$DIR/" "$SABPATH" || cleanup_error
echo " Done!"
printf "\nUpdate finished!\n\nOLD: %s\nNEW: %s\n\n" "$CURRENT" "$LATEST"
echo -n "Setting file permissions..."
chown "$OWNER":"$GROUP" -R "$SABPATH"
echo "Done!"
echo -n "Restarting \"$SERVICE\"..."
chk_service start "$SERVICE" || cleanup_error
echo " Done!"
echo
echo "Update finished."
cleanup
