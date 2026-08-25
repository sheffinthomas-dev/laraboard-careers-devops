#!/bin/sh
set -e
 
# The named volume "public-data" is empty the very first time it is
# created, which would hide the public files baked into this image.
# If it is empty, restore them from the backup made during the build.
if [ -z "$(ls -A /var/www/public 2>/dev/null)" ]; then
  echo "Seeding shared public volume from image..."
  cp -r /var/www/public-src/. /var/www/public/
fi
 
exec "$@"
