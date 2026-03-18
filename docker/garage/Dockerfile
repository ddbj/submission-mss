FROM dxflrs/garage:v2.2.0 AS garage

FROM alpine:3
RUN apk add --no-cache curl
COPY --from=garage /garage /usr/local/bin/garage
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
