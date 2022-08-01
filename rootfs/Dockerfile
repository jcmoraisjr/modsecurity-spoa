FROM alpine:3.16.1

ARG HAPROXY_MODSEC_REF=3c895f3e7dd291dba19d57ba054b277e6fb80ca4
ARG HAPROXY_MODSEC_MD5=1cc7bcb0e8b4d1d24e92dd941682e31d
ARG MODSEC_VERSION=2.9.5
ARG MODSEC_MD5=d13cf51673b25a10f7ba9969d9b48252

ADD spoa-log.patch /

RUN apk add --no-cache --virtual .build-modsecurity \
        curl \
        openssl \
        patch \
        tar \
        make \
        gcc \
        libc-dev \
        linux-headers \
        apache2-dev \
        pcre-dev \
        libxml2-dev \
        libevent-dev \
        curl-dev \
        yajl-dev\
    && curl -fsSLo /tmp/modsecurity.tar.gz https://github.com/SpiderLabs/ModSecurity/releases/download/v${MODSEC_VERSION}/modsecurity-${MODSEC_VERSION}.tar.gz \
    && curl -fsSLo /tmp/haproxy-modsecurity.zip https://github.com/haproxy/spoa-modsecurity/archive/${HAPROXY_MODSEC_REF}.zip \
    && echo "$MODSEC_MD5  /tmp/modsecurity.tar.gz" | md5sum -c \
    && mkdir -p /usr/src/modsecurity \
    && tar xzf /tmp/modsecurity.tar.gz --strip-components=1 -C /usr/src/modsecurity \
    && rm /tmp/modsecurity.tar.gz \
    && echo "$HAPROXY_MODSEC_MD5  /tmp/haproxy-modsecurity.zip" | md5sum -c \
    && unzip -d /usr/src /tmp/haproxy-modsecurity.zip \
    && mv /usr/src/spoa-modsecurity-${HAPROXY_MODSEC_REF} /usr/src/haproxy-modsecurity \
    && patch -p0 /usr/src/haproxy-modsecurity/spoa.c </spoa-log.patch \
    && rm /tmp/haproxy-modsecurity.zip \
    && cd /usr/src/modsecurity \
    && ./configure \
        --prefix=/usr/src/modsecurity/INSTALL \
        --disable-apache2-module \
        --enable-standalone-module \
        --enable-pcre-study \
        --without-lua \
        --enable-pcre-jit \
    && make -C standalone install \
    && mkdir -p INSTALL/include \
    && cp standalone/*.h apache2/*.h INSTALL/include \
    && cd / \
    && make -C /usr/src/haproxy-modsecurity \
        MODSEC_INC=/usr/src/modsecurity/INSTALL/include \
        MODSEC_LIB=/usr/src/modsecurity/INSTALL/lib \
        APACHE2_INC=/usr/include/apache2 \
        APR_INC=/usr/include/apr-1 \
    && mv /usr/src/haproxy-modsecurity/modsecurity /usr/local/bin/ \
    && rm -rf /usr/src/haproxy-modsecurity /usr/src/modsecurity \
    && deps=$( \
        scanelf --needed --nobanner --format '%n#p' /usr/local/bin/modsecurity \
            | tr ',' '\n' | sed 's/^/so:/' \
    ) \
    && apk add $deps \
    && apk del .build-modsecurity

ARG OWASP_MODSEC_VERSION=v3.3.2
ARG OWASP_MODSEC_MD5=244db30b807c56d8277010b70305efda

RUN mkdir -p /etc/modsecurity/owasp-modsecurity-crs \
    && wget -qO/etc/modsecurity/modsecurity.conf https://github.com/SpiderLabs/ModSecurity/raw/v2/master/modsecurity.conf-recommended \
    && wget -qO/etc/modsecurity/unicode.mapping https://github.com/SpiderLabs/ModSecurity/raw/v2/master/unicode.mapping \
    && wget -qO/tmp/owasp.tar.gz https://github.com/coreruleset/coreruleset/archive/${OWASP_MODSEC_VERSION}.tar.gz \
    && echo "$OWASP_MODSEC_MD5  /tmp/owasp.tar.gz" | md5sum -c \
    && tar xzf /tmp/owasp.tar.gz --strip-components=1 -C /etc/modsecurity/owasp-modsecurity-crs \
    && rm /tmp/owasp.tar.gz \
    && find \
            /etc/modsecurity/owasp-modsecurity-crs \
            -type f -name '*.example' \
        | while read -r f; do cp -p "$f" "${f%.example}"; done \
    && sed -i.example \
        's/^SecRuleEngine .*/SecRuleEngine On/' \
        /etc/modsecurity/modsecurity.conf \
    && sed -i.example \
        's/^\(SecDefaultAction "phase:[12]\),log,auditlog,pass"/\1,log,noauditlog,deny,status:403"/' \
        /etc/modsecurity/owasp-modsecurity-crs/crs-setup.conf \
    && find \
            /etc/modsecurity/owasp-modsecurity-crs \
            -type f -maxdepth 1 -name '*.conf' \
        | sort | sed 's/^/Include /' > /etc/modsecurity/owasp-modsecurity-crs.conf \
    && find \
            /etc/modsecurity/owasp-modsecurity-crs/rules \
            -type f -maxdepth 1 -name '*.conf' \
        | sort | sed 's/^/Include /' >> /etc/modsecurity/owasp-modsecurity-crs.conf

RUN apk add --no-cache tini

COPY . /

ENTRYPOINT ["tini", "--", "/start.sh"]
