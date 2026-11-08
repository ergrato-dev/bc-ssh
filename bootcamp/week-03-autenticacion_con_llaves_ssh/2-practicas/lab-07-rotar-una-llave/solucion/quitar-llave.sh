#!/usr/bin/env bash
#
# quitar-llave.sh — borra de authorized_keys las líneas de una llave.
#
# Uso: quitar-llave.sh LLAVE_BASE64 [ARCHIVO]   (~/.ssh/authorized_keys por defecto)
#   En el servidor, sin copiarlo:
#   ssh HOST bash -s -- "$(cut -d' ' -f2 vieja.pub)" < quitar-llave.sh
#
#   quitadas: 1
#
# Busca por la llave (el campo en base64), no por el comentario: el
# comentario lo puede cambiar cualquiera y dos llaves pueden compartirlo.
# Códigos de salida: 0 quitó al menos una, 1 no encontró ninguna, 2 uso.

set -euo pipefail

llave="${1:-}"
archivo="${2:-$HOME/.ssh/authorized_keys}"

# Sin esta comprobación, una llave vacía coincidiría con todas las líneas y
# grep -v las borraría todas: te quedarías fuera del servidor.
if [[ ! "$llave" =~ ^AAAA[A-Za-z0-9+/=]{20,}$ ]]; then
  echo "uso: quitar-llave.sh LLAVE_BASE64 [ARCHIVO]" >&2
  exit 2
fi

antes=$(wc -l < "$archivo")
# -F: la llave es texto literal, no una expresión regular (+ y / son
# caracteres especiales). || true: grep sale con 1 si no queda ninguna línea.
grep -vF -- "$llave" "$archivo" > "$archivo.nuevo" || true
despues=$(wc -l < "$archivo.nuevo")

if (( antes == despues )); then
  rm "$archivo.nuevo"
  echo "quitadas: 0" >&2
  exit 1
fi

# Se escribe aparte y se renombra: si algo falla a medias, el archivo
# original sigue intacto. chmod antes del mv, para que nunca exista abierto.
chmod 600 "$archivo.nuevo"
mv "$archivo.nuevo" "$archivo"
echo "quitadas: $(( antes - despues ))"
