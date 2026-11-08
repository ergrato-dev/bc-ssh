# Glosario — Semana 05

| Término | Definición |
|---------|------------|
| **alias** | Nombre que escribes en `ssh` y que un bloque `Host` traduce a host, usuario, llave y opciones (`lab-server` → `server`) |
| **`%C`** | Token con un hash de 40 caracteres del equipo local, host, puerto y usuario remoto; de longitud fija, ideal para `ControlPath` |
| **canal** | Cada sesión que viaja dentro de una conexión SSH. Con multiplexing, varios procesos comparten los canales de una misma conexión |
| **`ControlMaster`** | Opción de `ssh_config`: si `ssh` crea un master (`yes`, `auto`) o solo usa uno existente (`no`) |
| **`ControlPath`** | Ruta del socket del master; lleva tokens (`%C`) para que cada destino tenga el suyo. Debe medir menos de 108 bytes; `none` desactiva el socket |
| **`ControlPersist`** | Cuánto sigue vivo el master tras cerrar la última sesión (`no`, un tiempo como `10m`, o `yes`) |
| **enlace simbólico** | Archivo que apunta a otra ruta (`ln -s`); `bin/kit-link` crea `~/.ssh/kit` para que el `Include` encuentre el kit |
| **`-F`** | Opción de `ssh` que lee solo el archivo indicado, en lugar de `~/.ssh/config` y `/etc/ssh/ssh_config` |
| **`-G`** | Opción de `ssh` que escribe la configuración final para un destino y termina sin conectar |
| **`Host`** | Inicio de un bloque de `ssh_config` que se aplica a los nombres escritos que coinciden con sus patrones |
| **`HostName`** | El nombre o dirección real al que conecta `ssh`; acepta tokens (`%h`) |
| **`Include`** | Directiva que lee otros archivos de configuración en ese punto; rutas relativas desde `~/.ssh` (o `/etc/ssh`), comodines en orden alfabético |
| **master** | El proceso `ssh` que tiene la conexión autenticada y atiende, por su socket, las sesiones de otros `ssh` al mismo destino |
| **`Match`** | Inicio de un bloque que se aplica si se cumplen todos sus criterios: `host`, `originalhost`, `user`, `localuser`, `exec`, `tagged`, `all`, `final`... |
| **`Match exec`** | Criterio que ejecuta una orden con tu shell en cada `ssh`; se cumple si sale con 0 |
| **`Match final`** | Criterio que hace que `ssh` lea toda la configuración una segunda vez y aplique el bloque en esa segunda lectura |
| **multiplexing** | Reutilizar una conexión SSH ya autenticada para varias sesiones, sin repetir TCP, intercambio de llaves ni autenticación |
| **`-O`** | Opción de `ssh` que envía una orden al master: `check`, `exit`, `stop`, `forward`, `cancel` |
| **`originalhost`** | Criterio de `Match` que compara con el nombre escrito en la línea de comandos |
| **`-P`** | Opción de `ssh` que pone una etiqueta a la conexión (OpenSSH 9.4+) |
| **patrón** | Texto con comodines (`*` cero o más caracteres, `?` uno) o negación (`!`) que usan `Host` y `Match` |
| **perfil** | Conjunto de opciones que eliges al conectar con `ssh -P NOMBRE`, definido con `Match tagged NOMBRE` |
| **primer valor gana** | Regla de `ssh_config`: para cada opción, `ssh` se queda con el primer valor que encuentra; lo concreto va arriba y `Host *` al final |
| **`-S`** | Opción de `ssh` que indica la ruta del socket del master directamente |
| **`ServerAliveInterval`** | Cada cuántos segundos sin tráfico envía `ssh` un mensaje al servidor para mantener viva la conexión y detectar caídas |
| **`ssh_config`** | Formato de los archivos de configuración del cliente: `~/.ssh/config` y `/etc/ssh/ssh_config` |
| **`Tag`** | Opción de `ssh_config` que pone una etiqueta a la conexión, como `-P`; la evalúa `Match tagged` (OpenSSH 9.4+) |
| **token** | Marcador que `ssh` sustituye en cada conexión: `%h` host, `%n` nombre escrito, `%p` puerto, `%r` usuario remoto, `%u` usuario local, `%d` carpeta personal, `%C` hash |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | [📦 Semana 04: Transferencia de Archivos](../../week-06-transferencia_archivos_scp_sftp_rsync/README.md) → |

[↑ Semana 05](../README.md)
