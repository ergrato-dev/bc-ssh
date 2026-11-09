# Proyecto Semana 10 — ssh-infra-kit: tu autoridad de certificados

⏱ Duración estimada: ~3 h

## Contexto

Tu kit entra en `server` con una llave que está en su `authorized_keys`, y confía en `server` porque su host key está en tu `known_hosts`. Con un equipo y decenas de servidores, son dos listas que nunca están al día. Esta semana el kit gana **una CA**: firma personas y servidores, y los servidores solo necesitan conocerla a ella. Cuatro piezas:

- **`ca/ca-init`**: crea la CA de usuarios y la de hosts, fuera de git, con todo lo que necesitan las otras dos.
- **`ca/ca-sign`**: firma una llave con el siguiente número de serie, validez corta por defecto y una línea en el registro.
- **`ca/ca-revoke`**: revoca por número de serie, por certificado o por llave, sin arriesgar la KRL buena.
- **`server/sshd_config.d/50-ca.conf`**: `server` confía en tu CA, acepta roles, lee la KRL y presenta su certificado de host.

## Estructura del proyecto

```
starter/                    ← aquí trabajas: tu ssh-infra-kit de la semana 09 + TODOs
├── README.md               ← documentación del kit (TODOs)
├── config, conf.d/         ← semanas 05-09, terminados
├── bin/                    ← semanas 01-09, terminados
├── ca/
│   ├── ca-init             ← TODOs 1 y 2
│   ├── ca-sign             ← TODOs 3 y 4
│   └── ca-revoke           ← TODO 5
└── server/sshd_config.d/
    ├── 10-acceso.conf … 40-salto.conf   ← semanas 07 y 09
    └── 50-ca.conf          ← TODOs 6 a 9
solucion/                   ← referencia: no la abras hasta terminar
```

## Lo que debes construir

### La carpeta de la CA

`CA_DIR`, o `~/.ssh-ca` si no existe. **Nunca dentro del kit ni de ningún repositorio git**: tiene las llaves privadas.

| Archivo | Qué es | Permisos |
|---|---|---|
| `user_ca`, `host_ca` | Llaves privadas de las dos CA (Ed25519) | 600 |
| `user_ca.pub`, `host_ca.pub` | Lo que reciben servidores y clientes | 644 |
| `serial` | Último número de serie usado (empieza en 0) | 600 |
| `emitidos/SERIE-cert.pub` | Copia de cada certificado emitido | 600 |
| `emitidos.log` | Una línea por certificado: fecha, serie, tipo, identidad, principals, validez y huella | 600 |
| `revoked.krl` | La KRL (vacía al empezar) | 644 |

### Los tres scripts

| Script | Uso | Códigos |
|---|---|---|
| `ca/ca-init` | `ca-init [CARPETA]`. `CA_FRASE=` (vacía) para no pedir frase: **solo laboratorio** | 0 creada; 1 ya existe, dentro de git o `ssh-keygen` falla; 2 uso |
| `ca/ca-sign` | `ca-sign [-h] [-V VALIDEZ] [-O OPCIÓN]... LLAVE.pub IDENTIDAD PRINCIPALES`. Validez por defecto: `-5m:+8h` (usuario), `-5m:+52w` (host, con `-h`) | 0 firmado; 1 falta la llave o la CA, o `ssh-keygen` falla; 2 uso |
| `ca/ca-revoke` | `ca-revoke SERIE\|ARCHIVO...` | 0 revocados; 1 falta un archivo o la KRL, o `ssh-keygen` falla; 2 uso |

### `server/sshd_config.d/50-ca.conf`

| Opción | Valor | Lab |
|---|---|---|
| `TrustedUserCAKeys` | `/etc/ssh/user_ca.pub` | [01](../2-practicas/lab-01-primera-ca/README.md) |
| `AuthorizedPrincipalsFile` | `/etc/ssh/principals/%u` | [02](../2-practicas/lab-02-principals/README.md) |
| `RevokedKeys` | `/etc/ssh/revoked.krl` | [05](../2-practicas/lab-05-revocacion-krl/README.md) |
| `HostCertificate` | `/etc/ssh/ssh_host_ed25519_key-cert.pub` | [04](../2-practicas/lab-04-certificados-de-host/README.md) |

