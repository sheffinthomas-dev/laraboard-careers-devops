#!/bin/sh
set -e

# Always copy the latest baked-in public assets over the shared volume.
# This keeps build/ and tinymce/ fresh on every deploy, while cp's default
# behavior leaves the storage/ symlink (created separately by
# `artisan storage:link`) untouched, since it's not part of the image.
cp -r /var/www/public-src/. /var/www/public/

exec "$@"