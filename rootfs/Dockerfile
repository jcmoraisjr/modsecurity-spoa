FROM alpine:3.22.1

ARG HAPROXY_MODSEC_REF=3c895f3e7dd291dba19d57ba054b277e6fb80ca4
ARG HAPROXY_MODSEC_SHA256=645ff6fd6fe1394462bd6b82ee5430606c631b83021f8b5cd7eca2b62b427970
ARG MODSEC_VERSION=2.9.11
ARG MODSEC_SHA256=1fe16eb96b6093f062cef73ec8b7ae481a59813766d49a7f5e4d1b85900e239e

ADD spoa.patch /

RUN apk upgrade --no-cache \
 && apk add --no-cache --virtual .build-modsecurity \
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
        pcre2-dev \
        libxml2-dev \
        libevent-dev \
        curl-dev \
        yajl-dev \
    && curl -fsSLo /tmp/modsecurity.tar.gz https://github.com/owasp-modsecurity/ModSecurity/releases/download/v${MODSEC_VERSION}/modsecurity-v${MODSEC_VERSION}.tar.gz \
    && curl -fsSLo /tmp/haproxy-modsecurity.zip https://github.com/haproxy/spoa-modsecurity/archive/${HAPROXY_MODSEC_REF}.zip \
    && echo "$MODSEC_SHA256  /tmp/modsecurity.tar.gz" | sha256sum -c \
    && mkdir -p /usr/src/modsecurity \
    && tar xzf /tmp/modsecurity.tar.gz --strip-components=1 -C /usr/src/modsecurity \
    && rm /tmp/modsecurity.tar.gz \
    && echo "$HAPROXY_MODSEC_SHA256  /tmp/haproxy-modsecurity.zip" | sha256sum -c \
    && unzip -d /usr/src /tmp/haproxy-modsecurity.zip \
    && mv /usr/src/spoa-modsecurity-${HAPROXY_MODSEC_REF} /usr/src/haproxy-modsecurity \
    && cd /usr/src/haproxy-modsecurity \
    && patch -p0 </spoa.patch \
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
    && apk add --no-cache $deps tini \
    && apk del --no-cache .build-modsecurity

ARG OWASP_MODSEC_VERSION=v4.16.0
ARG OWASP_MODSEC_SHA256=923e16dceea02a6afb06176cecefe29f305fc2cbd613eec60655e274d3b5dce2

RUN mkdir -p /etc/modsecurity/owasp-modsecurity-crs \
    && wget -qO/etc/modsecurity/modsecurity.conf https://github.com/owasp-modsecurity/ModSecurity/raw/v2/master/modsecurity.conf-recommended \
    && wget -qO/etc/modsecurity/unicode.mapping https://github.com/owasp-modsecurity/ModSecurity/raw/v2/master/unicode.mapping \
    && wget -qO/tmp/owasp.tar.gz https://github.com/coreruleset/coreruleset/archive/${OWASP_MODSEC_VERSION}.tar.gz \
    && echo "$OWASP_MODSEC_SHA256  /tmp/owasp.tar.gz" | sha256sum -c \
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

COPY . /

ENTRYPOINT ["tini", "--", "/start.sh"]
