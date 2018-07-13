FROM alpine:3.7

ARG HAPROXY_MAJOR=1.8
ARG HAPROXY_VERSION=1.8.12
ARG HAPROXY_MD5=9f37013ec1e76942a67a9f7c067af9f2
ARG MODSEC_VERSION=2.9.2
ARG MODSEC_MD5=4d9454efb19269c4288ae408ea438b76

RUN apk add --no-cache --virtual .build-modsecurity \
        curl \
        openssl \
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
    && curl -fsSLo /tmp/modsecurity.tar.gz https://www.modsecurity.org/tarball/${MODSEC_VERSION}/modsecurity-${MODSEC_VERSION}.tar.gz \
    && curl -fsSLo /tmp/haproxy.tar.gz https://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz \
    && echo "$MODSEC_MD5  /tmp/modsecurity.tar.gz" | md5sum -c \
    && mkdir -p /usr/src/modsecurity \
    && tar xzf /tmp/modsecurity.tar.gz --strip-components=1 -C /usr/src/modsecurity \
    && rm /tmp/modsecurity.tar.gz \
    && echo "$HAPROXY_MD5  /tmp/haproxy.tar.gz" | md5sum -c \
    && mkdir -p /usr/src/haproxy \
    && tar xzf /tmp/haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
    && rm /tmp/haproxy.tar.gz \
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
    && make -C /usr/src/haproxy/contrib/modsecurity \
        MODSEC_INC=/usr/src/modsecurity/INSTALL/include \
        MODSEC_LIB=/usr/src/modsecurity/INSTALL/lib \
        APACHE2_INC=/usr/include/apache2 \
        APR_INC=/usr/include/apr-1 \
    && mv /usr/src/haproxy/contrib/modsecurity/modsecurity /usr/local/bin/ \
    && rm -rf /usr/src/haproxy /usr/src/modsecurity \
    && deps=$( \
        scanelf --needed --nobanner --format '%n#p' /usr/local/bin/modsecurity \
            | tr ',' '\n' | sed 's/^/so:/' \
    ) \
    && apk add $deps \
    && apk del .build-modsecurity

ARG OWASP_MODSEC_VERSION=v3.0.2
ARG OWASP_MODSEC_MD5=9cef8c63937a92dc350275fcf348baab

RUN mkdir -p /etc/modsecurity/owasp-modsecurity-crs \
    && wget -qO/etc/modsecurity/modsecurity.conf https://github.com/SpiderLabs/ModSecurity/raw/v2/master/modsecurity.conf-recommended \
    && wget -qO/etc/modsecurity/unicode.mapping https://github.com/SpiderLabs/ModSecurity/raw/v2/master/unicode.mapping \
    && wget -qO/tmp/owasp.tar.gz https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/${OWASP_MODSEC_VERSION}.tar.gz \
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
