# Proyecto Semana 06 — ssh-infra-kit: copias de seguridad y espejos con `rsync`

⏱ Duración estimada: ~3 h

## Contexto

Tu kit ya conecta bien: alias, llaves, agente y multiplexing. Esta semana le das dos usos que harás todas las semanas, convertidos en scripts que no te dejan equivocarte en lo que más duele:

- **`bin/backup ORIGEN DESTINO`**: una copia completa nueva cada vez, con fecha y hora, en la que lo que no cambió no ocupa otra vez ([lab 05](../2-practicas/lab-05-snapshots-con-link-dest/README.md)). Una copia cortada nunca pasa por buena, y se guardan solo las últimas.
- **`bin/mirror [-y] ORIGEN DESTINO`**: deja una carpeta remota igual que una local, con `--delete`. Sin `-y` solo enseña lo que haría, y no acepta el home ni la raíz como destino ([lab 04](../2-practicas/lab-04-delete-y-exclude/README.md)).

Los dos conectan con `ssh -F config` del kit: tus alias, `known_hosts` estricto y multiplexing.

## Estructura del proyecto

```
starter/                    ← aquí trabajas: tu ssh-infra-kit de la semana 05 + TODOs
├── README.md               ← documentación del kit (TODOs)
├── config, conf.d/         ← semana 05, terminados
└── bin/
    ├── lab-check, kh-add, ak-line, key-new, agent-up, kit-link, mux   ← semanas 01-05
    ├── backup              ← TODOs 1 a 4
    └── mirror              ← TODOs 5 y 6
solucion/                   ← referencia: no la abras hasta terminar
```

## Lo que debes construir

### `bin/backup ORIGEN DESTINO`

`ORIGEN` es una carpeta local o remota (`lab-server:datos`); se copia su contenido. `DESTINO` es una carpeta local:

```
DESTINO/
├── 2026-11-08T101500/      ← una copia completa por ejecución
├── 2026-11-09T101500/
└── latest -> 2026-11-09T101500
```

| Pieza | Qué hace | Por qué |
|---|---|---|
| `RSYNC_RSH` | `ssh -F config` del kit, salvo que ya venga definida | Alias y seguridad del kit; los tests la cambian |
| `.parcial-NOMBRE` | `rsync` escribe ahí y se renombra al terminar | Una copia cortada no se confunde con una buena |
| `--link-dest` | A `latest`, con ruta absoluta | Lo que no cambió son enlaces duros: no ocupa |
| `BACKUP_KEEP` | Borra las copias más antiguas y deja las N últimas (7) | El disco no se llena |

| Código | Cuándo |
|---|---|
| 0 | Copia hecha |
| 1 | `rsync` falló, o ya hay una copia de este mismo segundo |
| 2 | Argumentos o `BACKUP_KEEP` incorrectos |

### `bin/mirror [-y] ORIGEN DESTINO`

