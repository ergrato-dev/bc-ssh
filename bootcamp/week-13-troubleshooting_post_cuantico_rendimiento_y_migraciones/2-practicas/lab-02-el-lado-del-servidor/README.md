# Lab 02 — El lado del servidor

⏱ Duración estimada: ~60 min

## Objetivo

Encontrar la razón de un `Permission denied` que el cliente no conoce: arrancar un `sshd` de depuración en otro puerto, romper a propósito permisos y grupos para leer qué dice el servidor, y comprobar la configuración con `sshd -T -C` y `sshd -t` antes de tocar el `sshd` de verdad.

## Contexto

- Qué cuenta el servidor y qué no: [teoría 01](../../1-teoria/01-diagnostico-por-capas.md#el-servidor-sabe-la-razón).
- Vas a romper el acceso de `alumno` a propósito; cada paso lo arregla en la misma orden. Si te quedas fuera, en tu equipo: `docker compose exec server chmod 700 /home/alumno/.ssh`.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-v/README.md).

1. **Un `sshd` solo para mirar.** En `server`, como root, un `sshd` en el puerto 2222 con `-d`; en segundo plano, para seguir en la misma terminal:
   ```bash
   ssh -n server 'sudo /usr/sbin/sshd -d -p 2222 2>&1' > ~/w/sshd-d.log &
   sleep 1
   ssh -p 2222 -o HostKeyAlias=server server true; echo "código: $?"
   wait
   grep -E 'Server listening on 0|Connection from|Accepted|Starting session' ~/w/sshd-d.log
   ```
   ```
   Environment:
     LANG=C.UTF-8
     ...
   código: 0
   Server listening on 0.0.0.0 port 2222.
   Connection from 172.20.0.5 port 43524 on 172.20.0.2 port 2222 rdomain ""
   Accepted key ED25519 SHA256:Gmij3RUkXCAjU7MNogjC9Jvm0RX0Hn51wYPBFODPFdE found at /home/alumno/.ssh/authorized_keys:1
   Accepted publickey for alumno from 172.20.0.5 port 43524 ssh2: ED25519 SHA256:Gmij3RUkXCAjU7MNogjC9Jvm0RX0Hn51wYPBFODPFdE
   Starting session: command for alumno from 172.20.0.5 port 43524 id 0
   ```

   | Pieza | Qué hace |
   |---|---|
   | `/usr/sbin/sshd` | `sshd` exige ruta completa: se vuelve a ejecutar a sí mismo para cada conexión |
   | `-d` | Depuración: no pasa a segundo plano, escribe todo en `stderr`, atiende **una** conexión y sale |
   | `-p 2222` | Otro puerto: el `sshd` del 22 sigue intacto, y tu sesión con él también |
   | `ssh -n ... &` | La orden corre en segundo plano sin leer tu teclado (`-n`); `wait` espera a que termine |
   | `HostKeyAlias=server` | Es el mismo servidor con las mismas host keys, pero `known_hosts` guarda `server`, no `[server]:2222`: el alias le dice a `ssh` con qué línea comparar |

   - Las líneas `Environment:` las escribe el `sshd` en modo depuración en tu sesión; en uno normal no salen.
   - `found at .../authorized_keys:1`: qué archivo y qué línea dejaron entrar. Sirve para saber qué llave borrar.

2. **Permisos: el cliente no sabe nada.** Deja `~/.ssh` escribible por cualquiera, conecta y arréglalo, todo en la misma orden:
   ```bash
   ssh -n server 'chmod o+w .ssh; sudo /usr/sbin/sshd -d -p 2222 2>&1; chmod o-w .ssh' > ~/w/sshd-d.log &
   sleep 1
   ssh -p 2222 -o HostKeyAlias=server -o BatchMode=yes server true; echo "código: $?"
   wait
   grep -E 'refused|Failed' ~/w/sshd-d.log
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   Authentication refused: bad ownership or modes for directory /home/alumno/.ssh
   Failed publickey for alumno from 172.20.0.5 port 44592 ssh2: ED25519 SHA256:Gmij3RUkXCAjU7MNogjC9Jvm0RX0Hn51wYPBFODPFdE
   ```
   - El cliente ve lo mismo que con una llave desconocida ([lab 01](../lab-01-leer-ssh-v/README.md), paso 6). El servidor sabe la razón: con `StrictModes yes` (por defecto) **ignora** un `authorized_keys` que otro usuario podría haber escrito.
   - Lo que no puede ser escribible por otros: tu home, `~/.ssh` y `~/.ssh/authorized_keys`. Lo seguro: `chmod 700 ~/.ssh` y `chmod 600 ~/.ssh/authorized_keys`.
   - El `chmod o-w` del final es lo que te deja entrar en el paso siguiente. Compruébalo: `ssh server stat -c %A .ssh` da `drwx------`.

