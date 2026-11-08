# Lab 03 — Comandos remotos

⏱ Duración estimada: ~60 min

## Objetivo

Ejecutar comandos en `server` sin abrir una shell interactiva, entender qué código de salida devuelve `ssh`, quién expande cada variable y cómo viajan stdin y stdout.

## Contexto

- `ssh HOST COMANDO` abre la conexión, ejecuta `COMANDO` en el servidor con tu shell remota, te trae su salida y cierra. Es la base de todo script que administra servidores.
- `ssh` devuelve **el código de salida del comando remoto**. Si el fallo es de `ssh` (no conecta, no autentica), devuelve **255**.
- Escribir la contraseña en cada comando cansa. En este lab usarás `sshpass`, que la toma de la variable `SSHPASS`. **Qué:** un ayudante que teclea la contraseña por ti. **Para qué:** practicar sin interrupciones. **Impacto:** la contraseña queda en una variable de entorno; es aceptable **solo en el laboratorio**. En la semana 03 la sustituyen las llaves.

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-01-fundamentos_ssh_y_primera_conexion/2-practicas/lab-03-comandos-remotos
   ```

1. Ejecuta un comando en `server`:
   ```bash
   ssh server hostname
   ```
   El contenedor del cliente es nuevo, así que vuelve a preguntar por la huella. Si no recreaste `server`, es la misma que verificaste en el lab-02; compárala igual (`docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` en tu equipo), escribe `yes` y la contraseña `alumno`:
   ```
   alumno@server's password:
   server
   ```
   No escribiste `alumno@`: sin usuario, `ssh` usa tu usuario local, que en el cliente también es `alumno`. La conexión se cerró sola al terminar `hostname`.

2. Prepara `sshpass` para el resto del lab:
   ```bash
   export SSHPASS=alumno
   sshpass -e ssh server hostname
   ```
   ```
   server
   ```
   `-e` significa "lee la contraseña de `$SSHPASS`". `export` la deja disponible para los programas que lances desde esta shell; desaparece al cerrar el cliente.

3. El código de salida viaja de vuelta:
   ```bash
   sshpass -e ssh server 'exit 3'; echo "código: $?"
   sshpass -e ssh server 'test -d /no/existe'; echo "código: $?"
   ```
   ```
   código: 3
   código: 1
   ```
   Ahora un fallo de `ssh` y no del comando:
   ```bash
   ssh -p 2222 server true; echo "código: $?"
   ```
   ```
   ssh: connect to host server port 2222: Connection refused
   código: 255
   ```
   `-p` cambia el puerto. Un script distingue "el comando falló" (1–254) de "ni siquiera llegué" (255).

4. ¿Quién expande las variables? Compara:
   ```bash
   sshpass -e ssh server echo "$HOSTNAME"
   sshpass -e ssh server 'echo "$HOSTNAME"'
   ```
   ```
   client
   server
   ```
   Con comillas dobles (o sin comillas), **tu** shell sustituye `$HOSTNAME` antes de llamar a `ssh`: al servidor llega `echo client`. Con comillas simples, el texto viaja intacto y lo expande la shell **remota**. Regla: lo que debe evaluarse en el servidor, entre comillas simples.

5. stdout llega a tu equipo; stdin sale de él:
   ```bash
   sshpass -e ssh server 'cat /etc/os-release' | grep PRETTY_NAME
   echo "hola desde client" | sshpass -e ssh server 'tr a-z A-Z'
   ```
   ```
   PRETTY_NAME="Ubuntu 24.04.5 LTS"
   HOLA DESDE CLIENT
   ```
   En el primero, `grep` corre **en el cliente** sobre lo que devolvió `cat`. En el segundo, `tr` corre **en el servidor** y lee el texto que le mandaste por la tubería.

6. Terminal o no terminal:
   ```bash
   sshpass -e ssh server tty
   sshpass -e ssh -t server tty
   ```
   ```
   not a tty
   /dev/pts/0
   Connection to server closed.
   ```
   Con un comando, `ssh` no reserva terminal (*pseudo-terminal*, pty) en el servidor: la salida es texto limpio para scripts. `-t` la fuerza, y la necesitan los programas interactivos como `top` o `nano`. Prueba `sshpass -e ssh -t server top` y sal con `q`; sin `-t` falla con `TERM environment variable not set` o similar.

7. Una contraseña mal escrita:
   ```bash
   SSHPASS=mala sshpass -e ssh server true; echo "código: $?"
   ```
   ```
   Permission denied, please try again.
   código: 5
   ```
   El 5 es de `sshpass` ("contraseña incorrecta"), no de `ssh`.

8. **TODOs de `starter/remote-info.sh`.** Ábrelo. Ya imprime el `host:`. Completa:
   - **TODO 1:** `echo "usuario: $(remoto whoami)"`
   - **TODO 2:** `echo "sistema: $(remoto '. /etc/os-release && echo "$PRETTY_NAME"')"`. `.` carga el archivo como variables de shell; las comillas simples exteriores hacen que se expanda en el servidor (paso 4). `shellcheck` avisará (SC2016) de que `$PRETTY_NAME` no se expande: es justo lo que quieres, y se silencia con `# shellcheck disable=SC2016` en la línea anterior.
   - **TODO 3:**
     ```bash
     if remoto test -f /etc/ssh/sshd_config; then
       echo "sshd_config: existe"
     else
       echo "sshd_config: no existe (código $?)"
     fi
     ```
     El `if` es necesario: con `set -e`, un comando que falla fuera de un `if` cortaría el script.

   Pruébalo:
   ```bash
   ./starter/remote-info.sh server
   ```
   ```
   host:    server
   usuario: alumno
   sistema: Ubuntu 24.04.5 LTS
   sshd_config: existe
   ```

## Criterios de éxito

- [ ] `ssh server 'exit 3'` devuelve 3 y `ssh -p 2222 server true` devuelve 255 (paso 3)
- [ ] Explicas por qué `echo "$HOSTNAME"` imprime `client` y `'echo "$HOSTNAME"'` imprime `server` (paso 4)
- [ ] Sabes en qué máquina corrió `grep` y en cuál `tr` (paso 5)
- [ ] `./starter/remote-info.sh server` imprime las cuatro líneas (paso 8)

## Reto extra

Haz que `remote-info.sh` acepte varios hosts (`./starter/remote-info.sh server bastion`) e imprima un bloque por host. ¿Cuántas conexiones abre por host? Piensa cómo reducirlas a una sola con un único comando remoto.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — Tu primera conexión](../lab-02-primera-conexion/README.md) | [Lab 04 — Sesión interactiva y secuencias de escape](../lab-04-sesion-interactiva-y-escapes/README.md) → |

[↑ Semana 01](../../README.md)
