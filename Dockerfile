# renovate: datasource=docker depName=bentopdf/bentopdf versioning=semver
ARG BENTOPDF_VERSION=latest

# Use official bentopdf image as base to copy files
FROM bentopdf/bentopdf:${BENTOPDF_VERSION} as bentopdf-base

# Switch to cloudron base and copy bentopdf files
FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c

# Install nginx (bentopdf uses nginx-unprivileged, but we'll use standard nginx for Cloudron)
RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/cache/apt /var/lib/apt/lists

# Create necessary directories first
RUN mkdir -p /app/pkg /app/code /run/logs

# Copy bentopdf files from the official image with proper ownership
COPY --from=bentopdf-base --chown=cloudron:cloudron /usr/share/nginx/html /app/code

# Configure nginx for Cloudron - use custom config files for better maintainability
RUN rm -f /etc/nginx/sites-enabled/default && \
    mkdir -p /etc/nginx/conf.d

# Copy custom nginx configuration files
COPY --chown=root:root nginx.conf /etc/nginx/nginx.conf
COPY --chown=root:root nginx-bentopdf.conf /etc/nginx/conf.d/bentopdf.conf

# Set proper permissions for writable directories
RUN chown -R cloudron:cloudron /run/logs

COPY start.sh /app/pkg/
RUN chmod +x /app/pkg/start.sh

CMD [ "/app/pkg/start.sh" ]
