#!/usr/bin/env bash
#
# revisar-permisos.sh — revisa los permisos que exigen ssh y sshd en tu cuenta.
#
# Uso: revisar-permisos.sh
#   En el servidor, sin copiarlo:  ssh HOST bash -s < revisar-permisos.sh
#
#   ok   /home/alumno 750
#   MAL  /home/alumno/.ssh 777  (otros pueden escribir)
#
# Códigos de salida: 0 todo bien, 1 algún permiso incorrecto.

set -euo pipefail

mal=0

# revisar RUTA MASCARA MOTIVO: MAL si el modo tiene algún bit de MASCARA.
revisar() {
  [[ -e "$1" ]] || return 0
  local modo
  modo=$(stat -c %a "$1")
  # 8#... lee el número en octal; & deja los bits comunes a los dos.
  if (( 8#$modo & 8#$2 )); then
    printf 'MAL  %s %s  (%s)\n' "$1" "$modo" "$3"
    mal=$(( mal + 1 ))
  else
    printf 'ok   %s %s\n' "$1" "$modo"
  fi
}

# Carpeta personal y authorized_keys: StrictModes de sshd. 002 = escritura
# de otros. El grupo se tolera en Ubuntu si es el grupo personal del usuario.
revisar "$HOME" 002 "otros pueden escribir"
revisar "$HOME/.ssh" 077 "solo tú deberías poder entrar"
revisar "$HOME/.ssh/authorized_keys" 022 "solo tú deberías poder escribir"

# Privadas: ssh las ignora si el grupo u otros tienen cualquier permiso.
for pub in "$HOME"/.ssh/*.pub; do
  [[ -f "${pub%.pub}" ]] && revisar "${pub%.pub}" 077 "privada legible por otros"
done

(( mal == 0 ))
