#!/usr/bin/env bash
#
# agente-vivo.sh — dice si hay un ssh-agent detrás de un socket.
#
# Uso: agente-vivo.sh [SOCKET]      (sin SOCKET, usa $SSH_AUTH_SOCK)
#
# Códigos de salida, los mismos que ssh-add -l:
#   0 agente con llaves, 1 agente vacío, 2 no hay agente.

set -uo pipefail

sock="${1:-${SSH_AUTH_SOCK:-}}"
if [[ -z "$sock" ]]; then
  echo "sin agente: ni SOCKET ni SSH_AUTH_SOCK" >&2
  exit 2
fi

SSH_AUTH_SOCK="$sock" ssh-add -l >/dev/null 2>&1
rc=$?

# TODO: según $rc, imprime "con llaves: SOCKET" (0), "vacío: SOCKET" (1) o
#   "sin agente: SOCKET" (cualquier otro), y añade " (socket huérfano)" si
#   el archivo existe y es un socket (-S). Sal con 0, 1 o 2.
echo "TODO" >&2
exit 3
