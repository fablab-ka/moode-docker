#!/bin/bash
set -e

echo "Starting Moode Audio Docker..."

# Ensure /run/php exists
mkdir -p /run/php

# Populate /var/local/www if needed (for volume persistence)
echo "Ensuring /var/local/www content..."
# Copy missing files/dirs from backup
cp -rn /usr/share/moode/www-local/* /var/local/www/

# Initialize DB if missing (specifically if the file itself is missing, even after cp)
if [ ! -f /var/local/www/db/moode-sqlite3.db ]; then
    echo "Initializing Database..."
    mkdir -p /var/local/www/db
    if [ -f /usr/share/moode/www-local/db/moode-sqlite3.db.sql ]; then
         sqlite3 /var/local/www/db/moode-sqlite3.db < /usr/share/moode/www-local/db/moode-sqlite3.db.sql
    else 
         echo "WARNING: SQL schema not found. Database might be empty."
    fi
fi

# Ensure permissions
chown -R www-data:www-data /var/local/www

# Ensure PHP session dir
if [ ! -d /var/local/php ]; then
    mkdir -p /var/local/php
fi
chown -R www-data:www-data /var/local/php

# Ensure Moode Log
touch /var/log/moode.log
chown www-data:www-data /var/log/moode.log

# Ensure MPD DB file
# We do not touch the file, MPD will create it. 
# We just ensure the directory exists and permissions are right.
mkdir -p /var/lib/mpd
chown -R mpd:audio /var/lib/mpd /var/log/mpd

# Initialize DB if missing or empty (check for a known table)
DB_FILE="/var/local/www/db/moode-sqlite3.db"
mkdir -p /var/local/www/db

# Check if DB is valid (has cfg_system table)
DB_VALID=0
if [ -f "$DB_FILE" ]; then
    if sqlite3 "$DB_FILE" "SELECT count(*) FROM cfg_system;" >/dev/null 2>&1; then
        DB_VALID=1
    fi
fi

if [ $DB_VALID -eq 0 ]; then
    echo "Initializing Database (missing or empty)..."
    if [ -f /usr/share/moode/www-local/db/moode-sqlite3.db.sql ]; then
         sqlite3 "$DB_FILE" < /usr/share/moode/www-local/db/moode-sqlite3.db.sql
         echo "Database initialized."
    else 
         echo "WARNING: SQL schema not found. Database might be empty."
    fi
else
    echo "Database exists and appears valid."
fi
chown -R www-data:www-data /var/local/www/db

# Start PHP-FPM
echo "Starting PHP-FPM..."
/etc/init.d/php8.4-fpm start

# Start MPD
echo "Starting MPD..."
# We run mpd as a service or directly. 
# Using service wrapper for simplicity if available, otherwise direct.
if [ -x /etc/init.d/mpd ]; then
    /etc/init.d/mpd start
else
    mpd /etc/mpd.conf
fi

# Start Nginx
echo "Starting Nginx..."
nginx -g "daemon off;"
