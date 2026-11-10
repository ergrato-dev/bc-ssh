# Proyecto Semana 11 — ssh-infra-kit: auditoría, segundo factor y fail2ban

⏱ Duración estimada: ~3 h

## Contexto

Tu kit ya endurece `sshd`, salta a la red privada y firma certificados. Le faltan tres cosas que en un servidor expuesto a Internet se notan el primer día: saber si lo que anuncia es seguro, pedir algo más que una llave, y quitarse de encima a los robots. Esta semana gana:

- **`server/sshd_config.d/15-algoritmos.conf`**: sin curvas NIST, grupo 14, SHA-1, `umac-64` ni MAC sin `-etm`.
- **`server/ssh-audit-politica.txt` y `bin/audit`**: la lista de lo permitido y un script que comprueba con `ssh-audit` cada servidor del kit.
- **`server/sshd_config.d/60-2fa.conf` y `server/pam.d/sshd`**: llave **y** código TOTP para el grupo `dosfa`.
- **`server/fail2ban/jail.d/sshd.local`**: la jaula `sshd` de fail2ban.
- **`server/sshd-apply` y `bin/sshd-deploy`**: instalan y deshacen también el PAM y la jaula.

## Estructura del proyecto

```
starter/                        ← aquí trabajas: tu ssh-infra-kit de la semana 10 + TODOs
├── README.md                   ← documentación del kit (TODOs)
├── config, conf.d/, ca/        ← semanas 05-10, terminados
├── bin/
│   ├── audit                   ← TODOs 3 y 4
│   ├── sshd-deploy             ← TODO 9
│   └── …                       ← semanas 01-10, terminados
└── server/
    ├── sshd-apply              ← TODO 8
    ├── ssh-audit-politica.txt  ← TODO 2
    ├── sshd_config.d/
    │   ├── 15-algoritmos.conf  ← TODO 1
    │   ├── 60-2fa.conf         ← TODO 5
    │   └── 10-acceso … 50-ca   ← semanas 07-10
    ├── pam.d/sshd              ← TODO 6
    └── fail2ban/jail.d/sshd.local  ← TODO 7
solucion/                       ← referencia: no la abras hasta terminar
```

## Lo que debes construir

### `bin/audit`

| Uso | Salida | Códigos |
|---|---|---|
| `audit [-p POLÍTICA] HOST...` | Una línea por host: `HOST: cumple`, `HOST: no cumple` seguida de las líneas `  * ...` de `ssh-audit`, o `HOST: no responde` | 0 todos cumplen; 1 alguno no cumple o no responde (o `ssh-audit` falla); 2 uso incorrecto o política ilegible |

`HOST` es un alias de `conf.d/` o un nombre: el nombre real y el puerto salen de `$SSH_CMD -G HOST` (`ssh -F config` del kit por defecto), como en `kh-add` y `sshd-deploy`.

### Archivos de `server/`

| Archivo | Contenido | Lab |
|---|---|---|
| `sshd_config.d/15-algoritmos.conf` | `KexAlgorithms`, `HostKeyAlgorithms` y `MACs` con listas `-` | [02](../2-practicas/lab-02-quitar-algoritmos/README.md) |
| `ssh-audit-politica.txt` | Política con subconjunto, claves más grandes, certificados opcionales y `mlkem768x25519-sha256` | [03](../2-practicas/lab-03-politicas-ssh-audit/README.md) |
| `sshd_config.d/60-2fa.conf` | `Match Group dosfa`: `KbdInteractiveAuthentication yes` y `AuthenticationMethods publickey,keyboard-interactive` | [05](../2-practicas/lab-05-llave-y-codigo/README.md) |
| `pam.d/sshd` | El de Ubuntu 24.04 con `pam_google_authenticator.so` en lugar de `common-auth` | [05](../2-practicas/lab-05-llave-y-codigo/README.md) |
| `fail2ban/jail.d/sshd.local` | `[sshd]`: `mode = normal`, `backend = auto`, `logpath = /var/log/auth.log`, 5 fallos en `10m`, `1h` creciente hasta `1w`, `ignoreip` local | [06](../2-practicas/lab-06-fail2ban/README.md) |

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
cd bootcamp/week-11-2fa_fail2ban_y_auditoria/3-proyecto/starter
mkdir -p -m 700 ~/.ssh ~/w
bin/kit-link
export SSHPASS=alumno
ssh-keyscan -t ed25519 server 2>/dev/null > ~/.ssh/known_hosts
ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
sshpass -e ssh-copy-id -F config -o ControlPath=none -i ~/.ssh/lab.pub lab-server 2>&1 | grep 'Number of'
```

```
kit-link: /home/alumno/.ssh/kit -> /bc-ssh/bootcamp/week-11-2fa_fail2ban_y_auditoria/3-proyecto/starter
Number of key(s) added: 1
```

`SSHPASS=alumno` es la contraseña del laboratorio: **solo del laboratorio**.

### Paso 1 — TODO 1: `15-algoritmos.conf`

Escribe las tres líneas del [lab 02](../2-practicas/lab-02-quitar-algoritmos/README.md), cada una con su Qué / Para qué / Impacto. El Impacto dice qué clientes dejan de conectar. Comprueba el resultado sin servidor, con un `sshd` de prueba que solo lee tu archivo:

```bash
ssh-keygen -q -t ed25519 -N '' -f ~/w/hk
echo "Include $PWD/server/sshd_config.d/15-algoritmos.conf" > ~/w/sshd.conf
/usr/sbin/sshd -T -f ~/w/sshd.conf -h ~/w/hk | grep -E '^(kexalgorithms|macs) '
```

```
macs umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
kexalgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
```

`-T` no arranca nada: imprime la configuración final y sale. `-h` le da una host key cualquiera, porque sin ella se niega.

### Paso 2 — TODOs 2, 3 y 4: la política y `bin/audit`

**TODO 2**: la política del [lab 03](../2-practicas/lab-03-politicas-ssh-audit/README.md), paso 5, con comentarios (`#`) que expliquen `allow_algorithm_subset_and_reordering`, `allow_larger_keys`, por qué está `mlkem768x25519-sha256` y qué son `ext-info-s` y `kex-strict-s-v00@openssh.com`.

