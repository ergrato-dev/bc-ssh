# Lab 03 — Una llave de despliegue

⏱ Duración estimada: ~60 min

## Objetivo

Crear la llave que usará un CI para publicar una web en `server` y limitarla a eso: comando forzado que solo admite dos órdenes (`estado` y `publicar`), sin terminal ni reenvíos (`restrict`) y solo desde la red del laboratorio (`from=`). Al terminar sabes qué puede hacer esa llave si se filtra, y por qué una llave para Ansible no se puede limitar igual.

## Contexto

- Llave del CI y opciones de `authorized_keys`: [teoría 02](../../1-teoria/02-despliegue-desde-ci.md#la-llave-del-ci) y [semana 03](../../../week-03-autenticacion_con_llaves_ssh/1-teoria/03-authorized_keys-y-opciones.md).
- **La contraseña `alumno` y la llave sin frase de este lab son solo para el laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-ssh-en-scripts/README.md).

1. **La llave del CI.** Solo para esto, sin frase (nadie la escribiría), con un comentario que la identifique en los logs:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C ci@despliegue -f ~/.ssh/ci
   ```

2. **La puerta.** El comando forzado: se ejecuta pida lo que pida el cliente, y lo pedido llega en `$SSH_ORIGINAL_COMMAND`. Instálalo en `server` con tu llave de administrador:
   ```bash
   ssh server "mkdir -p bin web; cat > bin/puerta; chmod 755 bin/puerta" <<'FIN'
   #!/bin/sh
   # puerta: lo único que puede hacer la llave del CI (comando forzado).
   echo "$(date "+%F %T") $SSH_CLIENT: $SSH_ORIGINAL_COMMAND" >> "$HOME/despliegues.log"
   case "$SSH_ORIGINAL_COMMAND" in
     estado)   cat "$HOME/web/VERSION" 2>/dev/null || echo "sin desplegar" ;;
     publicar) rm -rf "$HOME/web.nueva" && mkdir "$HOME/web.nueva" &&
               tar -xzf - -C "$HOME/web.nueva" &&
               rm -rf "$HOME/web" && mv "$HOME/web.nueva" "$HOME/web" &&
               echo "publicada $(cat "$HOME/web/VERSION")" ;;
     *)        echo "puerta: no permitido: $SSH_ORIGINAL_COMMAND" >&2; exit 1 ;;
   esac
   FIN
   ```
   - Un `case` con la lista de lo permitido; lo demás, rechazado. Nunca `eval "$SSH_ORIGINAL_COMMAND"`: eso es un shell con más pasos.
   - `publicar` lee un `tar` de su entrada, lo deja en `web.nueva` y solo entonces sustituye `web`: un envío cortado no deja la web a medias.
   - Cada orden queda en `despliegues.log`, con la IP de origen.

3. **La línea de `authorized_keys`.** La IP del cliente está en la red `172.20.0.0/16`:
   ```bash
   ip -4 -o addr show eth0 | awk '{print $4}'
   echo "restrict,command=\"/home/alumno/bin/puerta\",from=\"172.20.0.0/16\" $(cat ~/.ssh/ci.pub)" | ssh server "cat >> .ssh/authorized_keys"
   ```
   ```
   172.20.0.5/16
   ```
   Tu IP puede ser otra dentro de esa red. El kit escribe la misma línea con `bin/ak-line -c /home/alumno/bin/puerta -f 172.20.0.0/16 ~/.ssh/ci.pub`.

4. **Lo que puede hacer.**
   ```bash
   C="ssh -i ~/.ssh/ci -o IdentitiesOnly=yes server"
   $C estado; echo "código: $?"
   mkdir -p ~/w/web; echo v1 > ~/w/web/VERSION; echo hola > ~/w/web/index.html
   tar -czf - -C ~/w/web . | $C publicar; echo "código: $?"
   $C estado
   ```
   ```
   sin desplegar
   código: 0
   publicada v1
   código: 0
   v1
   ```

5. **Lo que no puede hacer.**
   ```bash
   $C "cat /etc/shadow"; echo "código: $?"
   $C; echo "código: $?"
   ```
   ```
   puerta: no permitido: cat /etc/shadow
   código: 1
   PTY allocation request failed on channel 0
   puerta: no permitido: 
   Connection to server closed.
   código: 1
   ```
   - Pidas lo que pidas, se ejecuta `puerta`.
   - Sin comando, `ssh` pide una terminal y un shell: `restrict` niega la terminal, y `puerta` recibe una orden vacía.

6. **Ni túneles.** `restrict` también quita los reenvíos de puertos:
   ```bash
   ssh -i ~/.ssh/ci -o IdentitiesOnly=yes -N -L 9999:localhost:22 server &
   sleep 1; nc -z -w2 127.0.0.1 9999; kill %1
   ```
   ```
   Connection to 127.0.0.1 9999 port [tcp/*] succeeded!
   channel 2: open failed: administratively prohibited: open failed
   ```
   El puerto local se abre (lo abre tu `ssh`), pero `server` rechaza el canal: la llave no sirve para saltar a otra máquina de su red.

7. **Solo desde donde debe.** Cambia `from=` a una red que no es la tuya y prueba:
   ```bash
   ssh server "sed -i 's#172.20.0.0/16#10.0.0.0/8#' .ssh/authorized_keys"
   ssh -i ~/.ssh/ci -o IdentitiesOnly=yes -o BatchMode=yes server estado; echo "código: $?"
   ssh server "grep -F 10.0.0.0 /var/log/auth.log | tail -1 | cut -d: -f4-"
   ssh server "sed -i 's#10.0.0.0/8#172.20.0.0/16#' .ssh/authorized_keys"
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
    /home/alumno/.ssh/authorized_keys:2: Authentication tried for alumno with correct key but not from a permitted host (host=172.20.0.5, ip=172.20.0.5, required=10.0.0.0/8).
   ```
   Una llave del CI copiada a otro equipo no entra. Sirve si los runners tienen IP fija (o un rango conocido); con runners de IP variable, no.

8. **El registro.**
   ```bash
   ssh server cat despliegues.log
   ```
   ```
   2026-11-10 23:44:32 172.20.0.5 45696 22: estado
   2026-11-10 23:44:35 172.20.0.5 45712 22: publicar
   2026-11-10 23:44:35 172.20.0.5 45714 22: estado
   2026-11-10 23:44:36 172.20.0.5 45730 22: cat /etc/shadow
   2026-11-10 23:44:36 172.20.0.5 45732 22: 
   ```
   Lo que pidió el CI, también lo rechazado, con fecha e IP.

9. **¿Y para Ansible?** Escribe en `~/w/notas.md` por qué esta llave no serviría para que Ansible configure `server` (pista: ¿qué comando ejecuta Ansible?, [teoría 03](../../1-teoria/03-ansible.md#cómo-usa-ssh)) y qué te queda para limitar una llave que sí lo haga.

## Criterios de éxito

- [ ] Explicas qué recibe `puerta` en `$SSH_ORIGINAL_COMMAND` y por qué no se usa `eval` (paso 2)
- [ ] Publicas una versión con la llave del CI (paso 4)
- [ ] Explicas por qué fallan un comando no permitido, una sesión y un túnel (pasos 5 y 6)
- [ ] Explicas qué hace `from=` y cuándo no sirve (paso 7)
- [ ] Explicas por qué esta restricción no vale para Ansible (paso 9)

## Reto extra

Añade a `puerta` una orden `volver` que restaure la versión anterior. Pista: `publicar` puede mover `web` a `web.anterior` en lugar de borrarla.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — Muchos servidores](../lab-02-muchos-servidores/README.md) | [Lab 04 — Un CI sin nadie delante](../lab-04-un-ci-sin-nadie-delante/README.md) → |

[↑ Semana 12](../../README.md)
