# Lab 05 — Restringir destinos con `ssh-add -h`

⏱ Duración estimada: ~60 min

## Objetivo

Cargar una llave que solo sirve para un camino concreto (`client → server → bastion`), comprobar que el agente rechaza cualquier otro uso, también desde un socket reenviado, y entender por qué necesita tu `known_hosts`.

## Contexto

- Restricciones por destino: [teoría 02](../../1-teoria/02-agent-forwarding-y-riesgos.md#ssh-add--h-la-llave-solo-vale-en-un-camino). Requieren OpenSSH 8.9 o superior en todos los equipos del camino; el laboratorio tiene 9.6.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server bastion
   docker compose run --rm client
   ```
   **En el cliente**, la misma preparación que en el lab 04:
   ```bash
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   ssh-keygen -q -t ed25519 -N '' -C alumno@client -f ~/.ssh/lab
   for h in server bastion; do sshpass -e ssh-copy-id -f -i ~/.ssh/lab.pub $h; done
   ssh -i ~/.ssh/lab server 'ssh-keyscan -t ed25519 bastion 2>/dev/null > ~/.ssh/known_hosts'
   eval "$(ssh-agent)"
   ```
   Esta vez **no** ejecutes `ssh-add` todavía. Usa `-i ~/.ssh/lab` en la línea del `ssh-keyscan` porque `lab` no es un nombre que `ssh` pruebe solo.

1. **Carga la llave con un camino:**
   ```bash
   ssh-add -h server -h 'server>bastion' ~/.ssh/lab
   ```
   ```
   Identity added: /home/alumno/.ssh/lab (alumno@client)
   ```
   - `-h server`: desde este cliente, hacia `server`.
   - `-h 'server>bastion'`: desde `server` (con el agente reenviado), hacia `bastion`.

2. **El camino permitido funciona:**
   ```bash
   ssh -A server 'hostname; ssh bastion hostname'
   ```
   ```
   server
   bastion
   ```

3. **Cualquier otro uso, no.** Directamente a `bastion`, desde el cliente:
   ```bash
   ssh -o BatchMode=yes bastion hostname; echo "código: $?"
   ```
   ```
   alumno@bastion: Permission denied (publickey,password).
   código: 255
   ```
   La llave está instalada en `bastion` y el agente la tiene, pero `client → bastion` no está en la lista: el agente se niega a firmar. (El archivo `~/.ssh/lab` también la tiene, pero `ssh` no lo prueba solo: su nombre no es uno de los de por defecto.)

4. **Lo que ve `server`.** Vuelve a cargar la llave, ahora solo con `-h server`, y mira qué ve `server` por el socket reenviado:
   ```bash
   ssh-add -D
   ssh-add -h server ~/.ssh/lab
   ssh -A server 'ssh-add -l; echo "código: $?"'
   ```
   ```
   All identities removed.
   Identity added: /home/alumno/.ssh/lab (alumno@client)
   The agent has no identities.
   código: 1
   ```
   Desde `server`, la llave no tiene ningún destino permitido, y el agente ni siquiera la lista. Quien use ese socket en `server` (también root) no tiene nada que pedir.

5. **Por qué funciona:**
   ```bash
   ssh -v -A server true 2>&1 | grep bound
   ```
   ```
   debug1: get_agent_identities: bound agent to hostkey
   debug1: client_request_agent: bound agent to hostkey
   ```
   - La primera línea: tu `ssh` le dice al agente con qué host key está hablando (la de `server`).
   - La segunda: al abrir el canal del forwarding, lo mismo para lo que llegue desde `server`.

   El agente compara esas host keys con las de **tu** `known_hosts`. No se fía del nombre que le diga nadie.

6. **Sin `known_hosts`, no hay restricción posible:**
   ```bash
   ssh-add -D
   mv ~/.ssh/known_hosts ~/kh
   ssh-add -h server ~/.ssh/lab; echo "código: $?"
   mv ~/kh ~/.ssh/known_hosts
   ```
   ```
   All identities removed.
   No host keys found for destination "server"
   código: 255
   ```
   `ssh-add` necesita la host key de cada destino **al cargar** la llave. Es otro motivo para mantener `known_hosts` verificado (semana 02).

7. **Responde en tus notas:** con `-h server -h 'server>bastion'`, root de `server` usa tu socket reenviado mientras estás conectado. ¿A qué servidores puede entrar como tú? Compáralo con el lab 04, donde cargaste la llave sin `-h`.

## Criterios de éxito

- [ ] El camino `client → server → bastion` funciona (paso 2)
- [ ] `client → bastion` directo se rechaza aunque la llave esté instalada (paso 3)
- [ ] Con `-h server` solo, el agente reenviado no lista ninguna llave en `server` (paso 4)
- [ ] Explicas qué papel tiene `known_hosts` en la restricción (pasos 5 y 6)
- [ ] Respondiste la pregunta del paso 7

## Reto extra

Añade también el destino directo: `ssh-add -h server -h 'server>bastion' -h bastion ~/.ssh/lab`. Comprueba que ahora entras en `bastion` desde el cliente, pero que `ssh -A bastion 'ssh server hostname'` (el camino al revés) sigue sin funcionar. Para preparar ese camino necesitarás `server` en el `known_hosts` de `bastion`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — Agent forwarding](../lab-04-agent-forwarding/README.md) | [Lab 06 — Confirmar cada uso con `ssh-add -c`](../lab-06-confirmar-cada-uso/README.md) → |

[↑ Semana 04](../../README.md)
