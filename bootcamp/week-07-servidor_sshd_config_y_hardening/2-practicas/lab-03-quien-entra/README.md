# Lab 03 — Quién puede entrar: usuarios, grupos y shells

⏱ Duración estimada: ~60 min

## Objetivo

Decidir qué cuentas pueden abrir sesión SSH con `AllowUsers`, `AllowGroups` y `DenyUsers`, ver en qué orden se aplican, limitar un usuario a una red, quedarte fuera a propósito con `AllowGroups` y volver a entrar por la consola.

## Contexto

- `Allow*` / `Deny*` y su orden: [teoría 02](../../1-teoria/02-autenticacion-y-acceso.md#quién-puede-intentarlo-allowusers-allowgroups-denyusers-denygroups).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-sshd-config/README.md) y la variable `R` del [lab 02](../lab-02-autenticacion/README.md). Además, dos usuarios más en `server` con tu llave, y un grupo `ssh-users` con `ana` dentro:
   ```bash
   R='sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   B='-o BatchMode=yes -o ControlPath=none'
   ssh server 'for u in ana bot; do
     sudo useradd -m -s /bin/bash $u
     sudo mkdir -m 700 /home/$u/.ssh
     sudo cp .ssh/authorized_keys /home/$u/.ssh/
     sudo chown -R $u: /home/$u/.ssh
   done
   sudo groupadd ssh-users; sudo usermod -aG ssh-users ana; id ana; id bot'
   ```
   ```
   uid=1001(ana) gid=1001(ana) groups=1001(ana),1003(ssh-users)
   uid=1002(bot) gid=1002(bot) groups=1002(bot)
   ```
   - `useradd -m -s /bin/bash`: crea el usuario con su home (`-m`) y bash como shell. `chown -R ana:` (con `:` y sin grupo) usa el grupo principal del usuario.
   - `usermod -aG GRUPO USUARIO`: añade (`-a`) un grupo secundario (`-G`). Sin `-a`, **quita** al usuario de todos los demás.
   - `B`: `BatchMode=yes` hace que `ssh` falle en vez de pedir contraseña; `ControlPath=none`, que cada prueba sea una conexión nueva.

1. **Sin restricciones, entran todos:**
   ```bash
   for u in alumno ana bot; do echo "$u: $(ssh $B $u@server id -un 2>&1)"; done
   ```
   ```
   alumno: alumno
   ana: ana
   bot: bot
   ```
   `bot` podría ser la cuenta de una aplicación: que tenga una llave en su `authorized_keys` basta para abrir una shell.

2. **`AllowUsers`: una lista de nombres.**
   ```bash
   echo 'AllowUsers alumno ana' | ssh server "sudo tee /etc/ssh/sshd_config.d/05-quien.conf >/dev/null; sudo sshd -t && $R"
   for u in alumno ana bot; do echo "$u: $(ssh $B $u@server id -un 2>&1)"; done
   ```
   ```
   alumno: alumno
   ana: ana
   bot: bot@server: Permission denied (publickey,password).
   ```
   En el log (`docker compose logs server | grep 'not allowed'`, en tu equipo):
   ```
   server-1  | User bot from 172.20.0.4 not allowed because not listed in AllowUsers
   ```
   Funciona, pero cada persona nueva obliga a tocar `sshd_config` y recargar.

3. **`AllowGroups`, sin estar en el grupo.** Cambia a grupos. Antes de recargar, abre un master que quede vivo 10 minutos:
   ```bash
   M='-o ControlMaster=auto -o ControlPath=~/.ssh/cm-%C -o ControlPersist=10m'
   ssh $M server true
   echo 'AllowGroups ssh-users' | ssh server "sudo tee /etc/ssh/sshd_config.d/05-quien.conf >/dev/null; sudo sshd -t && $R"
   for u in alumno ana bot; do echo "$u: $(ssh $B $u@server id -un 2>&1)"; done
   ```
   ```
   alumno: alumno@server: Permission denied (publickey,password).
   ana: ana
   bot: bot@server: Permission denied (publickey,password).
   ```
   **Te has quedado fuera**: `alumno` no está en `ssh-users`. El log lo dice:
   ```
   server-1  | User alumno from 172.20.0.4 not allowed because none of user's groups are listed in AllowGroups
   ```

4. **Volver a entrar.** Tienes dos formas, y conviene que conozcas las dos.
   - **Una sesión que ya estaba abierta.** El master del paso 3 se autenticó antes del cambio y sigue vivo:
   ```bash
   ssh $M server 'sudo usermod -aG ssh-users alumno; id -nG alumno'
   ```
   ```
   alumno adm dialout cdrom floppy sudo audio dip video plugdev ssh-users
   ```
   - **La consola.** Si no tuvieras sesión abierta, en un servidor real usarías la consola del proveedor (serie, VNC o KVM), que no pasa por SSH. En el laboratorio, **en tu equipo**:
   ```bash
   docker compose exec server usermod -aG ssh-users alumno
   ```
   Ahora prueba con una conexión nueva:
   ```bash
   ssh $B server id -un; ssh $M -O exit server
   ```
   ```
   alumno
   Exit request sent.
   ```
   - El master te dejaba "entrar" aunque las conexiones nuevas fallaran: una prueba por el master no demuestra nada. Por eso `B` lleva `ControlPath=none`.
   - `-O exit`: cierra el master.

5. **`DenyUsers` gana siempre.** `ana` está en `ssh-users`, pero también en `DenyUsers`:
   ```bash
   printf 'AllowGroups ssh-users\nDenyUsers ana\n' | ssh server "sudo tee /etc/ssh/sshd_config.d/05-quien.conf >/dev/null; sudo sshd -t && $R"
   for u in alumno ana; do echo "$u: $(ssh $B $u@server id -un 2>&1)"; done
   ```
   ```
   alumno: alumno
   ana: ana@server: Permission denied (publickey,password).
   ```
   El orden es `DenyUsers`, `AllowUsers`, `DenyGroups`, `AllowGroups`, y hay que pasarlas todas. `DenyUsers` sirve para cortar a una persona concreta enseguida, sin sacarla de sus grupos.

6. **Un usuario, solo desde una red.** Mira desde qué dirección llegas:
   ```bash
   ssh server 'echo $SSH_CONNECTION'
   ```
   ```
   172.20.0.4 53416 172.20.0.2 22
   ```
   `SSH_CONNECTION`: tu IP y puerto, y los del servidor. Las tuyas serán otras. Permite a `ana` solo desde una red que no es la tuya:
   ```bash
   echo 'AllowUsers alumno ana@10.99.0.0/16' | ssh server "sudo tee /etc/ssh/sshd_config.d/05-quien.conf >/dev/null; sudo sshd -t && $R"
   for u in alumno ana; do echo "$u: $(ssh $B $u@server id -un 2>&1)"; done
   ```
   ```
   alumno: alumno
   ana: ana@server: Permission denied (publickey,password).
   ```
   `USUARIO@RED` sirve para una cuenta de copias o de despliegue que solo debe llegar desde un equipo concreto. Lo mismo, en la llave, es `from=` de `authorized_keys` (semana 03).

7. **La shell.** Quita las restricciones y cambia la shell de `bot` por `nologin`:
   ```bash
   ssh server "sudo rm /etc/ssh/sshd_config.d/05-quien.conf; sudo sshd -t && $R; sudo usermod -s /usr/sbin/nologin bot"
   ssh $B bot@server id; echo "código: $?"
   ```
   ```
   This account is currently not available.
   código: 1
   ```
   `bot` se autentica (la llave es válida), pero `sshd` ejecuta todo a través de su shell, y `nologin` solo escribe ese mensaje y sale. Es lo que tienen las cuentas de servicio de Ubuntu. No sustituye a `AllowGroups`: con `nologin`, `bot` todavía puede abrir túneles (`ssh -N -L`), porque un túnel no ejecuta ninguna shell.

## Criterios de éxito

- [ ] Limitaste quién entra con `AllowUsers` y con `AllowGroups`, y lees en el log por qué se rechaza a cada usuario (pasos 2 y 3)
- [ ] Te quedaste fuera con `AllowGroups` y volviste a entrar, y explicas por qué la prueba no puede ir por el master (pasos 3 y 4)
- [ ] Explicas el orden de `DenyUsers` / `AllowUsers` / `DenyGroups` / `AllowGroups` (paso 5)
- [ ] Limitaste un usuario a una red (paso 6)
- [ ] Explicas qué cierra `nologin` y qué no (paso 7)

## Reto extra

Con `bot` en `nologin`, abre un túnel hacia el puerto 22 del propio `server` y pide el banner a través de él: `ssh $B -f -N -L 2223:127.0.0.1:22 bot@server; nc -w 2 localhost 2223 </dev/null | head -1`. ¿Qué responde? ¿Qué opción del servidor lo impediría sin cambiar la shell?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — Solo llaves, sin root y con límites](../lab-02-autenticacion/README.md) | [Lab 04 — `Match`: reglas para unos pocos](../lab-04-match/README.md) → |

[↑ Semana 07](../../README.md)
