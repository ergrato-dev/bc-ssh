# Proyecto Semana 14 — ssh-infra-kit: integración, documentación y defensa

⏱ Duración estimada: ~3 h

## Contexto

Tu kit está completo: cliente, servidores, CA, automatización y diagnóstico. Esta semana lo cierras como lo heredaría otra persona:

- **`bin/kit-check`**: el kit se comprueba a sí mismo sin conectar a nada (llaves privadas, permisos, documentación, `TODO`, `ssh -G`, `sshd -t`, `shellcheck`), en tu equipo y en el CI antes de desplegar.
- **Los dos fallos de integración** que encontraste en los labs: `bin/doctor` con certificados de host (lab 03) y con una IP bloqueada (lab 05), y `bin/kh-add` con una línea `@cert-authority` (lab 06).
- **`RUNBOOK.md`**: los siete procedimientos de incidente, cada uno con síntoma, pasos y comprobación.
- **El README** como punto de entrada, con lo que el kit protege y lo que no.

Después, la [defensa](../1-teoria/03-la-defensa.md).

## Estructura del proyecto

```
starter/                        ← aquí trabajas: tu ssh-infra-kit de la semana 13 + TODOs
├── README.md                   ← TODO 8
├── RUNBOOK.md                  ← TODO 7 (nuevo)
├── bin/
│   ├── kit-check               ← TODOs 1 a 3 (nuevo)
│   ├── doctor                  ← TODOs 4 y 5
│   ├── kh-add                  ← TODO 6
│   └── …                       ← semanas 01-13, terminados
├── ci/github-actions.yml       ← TODO 9
└── config, conf.d/, ca/, server/, ansible/   ← terminados
solucion/                       ← la referencia, para comparar al final
```

## Lo que debes construir

| TODO | Archivo | Qué |
|:--:|---|---|
| 1-3 | `bin/kit-check` | Siete comprobaciones sin red, una línea `ok`/`fallo` cada una |
| 4-5 | `bin/doctor` | `host key` con certificado de host; la pista de `Connection refused` habla de fail2ban |
| 6 | `bin/kh-add` | Una línea `@cert-authority` no es la host key: no impide añadirla |
| 7 | `RUNBOOK.md` | Siete procedimientos: síntoma, pasos, comprobación |
| 8 | `README.md` | Punto de entrada, filas nuevas, "Qué protege el kit y qué no", bitácora |
| 9 | `ci/github-actions.yml` | `bin/kit-check` antes de `bin/ci-deploy` |

## Paso a paso

### Paso 0 — Preparar la terminal

`bin/kit-check` no necesita servidores. Desde la raíz del repositorio en tu equipo:

```bash
docker compose run --rm client
```

En el contenedor:

```bash
cd bootcamp/week-14-proyecto_integrador_ssh_infra_kit/3-proyecto/starter
bin/kit-check; echo "código $?"
```

```
kit-check: sin terminar
código 1
```

### Paso 1 — TODOs 1 a 3: `bin/kit-check`

**Uso.** `kit-check [CARPETA]`: sin argumento, la carpeta del propio kit (`$(dirname "${BASH_SOURCE[0]}")/..`). Con más de un argumento, o con una carpeta sin `config`, escribe `uso: kit-check [CARPETA]` (o por qué no es un kit) en `stderr` y sale con 2. Que acepte otra carpeta es lo que permite probarlo sobre una copia rota sin estropear el kit.

**La salida.** Una línea por comprobación, en este orden, y código 0 si todas son `ok`, 1 si alguna falla:

```
ok      secretos
ok      permisos
fallo   documentado  bin/nuevo no aparece en README.md
ok      pendientes
ok      config
ok      sshd
ok      shellcheck
```

Si una comprobación encuentra varios problemas, escribe el primero y cuántos más hay (`(y 2 más)`). Una función pequeña que reciba el nombre y el detalle (vacío = `ok`) escribe las siete líneas igual.

**Las siete comprobaciones** (TODO 2 las cuatro primeras, TODO 3 las tres últimas):

