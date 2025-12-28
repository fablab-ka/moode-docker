# Moode Audio for x86 Docker

This project provides a Dockerized environment to run Moode Audio on x86_64 systems (Debian-based).

## Prerequisites

- Docker
- Docker Compose

## Setup

1.  Clone the Moode Audio source code (or use the Makefile):
    ```bash
    make setup
    ```
    This clones the upstream Moode repository into `source/`.

2.  Build the image:
    ```bash
    make build
    ```

3.  Run the container:
    ```bash
    make up
    ```

4.  Access Moode at `http://localhost:80`.

## Architecture

- **Base Image:** Debian Bookworm (Slim)
- **Services:** Nginx, PHP 8.2-FPM, MPD, SQLite3.
- **Persistence:**
    - `moode-data`: Stores `/var/local/www` (Database, Images, Command scripts).
    - `moode-db`: (Legacy/Redundant) Stores `/var/local/www/db`.
    - `./music`: Mapped to `/var/lib/mpd/music` (Add your music here).

## Notes

- This is a port of the Moode Audio web interface and player daemon to a standard x86 Docker environment.
- Hardware-specific features (GPIO, Raspberry Pi specific drivers) are disabled or non-functional.
- MPD is configured to output to a "Null" output by default. You may need to configure ALSA or PulseAudio forwarding for actual sound output.

## License

This project is licensed under the same terms as Moode Audio (GPL-3.0).
