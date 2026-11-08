#!/usr/bin/env bash
# buscar.sh — hace a mano lo que ssh-keygen -F hace con las líneas hasheadas
# de known_hosts: calcular HMAC-SHA1(sal, nombre) y compararlo con el guardado.
# Uso: buscar.sh NOMBRE [ARCHIVO]   (ARCHIVO por defecto: ~/.ssh/known_hosts)
# Salida: 0 si encuentra alguna línea, 1 si no, 2 uso incorrecto.
set -euo pipefail

[[ $# -ge 1 ]] || { echo "uso: buscar.sh NOMBRE [ARCHIVO]" >&2; exit 2; }
nombre=$1 archivo=${2:-$HOME/.ssh/known_hosts}

# hmac SAL TEXTO: HMAC-SHA1 de TEXTO usando como llave la sal (en base64).
# openssl quiere la llave en hexadecimal: base64 -d la decodifica y od la
# pasa a hex.
hmac() {
  local llave_hex
  llave_hex=$(base64 -d <<<"$1" | od -An -tx1 | tr -d ' \n')
  printf %s "$2" | openssl dgst -sha1 -mac HMAC -macopt "hexkey:$llave_hex" -binary | base64
}

n=0 encontradas=0
while read -r nombres resto; do
  n=$((n + 1))
  [[ $nombres == '|1|'* ]] || continue        # solo líneas hasheadas
  IFS='|' read -r _ _ sal hash <<<"$nombres"  # |1|SAL|HASH
  if [[ $(hmac "$sal" "$nombre") == "$hash" ]]; then
    echo "línea $n: ${resto%% *}"
    encontradas=$((encontradas + 1))
  fi
done < "$archivo"

(( encontradas > 0 ))