Cada opción lleva su **Qué / Para qué / Impacto** en un comentario.

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d --force-recreate server
docker compose run --rm client
```

Ya dentro del contenedor, enlaza el kit, `known_hosts` y una llave sin frase (**solo laboratorio**) instalada en `lab-server`:

```bash
cd bootcamp/week-10-certificados_ssh_ca_principals_krl_y_rotacion/3-proyecto/starter
mkdir -p -m 700 ~/.ssh ~/w
bin/kit-link
export SSHPASS=alumno
ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab.pub lab-server 2>&1 | grep 'Number of'
```

```
kit-link: /home/alumno/.ssh/kit -> /bc-ssh/bootcamp/week-10-certificados_ssh_ca_principals_krl_y_rotacion/3-proyecto/starter
Number of key(s) added: 1
```

`SSHPASS=alumno` es la contraseña del laboratorio: **solo del laboratorio**.

### Paso 1 — Lo que hay ahora

```bash
CA_FRASE= ca/ca-init; echo "código: $?"
ca/ca-sign ~/.ssh/lab.pub alumno@client admins; echo "código: $?"
```

```
ca-init: sin terminar (TODOs 1 y 2)
código: 1
ca-sign: sin terminar (TODOs 3 y 4)
código: 1
```

Los tres scripts leen ya sus argumentos y salen con 2 si están mal; lo demás es tuyo.

### Paso 2 — TODOs 1 y 2: `ca-init`

**TODO 1**: antes de crear nada, sal con 1 si la carpeta ya tiene `user_ca` o `host_ca`, o si está dentro de un repositorio git. La carpeta aún puede no existir: pregunta a `git` desde la primera carpeta padre que sí exista:

```bash
padre=$dir
while [[ ! -d $padre ]]; do padre=$(dirname "$padre"); done
git -C "$padre" rev-parse --is-inside-work-tree >/dev/null 2>&1
```

**TODO 2**: con `umask 077`, crea `emitidos/`, la carpeta en 700, las dos llaves con `ssh-keygen -q -t ed25519 -a 100 -C "CA de usuarios $(date +%Y)"` (y `hosts`), `serial` con `0`, `emitidos.log` vacío y la KRL con `ssh-keygen -q -k -f`. Al final, `.pub` y KRL en 644, y las dos huellas por pantalla.

- `-a 100`: 100 rondas de bcrypt para la frase, como `bin/key-new` (semana 03): adivinarla cuesta 100 veces más.
- `frase=(); [[ -v CA_FRASE ]] && frase=(-N "$CA_FRASE")`: con `CA_FRASE` definida, aunque esté vacía, no pregunta. Sin ella, `ssh-keygen` pide la frase. `"${frase[@]}"` se expande a nada si el array está vacío.

```bash
CA_FRASE= ca/ca-init
ls -l ~/.ssh-ca | cut -c1-10,40-
ca/ca-init; echo "código: $?"
```

```
ca-init: CA creada en /home/alumno/.ssh-ca
256 SHA256:9yAeivSX3CBDXJqu2XJM3vSRdvFSkSIr/BnpnhpFxyk CA de usuarios 2026 (ED25519)
256 SHA256:hRrCC16DxzVlNV7OxJOksNXKLArkZTx/2VeikkM0qfY CA de hosts 2026 (ED25519)
total 28
drwx------04:02 emitidos
-rw-------04:02 emitidos.log
-rw-------04:02 host_ca
-rw-r--r--04:02 host_ca.pub
-rw-r--r--04:02 revoked.krl
-rw-------04:02 serial
-rw-------04:02 user_ca
-rw-r--r--04:02 user_ca.pub
ca-init: /home/alumno/.ssh-ca ya tiene una CA; no la piso
código: 1
```

**`CA_FRASE=` deja la CA sin frase: solo en el laboratorio.** En tu equipo, `ca/ca-init` a secas, y la frase que te pida (lab 07).

### Paso 3 — TODOs 3 y 4: `ca-sign`

**TODO 3**: según `-h`, elige `host_ca` con validez `-5m:+52w` y `-h` para `ssh-keygen`, o `user_ca` con `-5m:+8h`; un `-V` explícito gana. Sal con 1 si no existe la llave, o si faltan `$ca.pub` o `serial` en la carpeta. Si la llave privada de la CA no está, firma desde el agente:

```bash
if [[ -f $dir/$ca ]]; then
  firma=(-s "$dir/$ca")
else
  firma=(-U -s "$dir/$ca.pub")
