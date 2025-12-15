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

# Configure nginx to run as cloudron user
RUN sed -i 's/user www-data;/user cloudron;/' /etc/nginx/nginx.conf && \
    sed -i 's/pid \/run\/nginx.pid;/pid \/run\/nginx.pid;\n    daemon off;/' /etc/nginx/nginx.conf

# Set proper permissions for directories that need to be writable
RUN chown -R cloudron:cloudron /run/logs && \
    mkdir -p /var/log/nginx /var/lib/nginx && \
    chown -R cloudron:cloudron /var/log/nginx /var/lib/nginx

COPY start.sh /app/pkg/
RUN chmod +x /app/pkg/start.sh

CMD [ "/app/pkg/start.sh" ]
