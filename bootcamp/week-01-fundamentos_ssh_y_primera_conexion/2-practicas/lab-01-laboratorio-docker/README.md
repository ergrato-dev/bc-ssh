# Lab 01 — El laboratorio Docker

⏱ Duración estimada: ~60 min

## Objetivo

Levantar el laboratorio, entrar al cliente y comprobar desde él qué hosts existen, cuáles son alcanzables y cuáles tienen un servidor SSH escuchando, sin conectarte todavía a ninguno.

## Contexto

- El laboratorio son **cuatro contenedores** definidos en `compose.yaml`: `client` (donde trabajas tú), `server`, `bastion` e `interno` (los tres con `sshd`, el servidor SSH). El dibujo está en [la teoría](../../1-teoria/02-cliente-servidor-y-laboratorio.md#el-laboratorio).
- **Qué:** un contenedor es un proceso aislado con su propio sistema de archivos, nombre de host y red. **Para qué:** tener servidores reales sin alquilar ninguno. **Impacto:** lo que rompas aquí se arregla recreando el contenedor; tu equipo no se toca.
- Todos los servidores tienen el usuario `alumno` con contraseña `alumno`. **Es una contraseña débil a propósito y solo existe en el laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio `bc-ssh`, construye y levanta el laboratorio:
   ```bash
   docker compose up -d --build
   ```
   La primera vez descarga Ubuntu 24.04 e instala paquetes: tarda unos minutos. Al terminar:
   ```bash
   docker compose ps --format 'table {{.Service}}\t{{.Status}}'
   ```
   ```
   SERVICE   STATUS
   bastion   Up 10 seconds
   client    Up 10 seconds
   interno   Up 10 seconds
   server    Up 10 seconds
   ```
   Si falta alguno o dice `Exited`, revisa [docs/setup-entorno.md](../../../../docs/setup-entorno.md).

1. Entra al cliente:
   ```bash
   docker compose run --rm client
   ```
   ```
   alumno@client:/bc-ssh$
   ```
   El prompt dice quién eres (`alumno`), en qué host (`client`) y en qué carpeta (`/bc-ssh`, que es el repositorio de tu equipo montado dentro del contenedor). `--rm` borra el contenedor al salir: tu `~` dentro de él empieza vacío cada vez, pero lo que guardes en `/bc-ssh` se queda en tu equipo.

2. Ve a la carpeta del lab:
   ```bash
   cd bootcamp/week-01-fundamentos_ssh_y_primera_conexion/2-practicas/lab-01-laboratorio-docker
   ```

3. Comprueba la versión del cliente SSH:
   ```bash
   ssh -V
   ```
   ```
   OpenSSH_9.6p1 Ubuntu-3ubuntu13.20, OpenSSL 3.0.13 30 Jan 2024
   ```
   `ssh -V` escribe en stderr, no en stdout: para guardarlo en una variable necesitas `ssh -V 2>&1`. El número tras `13.` puede ser mayor si Ubuntu publicó parches.

4. Pregunta qué IP tiene cada host:
   ```bash
   getent hosts server bastion interno; echo "código: $?"
   ```
   ```
   172.20.0.3      server
   172.20.0.2      bastion
   código: 2
   ```
   Las IP pueden cambiar. `interno` no aparece y el código es 2 (“algún nombre no existe”): `interno` está solo en la red `privada` y `client` no está en ella. Docker solo resuelve los nombres de las redes en las que estás. Así simula el laboratorio una red interna de empresa; en la semana 09 llegarás a `interno` pasando por `bastion`.

5. Comprueba si hay alguien escuchando en el puerto 22 (el de SSH) y en uno donde no hay nada:
   ```bash
   nc -zv server 22
   nc -zv server 2222
   ```
   ```
   Connection to server (172.20.0.3) 22 port [tcp/*] succeeded!
   nc: connect to server (172.20.0.3) port 2222 (tcp) failed: Connection refused
   ```
   `nc` (netcat) abre conexiones TCP a mano. `-z` conecta y cierra sin enviar nada; `-v` cuenta qué pasó. `Connection refused` significa que el host existe y responde, pero nadie escucha en ese puerto.

6. Habla con el servidor SSH a mano. Conéctate sin `-z`:
   ```bash
   nc server 22
   ```
   ```
   SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   ```
   Esa línea es el **banner**: lo primero que dice un servidor SSH, antes de cualquier contraseña. Anuncia la versión del protocolo (`2.0`) y del software. Ahora escribe `hola` y pulsa Enter:
   ```
   Invalid SSH identification string.
   ```
   El servidor esperaba tu banner (`SSH-2.0-...`), recibió otra cosa y cerró la conexión. Ya has visto el primer paso del protocolo.

7. **TODO de `starter/banner.sh`.** Abre el archivo (`nano starter/banner.sh`) y sustituye la línea `echo "TODO: ..."` por:
   ```bash
   nc -w 2 "$host" "$puerto" </dev/null | head -n 1 | tr -d '\r'
   ```
   - `</dev/null`: no enviamos nada, para que el servidor no corte como en el paso 6.
   - `-w 2`: tras el banner el servidor espera el nuestro, que nunca llega; sin límite, `nc` no terminaría.
   - `head -n 1`: solo la primera línea. `tr -d '\r'`: el protocolo termina las líneas con `\r\n` y el `\r` sobra en una terminal.

   Pruébalo:
   ```bash
   ./starter/banner.sh server
   ./starter/banner.sh bastion
   ./starter/banner.sh server 2222; echo "código: $?"
   ```
   ```
   SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   código: 1
   ```
   Con el puerto cerrado no hay banner y el script sale con 1: `set -o pipefail` hace que el fallo de `nc` llegue al código de salida del script.

8. Sal del cliente:
   ```bash
   exit
   ```
   Vuelves a tu equipo. Los servidores siguen corriendo (`docker compose ps`); el cliente se borró por el `--rm`.

## Criterios de éxito

- [ ] `docker compose ps` muestra los cuatro servicios en `Up` (paso 0)
- [ ] `ssh -V` dentro de `client` imprime OpenSSH 9.6 o superior (paso 3)
- [ ] Puedes explicar por qué `interno` no resuelve desde `client` (paso 4)
- [ ] Distingues `succeeded` de `Connection refused` en `nc -zv` (paso 5)
- [ ] `./starter/banner.sh server` imprime una línea `SSH-2.0-OpenSSH_...` y con el puerto 2222 sale con 1 (paso 7)

## Reto extra

Desde **tu equipo**, ejecuta `docker compose exec bastion getent hosts interno`. ¿Por qué `bastion` sí resuelve `interno`? Mira la sección `networks` de `compose.yaml`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — Tu primera conexión](../lab-02-primera-conexion/README.md) → |

[↑ Semana 01](../../README.md)
