# Lab 05 — Un usuario que solo sube archivos

⏱ Duración estimada: ~60 min

## Objetivo

Crear una cuenta `proveedor` que solo pueda usar `sftp`, encerrada en su carpeta, añadiendo las protecciones de una en una: shell `nologin`, `ForceCommand internal-sftp`, `ChrootDirectory` y `DisableForwarding`. Probar después de cada una qué deja pasar todavía.

## Contexto

- Las cuatro capas y las reglas del chroot: [teoría 03](../../1-teoria/03-sftp-chroot-y-cambios-seguros.md).
- `sftp` en lotes: [semana 06, lab 02](../../../week-06-transferencia_archivos_scp_sftp_rsync/2-practicas/lab-02-sftp/README.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-sshd-config/README.md) y la variable `R` del [lab 02](../lab-02-autenticacion/README.md), que recarga `sshd`. Después, una carpeta de trabajo con un archivo, y la cuenta `proveedor` con tu llave:
   ```bash
   R='sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   B='-o BatchMode=yes'
   mkdir -p ~/w && cd ~/w; echo informe > informe.txt
   ssh server 'sudo groupadd sftp-only
   sudo useradd -m -s /usr/sbin/nologin -G sftp-only proveedor
   sudo mkdir -m 700 /home/proveedor/.ssh
   sudo cp .ssh/authorized_keys /home/proveedor/.ssh/
   sudo chown -R proveedor: /home/proveedor/.ssh; id proveedor'
   ```
   ```
   uid=1001(proveedor) gid=1002(proveedor) groups=1002(proveedor),1001(sftp-only)
   ```
   En la vida real, la llave sería la del proveedor (te envía su `.pub`). Aquí usas la tuya para no gestionar dos.

1. **Solo `nologin`.** La shell no deja entrar, y `sftp` tampoco funciona:
   ```bash
   ssh $B proveedor@server id
   sftp $B proveedor@server <<<'pwd' 2>&1 | tail -3
   ```
   ```
   This account is currently not available.
   Received message too long 1416128883
   Ensure the remote shell produces no output for non-interactive sessions.
   ```
   - `<<<'pwd'`: pasa `pwd` como entrada de `sftp`, como un lote de una línea.
   - `sshd` arranca `sftp-server` **a través de la shell del usuario**. `nologin` escribe su mensaje en lugar de arrancarlo, y `sftp` lee ese texto como si fuera el protocolo: `1416128883` son los bytes de `This` leídos como un número.

2. **`ForceCommand internal-sftp`.** Para el grupo `sftp-only`, `sshd` ignora lo que pida el cliente y usa el servidor SFTP que lleva dentro, sin pasar por la shell:
   ```bash
   printf 'Match Group sftp-only\n    ForceCommand internal-sftp\n' | ssh server "sudo tee /etc/ssh/sshd_config.d/30-sftp.conf >/dev/null; sudo sshd -t && $R"
   ssh $B proveedor@server id; echo "código: $?"
   sftp $B proveedor@server <<<'pwd
   ls /etc/ssh/sshd_config.d
   get /etc/passwd' 2>&1 | tail -5
   ```
   ```
   This service allows sftp connections only.
   código: 1
   Remote working directory: /home/proveedor
   sftp> ls /etc/ssh/sshd_config.d
   /etc/ssh/sshd_config.d/10-bc-ssh.conf   /etc/ssh/sshd_config.d/30-sftp.conf
   sftp> get /etc/passwd
   Fetching /etc/passwd to passwd
   ```
   `sftp` funciona y las órdenes no. Pero `proveedor` puede leer todo el disco que sus permisos le dejan: acaba de descargar la lista de usuarios del servidor.

3. **`ChrootDirectory`, mal hecho.** La carpeta del chroot es del usuario:
   ```bash
   ssh server "sudo mkdir -p /srv/sftp/proveedor; sudo chown proveedor: /srv/sftp/proveedor
   printf 'Match Group sftp-only\n    ChrootDirectory /srv/sftp/%%u\n    ForceCommand internal-sftp\n' | sudo tee /etc/ssh/sshd_config.d/30-sftp.conf >/dev/null; sudo sshd -t && $R"
   sftp $B proveedor@server <<<'pwd' 2>&1 | tail -1
   ```
   ```
   Connection closed
   ```
   - `%%u`: `printf` convierte `%%` en `%`. En el archivo queda `%u`, que `sshd` sustituye por el nombre del usuario.
   - `sshd -t` no protesta: la configuración es válida. El fallo es de permisos y llega al conectar. En el log (`docker compose logs server | grep chroot`, en tu equipo):
   ```
   server-1  | bad ownership or modes for chroot directory "/srv/sftp/proveedor"
   ```

