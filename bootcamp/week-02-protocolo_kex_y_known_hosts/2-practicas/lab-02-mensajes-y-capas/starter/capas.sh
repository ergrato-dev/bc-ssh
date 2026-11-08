#!/usr/bin/env bash
# capas.sh — lista los mensajes SSH de una conexión y la capa a la que pertenece cada uno.
# Uso: SSHPASS=alumno ./capas.sh HOST   (contraseña solo del laboratorio)
# Fuente: las líneas "send packet: type N" / "receive packet: type N" de ssh -vvv.
set -euo pipefail

[[ $# -eq 1 ]] || { echo "uso: capas.sh HOST" >&2; exit 2; }

# Nombres de RFC 4250 §4.1.2 para los tipos que aparecen en una conexión normal.
declare -A nombre=(
  [1]=DISCONNECT [5]=SERVICE_REQUEST [6]=SERVICE_ACCEPT [7]=EXT_INFO
  [20]=KEXINIT [21]=NEWKEYS [30]=KEX_ECDH_INIT [31]=KEX_ECDH_REPLY
  [50]=USERAUTH_REQUEST [51]=USERAUTH_FAILURE [52]=USERAUTH_SUCCESS
  [80]=GLOBAL_REQUEST [90]=CHANNEL_OPEN [91]=CHANNEL_OPEN_CONFIRMATION
  [93]=CHANNEL_WINDOW_ADJUST [94]=CHANNEL_DATA [96]=CHANNEL_EOF
  [97]=CHANNEL_CLOSE [98]=CHANNEL_REQUEST [99]=CHANNEL_SUCCESS
)

# El número de tipo dice la capa: cada protocolo tiene reservado un rango.
capa() {
  # TODO: imprime transporte (1-49), autenticacion (50-79), conexion (80-127)
  #   u otro, según el número $1. Usa if/elif con (( )).
  echo "?"
}

sshpass -e ssh -vvv "$1" true 2>&1 \
  | grep -oE '(send|receive) packet: type [0-9]+' \
  | while read -r dir _ _ tipo; do
      printf '%-8s %3s  %-13s %s\n' "$dir" "$tipo" "$(capa "$tipo")" "${nombre[$tipo]:-?}"
    done
