FROM php:apache-bookworm

ENV MSMTP_MAILHOST=mailserver
ENV MSMTP_TLS=off
ENV MSMTP_STARTTLS=off
ENV MSMTP_TLS_CERTCHECK=off
ENV MSMTP_AUTH=off
ENV MSMTP_FROM=mailer
ENV MSMTP_PORT=25
ENV MSMTP_LOGFILE=/var/log/msmtp.log

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    DEBIAN_FRONTEND=noninteractive \
    sed -i "s/^Components: main$/Components: main contrib non-free non-free-firmware/" /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install msmtp rsync gettext-base imagemagick ghostscript --no-install-recommends -y && \
    sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/' /etc/ImageMagick-6/policy.xml

# it would be nice to also include php-imagick, but that wont install on this image

COPY tree/ /
ENTRYPOINT ["entrypoint-override.sh"]
CMD ["apache2-foreground"]
