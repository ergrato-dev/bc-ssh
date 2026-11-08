# Lab 06 — Qué puede hacer una sesión abierta

⏱ Duración estimada: ~60 min

## Objetivo

Quitar a las sesiones lo que un servidor no necesita: reenvío del agente y de X11, variables de entorno del cliente. Ver cómo `MaxSessions` limita el multiplexing y cómo `ClientAliveInterval` cierra la sesión de un cliente que dejó de responder.

## Contexto

- Opciones de sesión: [teoría 02](../../1-teoria/02-autenticacion-y-acceso.md#qué-hace-la-sesión).
- Agente y su reenvío: [semana 04](../../../week-04-ssh_agent_y_llaves_fido2/README.md). Multiplexing: [semana 05](../../../week-05-configuracion_avanzada_cliente_ssh/1-teoria/03-multiplexing.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-sshd-config/README.md) y la variable `R` del [lab 02](../lab-02-autenticacion/README.md), que recarga `sshd`:
   ```bash
   R='sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ```

1. **El agente reenviado, con el valor por defecto.** Arranca un agente, carga tu llave y entra con `-A`:
   ```bash
   eval "$(ssh-agent -s)" >/dev/null; ssh-add -q ~/.ssh/id_ed25519
   ssh -A server 'ssh-add -l'
   ```
   ```
   256 SHA256:v16Of/auPpU/8RHOHGX+AhIum9yMDEw850u1aNMPua4 alumno@client (ED25519)
   ```
   Desde `server` se ve tu agente. Mientras dura la sesión, root en `server` también lo puede usar para entrar donde entras tú (semana 04). Tu huella será otra.

2. **Sin reenvío del agente:**
   ```bash
   echo 'AllowAgentForwarding no' | ssh server "sudo tee /etc/ssh/sshd_config.d/20-sesion.conf >/dev/null; sudo sshd -t && $R"
   ssh -A server 'ssh-add -l; echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK"'
   ```
   ```
   Could not open a connection to your authentication agent.
   SSH_AUTH_SOCK=
   ```
   - El cliente pide el reenvío y el servidor no lo crea: `SSH_AUTH_SOCK` queda vacía.
   - Es una segunda barrera. La primera es `ForwardAgent no` en tu kit (semana 04): quien tiene shell en el servidor puede montarse un reenvío propio con un túnel.

3. **X11.** Ubuntu lo trae activado en `sshd_config`:
   ```bash
   ssh server 'sudo sshd -T | grep ^x11forw'
   ```
   ```
   x11forwarding yes
   ```
   Con `ssh -X`, una aplicación gráfica del servidor se abre en tu escritorio, y puede leer lo que escribes en otras ventanas. En el laboratorio no hay entorno gráfico para probarlo; en un servidor, nunca hace falta. Añádelo:
   ```bash
   echo 'X11Forwarding no' | ssh server "sudo tee -a /etc/ssh/sshd_config.d/20-sesion.conf >/dev/null; sudo sshd -t && $R; sudo sshd -T | grep ^x11forw"
   ```
   ```
   x11forwarding no
   ```

4. **Variables que envía el cliente.** `SetEnv` (cliente) manda variables; `AcceptEnv` (servidor) decide cuáles acepta:
   ```bash
   ssh -o SetEnv=LC_PRUEBA=hola -o SetEnv=EDITOR=nano server 'echo "LC_PRUEBA=$LC_PRUEBA EDITOR=$EDITOR"'
   ssh server 'sudo sshd -T | grep -E "^(acceptenv|permituserenv)"'
   ```
   ```
   LC_PRUEBA=hola EDITOR=
   acceptenv LANG
   acceptenv LC_*
   permituserenvironment no
   ```
   - Pasa `LC_PRUEBA` (encaja en `LC_*`) y no pasa `EDITOR`. Ubuntu acepta el idioma para que veas los mensajes en el tuyo.
   - `PermitUserEnvironment no`: el usuario tampoco puede fijar variables con `~/.ssh/environment`. Una variable como `LD_PRELOAD` haría que cualquier programa de la sesión cargue código suyo, también un `ForceCommand`.

5. **`MaxSessions` y el multiplexing.** Cada `ssh` por un master es una sesión de la misma conexión. Limítalas a 2:
   ```bash
   echo 'MaxSessions 2' | ssh server "sudo tee -a /etc/ssh/sshd_config.d/20-sesion.conf >/dev/null; sudo sshd -t && $R"
   M='-o ControlMaster=auto -o ControlPath=~/.ssh/cm-%C -o ControlPersist=1m'
   ssh $M -fN server
   ssh $M server sleep 5 & sleep 0.5; ssh $M server sleep 5 & sleep 1
   ssh $M server echo tercera; echo "código: $?"
   wait; ssh $M -O exit server
   ```
   ```
   mux_client_request_session: session request failed: Session open refused by peer
   ControlSocket /home/alumno/.ssh/cm-e02bc41ef904cf7479525f22b4660ffc0adc7c8c already exists, disabling multiplexing
   tercera
   código: 0
   Exit request sent.
   ```
   - `ssh $M -fN server`: abre el master en segundo plano, sin sesión. Los dos `sleep 5` ocupan las 2 sesiones.
   - La tercera se rechaza en el master, y `ssh` abre **una conexión nueva por su cuenta** y funciona. `MaxSessions` no limita cuántas veces entra alguien, solo cuántas sesiones caben en una conexión.
   - Quítalo: `ssh server "sudo sed -i /MaxSessions/d /etc/ssh/sshd_config.d/20-sesion.conf; sudo sshd -t && $R"`.

6. **Un cliente que deja de responder.** Con valores cortos para no esperar: pregunta cada 3 s y corta tras 2 preguntas sin respuesta. `kill -STOP` congela tu `ssh`, como si el portátil se hubiera dormido:
   ```bash
   printf 'ClientAliveInterval 3\nClientAliveCountMax 2\n' | ssh server "sudo tee -a /etc/ssh/sshd_config.d/20-sesion.conf >/dev/null; sudo sshd -t && $R"
   ssh server 'sleep 60' & p=$!; sleep 1
   kill -STOP $p; sleep 12; kill -CONT $p; wait $p; echo "ssh: $?"
   ```
   ```
   Connection to server closed by remote host.
   ssh: 255
   ```
   - `$!`: el PID del último proceso lanzado en segundo plano. `kill -CONT` lo despierta: encuentra la conexión ya cerrada.
   - En el log: `Timeout, client not responding from user alumno 172.20.0.4 port 60260`.
   - Sin esto, la sesión de un equipo que perdió la red queda abierta en el servidor durante horas. El kit usa 300 s y 2: un cliente vivo responde siempre, así que una sesión inactiva pero viva no se corta.

7. **Lo que queda abierto a propósito.** Mira el resto de reenvíos:
   ```bash
   ssh server 'sudo sshd -T | grep -E "^(allowtcpforwarding|allowstreamlocalforwarding|permittunnel|gatewayports|disableforwarding)"'
   ```
   ```
   gatewayports no
   allowtcpforwarding yes
   disableforwarding no
   allowstreamlocalforwarding yes
   permittunnel no
   ```
   Los túneles TCP siguen permitidos: los usarás en las semanas 08 (PostgreSQL) y 09 (`ProxyJump` por `bastion`). El kit los quita solo donde no hacen falta, con `DisableForwarding` dentro de un `Match` (lab 05).

## Criterios de éxito

- [ ] Quitaste el reenvío del agente y explicas por qué es una segunda barrera y no la primera (pasos 1 y 2)
- [ ] Explicas el riesgo de X11 y lo desactivaste (paso 3)
- [ ] Explicas qué variables del cliente acepta el servidor y por qué no las del usuario (paso 4)
- [ ] Explicas qué limita `MaxSessions` y qué no (paso 5)
- [ ] Viste a `sshd` cerrar la sesión de un cliente que no responde (paso 6)

## Reto extra

Pon `ClientAliveInterval 3` y `ClientAliveCountMax 0` y repite el paso 6. Después, en lugar de congelar `ssh`, deja una sesión interactiva sin tocar el teclado 20 s. ¿Se corta? ¿Qué diferencia hay entre "inactiva" y "sin respuesta"?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Un usuario que solo sube archivos](../lab-05-sftp-chroot/README.md) | [Lab 07 — Cambiar `sshd` sin quedarte fuera](../lab-07-cambios-sin-quedarte-fuera/README.md) → |

[↑ Semana 07](../../README.md)
