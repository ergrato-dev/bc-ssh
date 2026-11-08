# Lab 05 — Host keys y huellas

⏱ Duración estimada: ~60 min

## Objetivo

Ver las tres host keys de un servidor y sus huellas en varios formatos, leerlas desde el cliente con `ssh-keyscan` y comprobar que, para un host conocido, un tipo de llave que no tenías guardado se trata como una llave cambiada.

## Contexto

- Todo lo que necesitas está en la [teoría 03](../../1-teoria/03-host-keys-y-known_hosts.md#las-host-keys-del-servidor), apartados "Las host keys del servidor", "Huellas" y "`ssh-keyscan`".
- Necesitas dos terminales: **En tu equipo** (para mirar dentro de `server` como root) y **En el cliente**.
- **La contraseña `alumno` es solo del laboratorio.**
- Las huellas de los ejemplos son las de un laboratorio concreto: las tuyas serán otras. Lo que debe coincidir es tu huella del servidor con tu huella del cliente.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   ```
   En otra terminal:
   ```bash
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   export SSHPASS=alumno
   ```

1. **Las llaves del servidor.** **En tu equipo**:
   ```bash
   docker compose exec server ls -l /etc/ssh/ | grep host_
   ```
   ```
   -rw------- 1 root root    505 Nov  8 04:47 ssh_host_ecdsa_key
   -rw-r--r-- 1 root root    173 Nov  8 04:47 ssh_host_ecdsa_key.pub
   -rw------- 1 root root    399 Nov  8 04:47 ssh_host_ed25519_key
   -rw-r--r-- 1 root root     93 Nov  8 04:47 ssh_host_ed25519_key.pub
   -rw------- 1 root root   2602 Nov  8 04:47 ssh_host_rsa_key
   -rw-r--r-- 1 root root    565 Nov  8 04:47 ssh_host_rsa_key.pub
   ```
   Tres pares. Las privadas (`-rw-------`) solo las lee root; las públicas (`.pub`) cualquiera. La fecha es la de arranque del contenedor: `start-sshd` las generó con `ssh-keygen -A`. La RSA es mucho más grande que la Ed25519 para una seguridad parecida.

2. **Sus huellas.** **En tu equipo**:
   ```bash
   docker compose exec server bash -c 'for f in /etc/ssh/ssh_host_*_key.pub; do ssh-keygen -lf "$f"; done'
   ```
   ```
   256 SHA256:D2Vh3iNoBr1S3wOQbjLDfw85+ab+RK9FhZv14i1wg4c root@server (ECDSA)
   256 SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M root@server (ED25519)
   3072 SHA256:SxDR3C2HCoPOpuoRGLdkDYX5uaQU2Mk/xaYI7uQaBUI root@server (RSA)
   ```
   `bash -c '...'` ejecuta el bucle **dentro** del servidor; sin él, el `*` lo expandiría tu shell en tu equipo. Cada línea: bits, huella, comentario y tipo. Guarda estas tres huellas: son tu referencia por el canal independiente.

3. **Otros formatos.** **En tu equipo**:
   ```bash
   docker compose exec server ssh-keygen -E md5 -lf /etc/ssh/ssh_host_ed25519_key.pub
   docker compose exec server ssh-keygen -lvf /etc/ssh/ssh_host_ed25519_key.pub
   ```
   ```
   256 MD5:04:0c:59:7d:df:a2:7f:01:53:d7:df:b4:05:0c:e5:8e root@server (ED25519)
   256 SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M root@server (ED25519)
   +--[ED25519 256]--+
   |  ..o+           |
   |  .oo =          |
   |   ...           |
   +----[SHA256]-----+
   ```
   La misma llave, tres representaciones. Si alguien te da una huella `MD5:...`, compárala con la salida de `-E md5`, no con la SHA-256.

4. **Desde el cliente, sin entrar.** **En el cliente**:
   ```bash
   ssh-keyscan server 2>/dev/null | ssh-keygen -lf -
   ```
   ```
   3072 SHA256:SxDR3C2HCoPOpuoRGLdkDYX5uaQU2Mk/xaYI7uQaBUI server (RSA)
   256 SHA256:D2Vh3iNoBr1S3wOQbjLDfw85+ab+RK9FhZv14i1wg4c server (ECDSA)
   256 SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M server (ED25519)
   ```
   `ssh-keyscan` escribe las llaves por stdout y comentarios por stderr (`2>/dev/null` los descarta). `ssh-keygen -lf -` calcula la huella de lo que le llega por stdin. Coinciden con las del paso 2.

   **Ojo:** esto **no** es una verificación. `ssh-keyscan` habló con quien respondiera en la red; si hubiera un intermediario, verías sus llaves. La verificación es comparar con el paso 2, que no pasó por la red SSH.

5. **Primera conexión pidiendo ECDSA.** Por defecto el cliente pediría Ed25519. Fuerza ECDSA y muestra el *randomart*:
   ```bash
   ssh -o HostKeyAlgorithms=ecdsa-sha2-nistp256 -o VisualHostKey=yes -o UpdateHostKeys=no server true
   ```
   ```
   The authenticity of host 'server (172.20.0.3)' can't be established.
   ECDSA key fingerprint is SHA256:D2Vh3iNoBr1S3wOQbjLDfw85+ab+RK9FhZv14i1wg4c.
   +---[ECDSA 256]---+
   |      ...oo      |
   |       .++.o   . |
   |   ...           |
   +----[SHA256]-----+
   This key is not known by any other names.
   Are you sure you want to continue connecting (yes/no/[fingerprint])?
   ```
   Compara con la huella ECDSA del paso 2, responde `yes` y escribe la contraseña. `UpdateHostKeys=no` impide que el cliente aprenda las demás llaves (lo verás en el paso 8).

6. **El cliente prefiere lo que ya conoce:**
   ```bash
   sshpass -e ssh -v -o UpdateHostKeys=no server true 2>&1 | grep -E 'kex: host key|matches'
   ```
   ```
   debug1: kex: host key algorithm: ecdsa-sha2-nistp256
   debug1: Host 'server' is known and matches the ECDSA host key.
   ```
   Sin forzar nada, ahora pide ECDSA: como `known_hosts` solo tiene esa llave de `server`, la pone primera en su lista.

7. **Un tipo desconocido de un host conocido.** Fuerza Ed25519:
   ```bash
   ssh -o HostKeyAlgorithms=ssh-ed25519 -o UpdateHostKeys=no server true
   ```
   ```
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   ...
   The fingerprint for the ED25519 key sent by the remote host is
   SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M.
   ...
   Offending ECDSA key in /home/alumno/.ssh/known_hosts:1
   ...
   Host key verification failed.
   ```
   La llave Ed25519 es **legítima** (compárala con el paso 2), y aun así `ssh` corta. Para `ssh`, "un host que conozco me presenta una llave que no tengo" es indistinguible de un intermediario que eligió justo el tipo que te falta. Por eso no pregunta: corta.

8. **Que el cliente aprenda las demás llaves.** Conéctate una vez con `UpdateHostKeys` activo (el valor por defecto):
   ```bash
   sshpass -e ssh -v server true 2>&1 | grep -E 'Learned new hostkey'
   ```
   ```
   Learned new hostkey: RSA SHA256:SxDR3C2HCoPOpuoRGLdkDYX5uaQU2Mk/xaYI7uQaBUI
   Learned new hostkey: ED25519 SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M
   ```
   La conexión se verificó con la llave ECDSA conocida; por ese canal ya verificado el servidor envió sus otras llaves, y el cliente las guardó. Comprueba:
   ```bash
   ssh-keygen -lf ~/.ssh/known_hosts | cut -c1-60
   sshpass -e ssh -v -o HostKeyAlgorithms=ssh-ed25519 server true 2>&1 | grep matches
   ```
   ```
   256 SHA256:D2Vh3iNoBr1S3wOQbjLDfw85+ab+RK9FhZv14i1wg4c |1|ty
   3072 SHA256:SxDR3C2HCoPOpuoRGLdkDYX5uaQU2Mk/xaYI7uQaBUI |1|N
   256 SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M |1|vL
   debug1: Host 'server' is known and matches the ED25519 host key.
   ```
   Tres llaves, todas hasheadas (`|1|`), y Ed25519 ya funciona.

## Criterios de éxito

- [ ] Tienes las tres huellas del servidor obtenidas por `docker compose exec` (paso 2)
- [ ] Explicas por qué `ssh-keyscan` no es una verificación (paso 4)
- [ ] Explicas por qué el cliente pidió ECDSA en el paso 6 sin que lo forzaras
- [ ] Explicas por qué una llave legítima de otro tipo provoca el aviso de llave cambiada (paso 7)
- [ ] Explicas por qué es seguro que `UpdateHostKeys` añada llaves sin preguntar (paso 8)

## Reto extra

Repite el paso 5 contra `bastion` con `HostKeyAlgorithms=rsa-sha2-512`. ¿Qué tipo de llave aparece en el mensaje (`RSA`) y qué tipo se guarda en `known_hosts` (mira la tercera columna de `ssh-keygen -F bastion`)? Explica la diferencia entre tipo de llave y algoritmo de firma con la teoría 03.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — Un servidor con algoritmos antiguos](../lab-04-servidor-antiguo/README.md) | [Lab 06 — `known_hosts` por dentro](../lab-06-known-hosts-por-dentro/README.md) → |

[↑ Semana 02](../../README.md)
