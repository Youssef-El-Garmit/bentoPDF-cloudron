#!/bin/bash

set -eu

mkdir -p /run/cloudron-dotconfig /run/cloudron-dotcache /run/logs /var/log/nginx /var/lib/nginx

# Set proper permissions
chown -R cloudron:cloudron /app/code /run/logs /var/log/nginx /var/lib/nginx

echo "==> Starting BentoPDF"
exec /usr/sbin/nginx -g "daemon off;"
