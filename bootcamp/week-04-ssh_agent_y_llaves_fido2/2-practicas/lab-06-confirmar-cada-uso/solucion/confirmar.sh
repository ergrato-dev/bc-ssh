#!/usr/bin/env bash
#
# confirmar.sh — SSH_ASKPASS para ssh-agent: decide cada firma de una
# llave añadida con ssh-add -c y la anota.
#
# ssh-agent lo ejecuta con la pregunta en $1. Salir con 0 firma; con
# cualquier otro código, el agente se niega ("agent refused operation").
# Permite solo mientras exista ~/.ssh/permitir.

log="$HOME/.ssh/confirmaciones.log"
pregunta="${1//$'\n'/ }"

if [[ -e "$HOME/.ssh/permitir" ]]; then
  echo "$(date +%T) SI  $pregunta" >> "$log"
  exit 0
fi
echo "$(date +%T) NO  $pregunta" >> "$log"
exit 1
