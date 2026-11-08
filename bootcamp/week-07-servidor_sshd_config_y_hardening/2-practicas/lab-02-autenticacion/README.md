# Lab 02 — Solo llaves, sin root y con límites

⏱ Duración estimada: ~60 min

## Objetivo

Quitar las contraseñas después de comprobar que tu llave funciona, ver que el valor por defecto de `PermitRootLogin` deja entrar a root con llave, y limitar lo que puede hacer una conexión antes de autenticarse: `MaxAuthTries` y `LoginGraceTime`. Leer en los logs qué pasó en cada caso.

## Contexto

- Métodos, `PermitRootLogin` y límites: [teoría 02](../../1-teoria/02-autenticacion-y-acceso.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-sshd-config/README.md). Guarda la orden de recarga en una variable para no repetirla:
   ```bash
   R='sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ```
   Las comillas simples guardan el texto tal cual: `$(cat ...)` se ejecuta en `server` cuando lo pasas en `ssh server "...; $R"`. `sleep 1` da tiempo a `sshd` a volver a escuchar: sin él, la siguiente orden puede llegar antes y recibir `Connection refused`.

1. **Antes de quitar contraseñas, comprueba la llave.** `PreferredAuthentications=publickey` obliga al cliente a usar solo llaves:
   ```bash
   ssh -o PreferredAuthentications=publickey server echo llave OK
   ```
   ```
   llave OK
   ```
   Si esto falla, **no sigas**: con el paso siguiente te quedarías fuera.

2. **Sin contraseñas.** Un archivo `05-` gana a `10-bc-ssh.conf` (lab 01, paso 4):
   ```bash
   printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\n' | ssh server "sudo tee /etc/ssh/sshd_config.d/05-acceso.conf >/dev/null; sudo sshd -t && $R"
   sshpass -e ssh -o PubkeyAuthentication=no server true; echo "código: $?"
   ```
   ```
   alumno@server: Permission denied (publickey).
   código: 255
   ```
   - `printf 'A\nB\n'`: escribe dos líneas (`\n` es el salto de línea). `ssh server "sudo tee ..."` recibe ese texto por la entrada.
   - `sudo sshd -t && $R`: solo recarga si la configuración es válida. Úsalo siempre.
   - El cliente ya no recibe la oferta de contraseña: `(publickey)`.

3. **root, con el valor por defecto.** Borra `10-bc-ssh.conf` (dejaba `PermitRootLogin no`) para ver qué hace OpenSSH sin nada escrito:
   ```bash
   ssh server "sudo rm /etc/ssh/sshd_config.d/10-bc-ssh.conf; sudo sshd -t && $R; sudo sshd -T | grep ^permitroot"
   ssh server 'sudo mkdir -p -m 700 /root/.ssh; sudo cp .ssh/authorized_keys /root/.ssh/'
   ssh root@server id
   ```
   ```
   permitrootlogin without-password
   uid=0(root) gid=0(root) groups=0(root)
   ```
   - `without-password` es el nombre antiguo de `prohibit-password`: root no entra con contraseña, pero **sí con llave**. Acabas de entrar como root.
   - El paso 2 de la línea copia tu llave a root, como haría alguien que "solo quiere entrar rápido como root".

4. **root, nunca:**
   ```bash
   echo 'PermitRootLogin no' | ssh server "sudo tee -a /etc/ssh/sshd_config.d/05-acceso.conf >/dev/null; sudo sshd -t && $R"
   ssh root@server id; echo "código: $?"
   ```
   ```
   root@server: Permission denied (publickey).
   código: 255
   ```
   - `tee -a`: añade al final del archivo en lugar de sustituirlo.
   - La llave es válida y está en `/root/.ssh/authorized_keys`, pero `sshd` no la mira. En el log (`docker compose logs server | tail -2`, en tu equipo):
   ```
   server-1  | ROOT LOGIN REFUSED FROM 172.20.0.4 port 39344
   server-1  | ROOT LOGIN REFUSED FROM 172.20.0.4 port 39344 [preauth]
   ```
   Tu dirección será otra. Quita la llave de root, ya no la necesitas: `ssh server 'sudo rm -r /root/.ssh'`.

