#!/bin/sh
set -eu

weed server -s3 \
  -s3.port=8333 \
  -s3.config=/etc/seaweedfs/s3.json \
  -s3.allowedOrigins='*' \
  -dir=/data \
  -volume.max=0 &
pid=$!

# Wait for SeaweedFS S3 to become ready
until curl -sf http://localhost:8333/status >/dev/null 2>&1; do
  sleep 0.5
done

# Create the bucket if it is not there yet. The S3 API answers nobody without
# credentials, so this goes through the shell, which talks to the master.
echo 's3.bucket.create -name uploads' | weed shell -master=localhost:9333

wait $pid
