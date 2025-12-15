#!/bin/bash

set -eu

# Create writable directories for nginx (using /run/logs instead of /var paths)
mkdir -p /run/cloudron-dotconfig /run/cloudron-dotcache /run/logs/nginx/client_temp \
    /run/logs/nginx/proxy_temp /run/logs/nginx/fastcgi_temp \
    /run/logs/nginx/uwsgi_temp /run/logs/nginx/scgi_temp \
    /run/logs/nginx/body /run/logs/nginx/fastcgi /run/logs/nginx/uwsgi

# Set proper permissions for writable directories
# Note: /app/code is already owned by cloudron from the Dockerfile
chown -R cloudron:cloudron /run/logs || true

echo "==> Starting BentoPDF"
exec /usr/sbin/nginx
