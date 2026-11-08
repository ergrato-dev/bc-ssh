#!/usr/bin/env bash
#
# banner.sh — muestra la primera línea que envía un servidor SSH.
# Uso: ./banner.sh HOST [PUERTO]

set -euo pipefail

host="${1:?uso: ./banner.sh HOST [PUERTO]}"
puerto="${2:-22}"

# El servidor envía su banner y se queda esperando el nuestro, que nunca
# llega: sin -w 2, nc no terminaría. tr quita el \r del final de línea.
nc -w 2 "$host" "$puerto" </dev/null | head -n 1 | tr -d '\r'