**TODO 3**: por cada `HOST`, el nombre y el puerto con `ssh -G`, sin conectar:

```bash
read -r nombre puerto < <($ssh_cmd -G "$host" 2>/dev/null |
  awk '$1 == "hostname" { h = $2 } $1 == "port" { p = $2 } END { print h, p }')
```

**TODO 4**: `ssh-audit -n -P "$politica" -p "$puerto" "$nombre"`, guardando la salida y el código sin que `set -e` corte el script (`codigo=0; salida=$(...) || codigo=$?`). Según el código:

| `ssh-audit` | `audit` escribe | `resultado` |
|---|---|---|
| 0 | `HOST: cumple` | — |
| 3 | `HOST: no cumple` y las líneas de la salida que empiezan por `  *` | 1 |
| 1 | `HOST: no responde` | 1 |
| otro | por stderr: la política no es válida | 1 |

Pruébalo con `server` tal como viene (sin desplegar nada):

```bash
bin/audit lab-server nohay; echo "código: $?"
```

```
lab-server: no cumple
  * Host keys did not match.
  * Key exchanges did not match.
  * MACs did not match.
nohay: no responde
código: 1
```

`ssh-audit` solo mira lo que `server` anuncia: no hace falta que el kit entre.

### Paso 3 — TODO 5: `60-2fa.conf`

El bloque `Match Group dosfa` del [lab 05](../2-practicas/lab-05-llave-y-codigo/README.md), paso 3. En el Impacto de `AuthenticationMethods`: estas cuentas necesitan una terminal (nada de `BatchMode`, `cron` ni `bin/backup`). Y en el de `Match`: qué le pasa a quien entra en el grupo antes de crear su secreto.

`10-acceso.conf` deja `KbdInteractiveAuthentication no` para todos: dentro del `Match` lo cambias solo para el grupo. Compruébalo con el `sshd` de prueba del paso 1:

```bash
for f in 10-acceso 60-2fa; do echo "Include $PWD/server/sshd_config.d/$f.conf"; done > ~/w/sshd.conf
sudo groupadd -f dosfa
/usr/sbin/sshd -T -f ~/w/sshd.conf -h ~/w/hk -C user=alumno,host=x,addr=1.2.3.4 | grep -iE '^(authenticationmethods|kbdinteractive)'
sudo usermod -aG dosfa alumno
/usr/sbin/sshd -T -f ~/w/sshd.conf -h ~/w/hk -C user=alumno,host=x,addr=1.2.3.4 | grep -iE '^(authenticationmethods|kbdinteractive)'
sudo gpasswd -d alumno dosfa
```

```
kbdinteractiveauthentication no
authenticationmethods any
kbdinteractiveauthentication yes
authenticationmethods publickey,keyboard-interactive
Removing user alumno from group dosfa
```

`sudo` sin contraseña en el cliente: **solo en el laboratorio**.

### Paso 4 — TODO 6: el PAM de `sshd`

`server/pam.d/sshd` es el de Ubuntu 24.04 tal cual. Comenta `@include common-auth` y añade debajo:

```
auth required pam_google_authenticator.so secret=${HOME}/.google_authenticator
```

En el comentario: por qué no se pide la contraseña de Unix, qué pasaría con `PasswordAuthentication yes`, y por qué no hay `nullok`. Compara con el original:

