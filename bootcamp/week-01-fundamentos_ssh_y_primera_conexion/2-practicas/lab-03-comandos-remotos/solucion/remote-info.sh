#!/usr/bin/env bash
#
# remote-info.sh — consulta un host remoto sin abrir una shell interactiva.
# Uso: SSHPASS=alumno ./remote-info.sh HOST

set -euo pipefail

host="${1:?uso: SSHPASS=alumno ./remote-info.sh HOST}"

# sshpass -e toma la contraseña de $SSHPASS. Solo para el laboratorio: en la
# semana 03 las llaves lo sustituyen. accept-new acepta la huella de un host
# nuevo sin preguntar, pero rechaza una que cambió (semana 02).
remoto() { sshpass -e ssh -o StrictHostKeyChecking=accept-new "$host" "$@"; }

echo "host:    $(remoto hostname)"
echo "usuario: $(remoto whoami)"
# Comillas simples: $PRETTY_NAME se expande en el servidor, no aquí.
# shellcheck disable=SC2016
echo "sistema: $(remoto '. /etc/os-release && echo "$PRETTY_NAME"')"

# ssh devuelve el código de salida del comando remoto.
if remoto test -f /etc/ssh/sshd_config; then
  echo "sshd_config: existe"
else
  echo "sshd_config: no existe (código $?)"
fi
