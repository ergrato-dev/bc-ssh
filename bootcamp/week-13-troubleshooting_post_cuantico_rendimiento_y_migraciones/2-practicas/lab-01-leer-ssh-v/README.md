# Lab 01 — Leer `ssh -v`

⏱ Duración estimada: ~60 min

## Objetivo

Seguir una conexión SSH paso a paso con `ssh -v`, de la configuración que resuelve tu cliente hasta el código de salida, y reconocer por su mensaje en qué paso falla cada error típico: el nombre, el puerto, la red, los algoritmos o la llave.

## Contexto

- Las capas de una conexión y qué error da cada una: [teoría 01](../../1-teoria/01-diagnostico-por-capas.md#una-conexión-por-capas).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación.** En tu equipo, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server bastion interno
   docker compose run --rm client
   ```
   `--force-recreate` deja los servidores como recién instalados: cada lab empieza limpio. **En el cliente**, `known_hosts` y una llave de administrador en `server` y `bastion`:
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh ~/w
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C admin@client -f ~/.ssh/id_ed25519
   sshpass -e ssh-copy-id -f server 2>&1 | grep 'Number of'
   sshpass -e ssh-copy-id -f bastion 2>&1 | grep 'Number of'
   ```
   ```
   Number of key(s) added: 1
   Number of key(s) added: 1
   ```
   Llave sin frase (`-N ''`) y la contraseña en `SSHPASS`: **solo en el laboratorio**.

1. **Antes de conectar: qué va a hacer `ssh`.** `ssh -G` imprime la configuración final para un host, sin conectar:
   ```bash
   ssh -G server | grep -E '^(user|hostname|port|connecttimeout|stricthostkeychecking) '
   ```
   ```
   user alumno
   hostname server
   port 22
   stricthostkeychecking ask
   connecttimeout none
   ```
   - Es lo primero que miras cuando "no conecta": la mitad de las veces el alias apunta a otro nombre, otro puerto u otro usuario.
   - `connecttimeout none`: sin `ConnectTimeout`, un host que no responde te tiene esperando lo que diga el sistema (unos 2 min). Tu kit pone 5 s.

2. **Una conexión que funciona, línea a línea.**
   ```bash
   ssh -v server true 2>&1 | grep -E 'Connecting|Connection established|Remote protocol|kex: (algorithm|host key|client)|Server host key|is known|Authentications that|Offering|Server accepts|Authenticated|Exit status'
   ```
   ```
   debug1: Connecting to server [172.20.0.2] port 22.
   debug1: Connection established.
   debug1: Remote protocol version 2.0, remote software version OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   debug1: kex: algorithm: sntrup761x25519-sha512@openssh.com
   debug1: kex: host key algorithm: ssh-ed25519
   debug1: kex: client->server cipher: chacha20-poly1305@openssh.com MAC: <implicit> compression: none
   debug1: Server host key: ssh-ed25519 SHA256:2ljR7FgI9NBHmXgXzVYVgEi+2j3e140cN+rVH3BmkQg
   debug1: Host 'server' is known and matches the ED25519 host key.
   debug1: Authentications that can continue: publickey,password
   debug1: Offering public key: /home/alumno/.ssh/id_ed25519 ED25519 SHA256:Gmij3RUkXCAjU7MNogjC9Jvm0RX0Hn51wYPBFODPFdE
   debug1: Server accepts key: /home/alumno/.ssh/id_ed25519 ED25519 SHA256:Gmij3RUkXCAjU7MNogjC9Jvm0RX0Hn51wYPBFODPFdE
   Authenticated to server ([172.20.0.2]:22) using "publickey".
   debug1: Exit status 0
   ```
   `-v` escribe en `stderr` (por eso `2>&1`). Tus huellas serán otras. Cada bloque es una capa:

   | Líneas | Capa | Si falla aquí |
   |---|---|---|
   | `Connecting to server [172.20.0.2]` | Nombre resuelto a una IP | `Could not resolve hostname` |
   | `Connection established` | TCP | `Connection refused`, `Connection timed out` |
   | `Remote protocol version` | El banner: al otro lado hay un SSH | `kex_exchange_identification` |
   | `kex: ...` | Algoritmos negociados | `no matching ... found. Their offer:` |
   | `Server host key`, `is known` | La identidad del servidor | `Host key verification failed` |
   | `Offering`, `Server accepts`, `Authenticated` | Tu identidad | `Permission denied` |
   | `Exit status` | El comando remoto | Su código (`ssh` sale con él) |

3. **Las dos ofertas.** Con `-vvv` (más detalle) ves la lista completa de cada lado:
   ```bash
   ssh -vvv server true 2>&1 | grep -A2 'KEXINIT proposal' | cut -c1-100
   ```
   ```
   debug2: local client KEXINIT proposal
   debug2: KEX algorithms: sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libss
   debug2: host key algorithms: ssh-ed25519-cert-v01@openssh.com,ecdsa-sha2-nistp256-cert-v01@openssh.c
   --
   debug2: peer server KEXINIT proposal
   debug2: KEX algorithms: sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libss
   debug2: host key algorithms: rsa-sha2-512,rsa-sha2-256,ecdsa-sha2-nistp256,ssh-ed25519
   ```
   - Gana **el primero de la lista del cliente** que también esté en la del servidor. Por eso sale `ssh-ed25519` aunque el servidor ponga primero `rsa-sha2-512`.
   - Para cifrados y MAC se negocia igual, una vez por sentido (`ctos`, cliente a servidor; `stoc`, al revés).
   - `cut -c1-100` corta las líneas: sin él, cada lista ocupa varias líneas de pantalla.

4. **Guardar el log.** `-E` manda los mensajes a un archivo y deja la terminal limpia:
   ```bash
   ssh -v -E ~/w/ssh.log server true; echo "código: $?"; wc -l < ~/w/ssh.log
   ```
   ```
   código: 0
   93
   ```
   Útil cuando el fallo es intermitente: guarda el log de cada intento y compáralos después.

5. **Cuatro errores, cuatro capas.** Ejecuta uno por uno y fíjate en la primera palabra útil de cada mensaje:
   ```bash
   ssh servr true; echo "código: $?"
   ssh -p 2222 server true; echo "código: $?"
   ssh -o ConnectTimeout=3 10.255.255.1 true; echo "código: $?"
   ssh -o Ciphers=aes128-cbc server true; echo "código: $?"
   ```
   ```
   ssh: Could not resolve hostname servr: Name or service not known
   código: 255
   ssh: connect to host server port 2222: Connection refused
   código: 255
   ssh: connect to host 10.255.255.1 port 22: Connection timed out
   código: 255
   Unable to negotiate with 172.20.0.2 port 22: no matching cipher found. Their offer: chacha20-poly1305@openssh.com,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com
   código: 255
   ```
   - **Nombre**: un error de escritura, o un DNS que no conoce el host. `getent hosts servr` lo confirma sin SSH.
   - **Refused**: la máquina responde, pero nadie escucha en ese puerto (sshd parado o en otro puerto). Es rápido: la respuesta llega al momento.
   - **Timed out**: no responde nadie. Máquina apagada, ruta inexistente, o un cortafuegos que tira los paquetes (también una IP bloqueada por fail2ban, [semana 11](../../../week-11-2fa_fail2ban_y_auditoria/README.md)). `10.255.255.1` es una IP que no existe en el laboratorio.
   - **No matching**: los dos lados hablan SSH pero no comparten ningún algoritmo de una lista. `Their offer` dice lo que acepta el servidor; aquí, porque tu cliente pidió solo `aes128-cbc`, un cifrado que el servidor ya no admite. El [lab 03](../lab-03-sin-algoritmo-en-comun/README.md) es entero sobre esto.
   - Todos salen con **255**: es `ssh` quien falla, no el comando remoto.

6. **La llave que no entra.** Una llave que `server` no conoce:
   ```bash
   ssh-keygen -q -t ed25519 -N '' -C alumno@otra -f ~/.ssh/otra
   ssh -v -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/otra server true 2>&1 | grep -E 'Authentications that|Offering|No more|Permission'
   ```
   ```
   debug1: Authentications that can continue: publickey,password
   debug1: Offering public key: /home/alumno/.ssh/otra ED25519 SHA256:pRbD8vKhAHRiYGZ7/WYzERqTNdIaUfIg62VTyf0Zkxw explicit
   debug1: Authentications that can continue: publickey,password
   debug1: No more authentication methods to try.
   alumno@server: Permission denied (publickey,password).
   ```
   - `Offering` sin `Server accepts`: el servidor no tiene esa llave en `authorized_keys` (o la tiene y no la puede leer).
   - El cliente **no sabe por qué**: el servidor no lo cuenta, para no ayudar a un atacante. La razón está en el log del servidor: el [lab 02](../lab-02-el-lado-del-servidor/README.md).
   - `BatchMode=yes`: sin él, `ssh` pasaría a pedirte la contraseña (`password` sigue en la lista).

## Criterios de éxito

- [ ] Explicas qué hace `ssh -G` y por qué es lo primero que miras (paso 1)
- [ ] Señalas en una salida de `ssh -v` cada capa: nombre, TCP, banner, algoritmos, host key, llave (paso 2)
- [ ] Explicas cómo se elige un algoritmo con las dos listas de `-vvv` (paso 3)
- [ ] Distingues `Could not resolve`, `Connection refused`, `timed out` y `no matching` y dices dónde buscar cada uno (paso 5)
- [ ] Explicas por qué el cliente no sabe la razón de un `Permission denied` (paso 6)

## Reto extra

Repite el paso 2 con `-vv` y busca la línea `debug2: ... SSH2_MSG_KEXINIT`. ¿Cuántos mensajes van y vienen antes de `Authenticated`? Con `-o ConnectTimeout=3 10.255.255.1`, ¿qué última línea de `-v` ves antes del fallo?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Índice de labs](../README.md) | [Lab 02 — El lado del servidor](../lab-02-el-lado-del-servidor/README.md) → |

[↑ Semana 13](../../README.md)
