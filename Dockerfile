FROM alpine:3.14
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
 && apk add --no-cache bash curl jq openssl
ENTRYPOINT ["/entrypoint.sh"]
