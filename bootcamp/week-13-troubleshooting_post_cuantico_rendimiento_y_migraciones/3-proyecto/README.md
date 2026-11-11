# Proyecto Semana 13 — ssh-infra-kit: diagnóstico y migración de algoritmos

⏱ Duración estimada: ~3 h

## Contexto

Tu kit configura, endurece y despliega. Esta semana aprende a **explicar** lo que pasa cuando algo no conecta, y a **cambiar** lo viejo sin dejar a nadie fuera:

- **`bin/doctor`**: una conexión nueva a un host y un resumen de lo que pasó: a dónde fue, qué se negoció (y si es postcuántico), con qué entró; si falla, el error y una pista según la capa.
- **`conf.d/90-legado.conf`**: los algoritmos viejos, solo para los alias `legado-*`.
- **`bin/key-audit`**: qué llaves de un `authorized_keys` hay que migrar.
- **`RequiredRSASize 3072`** en `15-algoritmos.conf` y **`UpdateHostKeys yes`** en `config`: exigir lo nuevo en el servidor y rotar host keys sin avisos.

## Estructura del proyecto

```
starter/                        ← aquí trabajas: tu ssh-infra-kit de la semana 12 + TODOs
├── README.md                   ← documentación del kit (TODO 7)
├── config                      ← TODO 7: UpdateHostKeys
├── conf.d/
│   ├── 90-legado.conf          ← TODO 4
│   └── …                       ← semanas 05-09, terminados
├── bin/
│   ├── doctor                  ← TODOs 1 a 3
│   ├── key-audit               ← TODO 5
│   └── …                       ← semanas 01-12, terminados
├── server/sshd_config.d/
│   └── 15-algoritmos.conf      ← TODO 6
└── ca/, ansible/, ci/          ← semanas 10-12, terminados
solucion/                       ← referencia: no la abras hasta terminar
```

## Lo que debes construir

