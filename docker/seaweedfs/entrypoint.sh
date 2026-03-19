#!/bin/sh
set -eu

weed server -s3 \
  -s3.port=8333 \
  -s3.config=/etc/seaweedfs/s3.json \
  -s3.allowedOrigins='*' \
  -volume.max=0 &
pid=$!

# Wait for SeaweedFS S3 to become ready
until curl -sf http://localhost:8333/status >/dev/null 2>&1; do
  sleep 0.5
done

# Create bucket if not exists
if ! curl -sf http://localhost:8333/uploads >/dev/null 2>&1; then
  curl -X PUT http://localhost:8333/uploads
fi

wait $pid
