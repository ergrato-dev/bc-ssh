# Lab 06 — Un bastion que solo deja saltar

⏱ Duración estimada: ~60 min

## Objetivo

Crear en el bastion una cuenta que solo sirve para saltar: sin shell, sin comandos, sin terminal, y con un único destino permitido. Ver qué mensaje recibe el cliente por cada cosa que el bastion rechaza.

## Contexto

- Cuentas de salto y opciones de `Match`: [teoría 03](../../1-teoria/03-endurecer-el-bastion.md#cuentas-que-solo-saltan).
- `Match Group`, `sshd -T -C` y recargar `sshd`: semana 07, [lab 04](../../../week-07-servidor_sshd_config_y_hardening/2-practicas/lab-04-match/README.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-red-segmentada/README.md), y la variable `R` de la semana 07, que recarga `sshd`:
   ```bash
   R='sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ```

1. **Una cuenta sin shell.** En el bastion, el grupo `saltadores` y la cuenta `salto`, con tu llave pública:
   ```bash
   ssh bastion 'sudo groupadd saltadores
   sudo useradd -m -s /usr/sbin/nologin -G saltadores salto
   sudo install -d -m 700 -o salto -g salto ~salto/.ssh
   sudo install -m 600 -o salto -g salto ~/.ssh/authorized_keys ~salto/.ssh/
   id salto'
   ```
   ```
   uid=1001(salto) gid=1002(salto) groups=1002(salto),1001(saltadores)
   ```
   - `useradd -m` crea la cuenta con su carpeta; `-s /usr/sbin/nologin`, sin shell; `-G saltadores`, en ese grupo.
   - `install -d -m 700 -o salto -g salto`: crea la carpeta con dueño y permisos en un paso. `install -m 600 ...`: copia el archivo igual. `~salto` es la carpeta personal de `salto`.
   - Copias el `authorized_keys` de `alumno` en el bastion, que tiene tu llave. En la vida real, cada persona tiene su cuenta de salto con su llave.

2. **`nologin` no basta.**
   ```bash
   ssh salto@bastion hostname; echo "código: $?"
   ssh -J salto@bastion interno hostname
   ssh -J salto@bastion server hostname
   ```
   ```
   This account is currently not available.
   código: 1
   interno
   server
   ```
   Sin shell, `salto` no ejecuta nada. Pero los reenvíos no pasan por la shell: `salto` salta a `interno`, y también a `server` o a cualquier host y puerto que alcance el bastion. Falta decirle a `sshd` qué permite.

3. **El `Match` de los saltadores.**
   ```bash
   ssh bastion "sudo tee /etc/ssh/sshd_config.d/40-salto.conf >/dev/null" <<'EOF'
   Match Group saltadores
       ForceCommand /usr/sbin/nologin
       PermitTTY no
       AllowTcpForwarding local
       PermitOpen interno:22
       AllowAgentForwarding no
       X11Forwarding no
   EOF
   ssh bastion "sudo sshd -t && $R && sudo sshd -T -C user=salto | grep -E '^(forcecommand|permittty|allowtcpforwarding|permitopen) '"
   ssh bastion "sudo sshd -T -C user=alumno | grep -E '^(forcecommand|permitopen) '"
   ```
   ```
   permittty no
   allowtcpforwarding local
   forcecommand /usr/sbin/nologin
   permitopen interno:22
   forcecommand none
   permitopen any
   ```
   - `ssh bastion "..." <<'EOF'`: el texto hasta `EOF` llega a la entrada del `sudo tee` remoto, que lo escribe en el archivo.
   - `sshd -t` valida antes de recargar. `sshd -T -C user=salto` enseña la configuración que tendría una conexión de `salto` (semana 07). `alumno` no cambia: el `Match` solo vale para el grupo.

4. **Sin shell ni terminal.**
   ```bash
   ssh salto@bastion
   ```
   ```
   PTY allocation request failed on channel 0
   This account is currently not available.
   Connection to bastion closed.
   ```
   - `PermitTTY no`: no hay terminal. `ForceCommand /usr/sbin/nologin`: pida lo que pida el cliente, se ejecuta `nologin`, que sale con 1. Aunque un día alguien le dé a `salto` una shell, el `Match` la sigue anulando.

5. **Solo a `interno:22`.**
   ```bash
   ssh -J salto@bastion interno hostname
   ssh -J salto@bastion server hostname; echo "código: $?"
   ssh -J salto@bastion 172.19.0.3 hostname; echo "código: $?"
   ```
   ```
   interno
   channel 0: open failed: administratively prohibited: open failed
   stdio forwarding failed
   Connection closed by UNKNOWN port 65535
   código: 255
   channel 0: open failed: administratively prohibited: open failed
   stdio forwarding failed
   Connection closed by UNKNOWN port 65535
   código: 255
   ```
   - `administratively prohibited`: el bastion rechaza el canal porque el destino no está en `PermitOpen`.
   - `172.19.0.3` **es** `interno` (lab 01), y aun así se rechaza: `PermitOpen` compara el texto que pide el cliente, sin resolverlo. Escribe en `PermitOpen` los mismos nombres que usan tus `HostName`.

6. **Ni `-R` ni otros puertos.**
   ```bash
   ssh -o ExitOnForwardFailure=yes -f -N -R 9000:localhost:9000 salto@bastion; echo "código: $?"
   ssh -f -N -L 2222:interno:22 salto@bastion
   ssh -p 2222 -o HostKeyAlias=interno localhost hostname
   ssh -f -N -L 8080:interno:80 salto@bastion
   curl -sS -m 3 localhost:8080; echo "código: $?"
   pkill -f '^ssh -f -N'
   ```
   ```
   Error: remote port forwarding failed for listen port 9000
   código: 255
   interno
   curl: (56) Recv failure: Connection reset by peer
   código: 56
   ```
   - `AllowTcpForwarding local`: `-R` no (semana 08). Nadie publica en el bastion un puerto que entre en su equipo.
   - Un `-L` es el mismo tipo de canal que `-J`: a `interno:22` se permite; a `interno:80`, el puerto local se abre (`ssh -f` no ve el error), pero cada conexión se corta.
   - `HostKeyAlias=interno`: `localhost:2222` es en realidad `interno` (lab 03, paso 5).

7. **El método antiguo ya no sirve.**
   ```bash
   ssh -o ProxyCommand='ssh salto@bastion nc %h %p' interno hostname; echo "código: $?"
   ```
   ```
   Connection closed by UNKNOWN port 65535
   código: 255
   ```
   `ssh salto@bastion nc ...` es una sesión con un comando, y `ForceCommand` la cambia por `nologin`: lo que llega por el tubo no es un saludo SSH. `-J` pide un canal, no un comando: es lo único que una cuenta de salto necesita.

## Criterios de éxito

- [ ] Creas una cuenta sin shell en un grupo, con su llave, y explicas por qué `nologin` solo no basta (pasos 1 y 2)
- [ ] Escribes el `Match Group saltadores` y lo compruebas con `sshd -T -C` para `salto` y para `alumno` (paso 3)
- [ ] Explicas qué mensaje produce `PermitTTY no`, `ForceCommand` y `PermitOpen` (pasos 4 y 5)
- [ ] Explicas por qué la IP de `interno` se rechaza (paso 5)
- [ ] Explicas qué deja y qué no `AllowTcpForwarding local` (paso 6)
- [ ] Explicas por qué `ProxyCommand ... nc` no funciona con esta cuenta y `-J` sí (paso 7)

## Reto extra

En lugar de una cuenta, limita una **llave**: crea `~/.ssh/salto` con `ssh-keygen`, añade al `authorized_keys` de `alumno` en el bastion la línea `restrict,port-forwarding,permitopen="interno:22",command="/usr/sbin/nologin" ` seguida de la pública, y salta con `ssh -o ProxyCommand='ssh -i ~/.ssh/salto -W %h:%p bastion' interno`. ¿Por qué aquí no sirve `-J`? ¿Qué ventaja tiene la cuenta de salto?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Agente reenviado frente a ProxyJump](../lab-05-agente-reenviado/README.md) | [Lab 07 — Quién salta a dónde, y cómo cortarlo](../lab-07-auditoria-y-cortes/README.md) → |

[↑ Semana 09](../../README.md)
