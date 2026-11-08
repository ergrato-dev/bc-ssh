# Lab 06 — Opciones de `authorized_keys`

⏱ Duración estimada: ~60 min

## Objetivo

Limitar lo que puede hacer una llave con `restrict`, `pty`, `command=`, `from=` y `expiry-time=`, y escribir un comando forzado que solo deja ejecutar tres consultas, para una llave de monitorización.

## Contexto

- Formato de la línea, tabla de opciones y por qué partir de `restrict`: [teoría 03](../../1-teoria/03-authorized_keys-y-opciones.md#las-opciones).
- Trabajarás con **dos** llaves: `id_ed25519`, la tuya, sin restricciones (para administrar), y `monitor`, la que vas limitando. Así nunca te quedas fuera mientras pruebas.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-03-autenticacion_con_llaves_ssh/2-practicas/lab-06-opciones-de-authorized-keys
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C alumno -f ~/.ssh/id_ed25519
   ssh-keygen -q -t ed25519 -N '' -C monitor -f ~/.ssh/monitor
   sshpass -e ssh-copy-id server
   ```
   Dos funciones para no repetir comandos largos. `ak OPCIONES` reescribe el `authorized_keys` del servidor con tu llave y la de `monitor` precedida de `OPCIONES`; `mon` conecta con la llave `monitor`:
   ```bash
   ak()  { { cat ~/.ssh/id_ed25519.pub; echo "$1 $(cat ~/.ssh/monitor.pub)"; } | ssh server 'cat > ~/.ssh/authorized_keys'; }
   mon() { ssh -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/monitor "$@"; echo "código: $?"; }
   ```
   - `{ ...; ...; }` agrupa dos comandos para enviar su salida junta por el `|`.
   - `cat >` **reescribe** el archivo cada vez: cada paso empieza limpio.

1. **`restrict`:** ejecutar comandos sí, terminal no.
   ```bash
   ak restrict
   mon server 'hostname; whoami'
   mon -tt server tty
   ```
   ```
   server
   alumno
   código: 0
   PTY allocation request failed on channel 0
   código: 255
   ```
   `-tt` exige una terminal (pty). Sin terminal no hay shell interactivo: esta llave sirve para un script, no para una persona.

2. **`restrict,pty`:** vuelve a permitir la terminal.
   ```bash
   ak restrict,pty
   mon -tt server tty
   ```
   ```
   /dev/pts/0
   Connection to server closed.
   código: 0
   ```
   `tty` imprime la terminal asignada. Los reenvíos (puertos, agente) siguen desactivados.

3. **`command=`:** pidas lo que pidas, se ejecuta otra cosa.
   ```bash
   ak 'restrict,command="date"'
   mon server 'cat /etc/shadow'
   ```
   ```
   Sun Nov  8 05:29:48 UTC 2026
   código: 0
   ```
   Las comillas simples alrededor de todo protegen las dobles, que deben llegar tal cual al archivo.

4. **`SSH_ORIGINAL_COMMAND`:** el comando forzado ve lo que se pidió.
   ```bash
   ak 'restrict,command="echo pediste: [$SSH_ORIGINAL_COMMAND]"'
   mon server 'ls -l /tmp'
   mon server
   ```
   ```
   pediste: [ls -l /tmp]
   código: 0
   pediste: []
   código: 0
   ```
   Sin comando (`mon server`), la variable llega vacía.

5. **TODO de `starter/solo-lectura.sh`.** Un sistema de monitorización necesita preguntar la carga, el disco y la memoria, y nada más. El script compara `SSH_ORIGINAL_COMMAND` con tres nombres y ejecuta el comando que corresponde. Completa las ramas del `case`:
   ```bash
     carga)   exec uptime ;;
     disco)   exec df -h / ;;
     memoria) exec free -m ;;
   ```
   - `case` compara el texto con cada patrón y ejecuta la primera rama que coincide; `*)` recoge el resto.
   - `exec` sustituye el script por el comando: su código de salida es el del comando.
   - El cliente nunca escribe el comando: elige un **nombre**. Nada de lo que envía llega a un shell.

   Cópialo al servidor e instálalo:
   ```bash
   ssh server 'cat > ~/solo-lectura.sh && chmod 700 ~/solo-lectura.sh' < starter/solo-lectura.sh
   ak 'restrict,command="~/solo-lectura.sh"'
   mon server carga
   mon server disco
   mon server 'carga; rm -rf ~'
   ```
   ```
    05:29:49 up  1:34,  0 user,  load average: 1.07, 0.96, 1.04
   código: 0
   Filesystem      Size  Used Avail Use% Mounted on
   overlay        1007G  315G  642G  33% /
   código: 0
   solo-lectura: no permitido: 'carga; rm -rf ~' (usa carga, disco o memoria)
   código: 1
   ```
   El tercero es el intento que importa: un `eval "$SSH_ORIGINAL_COMMAND"` habría ejecutado el `rm`. Con `case`, el texto completo no coincide con nada y se rechaza.

6. **`from=`:** solo desde ciertas redes.
   ```bash
   ak 'restrict,from="10.0.0.0/8"'
   mon server true
   ak 'restrict,from="172.16.0.0/12"'
   mon server hostname
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   server
   código: 0
   ```
   El laboratorio usa `172.x.x.x` (dentro de `172.16.0.0/12`), no `10.x.x.x`. **En tu equipo**, el log dice por qué falló el primero:
   ```bash
   docker compose logs server | grep 'permitted host' | tail -1
   ```
   ```
   server-1  | /home/alumno/.ssh/authorized_keys:2: Authentication tried for alumno with correct key but not from a permitted host (host=172.20.0.5, ip=172.20.0.5, required=10.0.0.0/8).
   ```
   **Impacto:** si la llave se filtra, no sirve desde fuera de esa red.

7. **`expiry-time=`:** caducidad. **En el cliente**:
   ```bash
   ak 'restrict,expiry-time="20240101"'
   mon server true
   ak 'restrict,expiry-time="20991231"'
   mon server hostname
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   server
   código: 0
   ```
   Para accesos temporales (un proveedor, una auditoría): la llave se apaga sola aunque nadie se acuerde de borrarla.

8. **Una opción mal escrita:**
   ```bash
   ak 'restrict,comand="date"'
   mon server true
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   `comand` (con una `m`) no existe: `sshd` descarta la línea entera (`Refused by key options` en el log) en vez de ignorar la opción. Si la ignorara, la llave entraría sin el comando forzado que querías.

