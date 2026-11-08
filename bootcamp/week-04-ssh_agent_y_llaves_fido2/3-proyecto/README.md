# Proyecto Semana 04 — ssh-infra-kit: agente y llaves `-sk`

⏱ Duración estimada: ~3 h

## Contexto

Desde la semana 03 tu kit entra con llave, pero pide la frase en cada conexión. Esta semana la pide una vez por sesión ([teoría 01](../1-teoria/01-ssh-agent.md)) sin abrir la puerta al agent forwarding ([teoría 02](../1-teoria/02-agent-forwarding-y-riesgos.md)), y aprende a crear llaves FIDO2 ([teoría 03](../1-teoria/03-llaves-fido2-sk.md)):

- **`config`**: `AddKeysToAgent 1h` (la primera conexión carga la llave en el agente durante una hora) y `ForwardAgent no` para todos los hosts.
- **`bin/agent-up`**: con `eval "$(bin/agent-up)"`, reutiliza el agente de `~/.ssh/agent.sock` si está vivo; si no, borra el socket huérfano (si queda) y arranca uno con caducidad por llave. Lo que hiciste a mano en el [lab 03](../2-practicas/lab-03-un-agente-para-todas-las-terminales/README.md).
- **`bin/key-new`**: acepta `KEY_TYPE=ed25519-sk` para crear llaves ligadas a un dispositivo FIDO2, y rechaza cualquier otro tipo.

## Estructura del proyecto

```
starter/                 ← aquí trabajas: tu ssh-infra-kit de la semana 03 + TODOs
├── README.md            ← documentación del kit (TODOs)
├── config               ← TODOs 1 y 2
└── bin/
    ├── lab-check        ← de la semana 01, terminado
    ├── kh-add           ← de la semana 02, terminado
    ├── ak-line          ← de la semana 03, terminado
    ├── key-new          ← TODO 6
    └── agent-up         ← TODOs 3 a 5
solucion/                ← referencia: no la abras hasta terminar
```

## Lo que debes construir

### `config`

| Bloque | Opción nueva | Por qué |
|---|---|---|
| `Host *` | `AddKeysToAgent 1h` | La frase una vez por sesión, y la llave fuera del agente pasada una hora |
| `Host *` | `ForwardAgent no` | Ningún servidor recibe acceso a tu agente |

### `bin/agent-up`

Uso: `eval "$(bin/agent-up)"`. Variables: `AGENT_SOCK` (por defecto `~/.ssh/agent.sock`) y `AGENT_LIFETIME` (por defecto `1h`).

| Situación | stderr | stdout | Código |
|---|---|---|---|
| Con argumentos | `uso: eval "$(agent-up)"` | — | 2 |
| Hay un agente vivo en el socket | `agent-up: reutilizo el agente de SOCKET` | `export SSH_AUTH_SOCK=SOCKET` | 0 |
| No hay socket, o es huérfano | `agent-up: agente nuevo en SOCKET` | `export SSH_AUTH_SOCK=SOCKET` | 0 |
| `ssh-agent` no arranca | el error de `ssh-agent` | — | 1 |

En stdout **solo** la línea `export`: es lo que ejecuta `eval`. Cualquier otro texto en stdout se ejecutaría como un comando.

### `bin/key-new NOMBRE [COMENTARIO]` — nuevo: `KEY_TYPE`

| Situación | Salida | Código |
|---|---|---|
| `KEY_TYPE` vacío o `ed25519` | Como en la semana 03 | 0 |
| `KEY_TYPE=ed25519-sk` con dispositivo | Pide el toque; crea `NOMBRE` (identificador) y `NOMBRE.pub` | 0 |
| `KEY_TYPE=ed25519-sk` sin dispositivo | Error de `ssh-keygen` y `key-new: ¿está conectada la llave FIDO2?` | 1 |
| Otro `KEY_TYPE` | `key-new: tipo no admitido: TIPO (usa ed25519 o ed25519-sk)`, sin crear nada | 2 |

## Paso a paso

### Paso 0 — Preparar la terminal

Desde la raíz del repositorio en tu equipo:

```bash
docker compose up -d --force-recreate server
docker compose run --rm client
```

Ya dentro del contenedor:

```bash
cd bootcamp/week-04-ssh_agent_y_llaves_fido2/3-proyecto/starter
ls bin
```

```
agent-up  ak-line  key-new  kh-add  lab-check
```

- `--force-recreate server` deja `server` sin llaves de otras semanas. La contraseña `alumno` que usarás en el paso 8 es **solo del laboratorio**.
- El cliente es un contenedor nuevo cada vez: `~/.ssh` y el agente desaparecen con `exit`. Haz los pasos 3 a 8 en la misma sesión.

### Paso 1 — TODO 1: `AddKeysToAgent`

