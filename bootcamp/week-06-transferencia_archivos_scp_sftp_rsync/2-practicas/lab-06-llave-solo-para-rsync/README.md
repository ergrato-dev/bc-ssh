# Lab 06 — Una llave que solo sirve para copiar

⏱ Duración estimada: ~60 min

## Objetivo

Crear una llave para copias de seguridad que, en `server`, solo pueda **leer** con `rsync` una carpeta concreta: sin shell, sin escribir, sin salir de esa carpeta y sin túneles. Comparar con `sftp-server -R`, que da solo lectura pero no encierra.

## Contexto

- `command=` y `restrict` en `authorized_keys`: [semana 03](../../../week-03-autenticacion_con_llaves_ssh/README.md).
- `rrsync` y por qué una copia desatendida necesita una llave propia: [teoría 03](../../1-teoria/03-copias-de-seguridad-y-llaves-restringidas.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-scp/README.md). Después, unos datos en `server`, un archivo fuera de ellos y la llave de copias:
   ```bash
   ssh server 'mkdir -p datos/sub; echo uno > datos/a.txt; echo dos > datos/sub/b.txt; echo secreto > privado.txt'
   ssh-keygen -q -t ed25519 -N '' -C backup@client -f ~/.ssh/backup
   ```
   Una llave de copias para `cron` suele ir sin frase, porque nadie está delante para escribirla. Por eso importa tanto lo que hace este lab: lo que la llave **no** puede hacer es lo que pierdes si te la roban.

1. **La línea de `authorized_keys`.** `command=` fuerza a ejecutar `rrsync` en lugar de lo que pida el cliente; `restrict` quita terminal, túneles y reenvío de agente:
   ```bash
   linea="command=\"rrsync -ro /home/alumno/datos\",restrict $(cat ~/.ssh/backup.pub)"
   echo "$linea" | ssh server 'cat >> .ssh/authorized_keys'
   ssh server tail -1 .ssh/authorized_keys | cut -c1-60
   ```
   ```
   command="rrsync -ro /home/alumno/datos",restrict ssh-ed25519
   ```
   - `rrsync` (*restricted rsync*) viene con `rsync`: lee la orden que pidió el cliente (variable `SSH_ORIGINAL_COMMAND`), comprueba que es un `rsync --server` y la ejecuta dentro de `/home/alumno/datos`. `-ro`: solo lectura.
   - Usas tu llave normal (`ssh server`) para añadir la línea: la de copias ya no podrá.
   - Con el kit: `bin/ak-line -c 'rrsync -ro /home/alumno/datos' ~/.ssh/backup.pub` escribe la misma línea.

2. **Sin shell.** Para no repetir opciones, guarda la orden de conexión en una variable:
   ```bash
   B='ssh -i ~/.ssh/backup -o IdentitiesOnly=yes'
   $B server ls; echo "código: $?"
   $B server; echo "código: $?"
   ```
   ```
   /usr/bin/rrsync error: SSH_ORIGINAL_COMMAND does not run rsync
   código: 1
   PTY allocation request failed on channel 0
   código: 255
   ```
   - `IdentitiesOnly=yes`: ofrece solo `~/.ssh/backup`, no también `id_ed25519` (que sí tiene shell).
   - Con `ls`, `rrsync` ve que la orden pedida no es `rsync` y la rechaza. Sin orden (una sesión interactiva), `restrict` niega la terminal y la conexión se cierra.

3. **Copiar sí.** La ruta remota es relativa a la carpeta permitida; `server:` es la carpeta entera:
   ```bash
   rsync -a -i -e "$B" server: ~/copia/
   find ~/copia | sort
   ```
   ```
   created directory /home/alumno/copia
   cd+++++++++ ./
   >f+++++++++ a.txt
   cd+++++++++ sub/
   >f+++++++++ sub/b.txt
   /home/alumno/copia
   /home/alumno/copia/a.txt
   /home/alumno/copia/sub
   /home/alumno/copia/sub/b.txt
   ```
   `bin/backup ALIAS: DESTINO` del proyecto funciona igual con un alias que use esta llave.

4. **Una subcarpeta:**
   ```bash
   rsync -a -i -e "$B" server:sub/ ~/solo-sub/
   ls ~/solo-sub
   ```
   ```
   created directory /home/alumno/solo-sub
   cd+++++++++ ./
   >f+++++++++ b.txt
   b.txt
   ```

