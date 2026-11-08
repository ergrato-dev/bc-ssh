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

# TODO: anota en "$log" una línea con la hora
#   (date +%T), SI o NO y "$pregunta" (ya sin saltos de línea).
#   Sal con 0 solo si existe ~/.ssh/permitir; si no, con 1.
exit 1
