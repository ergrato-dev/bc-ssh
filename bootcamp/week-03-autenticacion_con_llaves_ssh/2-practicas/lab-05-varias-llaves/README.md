# Lab 05 — Varias llaves, una por host

⏱ Duración estimada: ~60 min

## Objetivo

Usar una llave distinta para cada servidor, provocar `Too many authentication failures` con demasiadas llaves y evitarlo con `IdentityFile` e `IdentitiesOnly` en un `config`.

## Contexto

- Qué llaves prueba el cliente y por qué gastan intentos: [teoría 01](../../1-teoria/01-autenticacion-con-llave-publica.md#qué-llaves-prueba-el-cliente).
- ¿Por qué varias llaves? Si una se filtra, solo afecta a los servidores donde está; y puedes retirar el acceso de un equipo (el portátil del trabajo) sin tocar los demás.
- En el paso 4 usarás `ssh-agent` solo como "sitio con muchas llaves". Cómo funciona es la semana 04.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d --force-recreate server bastion
   docker compose run --rm client
   ```
   **En el cliente**:
   ```bash
   cd bootcamp/week-03-autenticacion_con_llaves_ssh/2-practicas/lab-05-varias-llaves
   export SSHPASS=alumno
   mkdir -p -m 700 ~/.ssh
   ssh-keyscan -t ed25519 server bastion 2>/dev/null > ~/.ssh/known_hosts
   ```

1. **Ocho llaves, con el comentario como nombre:**
   ```bash
   for n in lab trabajo uno dos tres cuatro cinco seis; do
     ssh-keygen -q -t ed25519 -N '' -C $n -f ~/.ssh/$n
   done
   ls ~/.ssh
   ```
   ```
   cinco  cinco.pub  cuatro  cuatro.pub  dos  dos.pub  known_hosts  lab  lab.pub  seis  seis.pub  trabajo  trabajo.pub  tres  tres.pub  uno  uno.pub
   ```
   Sin frase solo para que el lab vaya rápido.

2. **Cada llave en su servidor.** `-i` dice qué pública instalar:
   ```bash
   sshpass -e ssh-copy-id -i ~/.ssh/lab.pub server
   sshpass -e ssh-copy-id -i ~/.ssh/trabajo.pub bastion
   ```
   Cada uno termina con `Number of key(s) added: 1`.

3. **Sin decir qué llave, no entra:**
   ```bash
   ssh -o BatchMode=yes server true; echo "código: $?"
   ssh -o BatchMode=yes -i ~/.ssh/lab server hostname
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   server
   ```
   Ninguna se llama `id_ed25519`, así que `ssh` no prueba ninguna por su cuenta. Con `-i` sí.

4. **Demasiadas llaves.** Carga las seis "otras" en un agente y repite:
   ```bash
   eval "$(ssh-agent)"
   ssh-add ~/.ssh/{uno,dos,tres,cuatro,cinco,seis}
   ssh -o BatchMode=yes -i ~/.ssh/lab server hostname; echo "código: $?"
   ```
   ```
   Agent pid 108
   Identity added: /home/alumno/.ssh/uno (uno)
   ...
   Identity added: /home/alumno/.ssh/seis (seis)
   Received disconnect from 172.20.0.3 port 22:2: Too many authentication failures
   Disconnected from 172.20.0.3 port 22
   código: 255
   ```
   - `eval "$(ssh-agent)"` arranca el agente y define las variables para hablar con él; `{uno,dos,...}` lo expande bash en seis rutas.
   - El mismo comando que funcionaba en el paso 3 ahora falla, **aunque le diste la llave correcta**.

5. **Por qué:**
   ```bash
   ssh -v -o BatchMode=yes -i ~/.ssh/lab server hostname 2>&1 | grep Offering | cut -d' ' -f1-6
   ```
   ```
   debug1: Offering public key: uno ED25519
   debug1: Offering public key: dos ED25519
   debug1: Offering public key: tres ED25519
   debug1: Offering public key: cuatro ED25519
   debug1: Offering public key: cinco ED25519
   debug1: Offering public key: seis ED25519
   ```
   Las del agente van primero. Seis rechazos = `MaxAuthTries` (6) del servidor, y corta antes de llegar a `lab`. **En tu equipo**:
   ```bash
   docker compose logs server | grep -i 'too many' | tail -1
   ```
   ```
   server-1  | Disconnecting authenticating user alumno 172.20.0.5 port 55160: Too many authentication failures [preauth]
   ```
   Además, `server` acaba de ver seis llaves tuyas que no tienen nada que ver con él.

6. **`IdentitiesOnly`.** **En el cliente**:
   ```bash
   ssh -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/lab server hostname
   ```
   ```
   server
   ```
   Solo se ofrecen las llaves de `-i` / `IdentityFile`; las del agente se usan solo si coinciden con una de ellas.

7. **TODO de `starter/config`.** Escribir `-o IdentitiesOnly=yes -i ...` cada vez no es práctico. `starter/config` ya tiene un alias por host con su `IdentityFile`; falta el TODO en `Host *`:
   ```
       IdentitiesOnly yes
   ```
   con un comentario Qué / Para qué / Impacto. Comprueba con el agente todavía cargado:
   ```bash
   ssh -F starter/config -o BatchMode=yes lab hostname
   ssh -F starter/config -o BatchMode=yes trabajo hostname
   ```
   ```
   server
   bastion
   ```
   Sin el TODO, el primero falla con `Too many authentication failures`.

8. **Qué ofrece ahora:**
   ```bash
   ssh -v -F starter/config -o BatchMode=yes lab true 2>&1 | grep -E 'Will attempt|Offering' | cut -d' ' -f1-6
   ```
   ```
   debug1: Will attempt key: /home/alumno/.ssh/lab ED25519
   debug1: Offering public key: /home/alumno/.ssh/lab ED25519
   ```
   Una sola llave, la correcta, al primer intento. Detén el agente: `ssh-agent -k`.

9. **Responde en tus notas:** ¿qué servidor conoce tu llave `trabajo`? Si el portátil del trabajo se pierde, ¿qué línea borras y dónde? ¿Qué pasaría si usaras la misma llave para todo?

## Criterios de éxito

- [ ] Provocaste `Too many authentication failures` con la llave correcta en `-i` (paso 4)
- [ ] Explicas, con el `-v` del paso 5, por qué no llegó a `lab`
- [ ] `ssh -F starter/config lab` y `trabajo` entran con el agente cargado (paso 7)
- [ ] Respondiste las preguntas del paso 9

## Reto extra

Añade a `starter/config` un bloque `Host github.com` con `IdentityFile ~/.ssh/github` y `User git`. Sin conectarte, comprueba con `ssh -G -F starter/config github.com | grep -E '^(user|identityfile|identitiesonly) '` qué usaría. ¿Por qué `User git` y no tu usuario de GitHub? (Pista: busca "Testing your SSH connection" en la documentación de GitHub.)

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — Permisos y `StrictModes`](../lab-04-permisos-y-strictmodes/README.md) | [Lab 06 — Opciones de `authorized_keys`](../lab-06-opciones-de-authorized-keys/README.md) → |

[↑ Semana 03](../../README.md)
