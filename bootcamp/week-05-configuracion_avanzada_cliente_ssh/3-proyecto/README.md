# Proyecto Semana 05 — ssh-infra-kit: `conf.d/`, perfiles y multiplexing

⏱ Duración estimada: ~3 h

## Contexto

Tu `config` ya tiene seis semanas de opciones y dos alias. Esta semana lo preparas para crecer: los hosts pasan a archivos de `conf.d/` ([teoría 02](../1-teoria/02-include-match-y-perfiles.md)), las conexiones repetidas se reutilizan ([teoría 03](../1-teoria/03-multiplexing.md)), y un perfil deja saltarse esa reutilización cuando hace falta:

- **`config`**: solo valores por defecto. Incluye `conf.d/*.conf` a través de `~/.ssh/kit` y activa el multiplexing para todos los hosts.
- **`conf.d/10-lab.conf`**: los alias del laboratorio, que salen de `config`.
- **`conf.d/00-perfiles.conf`**: el perfil `sinmux` (`ssh -P sinmux`).
- **`bin/kit-link`**: crea el enlace `~/.ssh/kit` que necesita el `Include` y la carpeta `~/.ssh/cm` de los sockets. Lo que hiciste a mano en el [lab 03](../2-practicas/lab-03-include-y-conf-d/README.md) y el [lab 06](../2-practicas/lab-06-multiplexing/README.md).
- **`bin/mux`**: lista y cierra los masters, para después de cambiar llaves ([lab 07](../2-practicas/lab-07-lo-que-decide-el-master/README.md)).

## Estructura del proyecto

```
starter/                    ← aquí trabajas: tu ssh-infra-kit de la semana 04 + TODOs
├── README.md               ← documentación del kit (TODOs)
├── config                  ← TODOs 1 y 2
├── conf.d/
│   └── 00-perfiles.conf    ← TODO 3 (10-lab.conf lo creas tú)
└── bin/
    ├── lab-check, kh-add, ak-line, key-new, agent-up   ← semanas 01-04, terminados
    ├── kit-link            ← TODOs 4 y 5
    └── mux                 ← TODO 6
solucion/                   ← referencia: no la abras hasta terminar
```

## Lo que debes construir

### `config` y `conf.d/`

| Archivo | Contenido | Por qué |
|---|---|---|
| `config` | `Include kit/conf.d/*.conf` arriba y `Host *` al final | Lo concreto se lee antes que los valores por defecto |
| `config`, `Host *` | `ControlMaster auto`, `ControlPath ~/.ssh/cm/%C`, `ControlPersist 10m` | Una autenticación por host cada diez minutos, no una por comando |
| `conf.d/00-perfiles.conf` | `Match tagged sinmux` con `ControlMaster no` y `ControlPath none` | Una conexión limpia cuando la necesitas: `ssh -P sinmux` |
| `conf.d/10-lab.conf` | `Host lab-server` y `Host lab-bastion` | Un archivo por grupo de hosts |

### `bin/kit-link`

Sin argumentos. Crea o actualiza el enlace `~/.ssh/kit` → carpeta del kit, y deja `~/.ssh` y `~/.ssh/cm` con permisos 700. Si `~/.ssh/kit` existe y no es un enlace, no lo toca.

| Código | Cuándo |
|---|---|
| 0 | Enlace y carpeta listos (también si ya lo estaban) |
| 1 | `~/.ssh/kit` es un archivo o una carpeta |
| 2 | Recibe argumentos |

### `bin/mux list|stop`

Recorre los sockets de `~/.ssh/cm` (o de `MUX_DIR`). `list` escribe una línea por socket, `activo pid=N RUTA` o `huérfano RUTA`; `stop` cierra los activos con `ssh -O exit` y borra los huérfanos. Sale con 2 si la orden no es `list` ni `stop`.

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d --force-recreate server
docker compose run --rm client
```

Ya dentro del contenedor:

```bash
cd bootcamp/week-05-configuracion_avanzada_cliente_ssh/3-proyecto/starter
mkdir -p -m 700 ~/.ssh
ls bin conf.d
```

```
bin:
agent-up  ak-line  key-new  kh-add  kit-link  lab-check  mux

conf.d:
00-perfiles.conf
```

- `--force-recreate server` deja `server` sin llaves de otras semanas. La contraseña `alumno` que usarás en el paso 5 es **solo del laboratorio**.
- El cliente es un contenedor nuevo cada vez: `~/.ssh` y los masters desaparecen con `exit`. Haz los pasos 2 a 7 en la misma sesión.

### Paso 1 — TODO 1: los hosts, a `conf.d/10-lab.conf`

1. Crea `conf.d/10-lab.conf` y mueve a él, desde `config`, los bloques `Host lab-server` y `Host lab-bastion` con su comentario Qué / Para qué / Impacto. Empieza el archivo con una línea que diga qué contiene (`# Hosts del laboratorio (compose.yaml).`).
2. En `config`, donde está el TODO 1 (antes de `Host *`), escribe:
   ```
   Include kit/conf.d/*.conf
   ```
   con su Qué / Para qué / Impacto. El Impacto tiene que avisar de la ruta relativa a `~/.ssh`.
