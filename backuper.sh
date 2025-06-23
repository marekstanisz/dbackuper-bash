#!/bin/bash

set -euo pipefail

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

USER="$(whoami)"
CNF_PATH="/home/${USER}/.backup.cnf"
BACKUPS_PATH="/home/${USER}/db_backups"
DATESTAMP="$(date +%F)"

log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1" >&2
}

abort() {
    error "$1"
    exit 1
}

# Load and validate db_list.json
load_access_info() {
    log "Using DB file: $DB_FILE"

    if [[ ! -f "$DB_FILE" ]]; then
        abort "db_list.json not found."
    fi

    if ! jq empty "$DB_FILE" 2>/dev/null; then
        abort "db_list.json is not valid JSON."
    fi

    DB_COUNT=$(jq length "$DB_FILE")
    if [[ "$DB_COUNT" -eq 0 ]]; then
        abort "No database entries found in db_list.json."
    fi

    log "Database information loaded successfully."
    log "Found $DB_COUNT databases to back up."
}

# Validate config file
check_cnf_file() {
    if [[ ! -f "$CNF_PATH" ]]; then
        abort "Backup configuration file $CNF_PATH does not exist."
    fi

    log "Backup configuration file found: $CNF_PATH"
}

# Run the backup
backup_database() {
    local port="$1"
    local host="$2"
    local db_name="$3"
    local backup_file="${BACKUPS_PATH}/${db_name}_${DATESTAMP}.sql.gz"

    log "Backing up database: $db_name on host: $host at port: $port..."

    CMD=(
        mysqldump
        --defaults-extra-file="$CNF_PATH"
        -P "$port"
        -h "$host"
        "$db_name"
        --no-tablespaces
    )

    if ! "${CMD[@]}" | gzip > "$backup_file" 2> dump_error.log; then
        error_msg=$(<dump_error.log)
        rm -f "$backup_file"
        abort "Backup for $db_name failed: $error_msg"
    fi

    if [[ ! -f "$backup_file" ]]; then
        abort "Backup file $backup_file was not created."
    fi

    log "Backup for $db_name completed: $backup_file"
}

### === Main Script ===

log "Starting database backup process..."
log "Running as user: $USER"

check_cnf_file
load_access_info

for i in $(seq 0 $((DB_COUNT - 1))); do
    PORT=$(jq -r ".[$i].port // 3306" "$DB_FILE")
    HOST=$(jq -r ".[$i].host" "$DB_FILE")
    DB_NAME=$(jq -r ".[$i].db_name" "$DB_FILE")

    if [[ -z "$HOST" || -z "$DB_NAME" ]]; then
        error "Skipping incomplete entry at index $i."
        continue
    fi

    backup_database "$PORT" "$HOST" "$DB_NAME"
done

log "All backups completed successfully."
