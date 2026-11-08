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

case "$rc" in
  0) echo "con llaves: $sock" ;;
  1) echo "vacío: $sock" ;;
  *)
    # Un socket que existe sin agente detrás queda tras un reinicio o un
    # agente que murió: ssh-agent -a no podrá usar esa ruta hasta borrarlo.
    if [[ -S "$sock" ]]; then
      echo "sin agente: $sock (socket huérfano)"
    else
      echo "sin agente: $sock"
    fi
    rc=2
    ;;
esac
exit "$rc"