| Archivo | Contenido | Lab |
|---|---|---|
| `bin/doctor` | `doctor HOST [OPCIÓN_DE_SSH...]`: `destino:` siempre; si entra, `kex:` (con `(postcuántico)` o `(no postcuántico)`), `host key:`, `cifrado:` y `entrada:`, y sale con 0; si no, `error:` y `pista:`, y sale con el código de `ssh`. Sin argumentos, uso y 2 | [01](../2-practicas/lab-01-leer-ssh-v/README.md), [02](../2-practicas/lab-02-el-lado-del-servidor/README.md), [04](../2-practicas/lab-04-postcuantico/README.md) |
| `conf.d/90-legado.conf` | `Host legado-lab` (el equipo viejo del laboratorio) y `Host legado-*` con `+diffie-hellman-group14-sha1` y `+ssh-rsa` | [03](../2-practicas/lab-03-sin-algoritmo-en-comun/README.md) |
| `bin/key-audit` | `key-audit ARCHIVO...` (`-` es la entrada estándar): `ok` o `migrar` por llave; DSA, RSA de menos de 3072 bits y ECDSA se migran. Sale con 0, 1 si hay que migrar alguna, 2 por uso incorrecto o archivo sin llaves | [06](../2-practicas/lab-06-migrar-llaves-de-usuario/README.md) |
| `server/sshd_config.d/15-algoritmos.conf` | `RequiredRSASize 3072`, con su Qué / Para qué / Impacto | [06](../2-practicas/lab-06-migrar-llaves-de-usuario/README.md) |
| `config` | `UpdateHostKeys yes` en `Host *` | [07](../2-practicas/lab-07-rotar-host-keys/README.md) |

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d --force-recreate server bastion
docker compose run --rm client
```

Ya dentro del contenedor, enlaza el kit, `known_hosts` y una llave sin frase (**solo laboratorio**) instalada en `lab-server` y `lab-bastion`:

```bash
cd bootcamp/week-13-troubleshooting_post_cuantico_rendimiento_y_migraciones/3-proyecto/starter
mkdir -p -m 700 ~/.ssh ~/w
bin/kit-link
export SSHPASS=alumno
ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
for h in lab-server lab-bastion; do sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab.pub $h 2>&1 | grep 'Number of'; done
```

```
kit-link: /home/alumno/.ssh/kit -> /bc-ssh/bootcamp/week-13-troubleshooting_post_cuantico_rendimiento_y_migraciones/3-proyecto/starter
Number of key(s) added: 1
Number of key(s) added: 1
```

`SSHPASS=alumno` es la contraseña del laboratorio: **solo del laboratorio**.

### Paso 1 — TODO 1: el uso de `bin/doctor`

Sin argumentos, `uso: doctor HOST [OPCIÓN_DE_SSH...]` en `stderr` y código 2. Con argumentos, `$1` es el host y el resto (`shift`) son opciones que van a `ssh` **antes** del host:

```bash
bin/doctor; echo "código: $?"
```

```
uso: doctor HOST [OPCIÓN_DE_SSH...]
código: 2
```

Como `bin/audit` (semana 11), `SSH_CMD` cambia el `ssh` y, por defecto, es `ssh -F $kit/config`. Los checks lo usan para apuntar a servidores de prueba.

### Paso 2 — TODO 2: cuando entra

1. **El destino**, con `ssh -G` (las opciones también, para que `-p` o `-l` cuenten) y `awk` sobre `user`, `hostname` y `port`: `destino:  USUARIO@NOMBRE:PUERTO`.
2. **La conexión**: `ssh -v -o BatchMode=yes -o ControlMaster=no -o ControlPath=none -o ConnectTimeout=5 OPCIONES HOST true`, con `stderr` guardado en una variable (`2>&1`) y `</dev/null`.
   - `ControlPath=none`: con un master abierto, `ssh` no negocia nada y `-v` no dice qué algoritmos hay (lab 01).
   - Los mensajes de `-v` acaban en `\r\n`: quita los `\r` (`${log//$'\r'/}`) o tus `$` de fin de línea no casarán.
3. **El resumen**, con `sed -n 's/^debug1: kex: algorithm: //p'` y parecidos: `kex:` (y `(postcuántico)` si empieza por `sntrup761` o `mlkem`; si no, `(no postcuántico)`), `host key:` (de `Server host key:`), `cifrado:` (el primer campo tras `client->server cipher:`) y `entrada:` (lo que va entre comillas en `Authenticated to ... using "..."`).

```bash
bin/doctor lab-server; echo "código: $?"
bin/doctor lab-server -o KexAlgorithms=curve25519-sha256 | grep kex
```

```
destino:  alumno@server:22
kex:      sntrup761x25519-sha512@openssh.com (postcuántico)
host key: ssh-ed25519 SHA256:LaVStchsWusdjcLOv6p2yPBWNZIpm0kCdgrJeeqNGAs
cifrado:  chacha20-poly1305@openssh.com
entrada:  publickey
código: 0
kex:      curve25519-sha256 (no postcuántico)
```

### Paso 3 — TODO 3: cuando falla

`error:` con los mensajes de `ssh` que no son de depuración (las líneas que no empiezan por `debug1:` ni `OpenSSH_`), y `pista:` según lo que diga el log, de abajo arriba. Como mínimo:

| Si el log contiene | La pista habla de |
|---|---|
| `Could not resolve hostname` | `HostName` y el DNS |
| `Connection refused` | el **puerto**: nadie escucha |
| `timed out` | host apagado, cortafuegos, fail2ban |
| `no matching` | `Their offer` y los alias `legado-*` |
| `IDENTIFICATION HAS CHANGED`, `host key is known`, `Host key verification failed` | comprobar la huella y `bin/kh-add` |
| `Permission denied` | qué llaves se ofrecieron y el log del servidor (`sshd -d`) |

```bash
bin/doctor servr; echo "código: $?"
bin/doctor lab-server -p 2222
bin/doctor lab-server -l nadie
```

```
destino:  alumno@servr:22
error:    ssh: Could not resolve hostname servr: Name or service not known
pista:    el nombre no resuelve: revisa HostName (ssh -G HOST) y el DNS
código: 255
destino:  alumno@server:2222
error:    ssh: connect to host server port 2222: Connection refused
pista:    nadie escucha en ese puerto: ¿sshd está arrancado? ¿es el puerto correcto?
destino:  nadie@server:22
error:    nadie@server: Permission denied (publickey,password).
pista:    el servidor no aceptó la llave: mira qué llaves se ofrecieron (ssh -v, 'Offering') y la razón en el log del servidor (sudo sshd -d en otro puerto)
```

El equipo viejo del [lab 03](../2-practicas/lab-03-sin-algoritmo-en-comun/README.md), en `server:2223`:

```bash
ssh -F config lab-server 'sudo /usr/sbin/sshd -p 2223 -o KexAlgorithms=diffie-hellman-group14-sha1 -o HostKeyAlgorithms=ssh-rsa -o PidFile=/run/sshd-viejo.pid'
bin/doctor lab-server -p 2223
```

```
destino:  alumno@server:2223
error:    Unable to negotiate with 172.20.0.2 port 2223: no matching key exchange method found. Their offer: diffie-hellman-group14-sha1,ext-info-s,kex-strict-s-v00@openssh.com
pista:    sin algoritmo en común: 'Their offer' es lo que ofrece el servidor. Si es un equipo viejo que no puedes actualizar, dale un alias legado-* (conf.d/90-legado.conf)
```

### Paso 4 — TODO 4: `conf.d/90-legado.conf`

1. El alias del laboratorio: `Host legado-lab` con `HostName server`, `Port 2223`, `User alumno`, `IdentityFile ~/.ssh/lab` y `HostKeyAlias server`.
2. `Host legado-*` con `KexAlgorithms +diffie-hellman-group14-sha1`, `HostKeyAlgorithms +ssh-rsa` y `PubkeyAcceptedAlgorithms +ssh-rsa`, con Qué / Para qué / Impacto: qué se acepta, por qué solo ahí, y qué se pierde (SHA-1, sin postcuántico).

```bash
bin/doctor legado-lab
ssh -G -F config legado-lab | grep -E '^(kexalgorithms|hostkeyalgorithms|pubkeyacceptedalgorithms)' | tr , '\n' | grep -E 'sha1|ssh-rsa$'
ssh -G -F config lab-server | grep -cE 'group14-sha1|,ssh-rsa(,|$)'
ssh -F config lab-server 'sudo pkill -F /run/sshd-viejo.pid'
```

```
destino:  alumno@server:2223
kex:      diffie-hellman-group14-sha1 (no postcuántico)
host key: ssh-rsa SHA256:NMiHMdOzTMAmLBECB8B1gt1i9hjAkyNxJTY98M3ruh8
cifrado:  chacha20-poly1305@openssh.com
entrada:  publickey
ssh-rsa
diffie-hellman-group14-sha1
ssh-rsa
0
```

`bin/doctor` lo dice sin rodeos: `(no postcuántico)`. Es lo que pasa con lo viejo, y el motivo para actualizarlo.

### Paso 5 — TODO 5: `bin/key-audit`

Por cada archivo (`-` es `/dev/stdin`), `ssh-keygen -lf` y una línea por llave: el tipo es el último campo sin paréntesis, los bits el primero y el comentario lo de en medio. Si `ssh-keygen` falla (archivo vacío, sin llaves, inexistente), mensaje en `stderr` y código 2.

```bash
ssh-keygen -q -t rsa -b 2048 -N '' -C luis@portatil-2016 -f ~/w/viejo-rsa
ssh-keygen -q -t ecdsa -N '' -C eva@camara -f ~/w/cam-ecdsa
cat ~/w/viejo-rsa.pub ~/w/cam-ecdsa.pub | ssh -F config lab-server 'cat >> .ssh/authorized_keys'
ssh -F config lab-server cat .ssh/authorized_keys | bin/key-audit -; echo "código: $?"
```

```
ok      ED25519 256  alumno@client
migrar  RSA 2048     luis@portatil-2016   RSA de menos de 3072 bits
migrar  ECDSA 256    eva@camara   ECDSA (curva NIST): mejor Ed25519
código: 1
```

Llaves sin frase: **solo laboratorio**.

### Paso 6 — TODO 6: `RequiredRSASize`

`RequiredRSASize 3072` al final de `server/sshd_config.d/15-algoritmos.conf`, con Qué / Para qué / Impacto (incluido el orden: primero `bin/key-audit` y migrar, después exigir). Despliégalo con el playbook de la semana 12 y prueba la RSA de Luis sola:

```bash
(cd ansible && ansible-playbook servidores.yml --limit lab-server | tail -2)
ssh -F config lab-server 'sudo sshd -T 2>/dev/null | grep requiredrsasize'
ssh -o ControlPath=none -o BatchMode=yes -o IdentitiesOnly=yes -i ~/w/viejo-rsa server true; echo "código: $?"
ssh -F config lab-server "grep 'Invalid key length' /var/log/auth.log | tail -1"
```

```
lab-server                 : ok=14   changed=10   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

requiredrsasize 3072
alumno@server: Permission denied (publickey).
código: 255
2026-11-11 00:53:16 server sshd: refusing RSA key: Invalid key length [preauth]
```

El último `ssh` va sin el kit (sin `-F config`) a propósito: el kit añade tu `~/.ssh/lab` y entrarías con ella.

### Paso 7 — TODO 7: `config`, calidad, README y git

1. `UpdateHostKeys yes` en el `Host *` de `config`, con Qué / Para qué / Impacto (por qué permite rotar host keys sin avisos, y que solo actúa con una llave ya verificada). Compruébalo: `ssh -G -F config lab-server | grep updatehostkeys`.
2. `shellcheck bin/* ca/*` sin avisos, y ningún `TODO` en `README.md`, `config`, `conf.d/`, `bin/`, `ca/`, `server/`, `ansible/` ni `ci/`.
3. Completa los TODOs de `starter/README.md`: las tres filas nuevas (`bin/doctor`, `bin/key-audit`, `conf.d/90-legado.conf`), la bitácora de la semana 13 y la sección "Diagnóstico y migraciones" (qué hacer cuando algo no conecta; un equipo viejo; migrar llaves de usuario en orden; rotar host keys en dos fases). Actualiza también las filas de `config` y de `server/sshd_config.d/`.
4. Copia el kit a tu repositorio y haz el commit de la semana:
   ```bash
   cp -r config conf.d bin ca server ansible ci README.md ~/ssh-infra-kit/
   cd ~/ssh-infra-kit && git add -A && git commit -m "semana 13: diagnóstico y migración de algoritmos"
   git log --stat -1
   ```
   **Ninguna llave privada** en el commit: las de `~/w` son del laboratorio y se quedan ahí.

### Paso 8 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 13
```

Los checks de `bin/doctor` arrancan tres `sshd` sin root en `127.0.0.1` (2213 moderno, 2214 sin postcuántico, 2215 viejo) y usan `SSH_CMD` con una configuración de prueba que incluye tu `conf.d/`. Solo funcionan dentro del laboratorio.

## ✅ Requisitos verificables

- bin/doctor sin argumentos sale con 2 y dice cómo se usa
- bin/doctor entra con una conexión nueva aunque haya un master abierto, y escribe destino, kex postcuántico, host key, cifrado y método de entrada
- bin/doctor avisa cuando el intercambio de llaves no es postcuántico
- bin/doctor pasa a ssh las opciones que siguen al host (-o KexAlgorithms=...)
- Contra un servidor viejo, bin/doctor sale con 255, enseña lo que ofrece el servidor y apunta a los alias legado-*
- Con una host key cambiada, bin/doctor sale con 255 y apunta a comprobar la huella con bin/kh-add
- Con una llave que el servidor no acepta, bin/doctor sale con 255 y apunta al log del servidor (sshd -d)
- Sin nadie escuchando, bin/doctor sale con 255 y habla del puerto
- conf.d/90-legado.conf deja entrar a un alias legado-* en un servidor con grupo 14 SHA-1 y host key ssh-rsa
- Los algoritmos viejos solo se añaden a los alias legado-*: lab-server sigue sin ellos
- bin/key-audit marca DSA, RSA de 2048 y ECDSA, acepta Ed25519 (con opciones) y RSA de 3072, y sale con 1
- bin/key-audit sale con 0 si todo está bien (también leyendo de -), y con 2 sin argumentos o con un archivo sin llaves
- 15-algoritmos.conf exige RSA de 3072 bits: un sshd con él rechaza una llave RSA de 2048 y acepta una de 3072
- Sin TODOs, shellcheck sin avisos, el README documenta lo nuevo y los scripts anteriores siguen respondiendo

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): los comentarios Qué / Para qué / Impacto, que las pistas de `bin/doctor` lleven a un arreglo concreto, el README del kit y el historial de git sin llaves.

## Entrega

- [ ] `./scripts/verificar-semana.sh 13` con las 14 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ninguna llave en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Rotar host keys](../2-practicas/lab-07-rotar-host-keys/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 13](../README.md)