fi
```

**TODO 4**: el número de serie es el del contador más uno; firma con `ssh-keygen -q "${firma[@]}" "${extra[@]}" -I "$id" -n "$principales" -V "$validez" -z "$serie" "${opciones[@]}" "$pub"`. **Solo si la firma funciona**, guarda el número en `serial`, copia el certificado a `emitidos/$serie-cert.pub` y añade su línea a `emitidos.log` (con `printf`, como en el lab 07). Al revés, un fallo gastaría números.

```bash
ca/ca-sign ~/.ssh/lab.pub alumno@client admins
ssh-keygen -Lf ~/.ssh/lab-cert.pub | grep -E 'Key ID|Serial|Valid'
ca/ca-sign ~/.ssh/lab; echo "código: $?"
cut -c1-90 ~/.ssh-ca/emitidos.log
```

```
ca-sign: /home/alumno/.ssh/lab-cert.pub, serie 1 (usuario; admins; -5m:+8h)
        Key ID: "alumno@client"
        Serial: 1
        Valid: from 2026-11-09T03:57:14 to 2026-11-09T12:02:14
uso: ca-sign [-h] [-V VALIDEZ] [-O OPCIÓN]... LLAVE.pub IDENTIDAD PRINCIPALES
código: 2
2026-11-09T04:02:14Z serie=1 tipo=usuario id=alumno@client principals=admins validez=-5m:+
```

- Firmas `lab.pub` con el **rol** `admins`, no con el usuario: `server` decidirá en qué cuentas entra ese rol (paso 6).
- Sin `.pub`, `ca-sign` no firma: así no le pasas la llave privada por error.

### Paso 4 — TODO 5: `ca-revoke`

Un número de serie se convierte en `emitidos/SERIE-cert.pub`; cualquier otro argumento es un archivo. Lo importante es **no estropear la KRL buena**: si `revoked.krl` falta o está rota en un servidor, `sshd` rechaza todas las llaves (lab 05, paso 7). En el TODO:

1. Copia la KRL a un temporal en la misma carpeta (`mktemp "$dir/revoked.krl.XXXXXX"`), con `trap` que lo borre al salir.
2. `ssh-keygen -q -k -u -f "$tmp" "${archivos[@]}"`. Si falla: mensaje y 1.
3. Comprueba con `ssh-keygen -Q -f "$tmp"` que **todos** salen `REVOKED`. `-Q` sale con 1 si alguno lo está: guarda su salida con `|| true` y busca las líneas que no acaben en `: REVOKED`.
4. Solo entonces, `chmod 644` y `mv "$tmp" "$krl"`: en el mismo sistema de archivos, `mv` sustituye el archivo de una vez.

Pruébalo con una llave de usar y tirar:

```bash
ssh-keygen -q -t ed25519 -N '' -C prueba -f ~/w/prueba
ca/ca-sign ~/w/prueba.pub prueba@client admins
ca/ca-revoke 2
ca/ca-revoke 7; echo "código: $?"
ssh-keygen -Q -l -f ~/.ssh-ca/revoked.krl | tail -2
```

```
ca-sign: /home/alumno/w/prueba-cert.pub, serie 2 (usuario; admins; -5m:+8h)
/home/alumno/.ssh-ca/emitidos/2-cert.pub (prueba): REVOKED
ca-revoke: copia /home/alumno/.ssh-ca/revoked.krl a /etc/ssh/revoked.krl en cada servidor
ca-revoke: no existe /home/alumno/.ssh-ca/emitidos/7-cert.pub
código: 1
# CA key ssh-ed25519 SHA256:9yAeivSX3CBDXJqu2XJM3vSRdvFSkSIr/BnpnhpFxyk
serial: 2
```

### Paso 5 — TODOs 6 a 9: `50-ca.conf`

En `server/sshd_config.d/50-ca.conf`, las cuatro opciones de la tabla, cada una con su **Qué / Para qué / Impacto**. El Impacto de `RevokedKeys` tiene que decir qué pasa si el archivo falta; el de `AuthorizedPrincipalsFile`, qué pasa con una cuenta sin archivo. Compruébalo en `server` antes de desplegar:

```bash
tar -cf - server | ssh -F config lab-server 'd=$(mktemp -d); tar -xf - -C $d; sed "s|/etc/ssh/sshd_config.d|$d/server/sshd_config.d|" /etc/ssh/sshd_config > $d/main; sudo groupadd -f saltadores; sudo sshd -t -f $d/main && echo válida; rm -rf $d'
```

```
Could not load host certificate "/etc/ssh/ssh_host_ed25519_key-cert.pub": No such file or directory
válida
```

El aviso es correcto: el certificado de host aún no existe. `sshd -t` no comprueba los demás archivos. Por eso el paso siguiente los instala **antes**.

### Paso 6 — Desplegar en `server`

Primero los archivos que nombra `50-ca.conf`, después la configuración. Firma la host key de `server` (la trajiste por una conexión ya verificada: tu `known_hosts` del paso 0) y sube todo:

```bash
scp -F config -q lab-server:/etc/ssh/ssh_host_ed25519_key.pub ~/w/server.pub
ca/ca-sign -h ~/w/server.pub server server
scp -F config -q ~/.ssh-ca/user_ca.pub ~/.ssh-ca/revoked.krl ~/w/server-cert.pub lab-server:
ssh -F config lab-server 'sudo install -m 644 user_ca.pub revoked.krl /etc/ssh/
sudo install -m 644 server-cert.pub /etc/ssh/ssh_host_ed25519_key-cert.pub
sudo install -d -m 755 /etc/ssh/principals
echo admins | sudo tee /etc/ssh/principals/alumno
sudo groupadd -f ssh-users; sudo groupadd -f saltadores; sudo usermod -aG ssh-users alumno'
bin/sshd-deploy lab-server
```

```
ca-sign: /home/alumno/w/server-cert.pub, serie 3 (host; server; -5m:+52w)
admins
sshd-apply: aplicada; se deshace en 60 s si no se confirma
sshd-deploy: aplicada y confirmada en lab-server
```

- `principals/alumno` con `admins`: la cuenta `alumno` acepta certificados con ese rol. Los archivos son de `root`: `sshd` no acepta uno que pueda escribir el propio usuario.
- `ssh-users` y `saltadores`: los grupos que piden `10-acceso.conf` y `40-salto.conf` (semanas 07 y 09).
- `bin/sshd-deploy` prueba con una conexión nueva y deshace el cambio si te deja fuera. Prueba a desplegar **sin** subir `revoked.krl`: verás la vuelta atrás.

### Paso 7 — Confiar en `server` por la CA

Sustituye tu `known_hosts` por la línea de la CA de hosts:

```bash
bin/mux stop >/dev/null
echo "@cert-authority server,bastion,interno $(cat ~/.ssh-ca/host_ca.pub)" > ~/.ssh/known_hosts
ssh -F config lab-server hostname
ssh -v -F config -P sinmux lab-server true 2>&1 | grep -E 'is known|Server accepts' | cut -c1-90
```

```
server
debug1: Host 'server' is known and matches the ED25519-CERT host certificate.
debug1: Server accepts key: /home/alumno/.ssh/lab ED25519-CERT SHA256:8pppqZcIKPOI9TSyV1v0
```

`StrictHostKeyChecking yes` del kit sigue en pie: no hay pregunta porque no hace falta. `-P sinmux` (semana 05) fuerza una conexión nueva, para ver el intercambio en `-v`.

### Paso 8 — Sin `authorized_keys`, y revocar

Vacía tu `authorized_keys` en `server`: el certificado basta.

```bash
ssh -F config lab-server ': > ~/.ssh/authorized_keys'
bin/mux stop >/dev/null
ssh -F config lab-server hostname
```

```
server
```

Ahora tu llave «se filtró». Revoca su certificado (serie 1), sube la KRL y prueba con una conexión nueva:

```bash
ca/ca-revoke 1
scp -F config -q ~/.ssh-ca/revoked.krl lab-server:
ssh -F config lab-server 'sudo install -m 644 revoked.krl /etc/ssh/'
bin/mux stop >/dev/null
ssh -F config lab-server hostname; echo "código: $?"
```

```
/home/alumno/.ssh-ca/emitidos/1-cert.pub (alumno@client): REVOKED
ca-revoke: copia /home/alumno/.ssh-ca/revoked.krl a /etc/ssh/revoked.krl en cada servidor
alumno@server: Permission denied (publickey).
código: 255
```

- El `scp` y el `ssh` de después aún entran: van por el master que abrió la orden anterior, autenticado antes de revocar (lab 03, paso 6). Por eso `bin/mux stop` antes de probar.
- Sin `authorized_keys` ni certificado válido, no entras ni con la llave.

Revocaste un **certificado**, no la llave: uno nuevo vuelve a entrar. Si la llave se hubiera filtrado de verdad, revocarías `~/.ssh/lab.pub` y crearías otra.

```bash
ca/ca-sign ~/.ssh/lab.pub alumno@client admins
ssh -F config lab-server hostname
```

```
ca-sign: /home/alumno/.ssh/lab-cert.pub, serie 4 (usuario; admins; -5m:+8h)
server
```

En tu equipo, el log de `server` (`LogLevel VERBOSE`, semana 07) dice qué certificado entró:

```bash
docker compose logs --no-log-prefix server | grep 'Accepted certificate' | tail -1
```

```
Accepted certificate ID "alumno@client" (serial 4) signed by ED25519 CA SHA256:9yAeivSX3CBDXJqu2XJM3vSRdvFSkSIr/BnpnhpFxyk via /etc/ssh/user_ca.pub
```

### Paso 9 — Calidad, README y git

1. `shellcheck bin/* ca/*` sin avisos, y ningún `TODO` en `config`, `conf.d/`, `bin/`, `ca/` ni `server/`.
2. Completa los TODOs de `starter/README.md`: las filas de `ca/ca-init`, `ca/ca-sign`, `ca/ca-revoke` y `50-ca.conf`, la bitácora de la semana 10 y la sección "Autoridad de certificados" (dónde vive la CA y por qué fuera de git, preparar un servidor nuevo, firmar a una persona, revocar y subir la KRL, y rotar la CA).
3. Copia el kit a tu repositorio y haz el commit de la semana:
   ```bash
   cp -r config conf.d bin ca server README.md ~/ssh-infra-kit/
   cd ~/ssh-infra-kit && git add -A && git commit -m "semana 10: CA de usuarios y hosts, ca-sign y ca-revoke"
   git log --stat -1
   ```
   En el commit deben aparecer `README.md`, `ca/` y `server/sshd_config.d/50-ca.conf`: **ni `~/.ssh-ca`, ni llaves, ni certificados**.

### Paso 10 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 10
```

Los checks crean una CA de usar y tirar en una carpeta temporal con `CA_DIR` y `CA_FRASE=`, y prueban cada script. Los dos últimos arrancan un `sshd` propio en `127.0.0.1:2211` con tu `50-ca.conf` (rutas cambiadas a esa carpeta): sin `authorized_keys`, con un certificado de host y un `known_hosts` que solo tiene la CA. Solo se ejecutan dentro del laboratorio.

## ✅ Requisitos verificables

- ca-init crea user_ca y host_ca Ed25519 en una carpeta 700, con contador a 0 y una KRL vacía
- ca-init sale con 1 y no toca una CA que ya existe
- ca-init sale con 1 y no crea nada dentro de un repositorio git
- ca-init, ca-sign y ca-revoke salen con 2 por uso incorrecto (sin .pub, identidad con espacios, opción desconocida)
- ca-sign firma un certificado de usuario con user_ca, la identidad, los principals y el número de serie 1
- ca-sign da 8 h y 5 min de margen por defecto a un usuario, y respeta -V
- ca-sign -h firma un certificado de host con host_ca, sus nombres y un año de validez
- ca-sign numera cada certificado, guarda una copia en emitidos/ y una línea en emitidos.log
- ca-sign pasa las -O a ssh-keygen (force-command, source-address)
- ca-sign sale con 1 sin CA o sin la llave, y no gasta números de serie
- ca-sign firma con la CA cargada en el agente si su llave privada no está en la carpeta
- ca-revoke revoca un certificado sin revocar su llave ni los demás certificados
- ca-revoke SERIE revoca por número; con un número que no existe sale con 1 y no toca la KRL
- ca-revoke de una llave pública revoca sus certificados de antes y de después
- sshd confía en /etc/ssh/user_ca.pub, lee principals/%u y revoked.krl, y presenta el certificado de host
- Con el kit, un certificado con el rol admins entra sin authorized_keys en un sshd que solo conoces por la CA de hosts
- Tras ca-revoke y copiar la KRL, el mismo certificado ya no entra
- Sin TODOs, shellcheck sin avisos y los scripts anteriores siguen respondiendo

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): los comentarios Qué / Para qué / Impacto de los scripts y de `50-ca.conf`, los mensajes de error, el README del kit y el historial de git sin llaves.

## Entrega

- [ ] `./scripts/verificar-semana.sh 10` con las 18 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ninguna llave ni certificado en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Proteger la CA y saber qué firmó](../2-practicas/lab-07-proteger-y-auditar-la-ca/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 10](../README.md)
