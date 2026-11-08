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

# TODO 1: imprime "usuario: " seguido de lo que devuelve whoami en el remoto.

# TODO 2: imprime "sistema: " y el PRETTY_NAME de /etc/os-release del remoto.
#         Cuidado con las comillas: ¿quién debe expandir $PRETTY_NAME?

# TODO 3: con `remoto test -f /etc/ssh/sshd_config`, imprime
#         "sshd_config: existe" o "sshd_config: no existe (código N)".
