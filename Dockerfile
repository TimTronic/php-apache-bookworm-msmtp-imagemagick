# Debian 13 (trixie), the current stable. The image keeps its "bookworm" name
# because every site's compose file pulls it by that name.
FROM php:apache-trixie

# Require the emergency PHP fixes even while upstream images are still rebuilding.
COPY update-php-security.sh /usr/local/sbin/update-php-security
RUN sh /usr/local/sbin/update-php-security 8.5.12 08bc2eba2a588654ade1357174aa646b761556c862dda0678345ee29ed481209
ENV PHP_SECURITY_MIN_VERSION=8.5.12

ENV MSMTP_MAILHOST=mailserver
ENV MSMTP_TLS=off
ENV MSMTP_STARTTLS=off
ENV MSMTP_TLS_CERTCHECK=off
ENV MSMTP_AUTH=off
ENV MSMTP_FROM=mailer
ENV MSMTP_PORT=25
ENV MSMTP_LOGFILE=/var/log/msmtp.log

RUN --mount=type=cache,target=/var/cache/apt,sharing=private \
    --mount=type=cache,target=/var/lib/apt,sharing=private \
    DEBIAN_FRONTEND=noninteractive \
    sed -i "s/^Components: main$/Components: main contrib non-free non-free-firmware/" /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install msmtp rsync gettext-base imagemagick ghostscript libpq-dev --no-install-recommends -y && \
    for policy in /etc/ImageMagick-*/policy.xml; do \
        sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read|write" pattern="PDF" \/>/' "$policy"; \
    done && \
    ! grep -q 'rights="none" pattern="PDF"' /etc/ImageMagick-*/policy.xml && \
    docker-php-ext-install pdo_pgsql pgsql

# PostgreSQL: the image shipped with pdo_sqlite only, so a PHP page could not reach a
# Postgres container at all. libpq-dev is what docker-php-ext-install builds against; it
# is left in place rather than purged because it pulls libpq5, which the extensions need
# at runtime anyway, and the headers are a few megabytes.
#
# OPcache ships with the image but was never enabled, so every request recompiled every
# file it touched from source - on a PHP site that is most of the work of serving a page.
# The default validate_timestamps=1 is kept deliberately: the beta container bind-mounts
# the working tree, and an edit has to take effect on the next request without a restart.

# it would be nice to also include php-imagick, but that wont install on this image

COPY tree/ /

# COPY stamps the build checkout's directory modes straight onto the image, so the result
# depends on the umask of whoever built it. A clone made with umask 002 gives tree/etc and
# tree/usr mode 774, which lands on / etc and /usr and leaves them non-traversable for
# www-data: PHP can then no longer read /etc/resolv.conf or /etc/nsswitch.conf, and every
# hostname lookup fails with "Temporary failure in name resolution" - a symptom that looks
# nothing like a permissions problem. Jenkins happens to check out with umask 022 and so
# has never hit it. Pin the modes rather than depending on the builder.
RUN chmod 0755 /etc /usr /usr/local /usr/local/bin /usr/local/etc /usr/local/etc/php /usr/local/etc/php/conf.d

ENTRYPOINT ["entrypoint-override.sh"]
CMD ["apache2-foreground"]
