# Lab 06 — fail2ban

⏱ Duración estimada: ~60 min

## Objetivo

Proteger `server` con fail2ban: probar el filtro `sshd` contra el log con `fail2ban-regex`, escribir una jaula, provocar un bloqueo de verdad desde el cliente, verlo en nftables, deshacerlo, y entender por qué `bantime.increment`, `ignoreip` y el modo `aggressive` necesitan cuidado.

## Contexto

- Filtro, jaula y acción; modos `normal` y `aggressive`: [teoría 03](../../1-teoria/03-fail2ban-y-registros.md).
- En este lab **te vas a bloquear a ti mismo**. Ten abierta la otra terminal en tu equipo: desde ella deshaces el bloqueo con `docker compose exec server ...`.
- **La contraseña `alumno` es solo del laboratorio**; las contraseñas que se prueban aquí son de mentira, para generar fallos.

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-leer-ssh-audit/README.md). Apunta la IP del cliente:
   ```bash
   hostname -I
   ```
   ```
   172.20.0.4
   ```
   La tuya puede ser otra: úsala donde ponga `172.20.0.4`.

1. **Lo que trae Ubuntu.**
   ```bash
   ssh server cat /etc/fail2ban/jail.d/defaults-debian.conf
   ```
   ```
   [DEFAULT]
   banaction = nftables
   banaction_allports = nftables[type=allports]
   backend = systemd

   [sshd]
   enabled = true
   ```
   La jaula `sshd` viene activada, con bloqueos en nftables y leyendo el journal de systemd. El contenedor no tiene systemd: `sshd` escribe en `/var/log/auth.log`, como un Ubuntu con rsyslog. Por eso necesitarás `backend` y `logpath` propios.

2. **Algo de ruido.** Tres usuarios con una contraseña cualquiera, como un robot:
   ```bash
   for u in root admin test; do sshpass -p 123456 ssh -o PubkeyAuthentication=no $u@server true; done
   ssh server 'grep -E "Invalid user|Failed password" /var/log/auth.log'
   ```
   ```
   Permission denied, please try again.
   ...
   2026-11-10 22:02:51 server sshd: Failed password for root from 172.20.0.4 port 39270 ssh2
   2026-11-10 22:02:52 server sshd: Invalid user admin from 172.20.0.4 port 39282
   2026-11-10 22:02:53 server sshd: Failed password for invalid user admin from 172.20.0.4 port 39282 ssh2
   2026-11-10 22:02:53 server sshd: Invalid user test from 172.20.0.4 port 39292
   2026-11-10 22:02:54 server sshd: Failed password for invalid user test from 172.20.0.4 port 39292 ssh2
   ```
   `root` existe: solo `Failed password`. `admin` y `test` no: además, `Invalid user`.

3. **Probar el filtro antes de bloquear a nadie.**
   ```bash
   ssh server 'sudo fail2ban-regex /var/log/auth.log sshd' | grep -E '^Lines|^\|  +[0-9]+\) \[' | tr -d '[]' | cut -c1-80
   ```
   ```
   |   4) 3 ^Failed (?:<F-NOFAIL>publickey</F-NOFAIL>|\S+) for (?P<cond_inv>invalid use
   |   6) 2 ^iI(?:llegal|nvalid) user <F-USER>.*?</F-USER> from <HOST>(?: (?:port \d+|
   |  19) 2 ^<F-NOFAIL>Received <F-MLFFORGET>disconnect</F-MLFFORGET></F-NOFAIL> from <H
   |  20) 5 ^<F-NOFAIL><F-MLFFORGET>(Connection (?:closed|reset)|Disconnected)</F-MLFFORG
   |  21) 3 ^<F-MLFFORGET><F-MLFGAINED>Accepted \w+</F-MLFGAINED></F-MLFFORGET> for <F-US
   Lines: 19 lines, 10 ignored, 5 matched, 4 missed
   ```
   - Tras el número de la expresión, cuántas líneas casaron con ella (`tr -d '[]'` quita los corchetes para que se lea mejor). `5 matched`: los 3 `Failed password` y los 2 `Invalid user` cuentan como fallos.
   - Las expresiones con `<F-NOFAIL>` casan pero **no** cuentan (`Connection closed`, `Accepted`): ayudan a seguir una conexión.
   - Tres usuarios probados, **cinco** fallos: un usuario inexistente cuenta doble.

