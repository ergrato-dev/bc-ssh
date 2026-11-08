# Lab 02 — Mensajes y capas en `ssh -vvv`

⏱ Duración estimada: ~60 min

## Objetivo

Traducir los números de mensaje que imprime `ssh -vvv` a su nombre y a su capa con un script, recorrer una conexión completa mensaje a mensaje y provocar una renegociación de llaves.

## Contexto

- La [teoría 01](../../1-teoria/01-capas-del-protocolo.md#los-tipos-de-mensaje-y-sus-rangos) explica que el primer byte de cada mensaje es su tipo y que el rango del número dice la capa. Tenla abierta.
- `-vvv` es el nivel máximo de depuración. Entre otras cosas imprime `send packet: type N` y `receive packet: type N` por cada mensaje. Con `-v` no salen.
- **La contraseña `alumno` es solo del laboratorio.** Este lab la pasa con `sshpass`.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-02-protocolo_kex_y_known_hosts/2-practicas/lab-02-mensajes-y-capas
   export SSHPASS=alumno
   ssh server true
   ```
   Verifica la huella como en la semana 01 (lab-02), responde `yes` y escribe la contraseña. Así `server` queda en `known_hosts`.

1. Mira los números en bruto:
   ```bash
   sshpass -e ssh -vvv server true 2>&1 | grep 'packet: type' | head -5
   ```
   ```
   debug3: send packet: type 20
   debug3: receive packet: type 20
   debug3: send packet: type 30
   debug3: receive packet: type 31
   debug3: send packet: type 21
   ```
   Con la tabla de la teoría: 20 `KEXINIT` de ida y de vuelta, 30 y 31 el intercambio de llaves, 21 `NEWKEYS`.

2. Abre `starter/capas.sh`. Ya hace casi todo:
   - recoge las líneas `send/receive packet: type N` de `ssh -vvv`;
   - `read -r dir _ _ tipo` parte cada línea en palabras: la dirección y el número (`_` descarta las palabras que no interesan);
   - el array `nombre` traduce el número a su nombre;
   - `printf '%-8s %3s ...'` alinea las columnas.

   Ejecútalo tal cual:
   ```bash
   ./starter/capas.sh server | head -3
   ```
   ```
   send      20  ?             KEXINIT
   receive   20  ?             KEXINIT
   send      30  ?             KEX_ECDH_INIT
   ```
   Falta la capa.

3. **TODO.** Completa la función `capa` con los rangos de la teoría:
   ```bash
   capa() {
     local t=$1
     if   (( t <= 49 )); then echo transporte
     elif (( t <= 79 )); then echo autenticacion
     elif (( t <= 127 )); then echo conexion
     else echo otro
     fi
   }
   ```
   `local` hace que `t` solo exista dentro de la función. `(( ))` compara números. Como los `if` van en orden, `t <= 79` solo se evalúa si `t` ya es mayor que 49. Ejecuta:
   ```bash
   ./starter/capas.sh server
   ```
   ```
   send      20  transporte    KEXINIT
   receive   20  transporte    KEXINIT
   send      30  transporte    KEX_ECDH_INIT
   receive   31  transporte    KEX_ECDH_REPLY
   send      21  transporte    NEWKEYS
   send       7  transporte    EXT_INFO
   receive   21  transporte    NEWKEYS
   send       5  transporte    SERVICE_REQUEST
   receive    7  transporte    EXT_INFO
   receive    6  transporte    SERVICE_ACCEPT
   send      50  autenticacion USERAUTH_REQUEST
   receive    7  transporte    EXT_INFO
   receive   51  autenticacion USERAUTH_FAILURE
   send      50  autenticacion USERAUTH_REQUEST
   receive   52  autenticacion USERAUTH_SUCCESS
   send      90  conexion      CHANNEL_OPEN
   send      80  conexion      GLOBAL_REQUEST
   receive   80  conexion      GLOBAL_REQUEST
   receive   91  conexion      CHANNEL_OPEN_CONFIRMATION
   send      98  conexion      CHANNEL_REQUEST
   send      98  conexion      CHANNEL_REQUEST
   send      98  conexion      CHANNEL_REQUEST
   receive   99  conexion      CHANNEL_SUCCESS
   receive   96  conexion      CHANNEL_EOF
   receive   98  conexion      CHANNEL_REQUEST
   receive   98  conexion      CHANNEL_REQUEST
   receive   97  conexion      CHANNEL_CLOSE
   send      97  conexion      CHANNEL_CLOSE
   send       1  transporte    DISCONNECT
   ```
   Las tres capas aparecen en orden: transporte, autenticación, conexión. El orden exacto de algunas líneas puede variar.

4. **Lee la conversación.** Responde en tus notas, buscando en el `-vvv` si hace falta:
   - ¿Por qué hay un `USERAUTH_FAILURE` antes del `SUCCESS`? (Pista: semana 01, lab-05. ¿Qué método prueba el cliente primero?)
   - ¿Por qué `NEWKEYS` lo envían los dos lados?
   - Después del primer `NEWKEYS`, ¿algún mensaje viajó sin cifrar?

5. **Los `GLOBAL_REQUEST` (80).** Son peticiones para la conexión entera, no para un canal:
   ```bash
   sshpass -e ssh -vvv server true 2>&1 | grep -E 'no-more-sessions|hostkeys-00'
   ```
   ```
   debug1: Requesting no-more-sessions@openssh.com
   debug1: client_input_global_request: rtype hostkeys-00@openssh.com want_reply 0
   ```
   - El cliente pide `no-more-sessions`: "no aceptes que abra más sesiones en esta conexión". Si alguien tomara el control de la conexión, no podría abrir otra shell por ella.
   - El servidor envía `hostkeys-00`: la lista de todas sus host keys, para `UpdateHostKeys` ([teoría 03](../../1-teoria/03-host-keys-y-known_hosts.md#rotar-host-keys-updatehostkeys)). Lo usarás en el lab-07.

6. **Los `CHANNEL_REQUEST` (98).** Tres de ida y dos de vuelta:
   ```bash
   sshpass -e ssh -vvv server true 2>&1 | grep -E 'request (env|exec)|rtype exit-status'
   ```
   ```
   debug2: channel 0: request env confirm 0
   debug2: channel 0: request env confirm 0
   debug2: channel 0: request exec confirm 1
   debug1: client_input_channel_req: channel 0 rtype exit-status reply 0
   ```
   - Dos `env`: el cliente envía `LANG` y `LC_ALL` porque `/etc/ssh/ssh_config` tiene `SendEnv LANG LC_*` (semana 01, lab-07).
   - Un `exec`: el comando `true`.
   - De vuelta, `exit-status` con el código del comando y un aviso de fin de escritura (`eow@openssh.com`).

7. **Renegociar las llaves.** Envía 20 MB a `server` con un límite de 4 MB por llave:
   ```bash
   head -c 20M /dev/zero | sshpass -e ssh -v -o RekeyLimit=4M server 'cat > /dev/null' 2>&1 | grep -E 'rekey (in|out) after' | sort | uniq -c
   ```
   ```
         6 debug1: rekey in after 524288 blocks
         6 debug1: rekey out after 524288 blocks
   ```
   - `head -c 20M /dev/zero` produce 20 MB de ceros; `cat > /dev/null` en el servidor los lee y los descarta.
   - 524288 bloques de 8 bytes son los 4 MB del límite.
   - 6 veces: el intercambio inicial y 5 renegociaciones, una cada 4 MB.

   Cuenta los `KEXINIT`:
   ```bash
   head -c 20M /dev/zero | sshpass -e ssh -v -o RekeyLimit=4M server 'cat > /dev/null' 2>&1 | grep -c 'SSH2_MSG_KEXINIT sent'
   ```
   ```
   6
   ```
   La transferencia no se interrumpió: la renegociación ocurre **dentro** del canal cifrado y el session ID no cambia ([teoría 02](../../1-teoria/02-intercambio-de-llaves.md#renegociar-las-llaves-rekey)).

8. Sin `-o RekeyLimit`:
   ```bash
   sshpass -e ssh -v server true 2>&1 | grep 'rekey out'
   ```
   ```
   debug1: rekey out after 134217728 blocks
   ```
   Con el límite por defecto, una llave cubre unos 1 GB de datos con este cifrado.

## Criterios de éxito

- [ ] `./starter/capas.sh server` imprime la capa de cada mensaje (paso 3)
- [ ] Respondiste las tres preguntas del paso 4
- [ ] Explicas qué pide cada `GLOBAL_REQUEST` (paso 5)
- [ ] Provocaste 5 renegociaciones y explicas por qué la transferencia no se cortó (paso 7)

## Reto extra

Abre una sesión interactiva con `sshpass -e ssh -vvv server 2> /tmp/sesion.log`, ejecuta `ls` y sal con `exit`. Pasa el log por la parte final de `capas.sh` (copia el pipeline cambiando `ssh` por `cat /tmp/sesion.log`). ¿Qué `CHANNEL_REQUEST` nuevos aparecen? (Pista: `pty-req` y `shell`.) ¿Qué tipo de mensaje lleva cada tecla que escribes?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — Lo que ve un espía](../lab-01-lo-que-ve-un-espia/README.md) | [Lab 03 — Negociación de algoritmos](../lab-03-negociacion-de-algoritmos/README.md) → |

[↑ Semana 02](../../README.md)
