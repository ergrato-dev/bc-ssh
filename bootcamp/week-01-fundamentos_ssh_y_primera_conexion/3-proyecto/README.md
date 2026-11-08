# Proyecto Semana 01 — ssh-infra-kit: config y lab-check

⏱ Duración estimada: ~3 h

## Contexto

Entras en un equipo que administra servidores Linux. Cada mañana alguien pregunta "¿está caído `server` o es mi red?", y la respuesta suele llegar tras diez minutos de probar `ssh` a mano y mirar mensajes de error que no dicen qué capa falló.

Empiezas tu **`ssh-infra-kit`**, el kit que irás ampliando todo el bootcamp ([docs/proyecto-hilo-conductor.md](../../../docs/proyecto-hilo-conductor.md)), con dos piezas:

- **`config`**: alias para los hosts del laboratorio, para no escribir usuario y host en cada comando.
- **`bin/lab-check`**: dice, host por host, si el problema está en el nombre (DNS), en el puerto (TCP) o en el servicio (banner SSH). **Nunca se autentica**: no necesita contraseña ni llave.

## Estructura del proyecto

```
starter/                 ← aquí trabajas: es tu ssh-infra-kit (lo corrige el autograding)
├── README.md            ← documentación del kit (TODOs)
├── config               ← TODOs
└── bin/
    └── lab-check        ← TODOs
solucion/                ← referencia: no la abras hasta terminar
```

## Lo que debes construir

### `config`

| Alias | `HostName` | `User` |
|---|---|---|
| `lab-server` | `server` | `alumno` |
| `lab-bastion` | `bastion` | `alumno` |

Y para **todos** los hosts, `ConnectTimeout 5`.

### `bin/lab-check HOST[:PUERTO]...`

Comprueba cada destino por capas, de abajo arriba, y se detiene en la primera que falla:

| Capa | Cómo se comprueba | Línea si falla |
|---|---|---|
| DNS | `getent hosts HOST` | `HOST fallo dns` |
| TCP | `nc -z -w 3 HOST PUERTO` | `HOST:PUERTO fallo tcp` |
| Banner | La primera línea que envía el servidor empieza por `SSH-2.0-` | `HOST:PUERTO fallo banner` |

Si las tres pasan imprime `DESTINO ok BANNER`. Sale con **0** si todos los destinos están bien, **1** si falla al menos uno y **2** si no recibe ningún destino. Revisa **todos** los destinos aunque uno falle.

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d
docker compose run --rm client
```

Ya dentro del contenedor (el prompt dice `alumno@client`):

```bash
cd bootcamp/week-01-fundamentos_ssh_y_primera_conexion/3-proyecto/starter
ls
```

```
README.md  bin  config
```

### Paso 1 — `config`: comprobar que carga

`ssh -G` imprime la configuración **final** que usaría `ssh` para un host, sin conectarse. Es la forma de probar un `config` sin depender de la red:

```bash
ssh -G -F config lab-server | grep -E '^(hostname|user|port) '
```

```
user alumno
hostname lab-server
port 22
```

**Qué ves:** sin ningún bloque, `lab-server` se toma como nombre real del host y el usuario es el tuyo (`alumno`, por casualidad el mismo). **Para qué sirve:** cada cambio que hagas en `config` lo compruebas con este comando antes de conectar.

### Paso 2 — TODO 1: el alias `lab-server`

Abre `config` con tu editor (`nano config`). Debajo de `TODO 1` escribe:

```
Host lab-server
    HostName server
    User alumno
```

- `Host lab-server`: el bloque se aplica cuando escribes `ssh lab-server`.
- `HostName server`: el nombre real al que se conecta.
- `User alumno`: el usuario remoto, como si escribieras `alumno@`.

La sangría no es obligatoria, pero deja claro qué opciones son del bloque. Comprueba:

```bash
ssh -G -F config lab-server | grep -E '^(hostname|user) '
```

```
user alumno
hostname server
```

### Paso 3 — TODO 2: el alias `lab-bastion`

Igual que el anterior, debajo de `TODO 2`:

```
Host lab-bastion
    HostName bastion
    User alumno
```

```bash
ssh -G -F config lab-bastion | grep '^hostname '
```

```
hostname bastion
```

### Paso 4 — TODO 3: `ConnectTimeout` para todos

Debajo de `TODO 3`, **al final del archivo**:

```
Host *
    ConnectTimeout 5
