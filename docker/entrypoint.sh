#!/usr/bin/env bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- supervisord "$@"
fi

umask 002

echo "CMD: $*"
exec "$@"
