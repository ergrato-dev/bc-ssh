#!/usr/bin/env bash
#
# fases.sh — resume en seis líneas lo que ssh -v cuenta de una conexión.
# Uso: SSHPASS=alumno ./fases.sh HOST

set -euo pipefail

host="${1:?uso: SSHPASS=alumno ./fases.sh HOST}"

# -v escribe la depuración en stderr: 2>&1 la junta con stdout para leerla.
# Algunas líneas acaban en \r: tr lo quita para que las regex casen con $.
log=$(sshpass -e ssh -v -o StrictHostKeyChecking=accept-new "$host" true 2>&1 | tr -d '\r')

# Imprime el grupo 1 de la primera línea del log que casa con la regex $1.
campo() { sed -nE "s/$1/\1/p" <<<"$log" | head -n 1; }

echo "tcp:      $(campo '^debug1: Connecting to (.*)\.$')"
# TODO 1: servidor  — línea "Remote protocol version ..., remote software version X"
# TODO 2: kex       — línea "kex: algorithm: X"
# TODO 3: host key  — línea "Server host key: X"
# TODO 4: cifrado   — línea "kex: server->client cipher: X MAC: ..." (solo X)
# TODO 5: auth      — línea "Authenticated to ... using "X"."
