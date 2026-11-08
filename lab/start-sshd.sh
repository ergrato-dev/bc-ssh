#!/usr/bin/env bash
# Arranque de los roles servidor: genera host keys únicas y deja sshd en
# primer plano (-D) con logs a stderr (-e) para verlos con `docker compose logs`.
set -euo pipefail
ssh-keygen -A
exec /usr/sbin/sshd -D -e