4. **La jaula.** `bantime` de 1 minuto para que el lab no se eternice (el kit usa 1 h):
   ```bash
   ssh server 'sudo tee /etc/fail2ban/jail.d/sshd.local' <<'FIN'
   [sshd]
   backend = auto
   logpath = /var/log/auth.log
   maxretry = 5
   findtime = 10m
   bantime = 1m
   bantime.increment = true
   FIN
   ssh server 'sudo fail2ban-client -t'
   ```
   ```
   ...
   OK: configuration test is successful
   ```
   `-t` comprueba la configuración sin arrancar nada: el mismo papel que `sshd -t`.

5. **Arrancar… y el pasado cuenta.** El laboratorio no tiene systemd: lo arranca `fail2ban-client start`.
   ```bash
   ssh server 'sudo fail2ban-client start; sleep 2; sudo fail2ban-client status sshd'
   ssh server true; echo "código: $?"
   ```
   ```
   Server ready
   Status for the jail: sshd
   |- Filter
   |  |- Currently failed:	0
   |  |- Total failed:	5
   |  `- File list:	/var/log/auth.log
   `- Actions
      |- Currently banned:	1
      |- Total banned:	1
      `- Banned IP list:	172.20.0.4
   ssh: connect to host server port 22: Connection refused
   código: 255
   ```
   Al arrancar, fail2ban leyó los fallos del paso 2 (dentro de `findtime`): 5 = `maxretry`. **Te bloqueó con tu propio ruido**, y el `ssh` de la primera línea fue tu última conexión. Si activas fail2ban en un servidor con un log lleno, puede bloquear a quien estaba probando.

6. **El bloqueo, desde dentro.** En la terminal de **tu equipo**:
   ```bash
   docker compose exec server nft list table inet f2b-table
   docker compose exec server fail2ban-client get sshd banip --with-time
   ```
   ```
   table inet f2b-table {
   	set addr-set-sshd {
   		type ipv4_addr
   		elements = { 172.20.0.4 }
   	}

   	chain f2b-chain {
   		type filter hook input priority filter - 1; policy accept;
   		tcp dport 22 ip saddr @addr-set-sshd reject with icmp port-unreachable
   	}
   }
   172.20.0.4 	2026-11-10 22:02:58 + 60 = 2026-11-10 22:03:58
   ```
   - Un conjunto de IP (`addr-set-sshd`) y una regla: lo que llegue de ellas al puerto 22 se **rechaza** (`Connection refused` en el cliente). Bloquear o desbloquear es añadir o quitar del conjunto.
   - La regla no distingue conexiones nuevas de viejas: una sesión abierta o un master de multiplexing también se cortan.

7. **Desbloquear.** Desde tu equipo; después, prueba en el cliente:
   ```bash
   docker compose exec server fail2ban-client set sshd unbanip 172.20.0.4
   ```
   ```
   1
   ```
   ```bash
   ssh server true; echo "código: $?"
   ```
   ```
   código: 0
   ```
   En un servidor real no hay `docker compose exec`: necesitas otra IP, la consola del proveedor o esperar a que pase `bantime`.

8. **Los reincidentes.** Repite el ataque dos veces, dejando que el primer bloqueo caduque solo (1 minuto):
   ```bash
   for u in oracle ubuntu pi; do sshpass -p 123456 ssh -o PubkeyAuthentication=no -o ConnectTimeout=3 $u@server true 2>/dev/null; done
   sleep 65
   for u in oracle ubuntu pi; do sshpass -p 123456 ssh -o PubkeyAuthentication=no -o ConnectTimeout=3 $u@server true 2>/dev/null; done
   ```
   Desde tu equipo:
   ```bash
   docker compose exec server grep -E 'Increase|Unban' /var/log/fail2ban.log | tail -2 | cut -c1-120
   ```
   ```
   2026-11-10 22:04:33,186 fail2ban.actions        [87]: NOTICE  [sshd] Unban 172.20.0.4
   2026-11-10 22:04:52,090 fail2ban.observer       [87]: NOTICE  [sshd] Increase Ban 172.20.0.4 (3 # 4m -> 2026-11-10 22:08:48)
   ```
   `bantime.increment`: cada bloqueo de la misma IP dura el doble (1, 2, 4 minutos…; en el kit, 1 h, 2 h, 4 h… hasta `bantime.maxtime`). Un robot que vuelve cada hora acaba bloqueado días. El número tras `(` es cuántas veces se bloqueó. Desbloquéate como en el paso 7.

9. **`ignoreip`: nunca bloquear a alguien.** Desde tu equipo:
   ```bash
   docker compose exec server fail2ban-client set sshd addignoreip 172.20.0.4
   ```
   ```
   These IP addresses/networks are ignored:
   `- 172.20.0.4
   ```
   En el cliente, diez fallos seguidos:
   ```bash
   for u in a b c d e f g h i j; do sshpass -p 1 ssh -o PubkeyAuthentication=no $u@server true 2>/dev/null; done
   ssh server 'grep -c "Ignore 172.20.0.4 by ip" /var/log/fail2ban.log; sudo fail2ban-client set sshd delignoreip 172.20.0.4'
   ```
   ```
   19
   No IP address/network is ignored
   ```
   Unas 20 líneas ignoradas (dos por usuario inexistente; puede faltar alguna si la última aún no se leyó) y ningún bloqueo: tus fallos no cuentan. Cómodo para tu IP de administración, y peligroso: desde una IP de `ignoreip` se pueden probar contraseñas sin límite. El kit solo pone `127.0.0.1/8 ::1`.

10. **`aggressive` y tus propias herramientas.** Cambia el modo y audita `server` como en el lab 01 (sin `--skip-rate-test`):
    ```bash
    ssh server 'echo "mode = aggressive" | sudo tee -a /etc/fail2ban/jail.d/sshd.local; sudo fail2ban-client reload'
    ssh-audit server > /dev/null; sleep 2
    ssh server true; echo "código: $?"
    ```
    ```
    mode = aggressive
    OK
    ssh: connect to host server port 22: Connection refused
    código: 255
    ```
    `ssh-audit` abrió unas 40 conexiones que se cerraron sin autenticarse: en modo `aggressive` son 40 fallos. Por eso el kit usa `normal`. Desde tu equipo, deja `server` como estaba:
    ```bash
    docker compose exec server sed -i '/^mode = aggressive/d' /etc/fail2ban/jail.d/sshd.local
    docker compose exec server fail2ban-client reload
    docker compose exec server fail2ban-client unban --all
    ```

## Criterios de éxito

- [ ] Explicas qué trae `defaults-debian.conf` y por qué el laboratorio necesita `backend` y `logpath` (paso 1)
- [ ] Pruebas el filtro con `fail2ban-regex` y explicas por qué 3 usuarios dan 5 fallos (paso 3)
- [ ] Explicas por qué fail2ban te bloqueó nada más arrancar (paso 5)
- [ ] Encuentras el bloqueo en nftables y lo deshaces (pasos 6 y 7)
- [ ] Ves crecer un bloqueo con `bantime.increment` (paso 8)
- [ ] Explicas el riesgo de `ignoreip` y de `mode = aggressive` (pasos 9 y 10)

## Reto extra

Haz que fail2ban cuente también los códigos TOTP equivocados: monta el segundo factor del [lab 05](../lab-05-llave-y-codigo/README.md) y escribe cinco códigos malos. ¿Qué línea del log los cuenta? Pruébalo antes con `fail2ban-regex /var/log/auth.log sshd`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Llave y código](../lab-05-llave-y-codigo/README.md) | [Lab 07 — Leer el log](../lab-07-leer-el-log/README.md) → |

[↑ Semana 11](../../README.md)