3. Comprueba:
   ```bash
   ssh -G -F config lab-server | grep '^hostname '
   ssh -v -G -F config lab-server 2>&1 | grep 'matched no files' | head -1
   ```
   ```
   hostname lab-server
   debug1: config line 17: include ~/.ssh/kit/conf.d/*.conf matched no files
   ```
   Todavía no funciona: `~/.ssh/kit` no existe. Es el error que verá cualquiera que use tu kit sin preparar `~/.ssh`, y lo que resuelve el paso 2. Tu número de línea puede ser otro.

### Paso 2 — `kit-link`: lo que ya hace

```bash
bin/kit-link
ls -l ~/.ssh/kit
ssh -G -F config lab-server | grep '^hostname '
```

```
kit-link: /home/alumno/.ssh/kit -> /bc-ssh/bootcamp/week-05-configuracion_avanzada_cliente_ssh/3-proyecto/starter
lrwxrwxrwx 1 alumno alumno 78 Nov  8 06:29 /home/alumno/.ssh/kit -> /bc-ssh/bootcamp/week-05-configuracion_avanzada_cliente_ssh/3-proyecto/starter
hostname server
```

- `cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd`: la carpeta del kit en ruta absoluta, se llame desde donde se llame.
- `ln -sfn`: `-s` simbólico, `-f` reemplaza un enlace anterior, `-n` trata un enlace existente a una carpeta como archivo. Sin `-n`, la segunda vez crearía el enlace **dentro** de la carpeta del kit.

Ejecútalo otra vez: el resultado es el mismo. Lo que falta: no pisar una carpeta tuya y preparar `~/.ssh/cm`.

### Paso 3 — TODO 4: no pisar una carpeta

Si `~/.ssh/kit` existe y **no** es un enlace (`[[ -e ... && ! -L ... ]]`), puede tener trabajo tuyo dentro: avisa por stderr y sal con 1.

```bash
mv ~/.ssh/kit /tmp/enlace && mkdir ~/.ssh/kit
bin/kit-link; echo "código: $?"
rmdir ~/.ssh/kit && mv /tmp/enlace ~/.ssh/kit
```

```
kit-link: /home/alumno/.ssh/kit existe y no es un enlace; muévelo y repite
código: 1
```

`-L` comprueba si es un enlace simbólico; `-e`, si existe (siguiendo el enlace).

### Paso 4 — TODO 5: `~/.ssh/cm`, solo tuya

`ssh` no crea la carpeta de `ControlPath`, y sin ella no conecta ([lab 06, paso 3](../2-practicas/lab-06-multiplexing/README.md)). Crea `~/.ssh/cm` y deja `~/.ssh` y `~/.ssh/cm` en 700 **aunque ya existieran** con otros permisos: `mkdir -m` solo actúa al crear, `chmod` siempre.

```bash
mkdir -p ~/.ssh/cm && chmod 755 ~/.ssh/cm
bin/kit-link >/dev/null
stat -c '%a %n' ~/.ssh ~/.ssh/cm
```

```
700 /home/alumno/.ssh
700 /home/alumno/.ssh/cm
```

Explica en un comentario por qué importa: quien abra un socket de esa carpeta entra en tus servidores sin autenticarse.

### Paso 5 — TODO 2: multiplexing en `config`