9. **`environment=`:** responde en tus notas tras probarlo.
   ```bash
   ak 'restrict,environment="MODO=lectura"'
   mon server 'echo "MODO=[$MODO]"'
   ```
   ¿Sale el valor? ¿Por qué? (Pista: la tabla de la teoría 03.)

## Criterios de éxito

- [ ] Explicas qué quita `restrict` y qué devuelve `pty` (pasos 1 y 2)
- [ ] `starter/solo-lectura.sh` permite `carga`, `disco` y `memoria` y rechaza el resto (paso 5)
- [ ] Explicas por qué `case` es seguro y `eval "$SSH_ORIGINAL_COMMAND"` no (paso 5)
- [ ] Encontraste en el log el motivo del rechazo por `from=` (paso 6)
- [ ] Explicas por qué una opción mal escrita invalida la línea (paso 8)

## Reto extra

Haz que `solo-lectura.sh` deje constancia de cada petición: antes del `case`, añade `printf '%s %s\n' "$(date +%FT%T)" "${SSH_ORIGINAL_COMMAND:-}" >> ~/solo-lectura.log`. Reinstálalo, haz tres peticiones (una rechazada) y léelo con tu llave `id_ed25519`. ¿Por qué el registro va **antes** del `case` y no dentro de cada rama?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Varias llaves, una por host](../lab-05-varias-llaves/README.md) | [Lab 07 — Rotar una llave](../lab-07-rotar-una-llave/README.md) → |

[↑ Semana 03](../../README.md)
