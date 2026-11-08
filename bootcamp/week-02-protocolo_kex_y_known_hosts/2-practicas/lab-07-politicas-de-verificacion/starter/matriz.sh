#!/usr/bin/env bash
# matriz.sh — qué hace ssh con cada valor de StrictHostKeyChecking ante una
# host key nueva, cambiada o revocada. Usa un known_hosts temporal: no toca
# el tuyo.
# Uso: SSHPASS=alumno ./matriz.sh HOST   (contraseña solo del laboratorio)
set -euo pipefail

[[ $# -eq 1 ]] || { echo "uso: matriz.sh HOST" >&2; exit 2; }
host=$1
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

real=$(ssh-keyscan -t ed25519 "$host" 2>/dev/null | cut -d' ' -f2,3)
ssh-keygen -q -t ed25519 -N '' -f "$dir/falsa"   # una llave que no es la del host
falsa=$(cut -d' ' -f1,2 "$dir/falsa.pub")

# preparar ESCENARIO: deja en $dir/kh el known_hosts de ese escenario.
preparar() {
  case $1 in
    nueva)    : > "$dir/kh" ;;
    cambiada) echo "$host $falsa" > "$dir/kh" ;;
    revocada) echo "@revoked $host $real" > "$dir/kh" ;;
  esac
}

# resultado SALIDA: resume en una palabra lo que pasó.
resultado() {
  # TODO: imprime "conecta" si $1 contiene DENTRO, "sin-clave" si
  #   contiene "Password authentication is disabled" y "corta" en otro caso.
  #   Usa grep -q con <<<"$1".
  echo "?"
}

printf '%-12s %-15s %-15s %-15s\n' "" nueva cambiada revocada
for valor in yes accept-new no; do
  fila=$(printf '%-12s' "$valor")
  for escenario in nueva cambiada revocada; do
    preparar "$escenario"
    # UpdateHostKeys=no: que el aprendizaje de llaves no se mezcle con lo
    # que se mide. </dev/null: ssh no se come la entrada del bucle.
    salida=$(sshpass -e ssh -o StrictHostKeyChecking="$valor" \
      -o UserKnownHostsFile="$dir/kh" -o UpdateHostKeys=no \
      "$host" 'echo DENTRO' 2>&1 </dev/null) || true
    fila+=$(printf ' %-15s' "$(resultado "$salida")")
  done
  echo "$fila"
done