| Nombre | Cómo | Fallo si |
|---|---|---|
| `secretos` | `grep -rlE` de `-----BEGIN [A-Z ]*PRIVATE KEY-----` y `^PuTTY-User-Key-File`, sin `.git` | Algún archivo la contiene: di cuál |
| `permisos` | `find bin ca -type f` y `[[ -x ]]` | Alguno no es ejecutable |
| `documentado` | Cada uno de esos scripts, entre comillas invertidas, en `README.md` (`` grep -qF "\`bin/x\`" ``) | Alguno no aparece |
| `pendientes` | `grep -rn TODO` (sin `.git` y sin el propio `kit-check`, que contiene la palabra) | Queda alguno: archivo y línea |
| `config` | Un `config` temporal con `Include CARPETA/conf.d/*.conf` y el resto de `config` sin su `Include`; `ssh -G -F` de cada alias de `conf.d/` (los `Host` sin `*`, `?` ni `!`) | `ssh -G` sale con error: su primera línea, una vez aunque falle en todos los alias |
| `sshd` | Una copia de `server/sshd_config.d/` con las líneas `HostCertificate` comentadas, un `sshd_config` temporal que la incluye y `sshd -t -f ... -h HOSTKEY_TEMPORAL -o PidFile=none` | `sshd -t` escribe algo |
| `shellcheck` | `shellcheck -f gcc` de `bin/*` y `ca/*` | Algún aviso. Si no está instalado: `omitido shellcheck   no está instalado`, que no cuenta como fallo |

Dos detalles de `config` y `sshd`:

- El `Include kit/conf.d/*.conf` de `config` se busca desde `~/.ssh`: en la copia temporal incluye la carpeta que compruebas, o comprobarías la de `~/.ssh/kit`.
- `sshd -t` sin root funciona con una host key de prueba (`ssh-keygen -t ed25519 -N ''` en una carpeta temporal) y `PidFile=none`. Los archivos que nombra la configuración (la CA, la KRL) no hacen falta, salvo `HostCertificate`, que `sshd` intenta cargar y no existe fuera del servidor. Borra la carpeta temporal al salir (`trap ... EXIT`).

Pruébalo rompiendo una copia:

```bash
d=$(mktemp -d); cp -a . $d/kit
echo "Hots x" > $d/kit/conf.d/99-mal.conf
chmod -x $d/kit/bin/backup
$d/kit/bin/kit-check; echo "código $?"
rm -rf $d
```

```
ok      secretos
fallo   permisos     bin/backup no es ejecutable
ok      documentado
ok      pendientes
fallo   config       /tmp/tmp.2V9XU3UPsa/kit/conf.d/99-mal.conf: line 1: Bad configuration option: hots
ok      sshd
ok      shellcheck
código 1
```

(Mientras queden los TODOs 4 a 9, tu propio kit falla en `pendientes`: es lo esperado.)

### Paso 2 — TODOs 4 y 5: `bin/doctor`

**TODO 4, certificados de host.** Con un certificado, `ssh -v` escribe:

```
debug1: Server host certificate: ssh-ed25519-cert-v01@openssh.com SHA256:4r3jm8P1/zkQvTeq7jD60IHhei8I9JzzY6BkpIS/1PQ, serial 1 ID "server" CA ssh-ed25519 SHA256:1FrkMEJUB87CA8AVxONh7I9pVubEznKpqG+btUOeJgM valid from 2026-11-11T01:06:57 to 2027-11-10T01:11:57
```

`doctor` debe escribir el tipo y la huella, y entre paréntesis la serie, el ID y la CA (sin las fechas, que pueden faltar: un certificado sin `-V` dice `valid forever`):

```
host key: ssh-ed25519-cert-v01@openssh.com SHA256:4r3jm8P1/zkQvTeq7jD60IHhei8I9JzzY6BkpIS/1PQ (certificado: serial 1 ID "server" CA ssh-ed25519 SHA256:1FrkMEJUB87CA8AVxONh7I9pVubEznKpqG+btUOeJgM)
```

Un segundo `-e` en el mismo `sed -n` basta. Sin certificado, la línea sigue como antes. Añade al comentario de cabecera que `BatchMode` no puede pedir la frase de una llave (lab 01, paso 5): hay que cargarla antes en el agente.

