#!/usr/bin/env bash
# If you have problem, use this #!/bin/bash

####################################
# Linux SHH Backup Script
####################################

function header_info() {
  clear
}
header_info

# Bash Color Basics: Coloring Text with Escape Sequences
source "$(dirname "$0")/configs/bash_color.conf"

# date string
date_iso=$(date --iso)

echo -e "$PRINT_INFO Today we have $PRINT_DATE"
echo -e "$PRINT_INFO SCP/RSYNC Backup Script v1.20"

# Load the configuration file in the same directory, if it exists.
if [ -f "$(dirname "$0")/configs/backup_via_ssh.ini" ]; then
 source "$(dirname "$0")/configs/backup_via_ssh.ini"
  echo -e "$PRINT_OK$BOLD ./configs/backup_via_ssh.ini$NO_COLOR configuration file found. We are working"
 else
  echo -e "$PRINT_ERROR I cannot load the$BOLD ./configs/backup_via_ssh.ini$NO_COLOR configuration file"
  exit 1
fi

# Directory where there is a temporary backup for your needs 'tar' - archiving tool
BACKUP_TEMP_FOLDER="$BACKUP_DIR/backup-$date_iso"

first_install() {
    # $BACKUP_DIR
    if [ -d "$BACKUP_DIR" ]; then
    echo -e "$PRINT_INFO Directory "$BACKUP_DIR" exists."
    else
    echo -e "$PRINT_INFO Directory created "$BACKUP_DIR""
    mkdir "$BACKUP_DIR"
    chmod 644 "$BACKUP_DIR"
    fi
    # $LOG_DIR
    if [ -d "$LOG_DIR" ]; then
    echo -e "$PRINT_INFO Directory "$LOG_DIR" exists."
    else
    echo -e "$PRINT_INFO Directory created "$LOG_DIR""
    mkdir "$LOG_DIR"
    chmod 644 "$LOG_DIR"
    fi
}

backup_clean() {
    echo -e "$PRINT_INFO Deleting the local temporary backup folder"
    rm -rf $BACKUP_DIR/backup-*
}

backup_make_locally() {
    echo -e "$PRINT_INFO Make the Locally Backup"
    mkdir "$BACKUP_TEMP_FOLDER"

    # Load the configuration file in the same directory, if it exists.
    if [ -f "$(dirname "$0")/configs/backup_to_do.conf" ]; then
     source "$(dirname "$0")/configs/backup_to_do.conf"
      echo -e "$PRINT_OK$BOLD ./configs/backup_to_do.conf$NO_COLOR configuration file found. We are working"
     else
      echo -e "$PRINT_ERROR I cannot load the$BOLD ./configs/backup_to_do.conf$NO_COLOR configuration file"
      exit 1
    fi

    # tar folder into new .tar.gz with correct filename inside $BACKUP_DIR
    # tar -cz -C $BACKUP_DIR backup-$d/ | gpg -r $PGP_ID -o "$BACKUP_TEMP_DIR/backup-$d.tar.gz" --encrypt
    tar -Pczf "$BACKUP_DIR/$NAMEf-backup-$date_iso.tar.gz" $BACKUP_TEMP_FOLDER/

    echo -e "$PRINT_INFO The local backup was performed on $date_iso"
    echo "The local backup was performed on $date_iso" >> $LOG_DIR/$LOG_NAME-$date_iso.log

}

backup_make_remote() {
    echo -e "$PRINT_INFO Make the Remote Backup"

    case $SCPorRSYNC in
    "SCP")
        echo -e "$PRINT_INFO I use SCP service used to copy files between separate locations"
        echo "I use SCP service used to copy files between separate locations" >> $LOG_DIR/$LOG_NAME-$date_iso.log
        scp -P $SSH_PORT -i $SSH_KEY_FILE $BACKUP_DIR/$NAMEf-backup-$date_iso.tar.gz $SSH_USER@$SERVER_IP:$SERVER_LOCATION
    ;;
    "RSYNC")
        echo -e "$PRINT_INFO I use RSYNC service used to synchronize files between separate locations"
        echo "I use RSYNC service used to synchronize files between separate locations" >> $LOG_DIR/$LOG_NAME-$date_iso.log
        rsync -auz $BACKUP_DIR/$NAMEf-backup-$date_iso.tar.gz -e "ssh -p "$SSH_PORT" -i "$SSH_KEY_FILE"" $SSH_USER@$SERVER_IP:$SERVER_LOCATION
    ;;
    *)
        echo -e "$PRINT_ERROR Make your selection in the$BOLD configs/backup_via_ssh.ini$NO_COLOR file in the section$BOLD SCPorRSYNC$NO_COLOR"
        exit 1
    ;;
    esac

sync_result=$?
    if [ "$sync_result" -eq "0" ]
    then
        echo -e "$PRINT_INFO The remote backup was performed on $date_iso"
        echo "The remote backup was performed on $date_iso" >> $LOG_DIR/$LOG_NAME-$date_iso.log
    else
        echo -e "$PRINT_ERROR The remote server was down (no rysc and no remote file) on $date_iso"
        echo "The remote server was down (no rysc and no remote file) on $date_iso" >> $LOG_DIR/$LOG_NAME-$date_iso.log
    fi
    }

backup_rotation() {
     echo -e "$PRINT_INFO Deleting backup and log files older than "$BACKUP_DAYS" days."
     echo "Deleting backup and log files older than "$BACKUP_DAYS" days." >> $LOG_DIR/$LOG_NAME-$date_iso.log
     find $BACKUP_DIR/*.tar.gz -mtime +"$BACKUP_DAYS" -print >> $LOG_DIR/$LOG_NAME-$date_iso.log
     find $LOG_DIR/$LOG_NAME-$date_iso.log -mtime +"$BACKUP_DAYS" -print >> $LOG_DIR/$LOG_NAME-$date_iso.log
     find $BACKUP_DIR/*.tar.gz -mtime +"$BACKUP_DAYS" -exec rm {} \;
     find $LOG_DIR/$LOG_NAME-$date_iso.log -mtime +"$BACKUP_DAYS" -exec rm {} \;
}

# Directory structure and permissions
case $FIRST_INSTALL in
    "TRUE"|"true")
        first_install
        sed -i 's/^\(FIRST\_INSTALL\s*=\s*\).*$/\1"FALSE"/' "$(dirname "$0")/configs/backup_via_ssh.ini"
    ;;
    "FALSE"|"false")
    ;;
    *)
        echo -e "$PRINT_ERROR Make your selection in the$BOLD configs/backup_via_ssh.ini$NO_COLOR file in the section$BOLD TEST_DIRECTORY expect TRUE or FALSE$NO_COLOR"
    ;;
esac
# Deleting the local temporary backup folder
backup_clean
# Make the Locally Backup
backup_make_locally
# Make the Remote Backup
backup_make_remote
# Deleting backup and log files
backup_rotation
# Deleting the local temporary backup folder
backup_clean

