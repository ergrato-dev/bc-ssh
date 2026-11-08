# Lab 01 — Dónde vive la configuración de `sshd`

⏱ Duración estimada: ~60 min

## Objetivo

Encontrar los archivos que lee `sshd`, ver qué valor gana para cada opción con `sshd -T`, reproducir el caso de un `.conf` que no tiene efecto, detectar errores con `sshd -t` y recargar sin cortar las sesiones abiertas.

## Contexto

- Archivos, primer valor, `sshd -t` / `sshd -T` y recarga: [teoría 01](../../1-teoria/01-sshd-config-por-dentro.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --build --force-recreate server
   docker compose run --rm client
   ```
   `--build` reconstruye la imagen: esta semana añade `sudo` sin contraseña para `alumno` (**solo en el laboratorio**: en un servidor real, `sudo` pide la contraseña y se usa `ssh -t server sudo ...`). `--force-recreate` deja `server` con la configuración original. **En el cliente**, prepara `known_hosts` y una llave instalada en `server`, como en la semana 03:
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id -f server 2>&1 | grep 'Number of'
   ```
   ```
   Number of key(s) added: 1
   ```
   - La llave no tiene frase (`-N ''`) para no escribirla en cada paso: **solo en el laboratorio**.
   - Deja abierta **otra terminal en tu equipo**, en la raíz del repositorio, para ver los logs de `server` con `docker compose logs server`.

1. **El archivo principal.** Sus líneas sin comentarios ni vacías:
   ```bash
   ssh server 'grep -n -v -E "^(#|$)" /etc/ssh/sshd_config'
   ```
   ```
   12:Include /etc/ssh/sshd_config.d/*.conf
   71:KbdInteractiveAuthentication no
   94:UsePAM yes
   99:X11Forwarding yes
   103:PrintMotd no
   121:AcceptEnv LANG LC_*
   124:Subsystem	sftp	/usr/lib/openssh/sftp-server
   ```
   - `grep -v -E "^(#|$)"`: quita (`-v`) las líneas que empiezan por `#` y las vacías; `-n` añade el número de línea.
   - Todo lo demás está comentado: los comentarios muestran el valor por defecto de OpenSSH. El `Include` va en la línea 12, antes que todo lo activo.

2. **La carpeta de los cambios:**
   ```bash
   ssh server 'ls -l /etc/ssh/sshd_config.d; cat /etc/ssh/sshd_config.d/10-bc-ssh.conf'
   ```
   ```
   total 4
   -rw-r--r-- 1 root root 218 Nov  8 04:14 10-bc-ssh.conf
   # Punto de partida deliberadamente permisivo (semana 01). El estudiante lo
   # endurece en la semana 07; nunca uses esto en un servidor real.
   PasswordAuthentication yes
   KbdInteractiveAuthentication no
   PermitRootLogin no
   ```
   Es lo que ha dejado entrar con contraseña desde la semana 01.

3. **La configuración efectiva.** `sshd -T` escribe cada opción con el valor que gana. Necesita root:
   ```bash
   ssh server 'sudo sshd -T | wc -l'
   ssh server 'sudo sshd -T | grep -E "^(passwordauthentication|permitrootlogin|x11forwarding|maxauthtries)"'
   ```
   ```
   95
   maxauthtries 6
   permitrootlogin no
   passwordauthentication yes
   x11forwarding yes
   ```
   - 95 opciones, aunque los archivos solo escriben 9: el resto es el valor por defecto.
   - `sshd -T` escribe los nombres en minúsculas. Busca siempre con minúsculas o con `grep -i`.

4. **El primer valor gana.** Reproduce lo que pasa en muchas máquinas de nube: un `50-cloud-init.conf` que activa las contraseñas y tu archivo que intenta quitarlas:
   ```bash
   ssh server 'echo "PasswordAuthentication yes" | sudo tee /etc/ssh/sshd_config.d/50-cloud-init.conf >/dev/null
   echo "PasswordAuthentication no" | sudo tee /etc/ssh/sshd_config.d/60-endurecido.conf >/dev/null
   sudo grep -H Password /etc/ssh/sshd_config.d/*; sudo sshd -T | grep ^passwordauth'
   ```
   ```
   /etc/ssh/sshd_config.d/10-bc-ssh.conf:PasswordAuthentication yes
   /etc/ssh/sshd_config.d/50-cloud-init.conf:PasswordAuthentication yes
   /etc/ssh/sshd_config.d/60-endurecido.conf:PasswordAuthentication no
   ```
   ```
   passwordauthentication yes
   ```
   - `sudo tee ARCHIVO`: escribe lo que recibe en un archivo de root (`sudo echo ... > archivo` no sirve: la redirección la hace tu shell, sin root). `>/dev/null` evita que `tee` lo repita en pantalla.
   - `grep -H`: añade el nombre del archivo a cada línea.
   - `60-endurecido.conf` no tiene ningún efecto, y nada te avisa. Solo `sshd -T` te lo dice. Bórralo junto con el de prueba:
   ```bash
   ssh server 'sudo rm /etc/ssh/sshd_config.d/50-cloud-init.conf /etc/ssh/sshd_config.d/60-endurecido.conf'
   ```

5. **Un error de escritura.** Falta una `i` en el nombre de la opción:
   ```bash
   ssh server 'echo "PasswordAuthenticaton no" | sudo tee /etc/ssh/sshd_config.d/05-error.conf >/dev/null
   sudo sshd -t; echo "código: $?"
   sudo rm /etc/ssh/sshd_config.d/05-error.conf'
   ```
   ```
   /etc/ssh/sshd_config.d/05-error.conf: line 1: Bad configuration option: PasswordAuthenticaton
   /etc/ssh/sshd_config.d/05-error.conf: terminating, 1 bad configuration options
   código: 255
   ```
   `sshd -t` dice archivo, línea y opción. Sin errores no escribe nada y sale con 0. El lab 07 enseña lo que pasa si recargas sin pasar por aquí.

6. **`sshd -T` lee archivos, no lo que está en marcha.** Quita la contraseña en un archivo que gane (`05-` va antes que `10-`) y prueba **sin recargar**:
   ```bash
   ssh server 'echo "PasswordAuthentication no" | sudo tee /etc/ssh/sshd_config.d/05-sin-password.conf >/dev/null; sudo sshd -T | grep ^passwordauth'
   sshpass -e ssh -o PubkeyAuthentication=no server echo entré con contraseña
   ```
   ```
   passwordauthentication no
   entré con contraseña
   ```
   - `-o PubkeyAuthentication=no`: el cliente no prueba la llave, así que solo le queda la contraseña.
   - `sshd -T` dice `no`, pero el `sshd` en marcha leyó su configuración al arrancar y sigue aceptando contraseñas.

7. **Recargar.** La señal `HUP` hace que `sshd` vuelva a leer la configuración:
   ```bash
   ssh server 'sudo kill -HUP $(cat /run/sshd.pid)'
   sshpass -e ssh -o PubkeyAuthentication=no server echo entré con contraseña; echo "código: $?"
   ```
   ```
   alumno@server: Permission denied (publickey).
   código: 255
   ```
   - `$(cat /run/sshd.pid)`: el PID del `sshd` principal, que lo guarda ahí al arrancar. En un servidor con systemd: `sudo systemctl reload ssh`.
   - `Permission denied (publickey)`: entre paréntesis, los métodos que el servidor ofrece. Solo queda la llave.
   - En la terminal de tu equipo, `docker compose logs server | tail -3`:
   ```
   server-1  | Received SIGHUP; restarting.
   server-1  | Server listening on 0.0.0.0 port 22.
   server-1  | Server listening on :: port 22.
   ```

8. **Los procesos de `sshd`.** Con una sesión abierta:
   ```bash
   ssh server 'ps -o pid,ppid,user,args -C sshd'
   ```
   ```
       PID    PPID USER     COMMAND
         1       0 root     sshd: /usr/sbin/sshd -D -e [listener] 0 of 10-100 startups
        29       1 root     sshd: alumno [priv]
        40      29 alumno   sshd: alumno@notty
   ```
   - `-C sshd`: solo los procesos que se llaman `sshd`; `-o`: las columnas.
   - El `listener` (PID 1 en el contenedor) es el único que recarga. Tu conexión (`[priv]` y `alumno@notty`) es una copia que nació con la configuración de ese momento y la mantiene hasta cerrarse: [teoría 01](../../1-teoria/01-sshd-config-por-dentro.md#procesos-por-qué-recargar-no-corta-a-nadie).

## Criterios de éxito

- [ ] Sabes qué archivos lee `sshd`, en qué orden, y dónde va cada cambio tuyo (pasos 1, 2 y 4)
- [ ] Usas `sshd -T` para saber qué valor gana y explicas por qué `60-endurecido.conf` no tenía efecto (pasos 3 y 4)
- [ ] Encontraste un error con `sshd -t` antes de recargar (paso 5)
- [ ] Explicas la diferencia entre lo que dice `sshd -T` y lo que usa el `sshd` en marcha (pasos 6 y 7)
- [ ] Explicas por qué recargar no corta las sesiones abiertas (paso 8)

## Reto extra

Deja una sesión larga en segundo plano: `ssh server 'sleep 300' &`. Borra `05-sin-password.conf` y recarga. ¿Qué PID tiene ahora el `listener`? ¿Sigue viva la sesión (`jobs`)? ¿Y si en vez de recargar haces `docker compose restart server` en tu equipo?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — Solo llaves, sin root y con límites](../lab-02-autenticacion/README.md) → |

[↑ Semana 07](../../README.md)
