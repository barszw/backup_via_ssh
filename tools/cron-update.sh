#!/usr/bin/env bash
# If you have problem, use this #!/bin/bash

# Bash Color Basics: Coloring Text with Escape Sequences
source "../configs/bash_color.conf"

# Load the configuration file in the same directory, if it exists.
if [ -f "../configs/backup_via_ssh.ini" ]; then
    source "../configs/backup_via_ssh.ini"
    echo -e "$PRINT_OK$BOLD "$(dirname "$DIR_PATH")"/configs/backup_via_ssh.ini$NO_COLOR configuration file found. We are working"
else
    echo -e "$PRINT_ERROR I cannot load the$BOLD "$(dirname "$DIR_PATH")"/configs/backup_via_ssh.ini$NO_COLOR configuration file"
    exit 1
fi

DIR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#parentdir="$(dirname "$(pwd)")"
croncmd="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/bash -c "$(dirname "$(pwd)")"/backup_via_ssh.sh >> "$LOG_DIR"/"$CRON_LOG_NAME" 2>/dev/null"
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
        echo -e "$PRINT_INFO To view Cron Update logs: cat "$LOG_DIR"/"$CRON_LOG_NAME""
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