`ORIGEN`, carpeta local; `DESTINO`, local o remoto. `rsync -a --delete -i`, con `-n` salvo que reciba `-y`. Rechaza (código 2) un destino cuya ruta sea vacía, `~`, `.` o `/`. Sale con 1 si `rsync` falla.

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d --build --force-recreate server
docker compose run --rm client
```

Ya dentro del contenedor:

```bash
cd bootcamp/week-06-transferencia_archivos_scp_sftp_rsync/3-proyecto/starter
mkdir -p -m 700 ~/.ssh
bin/kit-link
ls bin
```

```
kit-link: /home/alumno/.ssh/kit -> /bc-ssh/bootcamp/week-06-transferencia_archivos_scp_sftp_rsync/3-proyecto/starter
agent-up  ak-line  backup  key-new  kh-add  kit-link  lab-check  mirror  mux
```

- `bin/kit-link` (semana 05): sin `~/.ssh/kit`, los alias de `conf.d/` no existen.
- La contraseña `alumno` que usarás en el paso 5 es **solo del laboratorio**. El cliente es un contenedor nuevo cada vez: haz los pasos 1 a 8 en la misma sesión.

### Paso 1 — `backup`: lo que ya hace

```bash
bin/backup; echo "código: $?"
mkdir -p ~/w/origen; echo uno > ~/w/origen/a.txt; echo dos > ~/w/origen/b.txt
bin/backup ~/w/origen ~/backups/prueba
ls ~/backups/prueba
cat ~/backups/prueba/latest/a.txt
```

```
uso: backup ORIGEN DESTINO
código: 2
backup: /home/alumno/backups/prueba/2026-11-08T065215
2026-11-08T065215
latest
uno
```

- `date +%Y-%m-%dT%H%M%S`: año-mes-día, `T`, hora-minuto-segundo. Ordenados alfabéticamente, los nombres quedan en orden cronológico; la retención del paso 5 se apoya en eso.
- El `case` de `origen` añade la barra final: `latest/a.txt`, no `latest/origen/a.txt` ([lab 03, paso 3](../2-practicas/lab-03-rsync/README.md)). `host:` se deja tal cual: con barra sería la raíz del servidor.
- `ln -sfn`: el mismo enlace que en `bin/kit-link`.

### Paso 2 — TODO 1: conectar con el config del kit

Sin nada más, `rsync` usa `ssh` a secas, que no conoce tus alias:

```bash
bin/backup lab-server:datos ~/backups/server 2>&1 | head -1
```

```
ssh: Could not resolve hostname lab-server: Name or service not known
```

Donde está el TODO 1, exporta `RSYNC_RSH` con `ssh -F $kit/config` **solo si no está ya definida**: `${RSYNC_RSH:-...}`. Así un test, o tú, podéis pasar otra orden. Repite:

```
No ED25519 host key is known for server and you have requested strict checking.
Host key verification failed.
```

Ahora `lab-server` se resuelve a `server` y se aplica `StrictHostKeyChecking yes` del kit: es el error correcto, y lo arreglas en el paso 5.

### Paso 3 — TODO 2: una copia cortada no es una copia

Hoy `rsync` escribe directamente en `DESTINO/NOMBRE`. Si falla, esa carpeta se queda a medias y `set -e` termina el script con el código de `rsync`:

```bash
sleep 1; bin/backup ~/w/no-existe ~/backups/prueba; echo "código: $?"
ls ~/backups/prueba
```

```
rsync: [sender] change_dir "/home/alumno/w/no-existe" failed: No such file or directory (2)
rsync error: some files/attrs were not transferred (see previous errors) (code 23) at main.c(1356) [sender=3.2.7]
código: 23
2026-11-08T065215
2026-11-08T065216
latest
```

`2026-11-08T065216` está vacía y parece una copia más. Haz que `rsync` escriba en `$destino/.parcial-$nombre`: si falla (`if ! rsync ...; then`), bórrala, avisa por stderr y sal con 1; si termina, renómbrala con `mv`. Borra la carpeta vacía y repite:

```bash
rm -rf ~/backups/prueba/2026-11-08T065216     # tu nombre será otro
sleep 1; bin/backup ~/w/no-existe ~/backups/prueba; echo "código: $?"
ls -A ~/backups/prueba
```

```
rsync: [sender] change_dir "/home/alumno/w/no-existe" failed: No such file or directory (2)
rsync error: some files/attrs were not transferred (see previous errors) (code 23) at main.c(1356) [sender=3.2.7]
backup: rsync falló; latest sigue en la copia anterior
código: 1
2026-11-08T065215
latest
```

- `sleep 1`: el nombre lleva segundos; dos copias en el mismo segundo se rechazan.
- `ls -A` enseña también lo oculto: ninguna `.parcial-` se queda.
- Comenta Qué / Para qué / Impacto: el Impacto es que `latest` apunta siempre a una copia completa.

### Paso 4 — TODO 3: lo que no cambió, no ocupa

Hoy cada copia es completa **y** ocupa entera. Si existe `$destino/latest`, añade a `opciones` `--link-dest=$destino/latest`. Ruta absoluta: una relativa se busca desde la carpeta de destino ([lab 05, paso 6](../2-practicas/lab-05-snapshots-con-link-dest/README.md)).

```bash
rm -rf ~/backups/prueba
bin/backup ~/w/origen ~/backups/prueba >/dev/null; sleep 1
echo dos-bis > ~/w/origen/b.txt
bin/backup ~/w/origen ~/backups/prueba >/dev/null
stat -c '%h %n' ~/backups/prueba/2*/*.txt
du -sh ~/backups/prueba/2*
```

```
2 /home/alumno/backups/prueba/2026-11-08T065217/a.txt
1 /home/alumno/backups/prueba/2026-11-08T065217/b.txt
2 /home/alumno/backups/prueba/2026-11-08T065218/a.txt
1 /home/alumno/backups/prueba/2026-11-08T065218/b.txt
12K	/home/alumno/backups/prueba/2026-11-08T065217
8.0K	/home/alumno/backups/prueba/2026-11-08T065218
```

`a.txt` no cambió: 2 nombres, un solo archivo. `b.txt` sí: uno en cada copia. `--delete` no hace falta: la carpeta de destino empieza vacía, así que lo borrado en el origen simplemente no aparece.

### Paso 5 — TODO 4: guardar solo las últimas

Recorre las copias (`"$destino"/[0-9][0-9][0-9][0-9]-*`, con `shopt -s nullglob`) y borra todas menos las `$keep` últimas, con una línea `backup: borrada RUTA` por cada una.

```bash
for i in 1 2 3; do sleep 1; BACKUP_KEEP=2 bin/backup ~/w/origen ~/backups/prueba; done
ls ~/backups/prueba
```

```
backup: /home/alumno/backups/prueba/2026-11-08T065219
backup: borrada /home/alumno/backups/prueba/2026-11-08T065217
backup: /home/alumno/backups/prueba/2026-11-08T065220
backup: borrada /home/alumno/backups/prueba/2026-11-08T065218
backup: /home/alumno/backups/prueba/2026-11-08T065221
backup: borrada /home/alumno/backups/prueba/2026-11-08T065219
2026-11-08T065220
2026-11-08T065221
latest
```

Ahora, de verdad desde `server`. Prepara `known_hosts` y una llave sin frase (solo laboratorio), como en la semana 05, y unos datos:

```bash
export SSHPASS=alumno
ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab.pub lab-server 2>&1 | grep 'Number of'
ssh -F config lab-server 'mkdir -p datos; head -c 5M /dev/urandom > datos/fotos.bin; echo v1 > datos/notas.txt'
bin/backup lab-server:datos ~/backups/server; sleep 1
ssh -F config lab-server 'echo v2 > datos/notas.txt'
bin/backup lab-server:datos ~/backups/server
du -sh ~/backups/server/2*
cat ~/backups/server/latest/notas.txt
```

```
Number of key(s) added: 1
backup: /home/alumno/backups/server/2026-11-08T065313
backup: /home/alumno/backups/server/2026-11-08T065314
5.1M	/home/alumno/backups/server/2026-11-08T065313
8.0K	/home/alumno/backups/server/2026-11-08T065314
v2
```

La segunda copia de 5 MB ocupa 8 KB.

### Paso 6 — `mirror`: lo que ya hace

```bash
bin/mirror; echo "código: $?"
bin/mirror ~/w/nada lab-server:web; echo "código: $?"
```

```
uso: mirror [-y] ORIGEN DESTINO
código: 2
mirror: /home/alumno/w/nada no es una carpeta local
código: 2
```

`-y` se lee primero y se quita con `shift`; después tienen que quedar exactamente dos argumentos. **No ejecutes todavía `bin/mirror` con un destino real**: hasta el paso 7 aplica `--delete` siempre, con o sin `-y`.

### Paso 7 — TODO 5: primero, enseñar

Donde está el TODO 5, si `aplicar` no es `si`, añade `-n` a `opciones`. Comenta en el bloque de `opciones` qué hace cada una y por qué el ensayo es lo que se hace por defecto.

```bash
mkdir -p ~/w/web; echo hola > ~/w/web/index.html
bin/mirror ~/w/web lab-server:web; echo "código: $?"
ssh -F config lab-server ls web
bin/mirror -y ~/w/web lab-server:web
ssh -F config lab-server 'ls web; echo viejo > web/viejo.html'
bin/mirror ~/w/web lab-server:web
```

```
created directory web
cd+++++++++ ./
<f+++++++++ index.html
mirror: vista previa, no se cambió nada; repite con -y para aplicar
código: 0
ls: cannot access 'web': No such file or directory
created directory web
cd+++++++++ ./
<f+++++++++ index.html
index.html
*deleting   viejo.html
mirror: vista previa, no se cambió nada; repite con -y para aplicar
```

- En el ensayo, `created directory web` es lo que *haría*: `ls` confirma que no existe.
- El último: `viejo.html` solo está en el servidor y `-y` lo borraría.

### Paso 8 — TODO 6: el home y la raíz, nunca

`ruta="${2#*:}"` quita todo hasta el primer `:` (o nada, si es local). Si `${ruta%/}` (sin barra final) es `""`, `~`, `.` o `/`, avisa por stderr y sal con 2: un `--delete` ahí borraría todo lo que no esté en `ORIGEN`, `.ssh/authorized_keys` incluido. Pruébalo **sin `-y`**:

```bash
for d in lab-server: lab-server:~/ lab-server:/; do bin/mirror ~/w/web "$d"; echo "código: $?"; done
```

```
mirror: destino peligroso: lab-server: (home o raíz)
código: 2
mirror: destino peligroso: lab-server:~/ (home o raíz)
código: 2
mirror: destino peligroso: lab-server:/ (home o raíz)
código: 2
```

El autograding lo comprueba con un `rsync` falso: aunque el TODO estuviera mal, nunca llega a borrar nada.

### Paso 9 — Calidad, README y git

1. `shellcheck bin/*` sin avisos y ningún `TODO` en `config`, `conf.d/` ni `bin/`.
2. Completa los TODOs de `starter/README.md`: las filas de `bin/backup` y `bin/mirror`, la bitácora de la semana 06 y las secciones "Copias de seguridad" (con la restauración en seco), "Una llave solo para copias" ([lab 06](../2-practicas/lab-06-llave-solo-para-rsync/README.md)) y "Publicar una carpeta".
3. Copia el kit a tu repositorio y haz el commit de la semana:
   ```bash
   cp -r config conf.d bin README.md ~/ssh-infra-kit/
   cd ~/ssh-infra-kit && git add -A && git commit -m "semana 06: backup con link-dest y mirror"
   git log --stat -1
   ```
   En el commit solo deben aparecer `README.md`, `bin/backup` y `bin/mirror`: ni llaves ni copias. Las copias viven en `~/backups`, fuera del kit.

### Paso 10 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 06
```

Dos comprobaciones arrancan un `sshd` en el cliente para copiar de verdad por SSH, y otras dos sustituyen `ssh` por un programa que solo anota con qué opciones lo llamaron.

## ✅ Requisitos verificables

- bin/backup rechaza un número de argumentos distinto de 2 y un BACKUP_KEEP no válido (sale con 2)
- bin/backup crea una copia con fecha y hora y latest apunta a ella
- bin/backup conecta con ssh -F config del kit
- Si rsync falla, bin/backup sale con 1, no deja copia a medias y latest no cambia
- Un archivo que no cambió es un enlace duro a la copia anterior
- Un archivo que cambió se copia de nuevo y la copia anterior conserva su versión
- Un archivo borrado del origen sigue en la copia anterior y no en la nueva
- Con BACKUP_KEEP=2 quedan las 2 copias más recientes y latest en la última
- bin/backup copia una carpeta remota por SSH
- bin/mirror rechaza argumentos de más o de menos y un origen que no es una carpeta (sale con 2)
- Sin -y, bin/mirror enseña lo que borraría y no toca el destino
- Con -y, bin/mirror deja el destino igual que el origen
- bin/mirror conecta con ssh -F config del kit
- bin/mirror -y deja igual una carpeta remota por SSH
- bin/mirror rechaza como destino el home o la raíz (sale con 2 sin llamar a rsync)
- config mantiene los valores de las semanas 02-05
- Los scripts de semanas anteriores siguen respondiendo
- Sin TODO en config, conf.d/ y bin/, y shellcheck sin avisos

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): README del kit, mensajes, comentarios que explican el porqué y el historial de git sin llaves ni copias.

## Entrega

- [ ] `./scripts/verificar-semana.sh 06` con las 18 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ninguna llave en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Transferencias grandes y muchas pequeñas](../2-practicas/lab-07-transferencias-grandes/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 06](../README.md)
