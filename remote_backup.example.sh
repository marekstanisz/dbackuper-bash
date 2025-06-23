#!/bin/bash

REMOTE_USER="youruser"
REMOTE_HOST="yourdomain.com"
REMOTE_PATH="/home/youruser/backups"
LOCAL_PATH="/your/local/backup/folder"
DB_FILE="./db_list.json"

# Parse optional --db-file argument
while [[ $# -gt 0 ]]; do
    case "$1" in
        --db-file)
            DB_FILE="$2"
            shift 2
            ;;
        -*)
            echo "[ERROR] Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Step 1: Trigger backup on remote server
ssh ${REMOTE_USER}@${REMOTE_HOST} -p 22022 'bash ~/scripts/run_backup.sh --db-file '"${DB_FILE}"''

# Step 2: Download new backups to local machine
rsync -avz -e "ssh -p 22022" --remove-source-files ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/ ${LOCAL_PATH}/

# Optional: Log it
echo "Backup completed at $(date)" >> /var/log/db_backup.log
