#!/usr/bin/env bash
#
# banner.sh — muestra la primera línea que envía un servidor SSH.
# Uso: ./banner.sh HOST [PUERTO]

set -euo pipefail

host="${1:?uso: ./banner.sh HOST [PUERTO]}"
puerto="${2:-22}"

# TODO: conecta con nc a "$host" "$puerto" con un límite de 2 s (-w 2),
#       con la entrada vacía (</dev/null), quédate con la primera línea
#       (head -n 1) y quítale el \r final (tr -d '\r').
echo "TODO: banner de $host:$puerto"
