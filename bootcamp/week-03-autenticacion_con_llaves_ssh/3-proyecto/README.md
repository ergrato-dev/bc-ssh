# Proyecto Semana 03 — ssh-infra-kit: llaves propias y authorized_keys restringido

⏱ Duración estimada: ~3 h

## Contexto

Hasta ahora tu kit entra en `lab-server` con la contraseña `alumno`. Esta semana deja de necesitarla ([teoría 01](../1-teoria/01-autenticacion-con-llave-publica.md)) y aprende a dar acceso limitado a otras llaves ([teoría 03](../1-teoria/03-authorized_keys-y-opciones.md)):

- **`config`**: cada host del laboratorio usa la llave `~/.ssh/lab` (`IdentityFile`) y todos los hosts ofrecen solo la llave que les toca (`IdentitiesOnly yes`).
- **`bin/key-new NOMBRE`**: crea un par Ed25519 siempre igual de bien hecho: frase de paso, 100 rondas de bcrypt, un comentario que dice de quién es y desde cuándo, y permisos correctos. Nunca pisa una llave que ya existe.
- **`bin/ak-line LLAVE.pub`**: escribe la línea de `authorized_keys` de una llave **empezando por `restrict`** y añadiendo solo lo que pidas: terminal, origen, comando forzado o caducidad. Rechaza una llave privada.

## Estructura del proyecto

```
starter/                 ← aquí trabajas: tu ssh-infra-kit de la semana 02 + TODOs
├── README.md            ← documentación del kit (TODOs)
├── config               ← TODOs 1 y 2
└── bin/
    ├── lab-check        ← de la semana 01, terminado
    ├── kh-add           ← de la semana 02, terminado
    ├── key-new          ← TODOs 3 a 5
    └── ak-line          ← TODOs 6 y 7
solucion/                ← referencia: no la abras hasta terminar
```

## Lo que debes construir

### `config`

| Bloque | Opción nueva | Por qué |
|---|---|---|
| `lab-server` y `lab-bastion` | `IdentityFile ~/.ssh/lab` | Saber siempre qué llave usa cada host |
| `Host *` | `IdentitiesOnly yes` | No ofrecer a un servidor llaves que no son suyas |

### `bin/key-new NOMBRE [COMENTARIO]`

| Situación | Salida | Código |
|---|---|---|
| Sin argumentos, o más de 2 | `uso: key-new NOMBRE [COMENTARIO]` (stderr) | 2 |
| Nombre con `/`, espacios o que empieza por `.` | `key-new: nombre no válido: ...` (stderr) | 2 |
| Ya existe `NOMBRE` o `NOMBRE.pub` | `key-new: ... ya existe; no se sobrescribe` (stderr) | 1 |
| Creada | `RUTA creada` y la huella | 0 |

`KEY_DIR` cambia el directorio (`~/.ssh` por defecto) y `KEY_PASSPHRASE` da la frase sin preguntar (para scripts y para el autograding).

### `bin/ak-line [-t] [-f ORIGEN] [-c COMANDO] [-e AAAAMMDD] LLAVE.pub`

