FROM dxflrs/garage:v2.2.0 AS garage

FROM busybox:stable
COPY --from=garage /garage /usr/local/bin/garage
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
