FROM alpine:3.21

RUN apk add --no-cache squid busybox-extras \
    && mkdir -p /var/log/squid /var/cache/squid \
    && chown -R squid:squid /var/log/squid /var/cache/squid

COPY squid.conf /etc/squid/squid.conf

USER squid

EXPOSE 3128

CMD ["squid", "-N", "-f", "/etc/squid/squid.conf"]
