# Lab 05 — Leer una conexión con `ssh -v`

⏱ Duración estimada: ~60 min

## Objetivo

Seguir en la salida de `ssh -v` cada fase de una conexión (TCP, versiones, intercambio de llaves, verificación del servidor, autenticación) y ver la misma conexión desde el lado del servidor.

## Contexto

- `-v` (*verbose*) hace que `ssh` cuente lo que hace, línea a línea, por stderr. `-vv` y `-vvv` cuentan más. Es la primera herramienta cuando algo falla: el mensaje de error final dice poco, el log dice en qué fase se paró.
- Las fases son las del diagrama de [la teoría](../../1-teoria/02-cliente-servidor-y-laboratorio.md#qué-pasa-al-conectar). Tenlo abierto mientras haces el lab.
- Este lab usa `sshpass` como el lab-03. **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-01-fundamentos_ssh_y_primera_conexion/2-practicas/lab-05-modo-verbose
   export SSHPASS=alumno
   ```
   Verifica la huella de `server` como en el lab-02 y conéctate una vez (`ssh server true`) para que quede en `known_hosts`.

1. Mira cuánto cuenta cada nivel:
   ```bash
   for v in -v -vv -vvv; do echo "$v $(sshpass -e ssh $v server true 2>&1 | wc -l) líneas"; done
   ```
   ```
   -v 92 líneas
   -vv 164 líneas
   -vvv 250 líneas
   ```
   Los números pueden variar un poco. `2>&1` junta stderr con stdout para que `wc -l` cuente las líneas de depuración. Con `-v` basta casi siempre.

2. Guarda el log para leerlo con calma:
   ```bash
   sshpass -e ssh -v server true 2> /tmp/conexion.log
   less /tmp/conexion.log
   ```
   `2>` manda solo stderr al archivo. En `less`, `/` busca texto, `n` va a la siguiente coincidencia y `q` sale.

3. **Fase TCP.** Busca `Connecting to`:
   ```
   debug1: Connecting to server [172.20.0.3] port 22.
   debug1: Connection established.
   ```
   Si un `ssh` se queda colgado **antes** de `Connection established`, el problema es de red, no de SSH.

4. **Versiones.** Busca `version`:
   ```
   debug1: Local version string SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   debug1: Remote protocol version 2.0, remote software version OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   ```
   Es el intercambio de banners que hiciste a mano con `nc` en el lab-01, ahora en las dos direcciones.

5. **Intercambio de llaves (KEX).** Busca `kex:`:
   ```
   debug1: kex: algorithm: sntrup761x25519-sha512@openssh.com
   debug1: kex: host key algorithm: ssh-ed25519
   debug1: kex: server->client cipher: chacha20-poly1305@openssh.com MAC: <implicit> compression: none
   ```
   - `algorithm`: cómo acuerdan cliente y servidor una llave de sesión sin enviarla por la red. `sntrup761x25519` combina un algoritmo clásico (X25519) con uno resistente a computadoras cuánticas (sntrup761). Es el que viene por defecto en OpenSSH 9.6; la semana 13 lo trata a fondo.
   - `host key algorithm`: con qué tipo de llave demuestra el servidor quién es.
   - `cipher`: el cifrado simétrico de los datos. `MAC: <implicit>` significa que ChaCha20-Poly1305 ya incluye la comprobación de integridad.

   Mira cuántas opciones conoce tu cliente:
   ```bash
   ssh -Q kex
   ```
   La lista es larga. Cliente y servidor eligen el primer algoritmo de la lista del cliente que el servidor también admite.

6. **Verificación del servidor.** Busca `host key`:
   ```
   debug1: Server host key: ssh-ed25519 SHA256:m/sNQegz9dMrhYOD58Pm4keTPbbWHqnCL05A0Q3W1g8
   debug1: Host 'server' is known and matches the ED25519 host key.
   ```
   La huella es la que verificaste en el lab-02. `is known and matches` es la comprobación contra `known_hosts`.

7. **Autenticación.** Busca `Authentications`:
   ```
   debug1: Authentications that can continue: publickey,password
   debug1: Next authentication method: publickey
   debug1: Next authentication method: password
   Authenticated to server ([172.20.0.3]:22) using "password".
   ```
   El servidor ofrece dos métodos. El cliente prueba primero `publickey`, no tiene llaves (llegan en la semana 03) y pasa a `password`.

8. **Fin.** Las últimas líneas:
   ```
   Transferred: sent 3312, received 3664 bytes, in 0.1 seconds
   debug1: Exit status 0
   ```
   `Exit status 0` es el código de `true` en el servidor.

9. **El lado del servidor.** **En tu equipo**:
   ```bash
   docker compose logs server --tail 3
   ```
   ```
   server-1  | Accepted password for alumno from 172.20.0.6 port 52084 ssh2
   ```
   El servidor del laboratorio arranca con `sshd -D -e`: `-D` no se va a segundo plano y `-e` escribe el log en stderr, que Docker recoge. En un servidor normal irían a `journalctl -u ssh` (semana 11).

10. **TODOs de `starter/fases.sh`.** El script guarda el log en `$log` y la función `campo REGEX` imprime lo que casa con el grupo `( )` de la regex. La línea `tcp:` ya está hecha como ejemplo. Escribe las otras cinco siguiendo el mismo patrón:
    ```bash
    echo "servidor: $(campo '^debug1: Remote protocol version .*, remote software version (.*)$')"
    echo "kex:      $(campo '^debug1: kex: algorithm: (.*)$')"
    echo "host key: $(campo '^debug1: Server host key: (.*)$')"
    echo "cifrado:  $(campo '^debug1: kex: server->client cipher: ([^ ]+).*$')"
    echo "auth:     $(campo '^Authenticated to .* using "(.*)"\.$')"
    ```
    `([^ ]+)` captura hasta el primer espacio: solo el nombre del cifrado. `\.` es un punto literal. Pruébalo:
    ```bash
    ./starter/fases.sh server
    ```
    ```
    tcp:      server [172.20.0.3] port 22
    servidor: OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
    kex:      sntrup761x25519-sha512@openssh.com
    host key: ssh-ed25519 SHA256:m/sNQegz9dMrhYOD58Pm4keTPbbWHqnCL05A0Q3W1g8
    cifrado:  chacha20-poly1305@openssh.com
    auth:     password
    ```

## Criterios de éxito

- [ ] Encuentras en el log las líneas de TCP, versiones, KEX, host key y autenticación (pasos 3 a 7)
- [ ] Explicas por qué el cliente prueba `publickey` antes que `password` (paso 7)
- [ ] Ves el `Accepted password` en el log del servidor (paso 9)
- [ ] `./starter/fases.sh server` imprime las seis líneas (paso 10)

## Reto extra

Fuerza otro algoritmo de intercambio: `sshpass -e ssh -v -o KexAlgorithms=curve25519-sha256 server true 2>&1 | grep 'kex: algorithm'`. Prueba también con `diffie-hellman-group1-sha1`. ¿Qué responde el servidor y por qué crees que lo rechaza?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — Sesión interactiva y secuencias de escape](../lab-04-sesion-interactiva-y-escapes/README.md) | [Lab 06 — Los cinco errores más comunes](../lab-06-errores-comunes/README.md) → |

[↑ Semana 01](../../README.md)
