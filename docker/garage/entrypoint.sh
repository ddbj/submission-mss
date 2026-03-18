#!/bin/sh
set -eu

garage server &
pid=$!

# Wait for Garage to become ready
until garage status >/dev/null 2>&1; do
  sleep 0.5
done

# Assign layout if not yet configured
node_id=$(garage status 2>/dev/null | awk '/NO ROLE/{print substr($1,1,16)}')

if [ -n "$node_id" ]; then
  garage layout assign -z dc1 -c 1G "$node_id"
  garage layout apply --version 1
fi

# Create bucket if not exists
if ! garage bucket info "$GARAGE_BUCKET_NAME" >/dev/null 2>&1; then
  garage bucket create "$GARAGE_BUCKET_NAME"
fi

# Import key if not exists
if ! garage key info "$GARAGE_KEY_NAME" >/dev/null 2>&1; then
  garage key import --yes -n "$GARAGE_KEY_NAME" "$GARAGE_API_KEY" "$GARAGE_SECRET_KEY"
  garage bucket allow --read --write --owner "$GARAGE_BUCKET_NAME" --key "$GARAGE_KEY_NAME"
fi

# Configure CORS
cors_xml='<CORSConfiguration>
  <CORSRule>
    <AllowedOrigin>*</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>PUT</AllowedMethod>
    <AllowedMethod>POST</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
    <ExposeHeader>ETag</ExposeHeader>
    <MaxAgeSeconds>3600</MaxAgeSeconds>
  </CORSRule>
</CORSConfiguration>'

curl --fail --silent --aws-sigv4 "aws:amz:garage:s3" \
  --user "${GARAGE_API_KEY}:${GARAGE_SECRET_KEY}" \
  -X PUT -H 'Content-Type: application/xml' \
  -d "$cors_xml" \
  "http://localhost:3900/${GARAGE_BUCKET_NAME}?cors"

wait $pid
