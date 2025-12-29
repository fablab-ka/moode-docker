# Moode Audio for Docker

This project provides a Dockerized environment to run Moode Audio on Docker (Debian-based).

## Prerequisites

- Docker
- Docker Compose
- Git

## Setup

### 1. Get the Code & Submodules

If you haven't already, clone the repository and initialize the submodules:

```bash
git clone <repository-url>
cd moode-docker
git submodule update --init --recursive
```

This will fetch both the `source` (Moode web UI) and `imgbuild` (Build configuration) submodules.

### 2. Run with Docker Compose (Recommended)

Build and start the container in detached mode:

```bash
docker compose up -d --build
```

To stop the container:

```bash
docker compose down
```

### 3. Run with Docker (Manual)

**Build the image:**

```bash
docker build -t moode-player .
```

**Run the container:**

```bash
docker run -d \
  --name moode \
  -p 80:80 \
  -p 6600:6600 \
  -v "$(pwd)/music:/var/lib/mpd/music" \
  -v moode-db:/var/local/www/db \
  -v moode-data:/var/local/www \
  moode-player
```

### Exposed Ports and Volumes

**Ports:**
- `80`: Web interface (Nginx).
- `6600`: MPD (Music Player Daemon) protocol.

**Volumes:**
- `/var/lib/mpd/music`: Your music library.
- `/var/local/www`: Application data, including configuration and covers.
- `/var/local/www/db`: SQLite database storage.

## Architecture

- **Base Image:** Debian Trixie (Slim)
- **Services:** Nginx, PHP 8.4-FPM, MPD, SQLite3.
- **Audio Services:**
  - **MPD:** Music Player Daemon (installed via apt).
  - **Shairport Sync:** AirPlay receiver (installed via apt).
  - **Squeezelite:** Squeezebox receiver (installed via apt).
  - **Librespot:** Spotify Connect receiver (compiled from source via Cargo).

## Notes

- **Build Time:** The initial build takes longer because `librespot` is compiled from source using Rust.
- This is a port of the Moode Audio web interface and player daemon to a standard Docker environment.
- Hardware-specific features (GPIO, Raspberry Pi specific drivers) are disabled or non-functional.
- MPD is configured to output to a "Null" output by default. You may need to configure ALSA or PulseAudio forwarding for actual sound output.

## License

This project is licensed under the same terms as Moode Audio (GPL-3.0).
