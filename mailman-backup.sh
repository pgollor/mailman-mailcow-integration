#!/bin/bash

# backup directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
backup_dir=${SCRIPT_DIR}/backup

# current date
DATE=$(date +"%Y%m%d_%H%M%S")

# create backup directories
mkdir -p ${backup_dir}/mailman


# backup
sudo tar -C ${SCRIPT_DIR}/data --exclude='mailman/core/var/logs' -I pbzip2 -cf ${backup_dir}/mailman/${DATE}-core.tbz2 mailman/core
sudo tar -C ${SCRIPT_DIR}/data --exclude='mailman/web/logs' -I pbzip2 -cf ${backup_dir}/mailman/${DATE}-web.tbz2 mailman/web
docker-compose exec mailman-database pg_dumpall -c -U postgres > ${backup_dir}/mailman/${DATE}-db.sql

