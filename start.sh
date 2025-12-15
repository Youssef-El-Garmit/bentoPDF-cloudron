#!/bin/bash

set -eu

mkdir -p /run/cloudron-dotconfig /run/cloudron-dotcache /run/logs /var/log/nginx /var/lib/nginx

# Set proper permissions for directories that need to be writable
# Note: /app/code is already owned by cloudron from the Dockerfile, so we skip it
chown -R cloudron:cloudron /run/logs /var/log/nginx /var/lib/nginx || true

echo "==> Starting BentoPDF"
exec /usr/sbin/nginx -g "daemon off;"