4. **`ChrootDirectory`, bien hecho.** La carpeta, de root y sin escritura para nadie más:
   ```bash
   ssh server 'sudo chown root:root /srv/sftp/proveedor; sudo chmod 755 /srv/sftp/proveedor; ls -ld /srv/sftp/proveedor'
   sftp $B proveedor@server <<<'pwd
   put informe.txt' 2>&1 | tail -4
   ```
   ```
   drwxr-xr-x 2 root root 4096 Nov  8 07:20 /srv/sftp/proveedor
   Remote working directory: /
   sftp> put informe.txt
   Uploading informe.txt to /informe.txt
   dest open "/informe.txt": Permission denied
   ```
   Entra, y `/` es `/srv/sftp/proveedor`. Pero no puede escribir: esa carpeta tiene que ser de root.

5. **Una carpeta suya dentro.** `subidas`, de `proveedor`, y `-d /subidas` para empezar ahí:
   ```bash
   ssh server "sudo mkdir /srv/sftp/proveedor/subidas; sudo chown proveedor: /srv/sftp/proveedor/subidas
   sudo sed -i 's|internal-sftp\$|internal-sftp -d /subidas|' /etc/ssh/sshd_config.d/30-sftp.conf; sudo sshd -t && $R"
   sftp $B proveedor@server <<<'put informe.txt
   cd /etc
   cd ..
   ls -l' 2>&1
   ssh server 'ls -l /srv/sftp/proveedor/subidas'
   ```
   ```
   Connected to server.
   sftp> put informe.txt
   Uploading informe.txt to /subidas/informe.txt
   sftp> cd /etc
   stat remote: No such file or directory
   sftp> cd ..
   sftp> ls -l
   drwxr-xr-x    ? 1001     1002         4096 Nov  8 07:20 subidas
   total 4
   -rw-r--r-- 1 proveedor proveedor 8 Nov  8 07:20 informe.txt
   ```
   - `sed -i 's|A$|B|'`: cambia `A` por `B` en el archivo; `\$` es el final de la línea (escapado porque va entre comillas dobles).
   - Para `proveedor`, `/etc` no existe. `ls -l` muestra números en lugar de nombres: dentro del chroot no hay `/etc/passwd` para traducirlos.
   - Desde fuera, el archivo está en `/srv/sftp/proveedor/subidas`, a nombre de `proveedor`.

6. **El chroot no encierra la red.** Abre un túnel con `proveedor` hacia el puerto 22 del propio `server` y pide el banner a través de él:
   ```bash
   ssh $B -f -N -L 2224:127.0.0.1:22 proveedor@server
   nc -w 2 localhost 2224 </dev/null | head -1
   ```
   ```
   SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   ```
   - `-L 2224:127.0.0.1:22`: lo que llegue a tu puerto 2224 sale desde `server` hacia `127.0.0.1:22` (semana 08). `-f -N`: en segundo plano, sin ejecutar nada.
   - Una cuenta que "solo sube archivos" te acaba de servir de pasarela hacia la red del servidor. Con `localhost` en lugar de `127.0.0.1` fallaría (`unknown host`: en el chroot no hay `/etc/hosts`), pero eso no es una protección.

7. **Sin reenvíos ni terminal:**
   ```bash
   pkill -f 'ssh -o BatchMode=yes -f -N'
   printf '    DisableForwarding yes\n    PermitTTY no\n' | ssh server "sudo tee -a /etc/ssh/sshd_config.d/30-sftp.conf >/dev/null; sudo sshd -t && $R; cat /etc/ssh/sshd_config.d/30-sftp.conf"
   ssh $B -f -N -L 2225:127.0.0.1:22 proveedor@server
   nc -w 2 localhost 2225 </dev/null | head -1; echo "nc: $?"
   ```
   ```
   Match Group sftp-only
       ChrootDirectory /srv/sftp/%u
       ForceCommand internal-sftp -d /subidas
       DisableForwarding yes
       PermitTTY no
   nc: 0
   ```
   - `pkill -f PATRÓN`: termina el túnel del paso 6, buscando su línea de órdenes.
   - El túnel se abre en tu lado, pero `server` rechaza cada conexión por él y `nc` no recibe nada. En el log: `refused local port forward: originator ::1 port 54014, target 127.0.0.1 port 22`.
   - Es el `30-sftp.conf` del proyecto.

## Criterios de éxito

- [ ] Explicas por qué `nologin` solo no sirve para una cuenta SFTP (paso 1)
- [ ] Explicas qué cierra `ForceCommand internal-sftp` y qué deja abierto (paso 2)
- [ ] Encontraste en el log el error de permisos del chroot y lo corregiste (pasos 3 y 4)
- [ ] `proveedor` sube archivos a `/subidas` y no ve nada fuera de su carpeta (paso 5)
- [ ] Explicas por qué hace falta `DisableForwarding` aunque haya chroot, y lo comprobaste (pasos 6 y 7)

## Reto extra

Añade `-l INFO` a `ForceCommand internal-sftp` y repite el `put` del paso 5. ¿Qué escribe ahora el log de `server` para cada operación? ¿Para qué te serviría si un proveedor dice que "subió el archivo y ha desaparecido"?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — `Match`: reglas para unos pocos](../lab-04-match/README.md) | [Lab 06 — Qué puede hacer una sesión abierta](../lab-06-sesion-y-reenvios/README.md) → |

[↑ Semana 07](../../README.md)