Al final de `Host *`, las tres opciones con un comentario Qué / Para qué / Impacto. El Impacto debe nombrar los riesgos de la [teoría 03](../1-teoria/03-multiplexing.md#riesgos).

```bash
ssh -G -F config lab-server | grep '^control'
```

```
controlmaster auto
controlpath /home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c
controlpersist 600
```

Pruébalo de verdad. Prepara `known_hosts` y una llave sin frase (solo laboratorio), instálala con la contraseña y conecta dos veces:

```bash
export SSHPASS=alumno
ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab.pub lab-server 2>&1 | grep added
time ssh -F config lab-server hostname
time ssh -F config lab-server hostname
ssh -F config -O check lab-server
```

```
Number of key(s) added: 1
server

real	0m0.192s
user	0m0.062s
sys	0m0.005s
server

real	0m0.011s
user	0m0.007s
sys	0m0.000s
Master running (pid=71)
```

`ssh-copy-id` con `-o ControlPath=none`: así no deja abierto un master autenticado con contraseña.

### Paso 6 — TODO 3: el perfil `sinmux`

En `conf.d/00-perfiles.conf`, un `Match tagged sinmux` con `ControlMaster no` **y** `ControlPath none` (con `no` solo, `ssh` seguiría usando el master que exista: [lab 07, paso 4](../2-practicas/lab-07-lo-que-decide-el-master/README.md)). Comenta Qué / Para qué / Impacto.

```bash
ssh -G -F config -P sinmux lab-server | grep '^control'
ssh -v -F config -P sinmux lab-server true 2>&1 | grep -E 'mux|Authenticated to'
```

```
controlmaster false
controlpersist 600
Authenticated to server ([172.20.0.3]:22) using "publickey".
```

Sin línea `controlpath` (no hay socket) y sin `mux` en la depuración: una autenticación completa, aunque el master del paso 5 siga abierto. Funciona porque `00-perfiles.conf` se lee antes que el `Host *` de `config`.

### Paso 7 — TODO 6: `mux stop`

`bin/mux list` ya funciona:

```bash
bin/mux list
```

```
activo    pid=71    /home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c
```

Completa las dos ramas de `stop`: en la de un master activo, `ssh -F /dev/null -S "$s" -O exit _` y la línea `cerrado   RUTA`; en la de un socket huérfano, `rm -f` y `borrado   RUTA`. Para probar los dos casos, fabrica un socket huérfano con un agente que muere sin limpiar (semana 04):

```bash
ssh-agent -a ~/.ssh/cm/viejo >/dev/null; pkill -9 -f 'ssh-agent -a'
bin/mux list
bin/mux stop
bin/mux list | wc -l
```

```
activo    pid=71    /home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c
huérfano            /home/alumno/.ssh/cm/viejo
cerrado   /home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c
borrado   /home/alumno/.ssh/cm/viejo
0
```

### Paso 8 — Calidad, README y git

1. `shellcheck bin/*` sin avisos y ningún `TODO` en `config`, `conf.d/` ni `bin/`.
2. Completa los TODOs de `starter/README.md`: las filas de `conf.d/` y de los dos scripts nuevos, la bitácora de la semana 05 y las secciones "Instalar el kit en un equipo" y "Cuando cambias llaves".
3. Copia el kit a tu repositorio, enlázalo desde allí y haz el commit de la semana:
   ```bash
   cp -r config conf.d bin README.md ~/ssh-infra-kit/
   ~/ssh-infra-kit/bin/kit-link
   cd ~/ssh-infra-kit && git add -A && git commit -m "semana 05: conf.d, perfiles y multiplexing"
   git log --stat -1
   ```
   En el commit solo deben aparecer `config`, `README.md` y archivos de `conf.d/` y `bin/`: ninguna llave. `~/.ssh/kit` y los sockets viven en `~/.ssh`, fuera del kit.

### Paso 9 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 05
```

Tres comprobaciones arrancan un `sshd` en el cliente: la segunda conexión debe viajar por el master (entra aunque la llave ya no esté autorizada), `-P sinmux` debe autenticarse de nuevo, y `bin/mux` debe ver y cerrar el master.

## ✅ Requisitos verificables

- bin/kit-link rechaza argumentos (sale con 2)
- bin/kit-link enlaza ~/.ssh/kit a la carpeta del kit
- bin/kit-link se puede repetir sin crear enlaces dentro del kit
- bin/kit-link no borra una carpeta ~/.ssh/kit que no es un enlace (sale con 1)
- bin/kit-link deja ~/.ssh/cm con permisos 700, aunque ya existiera
- config ya no define hosts: viven en conf.d/
- conf.d/10-lab.conf define lab-server y lab-bastion
- config incluye conf.d/ a través de ~/.ssh/kit
- config mantiene los valores de las semanas 02-04
- config activa el multiplexing (ControlMaster auto)
- Los sockets van a ~/.ssh/cm/%C
- El master sigue 10 min tras la última sesión
- ssh -P sinmux desactiva el multiplexing que config activa
- La segunda conexión viaja por el master: entra aunque la llave ya no esté en authorized_keys
- Con -P sinmux, la conexión no usa el master: se autentica de nuevo y falla
- bin/mux rechaza una orden desconocida (sale con 2)
- bin/mux list sin sockets no escribe nada
- bin/mux list marca un socket sin master como huérfano
- bin/mux stop borra los sockets huérfanos
- bin/mux list ve el master y bin/mux stop lo cierra
- Los scripts de semanas anteriores siguen respondiendo
- Sin TODO en config, conf.d/ y bin/, y shellcheck sin avisos

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): README del kit, mensajes, comentarios que explican el porqué y el historial de git sin llaves.

## Entrega

- [ ] `./scripts/verificar-semana.sh 05` con las 22 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ninguna llave en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Lo que decide el master](../2-practicas/lab-07-lo-que-decide-el-master/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 05](../README.md)
