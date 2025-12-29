# Builder stage for librespot
FROM debian:trixie-slim AS librespot-builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential \
    cargo \
    rustc \
    libasound2-dev \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN cargo install librespot --root /usr/local --locked

FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    php-fpm \
    php-sqlite3 \
    php-curl \
    php-gd \
    php-mbstring \
    php-zip \
    php-xml \
    mpd \
    mpc \
    sqlite3 \
    python3 \
    python3-pip \
    sudo \
    alsa-utils \
    curl \
    procps \
    iproute2 \
    kmod \
    timidity \
    && rm -rf /var/lib/apt/lists/*

# Install Moode dependencies from imgbuild
COPY imgbuild/moode-cfg /tmp/moode-cfg
COPY install-deps.sh /install-deps.sh
RUN chmod +x /install-deps.sh \
    && /install-deps.sh \
    && rm -rf /tmp/moode-cfg /install-deps.sh \
    && rm -rf /var/lib/apt/lists/*

# Copy librespot from builder
COPY --from=librespot-builder /usr/local/bin/librespot /usr/bin/librespot

# Download and install CamillaDSP
RUN curl -L https://github.com/HEnquist/camilladsp/releases/download/v3.0.1/camilladsp-linux-amd64.tar.gz -o /tmp/camilladsp.tar.gz \
    && tar -xzf /tmp/camilladsp.tar.gz -C /usr/local/bin/ \
    && rm /tmp/camilladsp.tar.gz \
    && chmod +x /usr/local/bin/camilladsp

# Create dummy vcgencmd for sysinfo compatibility
RUN echo '#!/bin/sh\nif [ "$1" = "get_throttled" ]; then echo "throttled=0x0"; else echo "0"; fi' > /usr/local/bin/vcgencmd \
    && chmod +x /usr/local/bin/vcgencmd

# Create directories
RUN mkdir -p /var/www \
    && mkdir -p /var/local/www/db \
    && mkdir -p /var/local/www/imagesw \
    && mkdir -p /var/local/www/commandw \
    && mkdir -p /var/lib/mpd/music \
    && mkdir -p /var/lib/mpd/playlists \
    && mkdir -p /var/log/mpd \
    && mkdir -p /mnt/NAS \
    && mkdir -p /mnt/USB \
    && mkdir -p /mnt/SD \
    && mkdir -p /run/php \
    && mkdir -p /var/local/php

# Install moodeutl
COPY source/usr/local/bin/moodeutl /usr/local/bin/moodeutl
RUN chmod +x /usr/local/bin/moodeutl

# Fix Python symlink
RUN ln -s /usr/bin/python3 /usr/bin/python

# Copy Moode source
COPY source/www /var/www
# Copy local www content to safe location for volume population
COPY source/var/local/www /usr/share/moode/www-local

# Initialize Database (pre-seed for non-volume usage)
RUN cp -r /usr/share/moode/www-local/* /var/local/www/ \
    && sqlite3 /var/local/www/db/moode-sqlite3.db < /usr/share/moode/www-local/db/moode-sqlite3.db.sql \
    && chown -R www-data:www-data /var/local/www

# Configure Sudoers
COPY source/etc/sudoers.d /etc/sudoers.d/
RUN chmod 440 /etc/sudoers.d/*

# Configure Nginx
# Remove default site
RUN rm /etc/nginx/sites-enabled/default

# Overwrite main nginx.conf
COPY source/etc/nginx/nginx.overwrite.conf /etc/nginx/nginx.conf

# Copy Nginx configs from source (adjusting paths as needed)
# We use the provided 'moode-http.overwrite.conf' as the main site
COPY source/etc/nginx/sites-available/moode-http.overwrite.conf /etc/nginx/sites-available/moode
COPY source/etc/nginx/moode-locations.conf /etc/nginx/moode-locations.conf
COPY source/etc/nginx/proxy.conf /etc/nginx/proxy.conf
COPY source/etc/nginx/fastcgi_params.overwrite /etc/nginx/fastcgi_params

# Enable site
RUN ln -s /etc/nginx/sites-available/moode /etc/nginx/sites-enabled/moode

# Configure MPD
# Create a basic mpd.conf since Moode's is generated
RUN echo 'music_directory "/var/lib/mpd/music"' > /etc/mpd.conf \
    && echo 'playlist_directory "/var/lib/mpd/playlists"' >> /etc/mpd.conf \
    && echo 'db_file "/var/lib/mpd/tag_cache"' >> /etc/mpd.conf \
    && echo 'log_file "/var/log/mpd/mpd.log"' >> /etc/mpd.conf \
    && echo 'pid_file "/run/mpd/pid"' >> /etc/mpd.conf \
    && echo 'state_file "/var/lib/mpd/state"' >> /etc/mpd.conf \
    && echo 'sticker_file "/var/lib/mpd/sticker.sql"' >> /etc/mpd.conf \
    && echo 'user "mpd"' >> /etc/mpd.conf \
    && echo 'bind_to_address "0.0.0.0"' >> /etc/mpd.conf \
    && echo 'port "6600"' >> /etc/mpd.conf \
    && echo 'auto_update "yes"' >> /etc/mpd.conf \
    && echo 'audio_output {' >> /etc/mpd.conf \
    && echo '    type "null"' >> /etc/mpd.conf \
    && echo '    name "Null Output"' >> /etc/mpd.conf \
    && echo '}' >> /etc/mpd.conf

# Create moode log file
RUN touch /var/log/moode.log && chown www-data:www-data /var/log/moode.log

# Permissions
RUN chown -R www-data:www-data /var/www /var/local/www /var/local/php
RUN chown -R mpd:audio /var/lib/mpd /var/log/mpd

# Expose ports
EXPOSE 80 6600

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
