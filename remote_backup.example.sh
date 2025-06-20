#!/bin/bash

REMOTE_USER="youruser"
REMOTE_HOST="yourdomain.com"
REMOTE_PATH="/home/youruser/backups"
LOCAL_PATH="/your/local/backup/folder"

# Step 1: Trigger backup on remote server
ssh ${REMOTE_USER}@${REMOTE_HOST} -p 22022 'bash ~/scripts/run_backup.sh'

# Step 2: Download new backups to local machine
rsync -avz --remove-source-files ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/ ${LOCAL_PATH}/

# Optional: Log it
echo "Backup completed at $(date)" >> /var/log/db_backup.log