```bash
diff /etc/pam.d/sshd server/pam.d/sshd | grep -E '^[<>] (@include common-auth|# @include common-auth|auth )'
```

```
< @include common-auth
> # @include common-auth
> auth required pam_google_authenticator.so secret=${HOME}/.google_authenticator
```

El `grep` deja fuera tus líneas de comentario: el resto del archivo tiene que ser igual al original.

### Paso 5 — TODO 7: la jaula de fail2ban

Las opciones del [lab 06](../2-practicas/lab-06-fail2ban/README.md) con los valores del kit (tabla de arriba). En el comentario de `mode`, por qué `normal` y no `aggressive`; en el de `ignoreip`, por qué no se añaden redes «por si acaso». Pruébala sobre una copia de `/etc/fail2ban`, sin arrancar nada:

```bash
cp -r /etc/fail2ban ~/w/f2b
cp server/fail2ban/jail.d/sshd.local ~/w/f2b/jail.d/
sudo touch /var/log/auth.log
fail2ban-client -c ~/w/f2b -t 2>&1 | tail -1
fail2ban-client -c ~/w/f2b -d 2>/dev/null | grep -E "'sshd', '(maxretry|findtime|bantime)"
```

```
OK: configuration test is successful
['set', 'sshd', 'maxretry', 5]
['set', 'sshd', 'findtime', '10m']
['set', 'sshd', 'bantime', '1h']
```

`-d` vuelca la configuración ya combinada (`.conf` + `.local`): lo que fail2ban usaría.

### Paso 6 — TODOs 8 y 9: `sshd-apply` y `sshd-deploy`

**TODO 8**, en `server/sshd-apply` (es `sh`, no `bash`: nada de `[[ ]]` ni arrays):

1. Dos variables, `con_pam` y `con_f2b`: `si` si `CARPETA/pam.d/sshd` existe, y si existen `CARPETA/fail2ban/jail.d` **y** `fail2ban-client`.
2. Después de instalar `sshd_config.d`: con PAM, copia `/etc/pam.d/sshd` a `/etc/pam.d/sshd.anterior` e instala el nuevo con `install -m 644 -o root -g root`; con fail2ban, lo mismo con la carpeta `/etc/fail2ban/jail.d` (`jail.d.anterior`) y los `.local`.
3. La validación: `sshd -t` **y**, con fail2ban, `fail2ban-client -t`.
4. `restaurar()` devuelve también PAM y jaulas; `recargar()` hace, con fail2ban, `fail2ban-client reload` o, si no está arrancado, `fail2ban-client start </dev/null >/dev/null 2>&1`. PAM no se recarga: `sshd` lo lee en cada conexión.

**TODO 9**, en `bin/sshd-deploy`: el `tar` envía `sshd-apply` y `sshd_config.d`, y además `pam.d` y `fail2ban` **solo si existen** en `server/` (un array `partes` y `"${partes[@]}"`).

Un despliegue que te deja fuera tiene que deshacer **todo**: un PAM roto sin vuelta atrás deja el servidor sin nadie que pueda entrar.

### Paso 7 — Desplegar en `lab-server` y probar

1. Prepara `server` en este orden: los grupos (con `AllowGroups ssh-users`, si no estás en él, te quedas fuera) y `revoked.krl` (con `RevokedKeys` de la semana 10 y sin el archivo, `sshd` rechaza todas las llaves):
   ```bash
   ssh -F config lab-server 'sudo groupadd -f ssh-users; sudo groupadd -f dosfa; sudo usermod -aG ssh-users alumno; sudo touch /etc/ssh/revoked.krl'
   bin/mux stop >/dev/null
   bin/sshd-deploy lab-server
   ```
   ```
   Could not load host certificate "/etc/ssh/ssh_host_ed25519_key-cert.pub": No such file or directory
   sshd-apply: aplicada; se deshace en 60 s si no se confirma
   sshd-deploy: aplicada y confirmada en lab-server
   ```
   El aviso del certificado de host es de `50-ca.conf`: en este `server` recién creado no hay CA. No impide entrar.

2. Audita:
   ```bash
   bin/audit lab-server; echo "código: $?"
   ```
   ```
   lab-server: cumple
   código: 0
   ```

