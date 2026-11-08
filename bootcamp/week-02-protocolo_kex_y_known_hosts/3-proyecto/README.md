# Proyecto Semana 02 — ssh-infra-kit: known_hosts verificado

⏱ Duración estimada: ~3 h

## Contexto

En tu equipo, cada servidor nuevo se añade igual: alguien escribe `ssh servidor-nuevo`, ve la pregunta `Are you sure you want to continue connecting (yes/no/[fingerprint])?` y responde `yes` sin mirar. Esa respuesta es justo el momento en que un intermediario entraría en tu `known_hosts` para siempre ([teoría 03](../1-teoria/03-host-keys-y-known_hosts.md)).

Esta semana tu kit cierra esa puerta:

- **`config`**: `StrictHostKeyChecking yes` para que `ssh` no acepte por su cuenta ninguna llave desconocida ni cambiada, y `HashKnownHosts yes` para que `known_hosts` no revele a qué servidores entras.
- **`bin/kh-add HOST[:PUERTO] HUELLA`**: lee la host key del servidor con `ssh-keyscan`, compara su huella con la que obtuviste por un canal independiente y solo si coinciden la añade a `known_hosts`. La comparación la hace la máquina: no se salta un carácter.

## Estructura del proyecto

```
starter/                 ← aquí trabajas: tu ssh-infra-kit de la semana 01 + TODOs
├── README.md            ← documentación del kit (TODOs)
├── config               ← TODOs 1 y 2
└── bin/
    ├── lab-check        ← de la semana 01, terminado
    └── kh-add           ← TODOs 3 a 7
solucion/                ← referencia: no la abras hasta terminar
```

Si tu `lab-check` de la semana 01 es distinto del de `starter/`, copia el tuyo encima: el autograding solo exige que siga funcionando.

## Lo que debes construir

### `config`

En el bloque `Host *`, además del `ConnectTimeout 5` de la semana 01:

| Opción | Valor | Qué evita |
|---|---|---|
| `StrictHostKeyChecking` | `yes` | El `yes` a ciegas en la primera conexión y cualquier conexión con una llave cambiada |
| `HashKnownHosts` | `yes` | Que quien copie tu `known_hosts` obtenga la lista de tus servidores |

### `bin/kh-add HOST[:PUERTO] HUELLA`

| Situación | Salida | Código |
|---|---|---|
| Sin dos argumentos, o la huella no empieza por `SHA256:`, o el puerto no es un número | `uso: ...` por stderr | 2 |
| `ssh-keyscan` no obtiene llave (no resuelve, no conecta, no habla SSH) | `HOST: no se pudo leer la host key` por stderr | 3 |
| La huella recibida no es la esperada | `HOST: HUELLA DISTINTA, esperada ..., recibida ...` por stderr; **no escribe nada** | 1 |
| `known_hosts` ya tiene esta llave para el host | `HOST ya estaba` | 0 |
| `known_hosts` tiene **otra** llave del mismo tipo para el host | Aviso por stderr; no escribe nada | 1 |
| Todo bien | Añade la línea hasheada; `HOST añadida SHA256:...` | 0 |

Variables: `KH_FILE` (archivo destino, por defecto `~/.ssh/known_hosts`) y `KH_TYPE` (tipo de llave, por defecto `ed25519`). El autograding usa `KH_FILE` para no tocar tu `known_hosts`.

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d
docker compose run --rm client
```

Ya dentro del contenedor (el prompt dice `alumno@client`):

```bash
cd bootcamp/week-02-protocolo_kex_y_known_hosts/3-proyecto/starter
ls bin
```

```
kh-add  lab-check
```

La contraseña `alumno` que usarás en el paso 10 es **solo del laboratorio**.

### Paso 1 — Comprobar el punto de partida

```bash
ssh -G -F config host-cualquiera | grep -E '^(stricthostkeychecking|hashknownhosts) '
```

```
hashknownhosts no
stricthostkeychecking ask
```

Con `-F`, `ssh` lee solo ese archivo y no `/etc/ssh/ssh_config`: estos son los valores por defecto de OpenSSH. `ask` es el que pregunta `yes/no`.

### Paso 2 — TODO 1: `StrictHostKeyChecking yes`

En `config`, dentro de `Host *`, debajo de `ConnectTimeout 5`, sustituye el comentario del TODO 1 por la opción y su comentario Qué / Para qué / Impacto. Por ejemplo:

```
    # Qué: ssh nunca acepta por su cuenta una host key desconocida o cambiada.
    # Para qué: que las llaves entren en known_hosts solo verificadas, con
    #   bin/kh-add, y no con un "yes" escrito de memoria.
    # Impacto: el primer ssh a un host nuevo falla con "No ED25519 host key
    #   is known" hasta que lo añades; un cambio de llave corta siempre.
    StrictHostKeyChecking yes
