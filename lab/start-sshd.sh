#!/usr/bin/env bash
# Arranque de los roles servidor: genera host keys únicas y deja sshd en
# primer plano (-D) con logs a stderr (-e) para verlos con `docker compose logs`.
#
# Qué: cada línea del log se escribe dos veces: tal cual en la salida del
#   contenedor y, con fecha, host y "sshd:", en /var/log/auth.log.
# Para qué: fail2ban (semana 11) necesita un archivo con la hora de cada
#   intento, como el auth.log que rsyslog escribe en un Ubuntu real.
# Impacto: `docker compose logs` no cambia; printf '%(...)T' pone la fecha
#   sin lanzar un proceso por línea.
set -euo pipefail
ssh-keygen -A
host=$(hostname)
exec /usr/sbin/sshd -D -e 2> >(
  while IFS= read -r linea; do
    linea=${linea%$'\r'}   # sshd -e termina cada línea con \r\n
    printf '%s\n' "$linea"
    printf '%(%F %T)T %s sshd: %s\n' -1 "$host" "$linea" >> /var/log/auth.log
  done
)