3. **Grupos: un usuario que no está invitado.** Ahora la regla va en el `sshd` de depuración (`-o`), no en su configuración:
   ```bash
   ssh -n server 'sudo /usr/sbin/sshd -d -p 2222 -o AllowGroups=ssh-users 2>&1' > ~/w/sshd-d.log &
   sleep 1
   ssh -p 2222 -o HostKeyAlias=server -o BatchMode=yes server true; echo "código: $?"
   wait
   grep -E 'not allowed|closed' ~/w/sshd-d.log
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   User alumno from 172.20.0.5 not allowed because none of user's groups are listed in AllowGroups
   Connection closed by invalid user alumno 172.20.0.5 port 38528 [preauth]
   ```
   - El mismo `Permission denied` en el cliente, otra razón en el servidor. Es el error de la [semana 07](../../../week-07-servidor_sshd_config_y_hardening/README.md) si despliegas `10-acceso.conf` sin `usermod -aG ssh-users`.
   - `-o` en `sshd` prueba una opción sin escribir ningún archivo. Cuando el `sshd` de depuración sale, la regla desaparece.

4. **Qué le toca a cada uno: `sshd -T -C`.** Escribe la regla en un archivo (sin recargar) y pregunta qué se aplicaría a `alumno` entrando desde el cliente:
   ```bash
   ssh server 'echo "AllowGroups ssh-users" | sudo tee /etc/ssh/sshd_config.d/05-prueba.conf >/dev/null
   id -nG
   sudo sshd -T -C user=alumno,host=client,addr=172.20.0.5 | grep -i allowgroups'
   ```
   ```
   alumno adm dialout cdrom floppy sudo audio dip video plugdev
   allowgroups ssh-users
   ```
   - `-T` imprime la configuración final, con todos los `Include` y valores por defecto; `-C` evalúa los `Match` como si entrara esa conexión (usuario, nombre, IP).
   - Con eso y `id -nG` ya sabes que `alumno` se quedaría fuera, **antes** de recargar. La IP es la de tu cliente: mírala en `Connection from` del paso 1.

5. **Una errata: `sshd -t`.** Cambia el archivo por uno con un error y valida:
   ```bash
   ssh server 'echo "MaxAuthTries tres" | sudo tee /etc/ssh/sshd_config.d/05-prueba.conf >/dev/null
   sudo sshd -t; echo "código: $?"
   sudo rm /etc/ssh/sshd_config.d/05-prueba.conf'
   ```
   ```
   /etc/ssh/sshd_config.d/05-prueba.conf line 1: MaxAuthTries integer value invalid.
   código: 255
   ```
   - `sshd -t` lee toda la configuración y sale con 0 si es válida, sin tocar el `sshd` que corre. Tu `bin/sshd-deploy` y el playbook de la [semana 12](../../../week-12-automatizacion_scripting_ci_cd_y_ansible/README.md) lo ejecutan antes de cada recarga.
   - Un `kill -HUP` con esta errata cerraría el `sshd` que escucha (al recargar se vuelve a ejecutar y no arranca): la sesión que tienes abierta seguiría, las nuevas recibirían `Connection refused`.
   - El `rm` del final deja el servidor como estaba.

6. **El resumen que vas a usar.** Cliente y servidor, lado a lado:

   | El cliente dice | El servidor dice (`sshd -d` o su log) | Arreglo |
   |---|---|---|
   | `Permission denied (publickey,...)` | `Authentication refused: bad ownership or modes` | `chmod 700 ~/.ssh`, `chmod 600 authorized_keys` |
   | `Permission denied (publickey,...)` | `not allowed because none of user's groups are listed in AllowGroups` | `usermod -aG GRUPO USUARIO` |
   | `Permission denied (publickey,...)` | `Failed publickey` sin `refused` antes | La llave no está en `authorized_keys` |
   | `Permission denied (publickey,...)` | `refusing RSA key: Invalid key length` | Llave RSA de menos de `RequiredRSASize` ([lab 06](../lab-06-migrar-llaves-de-usuario/README.md)) |
   | `Connection closed by ...` | `Connection closed by invalid user` | El usuario no existe o no puede entrar |

## Criterios de éxito

- [ ] Arrancas un `sshd -d` en otro puerto y explicas `HostKeyAlias` (paso 1)
- [ ] Encuentras en el servidor la razón de un `Permission denied` por permisos (paso 2)
- [ ] Encuentras la razón de un `Permission denied` por grupos (paso 3)
- [ ] Usas `sshd -T -C` para saber qué se aplica a un usuario antes de recargar (paso 4)
- [ ] Validas con `sshd -t` y explicas qué pasaría sin validar (paso 5)

## Reto extra

Repite el paso 2 con `chmod g+w .ssh` en lugar de `o+w`. ¿Entra? Busca en `ssh server cat /etc/group` qué miembros tiene el grupo `alumno`: Ubuntu acepta la escritura del grupo cuando el grupo es solo tuyo. ¿Qué pasaría en un servidor donde todos los usuarios comparten el grupo `users`?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — Leer `ssh -v`](../lab-01-leer-ssh-v/README.md) | [Lab 03 — Sin algoritmo en común](../lab-03-sin-algoritmo-en-comun/README.md) → |

[↑ Semana 13](../../README.md)
