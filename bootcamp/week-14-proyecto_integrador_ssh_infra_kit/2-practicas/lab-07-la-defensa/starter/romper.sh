#!/usr/bin/env bash
#
# romper.sh — estropea server de una forma al azar, para practicar la defensa.
#
# Uso (en tu equipo, desde la raíz del repositorio):
#   bootcamp/week-14-proyecto_integrador_ssh_infra_kit/2-practicas/lab-07-la-defensa/starter/romper.sh [N]
#
# Sin N, elige una avería de 1 a 6 y no dice cuál: la tienes que encontrar
# tú, con bin/doctor y el RUNBOOK. Con N, rompe esa (para repetir una).
# Solo para el laboratorio: actúa como root dentro del contenedor server.
#
# Para dejar server como nuevo: docker compose up -d --force-recreate server
# y los pasos del lab 06.
set -euo pipefail

n=${1:-$(( RANDOM % 6 + 1 ))}
en_server() { docker compose exec -T server sh -c "$1"; }
# shellcheck disable=SC2016 # $(cat ...) se expande en server, no aquí
recargar='sshd -t 2>/dev/null && kill -HUP $(cat /run/sshd.pid)'

case $n in
  1) en_server 'chmod o+w /home/alumno/.ssh' ;;
  2) en_server 'gpasswd -d alumno ssh-users >/dev/null' ;;
  3) en_server "echo 'KexAlgorithms diffie-hellman-group14-sha1' > /etc/ssh/sshd_config.d/05-cambio.conf && $recargar" ;;
  4) en_server "echo 'Port 2222' > /etc/ssh/sshd_config.d/05-cambio.conf && $recargar" ;;
  5) en_server "echo y | ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key && $recargar" ;;
  6) en_server 'ssh-keygen -q -k -f /etc/ssh/revoked.krl /home/alumno/.ssh/authorized_keys' ;;
  *) echo "uso: romper.sh [1-6]" >&2; exit 2 ;;
esac
echo "server roto. Empieza por bin/doctor lab-server."