5. **Salir de la carpeta, no.** Intenta leer `privado.txt`, que está en el home, fuera de `datos`:
   ```bash
   rsync -a -e "$B" server:../privado.txt ~/; echo "código: $?"
   rsync -a -e "$B" server:/home/alumno/privado.txt ~/; echo "código: $?"
   ls ~/privado.txt
   ```
   ```
   /usr/bin/rrsync error: do not use .. in arg (anchor the path at the root of your restricted dir)
   rsync: connection unexpectedly closed (0 bytes received so far) [Receiver]
   rsync error: error in rsync protocol data stream (code 12) at io.c(232) [Receiver=3.2.7]
   código: 12
   rsync: [sender] change_dir "/home/alumno/datos/home/alumno" failed: No such file or directory (2)
   rsync error: some files/attrs were not transferred (see previous errors) (code 23) at main.c(1887) [Receiver=3.2.7]
   rsync: [Receiver] write error: Broken pipe (32)
   código: 23
   ls: cannot access '/home/alumno/privado.txt': No such file or directory
   ```
   - `..` se rechaza directamente.
   - Una ruta absoluta se interpreta **dentro** de la carpeta: `/home/alumno/privado.txt` pasa a ser `/home/alumno/datos/home/alumno/privado.txt`, que no existe.

6. **Escribir, no.** Una llave de copias robada no debe servir para cambiar los datos:
   ```bash
   echo malo > malo.txt
   rsync -a -e "$B" malo.txt server:; echo "código: $?"
   ```
   ```
   /usr/bin/rrsync error: sending to read-only server is not allowed
   rsync: connection unexpectedly closed (0 bytes received so far) [sender]
   rsync error: error in rsync protocol data stream (code 12) at io.c(232) [sender=3.2.7]
   código: 12
   ```

7. **Ni `scp` ni `sftp`.** Piden el subsistema `sftp`, y `command=` lo sustituye por `rrsync`:
   ```bash
   scp -i ~/.ssh/backup -o IdentitiesOnly=yes server:a.txt .; echo "código: $?"
   ```
   ```
   scp: Connection closed
   código: 255
   ```

8. **Ni túneles.** Abre un túnel local (semana 08) con tu llave normal y con la de copias, y pide el banner SSH a través de él:
   ```bash
   ssh -f -N -L 2223:localhost:22 server
   nc -w 2 localhost 2223 </dev/null | head -1
   $B -f -N -L 2222:localhost:22 server
   nc -w 2 localhost 2222 </dev/null; echo "nc: $?"
   ```
   ```
   SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   nc: 0
   ```
   - `-L 2223:localhost:22`: lo que llegue a tu puerto 2223 sale desde `server` hacia su puerto 22. `-f -N`: en segundo plano y sin ejecutar nada.
   - Por el túnel de la llave normal responde `sshd`. Por el de la llave de copias no llega nada: `restrict` incluye `no-port-forwarding`. Sin `restrict`, la llave de copias valdría como pasarela hacia la red de `server`, aunque no tenga shell.

9. **Solo lectura no es lo mismo que encerrado.** Cambia `rrsync` por `sftp-server -R -d` (solo lectura, empezando en `datos`):
   ```bash
   ssh server "sed -i 's|^command=\"rrsync[^,]*|command=\"/usr/lib/openssh/sftp-server -R -d /home/alumno/datos\"|' .ssh/authorized_keys"
   sftp -i ~/.ssh/backup -o IdentitiesOnly=yes -b - server <<'EOF'
   pwd
   -put malo.txt
   get ../privado.txt
   EOF
   cat privado.txt
   ```
   ```
   sftp> pwd
   Remote working directory: /home/alumno/datos
   sftp> -put malo.txt
   dest open "/home/alumno/datos/malo.txt": Permission denied
   sftp> get ../privado.txt
   secreto
   ```
   - `sed -i 's|A|B|'` cambia `A` por `B` en el archivo; `[^,]*` es "todo hasta la siguiente coma".
   - `-R` impide escribir, pero `-d` solo elige la carpeta de inicio: `../privado.txt` se lee igual. Para encerrar `sftp` en una carpeta hace falta `ChrootDirectory` en `sshd_config` (semana 07). `rrsync` sí encierra, porque reescribe cada ruta.

## Criterios de éxito

- [ ] La llave de copias copia `datos` y sus subcarpetas con `rsync` (pasos 3 y 4)
- [ ] La misma llave no da shell, no escribe, no sale de `datos`, no abre `scp` y no abre túneles (pasos 2, 5 a 8)
- [ ] Explicas qué hace cada parte de la línea de `authorized_keys` (paso 1)
- [ ] Explicas por qué `sftp-server -R -d` no basta para encerrar (paso 9)

## Reto extra

Añade `from="172.16.0.0/12"` a la línea del paso 1 (las redes de Docker suelen estar ahí; mira la tuya con `ip -4 addr show eth0`). Compruébalo con una red que no es la tuya (`from="10.99.0.0/16"`): ¿qué ve el cliente y qué escribe `sshd` en `docker compose logs server`?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Copias completas que ocupan poco: `--link-dest`](../lab-05-snapshots-con-link-dest/README.md) | [Lab 07 — Transferencias grandes y muchas pequeñas](../lab-07-transferencias-grandes/README.md) → |

[↑ Semana 06](../../README.md)