3. fail2ban arrancó con tu jaula:
   ```bash
   ssh -F config lab-server 'sudo fail2ban-client status sshd | tail -3'
   ```
   ```
      |- Currently banned:	0
      |- Total banned:	0
      `- Banned IP list:
   ```

4. El segundo factor, en orden: el secreto, luego el grupo, luego una conexión **nueva**:
   ```bash
   ssh -F config lab-server 'google-authenticator -t -d -f -r 3 -R 30 -w 3 -e 5 -C -Q NONE -q'
   S=$(ssh -F config lab-server head -1 .google_authenticator)
   ssh -F config lab-server 'sudo usermod -aG dosfa alumno'
   bin/mux stop >/dev/null
   oathtool --totp -b "$S"; ssh -F config -P sinmux lab-server 'id -nG'
   ```
   ```
   406723
   (alumno@server) Verification code:
   alumno adm dialout cdrom floppy sudo audio dip video plugdev ssh-users dosfa
   ```
   Escribe el código que imprimió `oathtool`. El secreto en `$S` es **solo del laboratorio**. Desde aquí, `bin/sshd-deploy lab-server` también te pedirá el código para confirmar: así debe ser.

### Paso 8 — Calidad, README y git

1. `shellcheck bin/* ca/*` y `shellcheck -s sh server/sshd-apply` sin avisos, y ningún `TODO` en `README.md`, `config`, `conf.d/`, `bin/`, `ca/` ni `server/`.
2. Completa los TODOs de `starter/README.md`: las filas de `server/pam.d/sshd`, la jaula, la política y `bin/audit`; `15-algoritmos.conf` y `60-2fa.conf` en la fila de `sshd_config.d`; la bitácora de la semana 11 y la sección "Segundo factor, fail2ban y auditoría" (cuándo auditar y qué hacer con un `no cumple`; el alta del segundo factor en orden y qué hacer si alguien pierde el móvil; ver y deshacer bloqueos, y qué hacer si te bloqueas a ti). Actualiza también las filas de `sshd-deploy` y `sshd-apply`, y los requisitos (`ssh-audit`, `libpam-google-authenticator`, `fail2ban`).
3. Copia el kit a tu repositorio y haz el commit de la semana:
   ```bash
   cp -r config conf.d bin ca server README.md ~/ssh-infra-kit/
   cd ~/ssh-infra-kit && git add -A && git commit -m "semana 11: ssh-audit, segundo factor TOTP y fail2ban"
   git log --stat -1
   ```
   En el commit deben aparecer `bin/audit` y los archivos nuevos de `server/`: **ningún `.google_authenticator`, secreto ni código de emergencia**.

### Paso 9 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 11
```

Los checks de `bin/audit` arrancan dos `sshd` sin root en `127.0.0.1` (uno con tu `15-algoritmos.conf`, otro con los valores por defecto). Los del segundo factor, un `sshd` como root con tus `10-acceso`, `15-algoritmos` y `60-2fa`, tu PAM y un secreto TOTP de usar y tirar. El de fail2ban arranca uno con tu jaula leyendo un log de prueba. Los de despliegue repiten el paso 7 contra un `sshd` local. Solo funcionan dentro del laboratorio.

## ✅ Requisitos verificables

- audit sale con 2 sin hosts, con una opción desconocida o sin política legible
- audit dice «cumple» y sale con 0 con un sshd que usa 15-algoritmos.conf, resolviendo el alias con ssh -G
- audit dice «no cumple», enseña qué falla y sale con 1 si un host ofrece algoritmos fuera de la política
- audit dice «no responde» y sale con 1 si no puede conectar
- 15-algoritmos.conf quita curvas NIST, grupo 14, SHA-1, umac-64 y MAC sin etm, y conserva sntrup761 y los certificados Ed25519
- La política acepta un servidor que ofrece menos algoritmos y rechaza uno que añade un cifrado CBC
- Con 60-2fa.conf, un usuario de dosfa con su llave no entra sin código (keyboard-interactive)
- Un usuario de dosfa entra con su llave y el código TOTP, que PAM pide como «Verification code» y no como contraseña
- Un código equivocado no entra, y el mismo código bueno no sirve dos veces
- El código TOTP sin la llave no entra: primero publickey
- Quien no está en dosfa sigue entrando solo con su llave
- La jaula sshd del kit es válida: activa, lee /var/log/auth.log, 5 fallos en 10m, 1h creciente hasta 1w
- fail2ban bloquea la IP con 5 usuarios inválidos, no la de 4 ni la de conexiones cerradas sin autenticar, ni 127.0.0.1
- sshd-deploy instala sshd_config.d, pam.d/sshd y la jaula de fail2ban, arranca fail2ban y confirma
- Si no se confirma, sshd-apply devuelve también el PAM y las jaulas anteriores
- Sin TODOs, shellcheck sin avisos y los scripts anteriores siguen respondiendo

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): los comentarios Qué / Para qué / Impacto de cada archivo, los mensajes de `bin/audit`, el README del kit y el historial de git sin secretos.

## Entrega

- [ ] `./scripts/verificar-semana.sh 11` con las 16 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ningún secreto TOTP ni llave en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Leer el log](../2-practicas/lab-07-leer-el-log/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 11](../README.md)
