#!/usr/bin/env bash


# Bash Color Basics: Coloring Text with Escape Sequences
source "$(dirname "$0")/bash_color.conf"

# Load the configuration file in the same directory, if it exists.
if [ -f "$(dirname "$0")/backup_via_ssh.ini" ]; then
    source "$(dirname "$0")/backup_via_ssh.ini"
        echo -e "$PRINT_OK$BOLD backup_via_ssh.ini$NO_COLOR configuration file found. We are working"
    else
        echo -e "$PRINT_ERROR I cannot load the$BOLD backup_via_ssh.ini$NO_COLOR configuration file"
        exit 1
fi

DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
croncmd="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/bash -c "$DIR_PATH"/backup_via_ssh.sh >> "$LOG"/"$CRON_LOG_NAME" 2>/dev/null"
cronjob="$CRON_Schedule $croncmd"


BACKTITLE="Cron update Helper Scripts"
TITLE="Cron Update"
MENU="Select an option:"
HEIGHT="10"
WIDTH="55"
CHOICE_HEIGHT="2"

OPTIONS=(
        "Add" "Add Crontab Schedule"
        "Remove" "Remove Crontab Schedule"
        )

CHOICES=$(whiptail --backtitle "$BACKTITLE" --title "$TITLE" --menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT \
"${OPTIONS[@]}" \
2>&1 >/dev/tty)

clear

if [ -z "$CHOICES" ]; then
  echo -e "$PRINT_INFO No option was chosen (user hit Cancel)"
else
    case "$CHOICES" in
    "Add")
        ( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
        clear
        echo -e "$PRINT_INFO To view Cron Update logs: cat "$LOG"/"$CRON_LOG_NAME""
      ;;
    "Remove")
        ( crontab -l | grep -v -F "$croncmd" ) | crontab -
      ;;
    *)
      echo "Exiting..."
      exit 0
      ;;
    esac
fi