Al final de `Host *` en `config`, añade `AddKeysToAgent 1h` con su comentario Qué / Para qué / Impacto. Antes y después:

```bash
ssh -G -F config lab-server | grep addkeys
```

```
addkeystoagent false
```

```
addkeystoagent 3600
```

### Paso 2 — TODO 2: `ForwardAgent no`

En el mismo bloque, `ForwardAgent no`, con su comentario. El comentario tiene que decir **por qué**: qué puede hacer root en un servidor con tu agente reenviado ([teoría 02](../1-teoria/02-agent-forwarding-y-riesgos.md#el-riesgo)) y qué usar en su lugar.

```bash
ssh -G -F config lab-bastion | grep forwardagent
```

```
forwardagent no
```

Ya era el valor por defecto. Escribirlo deja la decisión a la vista de quien lea el kit, y protege si algún día un `Include` (semana 05) trae un `ForwardAgent yes` general.

### Paso 3 — `agent-up`: lo que ya hace

Lee `bin/agent-up`. La validación de argumentos, el arranque con `ssh-agent -a` y el `printf` final ya están escritos. Pruébalo dos veces:

```bash
eval "$(bin/agent-up)"; echo "código: $?"
bin/agent-up; echo "código: $?"
```

```
agent-up: agente nuevo en /home/alumno/.ssh/agent.sock
código: 0
unix_listener: cannot bind to path /home/alumno/.ssh/agent.sock: Address already in use
código: 1
```

La segunda llamada intenta arrancar otro agente en la misma ruta. Es lo que arreglan los TODOs.

- `printf '%q'` escribe la ruta con las comillas o escapes que haga falta para que `eval` la lea bien aunque tenga espacios.
- `(umask 077; mkdir -p ...)` crea el directorio en 700 sin cambiar el `umask` del resto del script: los paréntesis abren una subshell.

### Paso 4 — TODO 3: reutilizar el agente vivo

Si `"$sock"` es un socket (`-S`) y `ssh-add -l` contra él no sale con 2, el agente está vivo: avisa por stderr y no arranques otro. Pista: una función `vivo()` que devuelva éxito si el código no es 2. Con `set -e`, guarda el código con `ssh-add -l ... || rc=$?`, para que un 1 no detenga el script.

```bash
bin/agent-up; echo "código: $?"
pgrep -c ssh-agent
```

```
agent-up: reutilizo el agente de /home/alumno/.ssh/agent.sock
export SSH_AUTH_SOCK=/home/alumno/.ssh/agent.sock
código: 0
1
```

`pgrep -c` cuenta los procesos con ese nombre: uno solo.

### Paso 5 — TODO 4: el socket huérfano

Si el socket existe pero no hay agente detrás, bórralo antes de arrancar. Provócalo como en el lab 03:

```bash
pkill -9 ssh-agent
ls -l ~/.ssh/agent.sock | cut -c1-10
bin/agent-up; echo "código: $?"
```

```
srw-------
agent-up: agente nuevo en /home/alumno/.ssh/agent.sock
export SSH_AUTH_SOCK=/home/alumno/.ssh/agent.sock
código: 0
```

Borra solo en este caso. Si borraras un socket con un agente vivo, ese agente seguiría corriendo con tus llaves, pero nadie podría llegar a él para vaciarlo.

### Paso 6 — TODO 5: caducidad

Añade `-t "${AGENT_LIFETIME:-1h}"` a `ssh-agent`, con su Qué / Para qué / Impacto. Pruébalo con 5 segundos:

```bash
pkill ssh-agent
ssh-keygen -q -t ed25519 -N '' -f ~/tmpk
eval "$(AGENT_LIFETIME=5 bin/agent-up)"
ssh-add ~/tmpk
ssh-add -l | wc -l
sleep 6; ssh-add -l
pkill ssh-agent
```

```
agent-up: agente nuevo en /home/alumno/.ssh/agent.sock
Identity added: /home/alumno/tmpk (alumno@client)
1
The agent has no identities.
```

`AddKeysToAgent 1h` del `config` ya pone caducidad a las llaves que carga `ssh`. Esta cubre también las que añadas a mano con `ssh-add`.

### Paso 7 — TODO 6: `KEY_TYPE` en `key-new`

Lee `KEY_TYPE` (por defecto `ed25519`), rechaza cualquier valor que no sea `ed25519` o `ed25519-sk` **antes** de crear nada, y úsalo en `ssh-keygen -t`. Si `ssh-keygen` falla con `ed25519-sk`, añade la pista del dispositivo.

```bash
KEY_TYPE=rsa bin/key-new prueba; echo "código: $?"
KEY_TYPE=ed25519-sk KEY_PASSPHRASE= bin/key-new prueba; echo "código: $?"
```

```
key-new: tipo no admitido: rsa (usa ed25519 o ed25519-sk)
código: 2
key-new: aviso: llave sin frase de paso
Key enrollment failed: device not found
key-new: ¿está conectada la llave FIDO2?
código: 1
```

En el contenedor no hay dispositivo ([lab 07](../2-practicas/lab-07-llaves-fido2/README.md)). Con una llave FIDO2 en tu equipo, el mismo comando crea la llave después del toque.

### Paso 8 — La frase una vez

Prepara `known_hosts` y tu llave como en la semana 03. **En tu equipo**, la huella de `server`:

```bash
docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

**En el cliente:**

```bash
bin/kh-add server SHA256:...
bin/key-new lab
ssh-copy-id -F config -i ~/.ssh/lab.pub lab-server
```

`key-new` pide una frase para la llave; `ssh-copy-id`, la contraseña `alumno` (**solo laboratorio**). Ahora, el agente:

```bash
eval "$(bin/agent-up)"
ssh -F config lab-server hostname
ssh-add -l
ssh -F config lab-server hostname
```

```
agent-up: agente nuevo en /home/alumno/.ssh/agent.sock
Enter passphrase for key '/home/alumno/.ssh/lab':
server
256 SHA256:74IQURjlvCYpjvH0gDL2Xy/OhQYsUu8BPC6DVz944Gw alumno@client-2026-11-08 (ED25519)
server
```

La frase, una vez; la llave, en el agente durante una hora. Y el agente no sale del cliente:

```bash
ssh -F config lab-server 'echo "SSH_AUTH_SOCK=[$SSH_AUTH_SOCK]"'
```

```
SSH_AUTH_SOCK=[]
```

### Paso 9 — Calidad, README y git

1. `shellcheck bin/*` sin avisos y ningún `TODO` en `bin/`.
2. Completa los TODOs de `starter/README.md`: la fila de `agent-up`, `KEY_TYPE` en la de `key-new`, la bitácora de la semana 04 y la sección "Escribir la frase una vez por sesión".
3. Copia el kit a tu repositorio y haz el commit de la semana:
   ```bash
   cp -r config bin README.md ~/ssh-infra-kit/
   cd ~/ssh-infra-kit && git add -A && git commit -m "semana 04: agente y llaves -sk"
   git log --stat -1
   ```
   En la lista de archivos del commit solo deben aparecer `config`, `README.md` y archivos de `bin/`: ninguna llave. El socket del agente vive en `~/.ssh`, fuera del kit.

### Paso 10 — Autograding

Desde la raíz del repositorio, **en tu equipo**:

```bash
./scripts/verificar-semana.sh 04
```

Una comprobación arranca un `sshd` en el cliente y comprueba que, con tu `config` y tu `agent-up`, la primera conexión deja la llave en el agente.

## ✅ Requisitos verificables

- El config se lee sin errores
- Siguen las opciones de la semana 03 (IdentitiesOnly yes)
- La primera conexión deja la llave en el agente durante 1 h
- ssh no reenvía el agente
- agent-up con argumentos sale con 2
- agent-up crea un socket de agente con permisos 600
- El directorio nuevo del socket queda en 700
- eval de su salida deja un agente vacío listo (ssh-add -l sale con 1)
- stdout es solo la línea export SSH_AUTH_SOCK
- Una segunda llamada sale con 0 y no arranca otro agente
- El agente reutilizado conserva sus llaves
- Con un socket sin agente detrás, arranca uno nuevo
- Las llaves caducan en el agente pasado AGENT_LIFETIME
- key-new sin argumentos sale con 2
- Sin KEY_TYPE, la llave es Ed25519
- key-new rechaza KEY_TYPE=rsa (sale con 2)
- Con un tipo no admitido no crea ningún archivo
- Con ed25519-sk y sin llave FIDO2, sale con 1
- Sin llave FIDO2, el error lo dice
- Con el config, la primera conexión a un sshd real deja la llave en el agente
- ak-line y kh-add de semanas anteriores siguen en el kit
- Sin TODO y shellcheck sin avisos en bin/

## Calidad

Lo que el autograding no ve se evalúa en la [rúbrica](../rubrica-evaluacion.md#-producto-30): README del kit, mensajes, comentarios que explican el porqué y el historial de git sin llaves.

## Entrega

- [ ] `./scripts/verificar-semana.sh 04` con las 22 comprobaciones en verde
- [ ] `starter/README.md` sin TODOs
- [ ] `~/ssh-infra-kit` con un commit nuevo para esta semana y ninguna llave en `git log --stat`

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 07 — Llaves FIDO2](../2-practicas/lab-07-llaves-fido2/README.md) | [Rúbrica de evaluación](../rubrica-evaluacion.md) → |

[↑ Semana 04](../README.md)
