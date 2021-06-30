# HAProxy agent for ModSecurity

HAProxy [agent](http://cbonte.github.io/haproxy-dconv/1.8/configuration.html#9.3) (SPOA)
for [ModSecurity](http://www.modsecurity.org) web application firewall
([WAF](https://en.wikipedia.org/wiki/Web_application_firewall)).

[![Docker Repository on Quay](https://quay.io/repository/jcmoraisjr/modsecurity-spoa/status "Docker Repository on Quay")](https://quay.io/repository/jcmoraisjr/modsecurity-spoa)

## SPOP and HAProxy version

The current [SPOP](https://www.haproxy.org/download/2.2/doc/SPOE.txt) version is v2, used since modsecurity-spoa v0.4. This agent version works on HAProxy 1.8.10 and newer.

SPOP v1 is used on modsecurity-spoa v0.1 to v0.3. This agent version works on HAProxy up to 1.8.9.

## Agent configuration

Command line syntax:

```
$ docker run -p 12345:12345 quay.io/jcmoraisjr/modsecurity-spoa [options] [-- <config-file1> [<config-file2> ...] ]
```

`config-files` can be used either after `--` (see above) or from `-f` option (see below).
The only difference is that the later supports only one filename. All config-files found
will be used, included in the same order as they have been declared.

In order to contain the original rules that are included in the setup without config-files, you should include the following in your `crs-setup.conf` file (if required). Running the Docker image without these included will disable a lot of ModSecurity's default rules.

```
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-901-INITIALIZATION.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-903.9001-DRUPAL-EXCLUSION-RULES.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-903.9002-WORDPRESS-EXCLUSION-RULES.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-903.9003-NEXTCLOUD-EXCLUSION-RULES.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-903.9004-DOKUWIKI-EXCLUSION-RULES.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-903.9005-CPANEL-EXCLUSION-RULES.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-903.9006-XENFORO-EXCLUSION-RULES.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-905-COMMON-EXCEPTIONS.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-910-IP-REPUTATION.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-911-METHOD-ENFORCEMENT.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-912-DOS-PROTECTION.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-913-SCANNER-DETECTION.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-921-PROTOCOL-ATTACK.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-934-APPLICATION-ATTACK-NODEJS.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-944-APPLICATION-ATTACK-JAVA.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/REQUEST-949-BLOCKING-EVALUATION.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/RESPONSE-950-DATA-LEAKAGES.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/RESPONSE-959-BLOCKING-EVALUATION.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/RESPONSE-980-CORRELATION.conf
Include /etc/modsecurity/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
```

An example of using config files would be.
```
cd rootfs
# download and configure conf files in rootfs directory
docker run -p 12345:12345 -v $(pwd):/root/ quay.io/jcmoraisjr/modsecurity-spoa -n 1 -- /root/modsecurity.conf /root/crs-setup.conf
```

If no config-file is declared, the following will be used:

* `/etc/modsecurity/modsecurity.conf`: ModSecurity recommended config, from ModSecurity [repository](https://github.com/SpiderLabs/ModSecurity/tree/v2/master)
    * Changes: `SecRuleEngine`, changed from `DetectionOnly` to `On`
* `/etc/modsecurity/owasp-modsecurity-crs.conf`: Generic attack detection rules for ModSecurity, from OWASP ModSecurity CRS [repository](https://github.com/SpiderLabs/owasp-modsecurity-crs)
    * Changes: `SecDefaultAction`, `phase:1` and `phase:2`, changed from `log,auditlog,pass` to `log,noauditlog,deny,status:403`

Options are: (from modsecurity agent -h)

```
    -h                   Print this message
    -d                   Enable the debug mode
    -f <config-file>     ModSecurity configuration file
    -m <max-frame-size>  Specify the maximum frame size (default : 16384)
    -p <port>            Specify the port to listen on (default : 12345)
    -n <num-workers>     Specify the number of workers (default : 10)
    -c <capability>      Enable the support of the specified capability
    -t <time>            Set a delay to process a message (default: 0)
                           The value is specified in milliseconds by default,
                           but can be in any other unit if the number is suffixed
                           by a unit (us, ms, s)

    Supported capabilities: fragmentation, pipelining, async
```

## HAProxy configuration

Configure modsecurity-spoa as a HAProxy SPOE agent. See also SPOE filter
[doc](http://cbonte.github.io/haproxy-dconv/1.8/configuration.html#9.3)
and SPOE [spec](https://www.haproxy.org/download/1.8/doc/SPOE.txt).

Changes to `haproxy.cfg` - change `127.0.0.1:12345` below to the
modsecurity-spoa endpoint:

```
    frontend httpfront
        mode http
        ...
        filter spoe engine modsecurity config /etc/haproxy/spoe-modsecurity.conf
        http-request deny if { var(txn.modsec.code) -m int gt 0 }
        ...
    backend spoe-modsecurity
        mode tcp
        server modsec-spoa1 127.0.0.1:12345
```

Create a `/etc/haproxy/spoe-modsecurity.conf`:

```
    [modsecurity]
    spoe-agent modsecurity-agent
        messages     check-request
        option       var-prefix  modsec
        timeout      hello       100ms
        timeout      idle        30s
        timeout      processing  1s
        use-backend  spoe-modsecurity
    spoe-message check-request
        args   unique-id method path query req.ver req.hdrs_bin req.body_size req.body
        event  on-frontend-http-request
```

## Test with docker

```
(cd ./test && ./run.sh)
```