```

**Qué:** `Host *` casa con cualquier nombre. **Para qué:** que un host que no responde falle a los 5 s en vez de dejarte esperando el timeout de TCP del sistema (unos 2 minutos). **Impacto:** `ssh` usa el **primer** valor que encuentra para cada opción; si `Host *` fuera arriba, sus valores ganarían a los de los bloques concretos. Por eso los valores por defecto van al final.

```bash
ssh -G -F config host-cualquiera | grep '^connecttimeout '
```

```
connecttimeout 5
```

### Paso 5 — Conectar con el alias

```bash
ssh -F config lab-server hostname
```

La primera vez pregunta por la huella del servidor (lab-02 explica cómo verificarla). Escribe `yes`, y como contraseña `alumno` (**contraseña débil a propósito: solo existe en el laboratorio**).

```
alumno@server's password:
server
```

`hostname` se ejecutó **en `server`** y su salida llegó a tu terminal.

### Paso 6 — `lab-check`, TODO 1: sin argumentos

Abre `bin/lab-check`. Debajo de `TODO 1` escribe:

```bash
if (( $# == 0 )); then
  echo "uso: lab-check HOST[:PUERTO]..." >&2
  exit 2
fi
```

`$#` es el número de argumentos. `>&2` manda el mensaje a stderr: así no se mezcla con la salida que otro script podría leer. Prueba:

```bash
bin/lab-check; echo "código: $?"
```

```
uso: lab-check HOST[:PUERTO]...
código: 2
```

### Paso 7 — TODO 2: capa DNS

Borra la línea `echo "$destino ?"` y, en el lugar de los TODOs 2 a 4, empieza una cadena `if`/`elif`:

```bash
  if ! getent hosts "$host" >/dev/null; then
    echo "$destino fallo dns"
```

`getent hosts` pregunta al sistema la IP de un nombre, igual que haría `ssh`. Sale con 2 si el nombre no existe. Desde `client`, `interno` no resuelve: está en otra red (lo verás en el lab-01).

### Paso 8 — TODO 3: capa TCP

Sigue la cadena:

```bash
  elif ! nc -z -w "$TIMEOUT" "$host" "$puerto" 2>/dev/null; then
    echo "$destino fallo tcp"
```

`nc -z` abre la conexión TCP y la cierra sin enviar nada; `-w` limita la espera. En `server` no escucha nadie en el puerto 2222.

### Paso 9 — TODO 4: capa banner

Lo primero que hace un servidor SSH al aceptar una conexión es enviar una línea como `SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20`, terminada en `\r\n`. `leer_banner` ya la lee por ti. Completa la cadena:

```bash
  elif banner=$(leer_banner "$host" "$puerto") && [[ "$banner" == SSH-2.0-* ]]; then
    echo "$destino ok ${banner%$'\r'}"
    continue
  else
    echo "$destino fallo banner"
  fi
```

`${banner%$'\r'}` quita el `\r` final, que si no se imprimiría como un carácter invisible. `continue` salta al siguiente destino sin contar fallo. Prueba:

```bash
bin/lab-check server interno server:2222
```

```
server ok SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
interno fallo dns
server:2222 fallo tcp
```

### Paso 10 — TODOs 5 y 6: contar fallos y salir

Después del `fi` (cualquier rama que no hizo `continue` es un fallo):

```bash
  fallos=$(( fallos + 1 ))
```

Y al final del archivo, sustituye `exit 1` por:

```bash
(( fallos == 0 ))
```

`(( ))` sale con 0 si la expresión es verdadera y con 1 si es falsa: es el código de salida del script. Prueba los dos casos:

```bash
bin/lab-check server bastion; echo "código: $?"
bin/lab-check server interno; echo "código: $?"
```

```
server ok SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
bastion ok SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
código: 0
server ok SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
interno fallo dns
código: 1
```

### Paso 11 — Calidad y README

```bash
grep -n TODO bin/lab-check config; shellcheck bin/lab-check && echo limpio
```

```
limpio
```

`grep` no imprime nada (no quedan TODOs) y `shellcheck` no encuentra problemas. Completa los TODOs de `README.md` con tus palabras: qué hace cada archivo y la bitácora de la semana.

Por último, versiona tu kit fuera de este repositorio. En **tu equipo** (no en el contenedor), desde la raíz de bc-ssh:

```bash
cp -r bootcamp/week-01-fundamentos_ssh_y_primera_conexion/3-proyecto/starter ~/ssh-infra-kit
cd ~/ssh-infra-kit
git init
git add .
git commit -m "feat: config de laboratorio y lab-check"
```

### Paso 12 — Autograding

En tu equipo, desde la raíz de bc-ssh:

```bash
./scripts/verificar-semana.sh 01
```

```
Semana 01 — Fundamentos de SSH y primera conexión

  ✅ config carga sin errores con ssh -G
  ...
16/16 comprobaciones superadas.
```

Si alguna falla, su `pista` dice qué paso revisar.

## ✅ Requisitos verificables

- config carga sin errores con ssh -G
- El alias lab-server apunta al host server
- El bloque lab-server fija User alumno
- El alias lab-bastion apunta al host bastion
- ConnectTimeout 5 aplica a cualquier host, también a uno sin alias
- config no desactiva la verificación de host keys
- ssh lab-server con este config entra en server
- lab-check sin argumentos sale con 2
- lab-check server sale con 0
- Para un host sano, lab-check imprime ok y el banner del servidor
- Un host que no resuelve se informa como fallo dns
- Un puerto cerrado se informa como fallo tcp
- Un puerto abierto que no habla SSH se informa como fallo banner
- lab-check sale con 1 si falla al menos un host
- lab-check revisa todos los hosts aunque uno falle
- Los scripts de bin/ no tienen TODOs y pasan shellcheck

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): README del kit, mensajes de error, comentarios que explican el porqué y el historial de git.

## Entrega

- [ ] `./scripts/verificar-semana.sh 01` con las 16 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` versionado con git, con al menos un commit

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — `~/.ssh/config` y precedencia](../2-practicas/lab-07-config-y-precedencia/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 01](../README.md)