| Situación | Salida | Código |
|---|---|---|
| Sin archivo, opción desconocida, comillas en un valor, fecha mal escrita | `uso: ...` (stderr) | 2 |
| El archivo es una llave privada | `ak-line: ... es una llave PRIVADA; usa el .pub` (stderr) | 1 |
| El archivo no es una llave | `ak-line: ... no es una llave pública` (stderr) | 1 |
| Correcto | `restrict[,pty][,from="..."][,command="..."][,expiry-time="..."] TIPO LLAVE COMENTARIO` | 0 |

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d
docker compose run --rm client
```

Ya dentro del contenedor (el prompt dice `alumno@client`):

```bash
cd bootcamp/week-03-autenticacion_con_llaves_ssh/3-proyecto/starter
ls bin
```

```
ak-line  key-new  kh-add  lab-check
```

- La contraseña `alumno` que usarás en el paso 6 es **solo del laboratorio**.
- El cliente es un contenedor nuevo cada vez: `~/.ssh` (tus llaves y tu `known_hosts`) desaparece al salir con `exit`. Haz los pasos 6 a 9 en la misma sesión. En tu equipo real, las llaves se quedan.

### Paso 1 — TODO 1: `IdentityFile`

Mira primero qué llaves probaría `ssh` ahora:

```bash
ssh -G -F config lab-server | grep -E '^identit'
```

```
identitiesonly no
identityfile ~/.ssh/id_rsa
identityfile ~/.ssh/id_ecdsa
identityfile ~/.ssh/id_ecdsa_sk
identityfile ~/.ssh/id_ed25519
identityfile ~/.ssh/id_ed25519_sk
identityfile ~/.ssh/id_xmss
identityfile ~/.ssh/id_dsa
```

Es la lista por defecto. Abre `config` con `nano config` y, en `lab-server` y `lab-bastion`, añade:

```
    IdentityFile ~/.ssh/lab
```

Escribe **un** comentario Qué / Para qué / Impacto encima de `Host lab-server` (sirve para los dos bloques). Comprueba:

```bash
ssh -G -F config lab-server | grep -E '^identityfile'
```

```
identityfile ~/.ssh/lab
```

Con un `IdentityFile` explícito, la lista por defecto desaparece. Escribe `~` y no `/home/alumno`: `ssh` lo expande al usuario que lo ejecuta, y el kit sirve igual en tu equipo.

### Paso 2 — TODO 2: `IdentitiesOnly yes`

`IdentityFile` decide qué llaves **de archivo** se prueban; las del agente (semana 04) se ofrecerían igual, todas. En `Host *`, en el TODO 2:

```
    IdentitiesOnly yes
