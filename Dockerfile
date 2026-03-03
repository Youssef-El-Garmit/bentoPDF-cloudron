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

# Configure nginx for Cloudron
RUN rm -f /etc/nginx/sites-enabled/default && \
    mkdir -p /etc/nginx/conf.d && \
    # Configure nginx to run as cloudron user
    sed -i 's/user www-data;/user cloudron;/' /etc/nginx/nginx.conf && \
    # Set daemon off (remove existing if present to avoid duplicates)
    sed -i '/^[[:space:]]*daemon[[:space:]]/d' /etc/nginx/nginx.conf && \
    sed -i '/^pid[[:space:]]/a daemon off;' /etc/nginx/nginx.conf && \
    # Use writable paths for logs and temp files (replace all occurrences)
    sed -i 's|/var/log/nginx|/run/logs/nginx|g' /etc/nginx/nginx.conf && \
    sed -i 's|/var/cache/nginx|/run/logs/nginx|g' /etc/nginx/nginx.conf && \
    sed -i 's|/var/lib/nginx|/run/logs/nginx|g' /etc/nginx/nginx.conf && \
    # Add explicit client_body_path in http block to override defaults
    sed -i '/^http {/a\    client_body_temp_path /run/logs/nginx/client_temp;\n    proxy_temp_path /run/logs/nginx/proxy_temp;\n    fastcgi_temp_path /run/logs/nginx/fastcgi_temp;\n    uwsgi_temp_path /run/logs/nginx/uwsgi_temp;\n    scgi_temp_path /run/logs/nginx/scgi_temp;' /etc/nginx/nginx.conf

# Copy server configuration
COPY --chown=root:root nginx-bentopdf.conf /etc/nginx/conf.d/bentopdf.conf

# Set proper permissions for writable directories
RUN chown -R cloudron:cloudron /run/logs

COPY start.sh /app/pkg/
RUN chmod +x /app/pkg/start.sh

CMD [ "/app/pkg/start.sh" ]