**TODO 5, una IP bloqueada.** fail2ban rechaza tu IP con el mismo `Connection refused` que un `sshd` parado (lab 05, paso 7). La pista tiene que nombrar las dos causas y cómo distinguirlas: si desde otra IP entra, `fail2ban-client status sshd` en el servidor.

### Paso 3 — TODO 6: `bin/kh-add`

`ssh-keygen -F HOST` encuentra también las líneas `@cert-authority` (y `@revoked`) cuyo patrón cubre el host. Quítalas de `conocidas` antes de comparar: no son la host key del servidor. Comprueba los dos casos del lab 06:

```bash
d=$(mktemp -d); ssh-keygen -q -t ed25519 -N '' -f $d/ca
echo "@cert-authority server,bastion $(cat $d/ca.pub)" > $d/kh
f=$(ssh-keyscan -t ed25519 server 2>/dev/null | ssh-keygen -lf - | cut -d' ' -f2)
KH_FILE=$d/kh bin/kh-add server $f; echo "código $?"
rm -rf $d
```

```
server añadida SHA256:GnjOvNb8xwLhDIVu9LZu2zBwjbs6Sk4SzkMpkevjyC8
código 0
```

Una llave **distinta** del mismo tipo para el mismo host sigue siendo `ya tiene otra llave` y código 1: es el aviso de host key cambiada, y lo decide una persona.

### Paso 4 — TODO 7: `RUNBOOK.md`

Siete secciones, con estos títulos exactos (el autograding los busca):

| `## ...` | Lo que tiene que tener | Su comando |
|---|---|---|
| `No puedo entrar` | De `doctor` a `sshd -d` en otro puerto; masters viejos; fail2ban | `bin/doctor` |
| `La host key cambió` | No borrar a ciegas; huella por otro camino; si no coincide, no entrar; `KIT_KNOWN_HOSTS` | `bin/kh-add` |
| `Perdí una llave o un equipo` | Revocar hoy, KRL en cada servidor, cortar lo abierto, comprobar, llave nueva; si estaba en git o era la del CI | `ca/ca-revoke` |
| `Alta de una persona` | Solo la pública, comprobar su huella por otro camino, firmar (o `ak-line`), grupos | `ca/ca-sign` |
| `Baja de una persona` | Revocar, `authorized_keys` y `principals/`, grupos, sesiones, secretos compartidos | `ca/ca-revoke` |
| `Un servidor nuevo` | Host key, alias y `kit-check`, llave, inventario y playbook (`--check` primero), CA, `bin/audit` | `ansible-playbook` |
| `La CA queda expuesta` | Una CA nueva, solo la nueva en los servidores, volver a firmar, la de hosts, cómo salió | `ca/ca-init` |

