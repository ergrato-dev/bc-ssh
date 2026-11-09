# Lab 03 — Validez y opciones del certificado

⏱ Duración estimada: ~60 min

## Objetivo

Decidir **cuándo** vale un certificado y **qué** deja hacer: intervalos de validez, certificados que caducan con la sesión abierta, `force-command`, `source-address` y las extensiones. Ver el certificado dentro del agente.

## Contexto

- Validez, opciones críticas y extensiones: [teoría 02](../../1-teoria/02-certificados-de-usuario-y-de-host.md#validez-opciones-y-extensiones).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 02](../lab-02-principals/README.md). Para no repetir la orden de firmar, una función de shell que firma `trabajo` para `alumno` con las opciones que le pases:
   ```bash
   firma() { ssh-keygen -q -s ~/ca/user_ca -I alumno@client -n alumno "$@" ~/.ssh/trabajo.pub; }
   ```

1. **Ventanas de validez.** `-V` acepta un intervalo `DESDE:HASTA`, relativo (`-5m`, `+1h`, `+52w`) o absoluto (`AAAAMMDD`):
   ```bash
   date -u +%FT%T
   firma -V -5m:+1h; ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | grep Valid
   firma -V 20270101:20270201; ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | grep Valid
   ssh server-cert true; echo "código: $?"
   firma -V -2h:-1h; ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | grep Valid
   ssh server-cert true; echo "código: $?"
   firma; ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | grep Valid
   ```
   ```
   2026-11-09T03:48:45
           Valid: from 2026-11-09T03:43:45 to 2026-11-09T04:48:45
           Valid: from 2027-01-01T00:00:00 to 2027-02-01T00:00:00
   alumno@server: Permission denied (publickey,password).
   código: 255
           Valid: from 2026-11-09T01:48:45 to 2026-11-09T02:48:45
   alumno@server: Permission denied (publickey,password).
   código: 255
           Valid: forever
   ```
   En el log de `server` (desde tu equipo, `docker compose logs --no-log-prefix server | grep Certificate | tail -2`):
   ```
   Certificate invalid: not yet valid
   Certificate invalid: expired
   ```
   - `-5m` como inicio: tolera un servidor con el reloj 5 minutos atrasado. Los certificados dependen de que los relojes estén en hora (NTP).
   - Las horas son UTC.
   - Sin `-V`: `forever`. Un certificado eterno es una llave en `authorized_keys` que no puedes borrar: solo la KRL lo para (lab 05). **Pon siempre `-V`**.

2. **`force-command`: un certificado para una sola orden.** Para un monitor o una copia de seguridad que solo necesitan ejecutar una cosa:
   ```bash
   firma -V +1h -O force-command=uptime
   ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | grep -A1 'Critical'
   ssh server-cert hostname | cut -c1-20
   ssh server-cert 'rm -rf ~' | cut -c1-20
   ```
   ```
           Critical Options: 
                   force-command uptime
    03:48:46 up  1:28, 
    03:48:46 up  1:28, 
   ```
   Pidas lo que pidas, se ejecuta `uptime`. Es el `command=` de `authorized_keys` (semana 07), pero va en el certificado: vale en todos los servidores sin tocar ninguno. *Critical* quiere decir que un servidor que no entienda la opción debe rechazar el certificado, no ignorarla.

3. **`source-address`: solo desde ciertas IP.**
   ```bash
   ip=$(hostname -I | cut -d' ' -f1); echo $ip
   firma -V +1h -O source-address=$ip/32; ssh server-cert hostname
   firma -V +1h -O source-address=10.0.0.0/8; ssh server-cert hostname; echo "código: $?"
   ```
   ```
   172.20.0.6
   server
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   ```
   cert: Authentication tried for alumno with valid certificate but not from a permitted source address (172.20.0.6).
   Refused by certificate options
   ```
   Una lista de redes separadas por comas, en notación CIDR (`/32`: esa IP exacta). Si roban la llave y el certificado, no les sirven fuera de esas redes. Tu IP será otra.

4. **Extensiones: lo que permite.** Por defecto, todo. `-O no-pty` quita una; `-O clear` quita todas, y `-O permit-...` devuelve las que quieras:
   ```bash
   firma -V +1h -O no-pty; ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | sed -n '/Extensions/,$p'
   ssh -tt server-cert hostname; echo "código: $?"
   firma -V +1h -O clear -O permit-pty; ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | sed -n '/Extensions/,$p'
   ssh -W server:22 server-cert </dev/null; echo "código: $?"
   ```
   ```
           Extensions: 
                   permit-X11-forwarding
                   permit-agent-forwarding
                   permit-port-forwarding
                   permit-user-rc
   PTY allocation request failed on channel 0
   código: 255
           Extensions: 
                   permit-pty
   channel 0: open failed: administratively prohibited: open failed
   stdio forwarding failed
   código: 255
   ```
   - Sin `permit-pty`, `sshd` no da terminal. `-tt` la pide aunque no tengas una.
   - Sin `permit-port-forwarding`, ni `-L`, ni `-R`, ni `-W` (el `ProxyJump` de la semana 09).
   - Lo que no está en el certificado, no lo devuelve el servidor; lo que está, el servidor aún puede quitarlo (`AllowTcpForwarding no`). Vale lo más restrictivo de los dos.

5. **El certificado en el agente.**
   ```bash
   firma -V +1h
   eval $(ssh-agent) >/dev/null
   ssh-add ~/.ssh/trabajo
   ssh-add -l
   ```
   ```
   Identity added: /home/alumno/.ssh/trabajo (alumno@client)
   Certificate added: /home/alumno/.ssh/trabajo-cert.pub (alumno@client)
   256 SHA256:a56quJ+j+qW0CCvMgG5jZJbufQURdtmlE/bCJ04xHAA alumno@client (ED25519)
   256 SHA256:a56quJ+j+qW0CCvMgG5jZJbufQURdtmlE/bCJ04xHAA alumno@client (ED25519-CERT)
   ```
   `ssh-add` carga la llave y, si existe, su `-cert.pub`: dos entradas, misma huella. Ahora firma uno caducado y repite:
   ```bash
   firma -V -2h:-1h
   ssh-add -D; ssh-add ~/.ssh/trabajo; ssh-add -l | grep CERT
   kill $SSH_AGENT_PID
   ```
   ```
   All identities removed.
   Identity added: /home/alumno/.ssh/trabajo (alumno@client)
   Certificate added: /home/alumno/.ssh/trabajo-cert.pub (alumno@client)
   256 SHA256:a56quJ+j+qW0CCvMgG5jZJbufQURdtmlE/bCJ04xHAA alumno@client (ED25519-CERT)
   ```
   El agente no comprueba la validez: lo acepta caducado. Quien decide es `sshd`. Si firmas uno nuevo, vuelve a cargarlo: el agente guarda una copia.

6. **Caducar no corta lo que ya entró.** Un certificado de 2 minutos y un master (semana 05):
   ```bash
   firma -V -1m:+1m; ssh-keygen -Lf ~/.ssh/trabajo-cert.pub | grep Valid
   ssh -o ControlMaster=auto -o ControlPath=~/.ssh/cm-%C -o ControlPersist=10m server-cert true
   sleep 65; date -u +%T
   ssh -o ControlPath=~/.ssh/cm-%C server-cert 'echo por el master'
   ssh -o ControlPath=none server-cert true; echo "código: $?"
   ssh -O exit -o ControlPath=~/.ssh/cm-%C server-cert
   ```
   ```
           Valid: from 2026-11-09T03:47:47 to 2026-11-09T03:49:47
   03:49:58
   por el master
   alumno@server: Permission denied (publickey,password).
   código: 255
   Exit request sent.
   ```
   `sshd` comprueba el certificado **al autenticar**. La conexión del master ya estaba autenticada y sigue, y cada sesión nueva dentro de ella también. Una conexión nueva, no. Para cortar a alguien que ya entró: `pkill` en el servidor (semana 09), o un `ControlPersist` corto.

## Criterios de éxito

- [ ] Firmas con validez relativa y absoluta, y explicas el `-5m` del inicio y el riesgo de no poner `-V` (paso 1)
- [ ] Limitas un certificado a una orden con `force-command` y explicas qué significa *critical* (paso 2)
- [ ] Limitas un certificado a una IP con `source-address` y lees el rechazo en el log (paso 3)
- [ ] Quitas extensiones y dices qué deja de funcionar sin `permit-pty` y sin `permit-port-forwarding` (paso 4)
- [ ] Explicas qué guarda el agente y por qué acepta un certificado caducado (paso 5)
- [ ] Explicas por qué una sesión sigue abierta después de caducar el certificado (paso 6)

## Reto extra

Las extensiones de OpenSSH son nombres sin `@`; puedes añadir las tuyas con `-O extension:nombre@tu-dominio=valor`. `sshd` las ignora, pero tu `AuthorizedPrincipalsCommand` podría leerlas. Firma una y busca dónde aparece en `ssh-keygen -L`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — Principals: como quién puede entrar](../lab-02-principals/README.md) | [Lab 04 — Certificados de host: adiós a «Are you sure?»](../lab-04-certificados-de-host/README.md) → |

[↑ Semana 10](../../README.md)
