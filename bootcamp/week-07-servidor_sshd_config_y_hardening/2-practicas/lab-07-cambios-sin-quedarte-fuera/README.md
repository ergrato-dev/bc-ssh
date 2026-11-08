# Lab 07 — Cambiar `sshd` sin quedarte fuera

⏱ Duración estimada: ~60 min

## Objetivo

Quedarte fuera de `server` de las dos formas más comunes, una configuración que te rechaza y un error que tumba `sshd`, y salir de cada una. Ver por qué una prueba por el master del multiplexing engaña, y montar a mano la vuelta atrás automática que el proyecto convierte en `bin/sshd-deploy`.

## Contexto

- El procedimiento de cambio seguro: [teoría 03](../../1-teoria/03-sftp-chroot-y-cambios-seguros.md#cambiar-sshd-sin-quedarte-fuera).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-sshd-config/README.md) y la variable `R` del [lab 02](../lab-02-autenticacion/README.md). Abre un master que dure 5 minutos: hará de "sesión que dejas abierta":
   ```bash
   R='sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   M='-o ControlMaster=auto -o ControlPath=~/.ssh/cm-%C -o ControlPersist=5m'
   ssh $M server true
   ```

1. **Una configuración que te deja fuera.** Válida para `sshd -t`, pero solo deja entrar a un usuario que no existe:
   ```bash
   echo 'AllowUsers nadie' | ssh $M server "sudo tee /etc/ssh/sshd_config.d/05-cierre.conf >/dev/null; sudo sshd -t && $R"
   ssh $M server 'echo sigo dentro'; echo "código: $?"
   ssh -o BatchMode=yes -o ControlPath=none server 'echo nueva'; echo "código: $?"
   ```
   ```
   sigo dentro
   código: 0
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   - Por el master, todo parece ir bien. Con una conexión nueva, estás fuera.
   - Si hubieras probado solo con `ssh server` y un `ControlMaster auto` en tu config (como el kit), habrías dado el cambio por bueno. Al cerrarse el master, ya no entrarías.

2. **Deshacer desde la sesión abierta.** El master es tu red de seguridad mientras siga vivo:
   ```bash
   ssh $M server "sudo rm /etc/ssh/sshd_config.d/05-cierre.conf; sudo sshd -t && $R"
   ssh -o BatchMode=yes -o ControlPath=none server 'echo nueva'
   ```
   ```
   nueva
   ```

3. **La vuelta atrás automática, a mano.** Antes de recargar, deja programado en `server` un proceso que deshaga el cambio en 20 s:
   ```bash
   echo 'AllowUsers nadie' | ssh $M server "sudo tee /etc/ssh/sshd_config.d/05-cierre.conf >/dev/null; sudo sshd -t"
   ssh $M server 'sudo sh -c "(sleep 20; rm /etc/ssh/sshd_config.d/05-cierre.conf; kill -HUP \$(cat /run/sshd.pid)) </dev/null >/dev/null 2>&1 &"'
   ssh $M server "$R"; ssh $M -O exit server
   ssh -o BatchMode=yes -o ControlPath=none server 'echo nueva'; echo "código: $?"
   sleep 25; ssh -o BatchMode=yes -o ControlPath=none server 'echo he vuelto'
   ```
   ```
   Exit request sent.
   alumno@server: Permission denied (publickey,password).
   código: 255
   he vuelto
   ```
   - `( ... ) &`: un grupo de órdenes en segundo plano. `\$(...)`: la `\` evita que tu shell lo expanda; se expande en `server`.
   - `</dev/null >/dev/null 2>&1`: el proceso suelta la entrada y la salida de la conexión, así que `ssh` termina enseguida y el proceso sigue vivo en `server`.
   - Cerraste el master **a propósito**: sin sesión abierta y fuera, 20 s después el servidor se arregló solo. Es un *dead man's switch*: se activa si tú no haces nada. Si el cambio fuera bueno, lo cancelarías (en el proyecto, creando un archivo de confirmación).

4. **Fuera y sin sesión: la consola.** Repite el bloqueo, esta vez sin vuelta atrás y sin master:
   ```bash
   echo 'AllowUsers nadie' | ssh server "sudo tee /etc/ssh/sshd_config.d/05-cierre.conf >/dev/null; sudo sshd -t && $R"
   ssh -o BatchMode=yes server true; echo "código: $?"
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   Por SSH ya no hay nada que hacer. En un servidor real, entras por la consola del proveedor. En el laboratorio, **en tu equipo**:
   ```bash
   docker compose exec server sh -c 'rm /etc/ssh/sshd_config.d/05-cierre.conf; kill -HUP 1'
   ```
   `docker compose exec` entra en el contenedor sin SSH, como root. `kill -HUP 1`: en el contenedor, `sshd` es el proceso 1. **En el cliente**, comprueba que vuelves a entrar: `ssh server true; echo "código: $?"` da `código: 0`.

5. **Un error que tumba `sshd`.** Recarga sin `sshd -t`, con un valor que no existe:
   ```bash
   ssh server "echo 'PasswordAuthentication talvez' | sudo tee /etc/ssh/sshd_config.d/05-mal.conf >/dev/null; $R"
   sleep 1; ssh server true; echo "código: $?"
   ```
   ```
   Connection to server closed by remote host.
   ssh: Could not resolve hostname server: Name or service not known
   código: 255
   ```
   En tu equipo:
   ```bash
   docker compose ps -a server --format '{{.Status}}'
   docker compose logs server | tail -1
   ```
   ```
   Exited (255) 1 second ago
   server-1  | /etc/ssh/sshd_config.d/05-mal.conf line 1: unsupported option "talvez".
   ```
   - Al recargar, `sshd` no pudo leer su configuración y terminó, y con él tu propia conexión (`closed by remote host`). En el contenedor era el proceso principal, así que el contenedor entero se paró y su nombre dejó de resolver.
   - En un servidor real, `sshd` muere igual y nadie puede entrar. `systemctl reload ssh` de Ubuntu ejecuta `sshd -t` antes y no recarga si falla; `kill -HUP` no.
   - Aquí no hay consola que valga: el contenedor no arranca con esa configuración. Lo recreas, y pierdes todo lo que había en él: `docker compose up -d --force-recreate server`. **En el cliente**, el servidor tiene host key nueva y no tiene tu llave: repite el paso 0 del [lab 01](../lab-01-sshd-config/README.md) desde `ssh-keyscan`.

6. **El orden que evita todo esto.** Lo que vas a automatizar en el proyecto:

   | Paso | Orden | Qué evita |
   |---|---|---|
   | 1 | Deja una sesión abierta | Quedarte sin forma de deshacer (pasos 1 y 2) |
   | 2 | `sudo sshd -t` | Tumbar `sshd` (paso 5) |
   | 3 | Programa la vuelta atrás | Quedarte fuera sin sesión (pasos 3 y 4) |
   | 4 | Recarga | |
   | 5 | Prueba con `ssh -o ControlPath=none` | Dar por bueno un cambio que solo funciona por el master (paso 1) |
   | 6 | Si entra, cancela la vuelta atrás | |

   `bin/sshd-deploy HOST` hace los pasos 2 a 6 en una orden: [proyecto](../../3-proyecto/README.md).

## Criterios de éxito

- [ ] Te quedaste fuera con una configuración válida y explicas por qué el master no lo detecta (paso 1)
- [ ] Deshiciste el cambio desde una sesión abierta y desde la consola (pasos 2 y 4)
- [ ] El servidor deshizo solo un cambio que no confirmaste (paso 3)
- [ ] Explicas qué pasa al recargar sin `sshd -t` y cómo recuperaste `server` (paso 5)
- [ ] Explicas cada paso del procedimiento y qué evita (paso 6)

## Reto extra

La vuelta atrás del paso 3 se ejecuta siempre, también cuando el cambio era bueno. Escribe una versión del proceso en segundo plano que solo deshaga si **no** existe un archivo `/tmp/confirmado`, y confírmalo con `ssh -o ControlPath=none server touch /tmp/confirmado`. Compárala con `server/sshd-apply` del proyecto: ¿por qué el kit no usa un nombre fijo en `/tmp`?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Qué puede hacer una sesión abierta](../lab-06-sesion-y-reenvios/README.md) | [Proyecto — ssh-infra-kit: el servidor endurecido y cómo aplicarlo](../../3-proyecto/README.md) → |

[↑ Semana 07](../../README.md)