```

```bash
ssh -G -F config host-cualquiera | grep '^stricthostkeychecking '
```

```
stricthostkeychecking true
```

`ssh -G` escribe `yes` como `true`. Ahora prueba a conectarte:

```bash
ssh -F config lab-server hostname; echo "código: $?"
```

```
No ED25519 host key is known for server and you have requested strict checking.
Host key verification failed.
código: 255
```

Ni siquiera pregunta. Para entrar, la llave tiene que estar ya en `known_hosts`: eso es lo que hará `kh-add`.

### Paso 3 — TODO 2: `HashKnownHosts yes`

Sustituye el comentario del TODO 2 por `HashKnownHosts yes`, con un comentario de una o dos líneas que diga para qué sirve (lab-06). Comprueba:

```bash
ssh -G -F config host-cualquiera | grep '^hashknownhosts '
```

```
hashknownhosts yes
```

### Paso 4 — `kh-add`, TODO 3: validar argumentos

Abre `bin/kh-add`. La cabecera ya documenta uso, variables y códigos de salida; la función `uso` imprime el mensaje por stderr y sale con 2.

Sustituye las dos líneas que siguen al TODO 3 por la validación y la separación de `HOST:PUERTO`:

```bash
[[ $# -eq 2 && $2 == SHA256:* ]] || uso
destino=$1 esperada=$2
host=${destino%%:*} puerto=22
[[ $destino == *:* ]] && puerto=${destino#*:}
[[ $puerto =~ ^[0-9]+$ ]] || uso
```

- `${destino%%:*}` quita desde el primer `:` hasta el final: `server:2200` → `server`.
- `${destino#*:}` quita hasta el primer `:`: `server:2200` → `2200`.
- `=~` compara con una expresión regular; `^[0-9]+$` exige solo dígitos.

```bash
bin/kh-add; echo "código: $?"
bin/kh-add server abc; echo "código: $?"
bin/kh-add server:ssh SHA256:x; echo "código: $?"
```

```
uso: kh-add HOST[:PUERTO] HUELLA   (HUELLA = SHA256:...)
código: 2
uso: kh-add HOST[:PUERTO] HUELLA   (HUELLA = SHA256:...)
código: 2
uso: kh-add HOST[:PUERTO] HUELLA   (HUELLA = SHA256:...)
código: 2
```

### Paso 5 — TODO 4: el nombre en `known_hosts`

En `known_hosts` un host en el puerto 22 se guarda como `server`, y en cualquier otro como `[server]:2200` (lab-06). `kh-add` necesita ese nombre para buscar si el host ya está:

```bash
nombre=$host
(( puerto == 22 )) || nombre="[$host]:$puerto"
```

`(( ))` evalúa aritmética; si `puerto == 22` es falso, `||` ejecuta la asignación.

### Paso 6 — TODO 5, primera parte: leer la llave

```bash
linea=$(ssh-keyscan -H -T 5 -p "$puerto" -t "$KH_TYPE" "$host" 2>/dev/null) || true
[[ -n $linea ]] || { echo "$destino: no se pudo leer la host key" >&2; exit 3; }
llave=${linea#* }
```

- `-H` devuelve la línea con el nombre ya hasheado, lista para `known_hosts`.
- `-T 5`: espera como máximo 5 s.
- `2>/dev/null` descarta los comentarios `# server:22 SSH-2.0-...` que `ssh-keyscan` escribe por stderr.
- `|| true`: si `ssh-keyscan` falla, `set -e` no corta el script; lo decide la línea siguiente con su propio mensaje.
- `${linea#* }` quita el nombre (hasta el primer espacio) y deja `ssh-ed25519 AAAA...`.

```bash
bin/kh-add interno SHA256:x; echo "código: $?"
```

```
interno: no se pudo leer la host key
código: 3
```

`interno` no resuelve desde `client` (semana 01, lab-01).

### Paso 7 — TODO 5, segunda parte: comparar huellas

```bash
recibida=$(ssh-keygen -lf - <<<"$linea" | cut -d' ' -f2)

if [[ $recibida != "$esperada" ]]; then
  echo "$destino: HUELLA DISTINTA, esperada $esperada, recibida $recibida" >&2
  exit 1
fi
```

`ssh-keygen -lf -` calcula la huella de la llave que le llega por stdin (`<<<` pasa una variable como stdin). `cut -f2` se queda con el campo `SHA256:...`.

Consigue la huella **por el canal independiente**. **En tu equipo**, en otra terminal:

```bash
docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

```
256 SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M root@server (ED25519)
```

Tu huella será otra: cada contenedor genera sus llaves al arrancar. **En el cliente**, prueba con la de `server` contra `bastion`, que debe fallar:

```bash
bin/kh-add bastion SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M; echo "código: $?"
```

```
bastion: HUELLA DISTINTA, esperada SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M, recibida SHA256:APuRI98Go93EXpf/RLO5tvZwGBrUxotQ6FP/EOy8L1o
código: 1
```

Es exactamente lo que vería quien tuviera un intermediario delante de `bastion`.

### Paso 8 — TODO 6: ¿ya estaba?

```bash
if conocidas=$(ssh-keygen -F "$nombre" -f "$KH_FILE" 2>/dev/null); then
  if grep -qF "$llave" <<<"$conocidas"; then
    echo "$destino ya estaba"
    exit 0
  fi
  if grep -q " ${llave%% *} " <<<"$conocidas"; then
    echo "$destino: known_hosts ya tiene otra llave ${llave%% *}; verifica y usa ssh-keygen -R $nombre" >&2
    exit 1
  fi
fi
```

- `ssh-keygen -F` sale con 0 si encuentra el host, también en líneas hasheadas, y con otro código si no está o el archivo no existe.
- `grep -qF`: busca el texto literal (`-F`), sin imprimir (`-q`).
- `${llave%% *}` es el tipo (`ssh-ed25519`). Si hay otra llave del mismo tipo, es el caso "host key cambiada" del lab-07: **no se sobrescribe**, lo decide una persona.

### Paso 9 — TODO 7: escribir

Borra las dos últimas líneas del starter (`echo "$destino ? ..."` y `exit 1`) y escribe:

```bash
(umask 077; mkdir -p "$(dirname "$KH_FILE")")
echo "$linea" >> "$KH_FILE"
echo "$destino añadida $recibida"
```

`umask 077` dentro de `( )` (una subshell) hace que los directorios que cree `mkdir -p` sean solo para ti (`700`) sin cambiar la umask del resto del script. En un contenedor nuevo, `~/.ssh` no existe.

```bash
bin/kh-add server SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M; echo "código: $?"
bin/kh-add server SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M; echo "código: $?"
ls -ld ~/.ssh
```

```
server añadida SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M
código: 0
server ya estaba
código: 0
drwx------ 2 alumno alumno 4096 Nov  8 04:51 /home/alumno/.ssh
```

Usa tu huella, no la del ejemplo.

### Paso 10 — Probar con `ssh`

```bash
ssh -F config lab-server hostname
```

```
alumno@server's password:
server
```

Ya no hay pregunta `yes/no`: la llave entró verificada. Contraseña `alumno` (**solo laboratorio**).

### Paso 11 — Calidad, README y git

```bash
grep -n TODO bin/* config; shellcheck bin/* && echo limpio
```

```
limpio
```

Completa los TODOs de `README.md`: la fila de `kh-add` y la bitácora de la semana 02. Después lleva los cambios a tu kit. En **tu equipo**, desde la raíz de bc-ssh:

```bash
cp -r bootcamp/week-02-protocolo_kex_y_known_hosts/3-proyecto/starter/. ~/ssh-infra-kit/
cd ~/ssh-infra-kit
git add .
git commit -m "feat: known_hosts verificado con kh-add"
```

`starter/.` copia el **contenido** de `starter/` encima del kit, no la carpeta.

### Paso 12 — Autograding

En tu equipo, desde la raíz de bc-ssh:

```bash
./scripts/verificar-semana.sh 02
```

```
Semana 02 — Protocolo por dentro: KEX, host keys y known_hosts

  ✅ config carga sin errores con ssh -G
  ...
19/19 comprobaciones superadas.
```

Si alguna falla, su `pista` dice qué paso revisar.

## ✅ Requisitos verificables

- config carga sin errores con ssh -G
- El alias lab-server de la semana 01 sigue apuntando a server
- StrictHostKeyChecking yes aplica a cualquier host
- HashKnownHosts yes aplica a cualquier host
- config no desactiva la verificación de host keys
- kh-add sin argumentos sale con 2
- kh-add con una huella que no empieza por SHA256: sale con 2
- Con la huella correcta añade la llave e informa la huella
- La línea añadida lleva el nombre hasheado
- Crea el directorio de known_hosts con permisos 700
- Tras kh-add, ssh con el config del kit entra sin preguntar
- Ejecutarlo dos veces no duplica la línea
- Con la huella de otro host sale con 1
- Con una huella distinta no escribe nada
- Si known_hosts ya tiene otra llave del mismo tipo, sale con 1
- Con HOST:PUERTO usa [host]:puerto y no duplica
- Un host que no responde sale con 3
- lab-check de la semana 01 sigue funcionando
- bin/ sin TODOs y limpio para shellcheck

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): README del kit, mensajes de error, comentarios que explican el porqué y el historial de git.

## Entrega

- [ ] `./scripts/verificar-semana.sh 02` con las 19 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Políticas de verificación](../2-practicas/lab-07-politicas-de-verificacion/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 02](../README.md)
