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
    mkdir -p /etc/nginx/conf.d

# Create nginx configuration
RUN echo 'server {' > /etc/nginx/conf.d/bentopdf.conf && \
    echo '    listen 8080;' >> /etc/nginx/conf.d/bentopdf.conf && \
    echo '    server_name _;' >> /etc/nginx/conf.d/bentopdf.conf && \
    echo '    root /app/code;' >> /etc/nginx/conf.d/bentopdf.conf && \
    echo '    index index.html;' >> /etc/nginx/conf.d/bentopdf.conf && \
    echo '    location / {' >> /etc/nginx/conf.d/bentopdf.conf && \
    echo '        try_files $uri $uri/ /index.html;' >> /etc/nginx/conf.d/bentopdf.conf && \
    echo '    }' >> /etc/nginx/conf.d/bentopdf.conf && \
    echo '}' >> /etc/nginx/conf.d/bentopdf.conf

# Configure nginx to run as cloudron user and use writable directories
RUN sed -i 's/user www-data;/user cloudron;/' /etc/nginx/nginx.conf && \
    # Remove any existing daemon directive to avoid duplicates
    sed -i '/^[[:space:]]*daemon[[:space:]]/d' /etc/nginx/nginx.conf && \
    # Add daemon off; right after the pid directive
    sed -i '/^pid[[:space:]]/a daemon off;' /etc/nginx/nginx.conf && \
    # Replace /var/log/nginx with /run/logs/nginx for all log paths
    sed -i 's|/var/log/nginx|/run/logs/nginx|g' /etc/nginx/nginx.conf && \
    # Replace /var/cache/nginx with /run/logs/nginx for temp paths
    sed -i 's|/var/cache/nginx|/run/logs/nginx|g' /etc/nginx/nginx.conf && \
    # Replace /var/lib/nginx with /run/logs/nginx
    sed -i 's|/var/lib/nginx|/run/logs/nginx|g' /etc/nginx/nginx.conf

# Set proper permissions for writable directories
RUN chown -R cloudron:cloudron /run/logs

COPY start.sh /app/pkg/
RUN chmod +x /app/pkg/start.sh

CMD [ "/app/pkg/start.sh" ]
