#!/bin/bash
set -e

# Split by comma
IFS=',' read -r -a lines <<< "$@"

for x in "${lines[@]}"; do
    # Split by space
    IFS=' ' read -r -a param <<< "${x[@]}"
    echo "<========  ${param[*]}  ========>"
    curl "${param[@]}"
    echo -e '\n'
done