5. **`MaxAuthTries`.** Crea tres llaves que el servidor no conoce y ofrécelas antes de la buena:
   ```bash
   for i in 1 2 3; do ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/otra$i; done
   echo 'MaxAuthTries 3' | ssh server "sudo tee -a /etc/ssh/sshd_config.d/05-acceso.conf >/dev/null; sudo sshd -t && $R"
   ssh -o IdentitiesOnly=yes -i ~/.ssh/otra1 -i ~/.ssh/otra2 -i ~/.ssh/otra3 -i ~/.ssh/id_ed25519 server id; echo "código: $?"
   ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 -i ~/.ssh/otra1 server id -un
   ```
   ```
   Received disconnect from 172.20.0.2 port 22:2: Too many authentication failures
   Disconnected from 172.20.0.2 port 22
   código: 255
   alumno
   ```
   - Cada `-i` añade una llave; el cliente las ofrece en ese orden. Las tres primeras fallan y `sshd` corta antes de la cuarta, que era la buena.
   - Con la buena primero, entra al primer intento.
   - Lo mismo te pasa sin `-i`, con muchas llaves en el agente y sin `IdentitiesOnly yes`. Por eso tu kit lo usa desde la semana 03.

6. **`LoginGraceTime`.** Abre una conexión TCP y no hagas nada:
   ```bash
   echo 'LoginGraceTime 10' | ssh server "sudo tee -a /etc/ssh/sshd_config.d/05-acceso.conf >/dev/null; sudo sshd -t && $R"
   time nc -d server 22
   ```
   ```
   SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20

   real	0m10.015s
   ```
   - `nc -d`: conecta y no envía nada (`-d`: no lee del teclado).
   - `sshd` saluda con su versión y espera. A los 10 s cierra. Cada conexión así ocupa un hueco de `MaxStartups` mientras dura: con 120 s (el valor por defecto) hay que esperar 12 veces más.

7. **Lo que queda en los logs.** Intenta entrar con un usuario que no existe y mira los logs:
   ```bash
   ssh nadie@server true
   ```
   ```
   nadie@server: Permission denied (publickey).
   ```
   En tu equipo, `docker compose logs server | grep -E 'Invalid|maximum|REFUSED'`:
   ```
   server-1  | ROOT LOGIN REFUSED FROM 172.20.0.4 port 39344
   server-1  | maximum authentication attempts exceeded for alumno from 172.20.0.4 port 39356 ssh2 [preauth]
   server-1  | Invalid user nadie from 172.20.0.4 port 56584
   ```
   El cliente recibe siempre el mismo `Permission denied`, exista o no el usuario: quien prueba no sabe qué usuarios hay. El porqué solo lo ve quien administra.

## Criterios de éxito

- [ ] Comprobaste tu llave antes de quitar las contraseñas, y después la contraseña ya no entra (pasos 1 y 2)
- [ ] Explicas qué deja hacer a root el valor por defecto de `PermitRootLogin` y lo cambiaste a `no` (pasos 3 y 4)
- [ ] Explicas cómo `MaxAuthTries` y `IdentitiesOnly` se relacionan (paso 5)
- [ ] Explicas qué protege `LoginGraceTime` (paso 6)
- [ ] Encuentras en los logs el motivo de cada rechazo (pasos 4 y 7)

## Reto extra

Pon `LogLevel VERBOSE` en `05-acceso.conf`, recarga y repite la orden con `otra1` y `id_ed25519` del paso 5. ¿Qué líneas nuevas aparecen en el log? Compara la huella de `Failed publickey` con `ssh-keygen -lf ~/.ssh/otra1.pub`. ¿Para qué te sirve saber qué llaves rechaza el servidor?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — Dónde vive la configuración de `sshd`](../lab-01-sshd-config/README.md) | [Lab 03 — Quién puede entrar: usuarios, grupos y shells](../lab-03-quien-entra/README.md) → |

[↑ Semana 07](../../README.md)
