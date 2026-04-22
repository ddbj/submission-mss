#!/bin/sh

set -eu

trap 'docker stop -t 3 mssform-seaweedfs >/dev/null 2>&1' INT TERM HUP

docker run --rm --name mssform-seaweedfs \
  --publish 8333:8333 \
  --volume mssform_seaweedfs:/data \
  --volume ./docker/seaweedfs/entrypoint.sh:/entrypoint.sh \
  --volume ./docker/seaweedfs/s3.development.json:/etc/seaweedfs/s3.json \
  chrislusf/seaweedfs /entrypoint.sh &

wait
