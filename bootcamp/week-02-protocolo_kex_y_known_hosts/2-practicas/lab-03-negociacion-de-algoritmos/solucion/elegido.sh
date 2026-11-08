#!/usr/bin/env bash
# elegido.sh — aplica a mano la regla de negociación de SSH y la compara con
# lo que eligió ssh. Regla (RFC 4253 §7.1): para cada función gana el PRIMER
# algoritmo de la lista del CLIENTE que también esté en la del servidor.
# Uso: SSHPASS=alumno ./elegido.sh HOST [opciones de ssh...]   (contraseña solo del laboratorio)
set -euo pipefail

[[ $# -ge 1 ]] || { echo "uso: elegido.sh HOST [opciones de ssh...]" >&2; exit 2; }
# || true: si la conexión falla, igual se analiza lo negociado hasta el fallo.
log=$(sshpass -e ssh -vv "$@" true 2>&1 | tr -d '\r') || true

# lista LADO FUNCION: la lista que envió ese lado en su KEXINIT.
# LADO es "local client" o "peer server"; FUNCION, el prefijo de la línea.
lista() {
  sed -n "/^debug2: $1 KEXINIT proposal/,/first_kex_follows/p" <<<"$log" \
    | sed -n "s/^debug2: $2: //p"
}

# primero CLIENTE SERVIDOR: el primer elemento de CLIENTE presente en SERVIDOR.
primero() {
  local alg
  for alg in ${1//,/ }; do
    [[ ",$2," == *",$alg,"* ]] && { echo "$alg"; return; }
  done
  echo "(ninguno)"
}

for f in "KEX algorithms" "host key algorithms" "ciphers ctos" "MACs ctos"; do
  printf '%-20s %s\n' "$f:" "$(primero "$(lista 'local client' "$f")" "$(lista 'peer server' "$f")")"
done
echo "--- ssh eligió:"
grep -E '^debug1: kex: (algorithm|host key algorithm|client->server)' <<<"$log" | sed 's/^debug1: //'
