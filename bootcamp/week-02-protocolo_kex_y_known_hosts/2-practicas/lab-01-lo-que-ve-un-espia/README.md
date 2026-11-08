# Lab 01 — Lo que ve un espía

⏱ Duración estimada: ~60 min

## Objetivo

Capturar con `tcpdump` el tráfico de una conexión SSH y el de un protocolo en texto plano, y comprobar con tus ojos qué partes de SSH viajan en claro (banners, listas de algoritmos, host key pública) y cuáles no (usuario, contraseña, comandos, salida).

## Contexto

- La tabla "Lo que ve alguien que escucha la red" de la [teoría 01](../../1-teoria/01-capas-del-protocolo.md#lo-que-ve-alguien-que-escucha-la-red) es lo que vas a comprobar.
- **Qué:** `tcpdump` captura los paquetes que pasan por una interfaz de red. **Para qué:** ver la red como la vería un atacante en la misma Wi-Fi o en un router intermedio. **Impacto:** después de este lab, "SSH cifra" deja de ser una frase y pasa a ser algo que comprobaste.
- `tcpdump` necesita privilegios de root, así que corre **en el servidor** con `docker compose exec` (que entra como root). El servidor ve los mismos paquetes que vería alguien en medio.
- Como "protocolo en texto plano" usarás `nc` en el puerto 2300: es lo que hacía Telnet.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --build
   ```
   `--build` reconstruye la imagen si cambió; esta semana incluye `tcpdump`. En otra terminal, abre el cliente:
   ```bash
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   export SSHPASS=alumno
   ```

1. **En tu equipo**, deja un servidor de texto plano escuchando en el puerto 2300 de `server`:
   ```bash
   docker compose exec -d server nc -l 2300
   ```
   `-d` lo deja en segundo plano. `nc -l 2300` acepta una conexión y muestra lo que reciba.

2. **En tu equipo**, empieza a capturar:
   ```bash
   docker compose exec server tcpdump -i eth0 -nn -w /tmp/captura.pcap 'port 22 or port 2300'
   ```
   ```
   tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
   ```
   - `-i eth0`: la interfaz de red del contenedor.
   - `-nn`: muestra IPs y puertos como números, sin resolver nombres.
   - `-w`: guarda los paquetes en un archivo para leerlos después.
   - `'port 22 or port 2300'`: solo esos dos puertos.

   Se queda esperando. Déjalo así.

3. **En el cliente**, envía "credenciales" por el protocolo de texto plano:
   ```bash
   echo "usuario alumno clave alumno" | nc -N server 2300
   ```
   `-N` cierra la conexión al terminar de enviar.

4. **En el cliente**, haz lo mismo por SSH:
   ```bash
   sshpass -e ssh -o StrictHostKeyChecking=accept-new server 'echo secreto-remoto'
   ```
   ```
   Warning: Permanently added 'server' (ED25519) to the list of known hosts.
   secreto-remoto
   ```
   `accept-new` acepta la host key sin preguntar: aquí vale porque el lab trata de la red, no de la verificación. El lab-07 explica por qué **no** se usa fuera del laboratorio.

5. **En tu equipo**, detén la captura con **Ctrl+C**:
   ```
   48 packets captured
   48 packets received by filter
   0 packets dropped by kernel
   ```
   El número puede variar.

6. **El texto plano.** Lee lo que viajó por el puerto 2300:
   ```bash
   docker compose exec server tcpdump -nn -A -r /tmp/captura.pcap port 2300 | grep -a usuario
   ```
   ```
   o.l..?3.usuario alumno clave alumno
   ```
   `-r` lee el archivo y `-A` muestra el contenido de cada paquete como texto. `grep -a` busca aunque haya bytes binarios. Los caracteres raros del principio son las cabeceras TCP. **Cualquiera en el camino lee la contraseña.**

7. **SSH: lo que sí se ve.**
   ```bash
   docker compose exec server tcpdump -nn -A -r /tmp/captura.pcap port 22 \
     | grep -aoE 'SSH-2.0-[^ ]*|sntrup761x25519-sha512@openssh.com|chacha20-poly1305@openssh.com|ssh-ed25519' \
     | sort -u
   ```
   ```
   SSH-2.0-OpenSSH_9.6p1
   chacha20-poly1305@openssh.com
   ssh-ed25519
   sntrup761x25519-sha512@openssh.com
   ```
   `grep -o` imprime solo el texto que casa; `sort -u` quita repetidos. Se ven:
   - el **banner** de cada lado;
   - las **listas de algoritmos** de los dos `KEXINIT`;
   - `ssh-ed25519`, que sale en las listas y otra vez dentro del `KEX_ECDH_REPLY`, junto a la host key pública del servidor.

8. **SSH: lo que no se ve.**
   ```bash
   docker compose exec server tcpdump -nn -A -r /tmp/captura.pcap port 22 | grep -ac alumno
   docker compose exec server tcpdump -nn -A -r /tmp/captura.pcap port 22 | grep -ac secreto-remoto
   ```
   ```
   0
   0
   ```
   `grep -c` cuenta las líneas que casan. Ni el usuario, ni la contraseña (también `alumno`), ni el comando, ni su salida: todo eso viajó después de `NEWKEYS`.

9. **El tamaño sí se ve.** Mira los primeros paquetes con datos:
   ```bash
   docker compose exec server tcpdump -nn -r /tmp/captura.pcap 'port 22 and tcp[tcpflags] & tcp-push != 0' | head -6
   ```
   La expresión `tcp[tcpflags] & tcp-push != 0` deja solo los paquetes que llevan datos (bandera `PSH`). Fíjate en el campo `length` de cada línea:

   | Paquete | `length` aproximado | Mensaje |
   |---|---|---|
   | 1 y 2 | 43 | Los banners |
   | 3 y 4 | 1500 y 1100 | Los `KEXINIT` (listas largas) |
   | 5 | 1200 | `KEX_ECDH_INIT`: la parte pública de sntrup761 es grande |
   | 6 | 1500 | `KEX_ECDH_REPLY` con host key y firma |

   Después llegan paquetes cifrados de tamaños pequeños y variables. Un observador no lee el contenido, pero sí deduce "aquí se autenticó" o "aquí empezó una transferencia grande" por el tamaño y el momento.

## Criterios de éxito

- [ ] Viste la contraseña en claro en la captura del puerto 2300 (paso 6)
- [ ] Encontraste banners, algoritmos y `ssh-ed25519` en la captura del puerto 22 (paso 7)
- [ ] Explicas por qué `alumno` y `secreto-remoto` dan 0 en la captura SSH (paso 8)
- [ ] Explicas por qué no es un problema que la host key se vea en claro (paso 7 y teoría 01)

## Reto extra

Repite la captura abriendo una sesión **interactiva** (`ssh server`), escribe despacio `ls` y Enter, y sal. Cuenta los paquetes del cliente al servidor (`'src host client and dst port 22'` no sirve con IPs: usa la IP del cliente que viste en el paso 9). Repite con `ssh -o ObscureKeystrokeTiming=no server`. ¿Cuántos paquetes envía cada uno por tecla? Explica qué ocultan los paquetes de más (teoría 01).

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — Mensajes y capas en `ssh -vvv`](../lab-02-mensajes-y-capas/README.md) → |

[↑ Semana 02](../../README.md)
