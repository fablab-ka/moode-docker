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


# Start PHP-FPM
echo "Starting PHP-FPM..."
/etc/init.d/php8.2-fpm start

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