Cada una con su **Síntoma:** (el texto del error, para encontrarla buscando), pasos numerados con su comando, y **Comprobación:** (cómo sabes que terminó). Los porqués, en el README: aquí solo los pasos ([teoría 02](../1-teoria/02-documentar-para-operar.md#el-runbook-síntoma-pasos-comprobación)). Usa lo que apuntaste en los labs 04 y 06: un procedimiento que no probaste no está terminado.

### Paso 5 — TODO 8: el README

1. **El principio**: después del título, una frase de qué es el kit y cuatro enlaces: instalar, `RUNBOOK.md`, "Qué protege el kit y qué no", y `bin/kit-check` antes de cada commit. Todo en las primeras 12 líneas.
2. **Dos filas nuevas** en `Contenido`: `bin/kit-check` y `RUNBOOK.md`. Y `shellcheck` en `Requisitos`.
3. **Instalar el kit en un equipo**: un paso con `bin/kit-check` después de `kit-link`.
4. **`## Qué protege el kit y qué no`**: una tabla "amenaza / lo que la para / dónde" (al menos contraseñas, servidor falso, llave robada, agente, cuentas restringidas, algoritmos, un cambio que te deja fuera, una llave en el repositorio) y una lista **No protege contra** con qué hacer en cada caso. Usa lo que apuntaste en el lab 05.
5. **La bitácora**: la fila `| 14 |`.

### Paso 6 — TODO 9: el CI

En `ci/github-actions.yml`, un paso `- run: bin/kit-check` **antes** de `- run: bin/ci-deploy`, con un comentario de qué evita. Los runners `ubuntu-24.04` ya traen `shellcheck`. Un kit roto no llega a los servidores.

### Paso 7 — Calidad, git y versión

1. `bin/kit-check` en tu kit: siete `ok`, código 0.
2. Copia el kit a tu repositorio, haz el commit de la semana y márcalo como la primera versión completa:
   ```bash
   cp -r config conf.d bin ca server ansible ci README.md RUNBOOK.md ~/ssh-infra-kit/
   cd ~/ssh-infra-kit && bin/kit-check && git add -A && git commit -m "semana 14: kit-check, RUNBOOK y README final"
   git tag -a v1.0 -m "ssh-infra-kit completo"
   git log --stat -1
   ```
   **Ninguna llave privada** en el commit ni en el historial: `bin/kit-check` mira los archivos, no el historial. Para el historial, `git log -p | grep -c 'PRIVATE KEY'` debe dar 0.
3. Ensaya la defensa: [lab 07](../2-practicas/lab-07-la-defensa/README.md).

### Paso 8 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 14
```

Los checks de `bin/kit-check` lo ejecutan sobre copias de tu kit con una sola cosa rota, y esperan una sola línea `fallo`, la de esa cosa. Los de `bin/doctor` y `bin/kh-add` arrancan un `sshd` sin root en `127.0.0.1:2218` con un certificado de host firmado por una CA de prueba: solo funcionan dentro del laboratorio.

## ✅ Requisitos verificables

- bin/kit-check sale con 2 y dice cómo se usa con dos argumentos o con una carpeta que no es un kit
- bin/kit-check sale con 0 en tu kit, con una línea ok por cada comprobación
- bin/kit-check falla (solo en secretos) si el kit contiene una llave privada, y dice qué archivo
- bin/kit-check falla (solo en permisos) si un script de bin/ no es ejecutable
- bin/kit-check falla (solo en documentado) si un script de bin/ no aparece en el README
- bin/kit-check falla (solo en pendientes) si queda un TODO, y dice dónde
- bin/kit-check falla (solo en config) si un archivo de conf.d/ tiene una opción que ssh no conoce
- bin/kit-check falla (solo en sshd) si server/sshd_config.d/ tiene un valor que sshd no acepta
- Con un servidor que presenta certificado de host, bin/doctor escribe su tipo, la serie, el ID y la CA en host key
- Con la conexión rechazada, la pista de bin/doctor habla del puerto y también de una IP bloqueada (fail2ban)
- bin/kh-add añade la host key aunque known_hosts tenga una línea @cert-authority que cubre el host, y sigue negándose si hay otra llave
- RUNBOOK.md tiene los siete procedimientos, cada uno con Síntoma, Comprobación y el comando del kit que lo resuelve
- El README empieza por dónde mirar, documenta kit-check y RUNBOOK.md, dice qué protege el kit y qué no, y tiene la semana 14 en la bitácora
- El workflow del CI ejecuta bin/kit-check antes de bin/ci-deploy
- Sin TODOs, shellcheck sin avisos y los scripts de semanas anteriores siguen respondiendo

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): que el RUNBOOK se pueda seguir sin preguntarte nada, que la lista de lo que el kit no protege sea honesta, los comentarios Qué / Para qué / Impacto de `kit-check`, y el historial de git sin llaves.

## Entrega

- [ ] `./scripts/verificar-semana.sh 14` con las 15 comprobaciones en verde
- [ ] `starter/README.md` y `starter/RUNBOOK.md` sin TODOs
- [ ] `~/ssh-infra-kit` con el commit de la semana, la etiqueta `v1.0` y ninguna llave en el historial
- [ ] El guion de la defensa ensayado ([lab 07](../2-practicas/lab-07-la-defensa/README.md))

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — La defensa](../2-practicas/lab-07-la-defensa/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 14](../README.md)