```

con su comentario. Comprueba:

```bash
ssh -G -F config host-cualquiera | grep -E '^identitiesonly'
```

```
identitiesonly yes
```

Qué ganas lo viste en el [lab 05](../2-practicas/lab-05-varias-llaves/README.md): un servidor corta tras 6 llaves rechazadas, y cada llave que ofreces le dice quién eres.

### Paso 3 — `key-new`, TODO 3: validar argumentos

Abre `bin/key-new`. Lee la cabecera: es el contrato. En el TODO 3:

```bash
if (( $# < 1 || $# > 2 )); then
  echo "uso: key-new NOMBRE [COMENTARIO]" >&2
  exit 2
fi

nombre="$1"
if [[ ! "$nombre" =~ ^[A-Za-z0-9._-]+$ || "$nombre" == .* ]]; then
  echo "key-new: nombre no válido: $nombre (usa letras, números, . _ -)" >&2
  exit 2
fi
```

y borra la línea `nombre="${1:-}"` de arriba.

- `=~` compara con una expresión regular: solo letras, números, `.`, `_` y `-`. Sin `/`, nadie escribe fuera de `KEY_DIR` con `key-new ../../algo`.
- `"$nombre" == .*` rechaza nombres que empiezan por punto (`..`, `.oculta`).

```bash
bin/key-new; echo "código: $?"
bin/key-new ../fuera; echo "código: $?"
```

```
uso: key-new NOMBRE [COMENTARIO]
código: 2
key-new: nombre no válido: ../fuera (usa letras, números, . _ -)
código: 2
```

### Paso 4 — TODO 4: no sobrescribir

`ssh-keygen` pregunta `Overwrite (y/n)?` si el archivo existe. Un `y` por inercia destruye una llave que quizá era tu único acceso a un servidor. El kit no pregunta: se niega. En el TODO 4:

```bash
if [[ -e "$llave" || -e "$llave.pub" ]]; then
  echo "key-new: $llave ya existe; no se sobrescribe" >&2
  exit 1
fi
```

`-e` es verdadero si la ruta existe, sea lo que sea. Se comprueban los dos archivos: un `.pub` suelto también indica que ese nombre ya se usó.

### Paso 5 — TODO 5: generar la llave

En el TODO 5, cambia `opciones=()` por:

```bash
opciones=(-q -t ed25519 -a 100 -C "$comentario" -f "$llave")
if [[ -v KEY_PASSPHRASE ]]; then
  opciones+=(-N "$KEY_PASSPHRASE")
  [[ -z "$KEY_PASSPHRASE" ]] && echo "key-new: aviso: llave sin frase de paso" >&2
fi
```

Sustituye el TODO por un comentario que explique el `-a 100` ([teoría 02](../1-teoria/02-tipos-de-llave-y-frase-de-paso.md#rondas-de-bcrypt)).

- `opciones=(...)` es un array: cada elemento llega a `ssh-keygen` como un argumento, aunque el comentario tenga espacios. `"${opciones[@]}"` lo expande así.
- `[[ -v VAR ]]` es verdadero si la variable está **definida**, aunque esté vacía: `KEY_PASSPHRASE=` pide expresamente una llave sin frase (para un script), y se avisa.
- Sin `KEY_PASSPHRASE`, no hay `-N` y `ssh-keygen` pregunta la frase por teclado.

Pruébalo en un directorio temporal:

```bash
KEY_DIR=/tmp/prueba KEY_PASSPHRASE=x bin/key-new demo
ls -l /tmp/prueba
```

```
/tmp/prueba/demo creada
256 SHA256:jZxQvyxhjgpeXKUUb1gz1I7YdfiePi+R4AAETpMmBdc alumno@client-2026-11-08 (ED25519)
total 8
-rw------- 1 alumno alumno 464 Nov  8 05:19 demo
-rw-r--r-- 1 alumno alumno 106 Nov  8 05:19 demo.pub
```

El directorio lo creó con `umask 077` (700) y `ssh-keygen` deja la privada en 600. Bórralo: `rm -r /tmp/prueba`.

### Paso 6 — Tu llave del laboratorio

Primero, `known_hosts`: tu `config` tiene `StrictHostKeyChecking yes` (semana 02). **En tu equipo**, lee la huella del servidor:

```bash
docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

**En el cliente**, con esa huella:

```bash
bin/kh-add server SHA256:...
bin/key-new lab
```

```
server añadida SHA256:GiOO/MygF0Rrs+8btbv8PAxfRi9aDhaYQwNyfIza69M
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
/home/alumno/.ssh/lab creada
256 SHA256:OgXYklFF1z4l9xn27tSpkW9ToOvKqTVEd1DBbP/JnlY alumno@client-2026-11-08 (ED25519)
```

Elige una frase que recuerdes durante esta sesión. Instala la pública en el servidor:

```bash
ssh-copy-id -F config -i ~/.ssh/lab.pub lab-server
```

```
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/alumno/.ssh/lab.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
alumno@server's password:

Number of key(s) added: 1
```

La contraseña `alumno` (**solo laboratorio**) es la última vez que la escribes para `lab-server`. Entra:

```bash
ssh -F config lab-server hostname
```

```
Enter passphrase for key '/home/alumno/.ssh/lab':
server
```

Ahora pide la **frase de tu llave**, que nunca sale de tu equipo, y no la contraseña del servidor. En la semana 04, `ssh-agent` la pedirá una sola vez por sesión.

### Paso 7 — `ak-line`, TODO 6: las opciones

Abre `bin/ak-line`. El bucle `while getopts ':tf:c:e:' op` ya está escrito: `getopts` lee una opción en cada vuelta, la deja en `op` y su valor en `OPTARG`. En la cadena, `f:` significa "`-f` lleva valor" y `t` sin `:` que no. El `:` inicial hace que una opción desconocida llegue como `?` en lugar de un error de bash. La comprobación de comillas también está: un `"` en un valor cerraría las comillas de `authorized_keys`.

Completa el TODO 6 dentro del `case`, antes de `*) uso ;;`:

```bash
    t) opciones+=",pty" ;;
    f) opciones+=",from=\"$OPTARG\"" ;;
    c) opciones+=",command=\"$OPTARG\"" ;;
    e) [[ "$OPTARG" =~ ^[0-9]{8}$ ]] || { echo "ak-line: fecha no válida: $OPTARG (AAAAMMDD)" >&2; uso; }
       opciones+=",expiry-time=\"$OPTARG\"" ;;
```

`\"` escribe una comilla literal dentro de una cadena entre comillas dobles. Prueba con una llave temporal:

```bash
ssh-keygen -q -t ed25519 -N '' -C prueba -f /tmp/k
bin/ak-line /tmp/k.pub | cut -c1-50
bin/ak-line -f 172.16.0.0/12 -c uptime -e 20991231 /tmp/k.pub | cut -d' ' -f1
bin/ak-line -e 2099-12-31 /tmp/k.pub; echo "código: $?"
```

```
restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIzZ
restrict,from="172.16.0.0/12",command="uptime",expiry-time="20991231"
ak-line: fecha no válida: 2099-12-31 (AAAAMMDD)
uso: ak-line [-t] [-f ORIGEN] [-c COMANDO] [-e AAAAMMDD] LLAVE.pub
código: 2
```

`cut -d' ' -f1` muestra solo el primer campo: las opciones. Sin espacios entre ellas, porque un espacio separa las opciones del tipo de llave.

### Paso 8 — TODO 7: rechazar la llave privada

```bash
ssh-keygen -lf /tmp/k
```

```
256 SHA256:fxmXVVflXPMuqyLvtINQXw+MRKjAmGh6R/oaDvI7y8c prueba (ED25519)
```

`ssh-keygen -l` acepta también la **privada** (calcula la pública a partir de ella), así que esa comprobación no basta. Si alguien pega su privada en un servidor, cualquiera con acceso a ese archivo la tiene. En el TODO 7:

```bash
if grep -q 'PRIVATE KEY' "$archivo" 2>/dev/null; then
  echo "ak-line: $archivo es una llave PRIVADA; usa el .pub" >&2
  exit 1
fi
```

Toda privada en formato OpenSSH empieza por `-----BEGIN OPENSSH PRIVATE KEY-----`, y las antiguas por `-----BEGIN RSA PRIVATE KEY-----`.

```bash
bin/ak-line /tmp/k; echo "código: $?"
bin/ak-line /etc/hostname; echo "código: $?"
```

```
ak-line: /tmp/k es una llave PRIVADA; usa el .pub
código: 1
ak-line: /etc/hostname no es una llave pública
código: 1
```

### Paso 9 — Probar en el servidor

Una llave que solo puede ejecutar `uptime`: el tipo de llave que darías a un sistema de monitorización.

```bash
bin/ak-line -c uptime /tmp/k.pub | ssh -F config lab-server 'cat >> ~/.ssh/authorized_keys'
ssh -F /dev/null -o IdentitiesOnly=yes -i /tmp/k server 'rm -rf ~'
```

```
 05:21:37 up  1:27,  0 user,  load average: 1.04, 1.08, 1.17
```

- `ssh ... 'cat >> ~/.ssh/authorized_keys'` añade al final lo que llega por stdin (el `|`). Entra con tu llave `lab`: pedirá su frase.
- `-F /dev/null` no lee ningún config, para probar solo la llave `/tmp/k`; el `known_hosts` es el que llenó `kh-add`.
- Pediste `rm -rf ~` y el servidor ejecutó `uptime`: `command=` manda. El comando pedido no se pierde: llega al servidor en la variable `SSH_ORIGINAL_COMMAND` ([lab 06](../2-practicas/lab-06-opciones-de-authorized-keys/README.md)).

Quita esa línea antes de seguir. `grep -v` deja pasar todas las líneas **menos** las que contienen el texto:

```bash
ssh -F config lab-server 'grep -v "prueba$" ~/.ssh/authorized_keys > ~/ak && mv ~/ak ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
ssh -F config lab-server 'ssh-keygen -lf ~/.ssh/authorized_keys'
```

```
256 SHA256:OgXYklFF1z4l9xn27tSpkW9ToOvKqTVEd1DBbP/JnlY alumno@client-2026-11-08 (ED25519)
```

Queda solo tu llave `lab` (más las de los labs, si las instalaste en este mismo `server`). El comentario `prueba` es lo que te permitió elegir qué borrar: por eso `key-new` pone siempre uno con sentido.

### Paso 10 — Calidad, README y git

```bash
grep -n TODO bin/* config; shellcheck bin/* && echo limpio
```

```
limpio
```

Completa los TODOs de `README.md`: las filas de `key-new` y `ak-line` y la bitácora de la semana 03. Después lleva los cambios a tu kit. En **tu equipo**, desde la raíz de bc-ssh:

```bash
cp -r bootcamp/week-03-autenticacion_con_llaves_ssh/3-proyecto/starter/. ~/ssh-infra-kit/
cd ~/ssh-infra-kit
git add .
git status --short
git commit -m "feat: llaves propias con key-new y authorized_keys restringido con ak-line"
```

`git status --short` antes del commit: comprueba que no aparece ninguna llave. El kit contiene **scripts que crean llaves**, nunca llaves: las llaves viven en `~/.ssh`, fuera del repositorio.

### Paso 11 — Autograding

En tu equipo, desde la raíz de bc-ssh:

```bash
./scripts/verificar-semana.sh 03
```

```
Semana 03 — Autenticación con llaves

  ✅ El config se lee sin errores
  ...
26/26 comprobaciones superadas.
```

Las tres últimas pruebas de `ak-line` arrancan un `sshd` propio dentro del cliente (puerto 2203, con un `authorized_keys` temporal) y comprueban que tus líneas funcionan en un servidor real. Si alguna falla, su `pista` dice qué paso revisar.

## ✅ Requisitos verificables

- El config se lee sin errores
- Siguen las opciones de la semana 02 (StrictHostKeyChecking yes)
- lab-server usa la llave ~/.ssh/lab
- lab-bastion usa la llave ~/.ssh/lab
- Todos los hosts ofrecen solo sus IdentityFile
- key-new sin argumentos sale con 2
- key-new rechaza un nombre con ../
- key-new no pisa una llave existente (sale con 1)
- key-new crea la llave e imprime su huella
- La llave creada es Ed25519
- Privada 600 y directorio 700
- Con frase de paso, la privada no se abre sin ella
- Con la frase correcta, la privada se abre
- El comentario por defecto es usuario@equipo-fecha
- ak-line sin argumentos sale con 2
- Sin opciones, la línea empieza por restrict
- -t -f -c -e se escriben como pty, from, command y expiry-time
- ak-line rechaza comillas en un valor (sale con 2)
- ak-line rechaza una fecha que no es AAAAMMDD
- ak-line rechaza una llave privada (sale con 1)
- ak-line rechaza un archivo que no es una llave
- Un sshd real ejecuta el comando forzado, pidas lo que pidas
- Sin -t, sshd niega la terminal
- Con -f de otra red, sshd rechaza la llave
- kh-add de la semana 02 sigue en el kit
- Sin TODO y shellcheck sin avisos en bin/

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): README del kit, mensajes de error, comentarios que explican el porqué y el historial de git sin ninguna llave.

## Entrega

- [ ] `./scripts/verificar-semana.sh 03` con las 26 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ninguna llave en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Rotar una llave](../2-practicas/lab-07-rotar-una-llave/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 03](../README.md)
