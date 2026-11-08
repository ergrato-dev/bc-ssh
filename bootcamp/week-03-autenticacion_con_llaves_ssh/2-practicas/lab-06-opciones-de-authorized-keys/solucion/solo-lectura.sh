#!/usr/bin/env bash
#
# solo-lectura.sh — comando forzado para una llave de monitorización.
#
# En authorized_keys del servidor:
#   restrict,command="~/solo-lectura.sh" ssh-ed25519 AAAA... monitor
#
# El cliente pide un nombre y el script ejecuta el comando que le corresponde:
#   ssh -i monitor server carga     → uptime
#   ssh -i monitor server disco     → df -h /
#   ssh -i monitor server memoria   → free -m
# Cualquier otra cosa se rechaza con código 1.

set -euo pipefail

# sshd deja en SSH_ORIGINAL_COMMAND lo que pidió el cliente. Se compara como
# texto y nunca se ejecuta: así nada de lo que escriba el cliente llega al shell.
case "${SSH_ORIGINAL_COMMAND:-}" in
  carga)   exec uptime ;;
  disco)   exec df -h / ;;
  memoria) exec free -m ;;
  *)
    echo "solo-lectura: no permitido: '${SSH_ORIGINAL_COMMAND:-}' (usa carga, disco o memoria)" >&2
    exit 1
    ;;
esac
