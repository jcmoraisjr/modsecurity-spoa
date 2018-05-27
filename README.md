# HAProxy agent for ModSecurity

HAProxy [agent](http://cbonte.github.io/haproxy-dconv/1.8/configuration.html#9.3) (SPOA)
for [ModSecurity](http://www.modsecurity.org) web application firewall
([WAF](https://en.wikipedia.org/wiki/Web_application_firewall)).

[![Docker Repository on Quay](https://quay.io/repository/jcmoraisjr/modsecurity-spoa/status "Docker Repository on Quay")](https://quay.io/repository/jcmoraisjr/modsecurity-spoa)

## Agent configuration

Command line syntax:

```
$ docker run quay.io/jcmoraisjr/modsecurity-spoa [options] [-- <config-file1> [<config-file2> ...] ]
```

`config-files` can be used either after `--` (see above) or from `-f` option (see below).
The only difference is that the later supports only one filename. All config-files found
will be used, included in the same order as they have been declared. If no config-file is
declared, the following will be used:

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
