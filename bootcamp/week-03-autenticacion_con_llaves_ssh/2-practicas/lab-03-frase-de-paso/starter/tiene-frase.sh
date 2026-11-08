#!/usr/bin/env bash
#
# tiene-frase.sh — dice qué llaves privadas de un directorio no tienen frase de paso.
#
# Uso: tiene-frase.sh [DIRECTORIO]      (~/.ssh por defecto)
#
#   lab con-frase
#   viejo SIN-FRASE
#
# Una privada es cualquier archivo con un .pub al lado.
# Códigos de salida: 0 todas tienen frase, 1 alguna no la tiene.

set -euo pipefail

dir="${1:-$HOME/.ssh}"
sin_frase=0
for pub in "$dir"/*.pub; do
  [[ -e "$pub" ]] || continue          # directorio sin ninguna .pub
  privada="${pub%.pub}"
  [[ -f "$privada" ]] || continue
  # TODO: cambia "false" por un ssh-keygen que intente sacar la pública de
  #   "$privada" con la frase vacía (-y -P ""), sin imprimir nada.
  if false; then
    echo "$(basename "$privada") SIN-FRASE"
    sin_frase=$(( sin_frase + 1 ))
  else
    echo "$(basename "$privada") con-frase"
  fi
done

(( sin_frase == 0 ))
