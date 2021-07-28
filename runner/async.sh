#!/bin/sh
find /home/backups -type f -name "*.sql.gz" -mtime +7 -delete
