#!/bin/bash

# crontab -e
0 2 * * * /home/user/scripts/backup.sh >> /home/user/scripts/backup.log 2>&1


# 设置源目录和目标目录
SOURCE_DIR="/home/user/data"
BACKUP_DIR="/home/user/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

# 创建备份
tar -czf "$BACKUP_FILE" "$SOURCE_DIR"

# 可选：删除 7 天前的旧备份
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -exec rm {} \;
