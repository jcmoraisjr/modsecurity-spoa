#!/bin/sh
set -e

if [ $# -gt 0 ] && [ "$1" = "${1#-}" ]; then
    # First char isn't `-`, probably a `docker run -ti <cmd>`
    # Just exec and exit
    exec "$@"
    exit
fi

unset options configFiles
while [ $# -gt 0 ]; do
    case "$1" in
        -f)
            shift
            configFiles="$configFiles $1"
            ;;
        --)
            shift
            configFiles="$configFiles $@"
            break
            ;;
        *)
            options="$options $1"
            ;;
    esac
    shift
done

configFiles="${configFiles:-/etc/modsecurity/modsecurity.conf /etc/modsecurity/owasp-modsecurity-crs.conf}"

conf=$(mktemp)
for f in $configFiles; do
    if [ ! -f "$f" ]; then
        echo "File not found: $f" >&2
        exit 1
    fi
    echo "Include $f"
done > $conf

echo "Using options:${options:- <default>}"
echo "Using config files:"
sed -n 's/Include /  - /p' $conf

exec modsecurity $options -f $conf
