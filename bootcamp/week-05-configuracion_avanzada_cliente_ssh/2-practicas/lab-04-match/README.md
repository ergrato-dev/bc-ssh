# Lab 04 — `Match`

⏱ Duración estimada: ~60 min

## Objetivo

Aplicar opciones según el host final, el usuario remoto o el resultado de una orden, y comprobar en qué momento de la lectura evalúa `ssh` cada `Match`.

## Contexto

- `Match` y sus criterios: [teoría 02](../../1-teoria/02-include-match-y-perfiles.md#match-condiciones).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-el-primer-valor-gana/README.md), con `cd` a esta carpeta.

1. **`host` frente a `originalhost`.** Crea el archivo de la teoría:
   ```bash
   cat > /tmp/orden.conf <<'EOF'
   Match host server
       User antes
   Host lab-server
       HostName server
   Match host server
       Port 2222
   Match originalhost server
       ConnectTimeout 9
   EOF
   for h in lab-server server; do echo "-- $h"; ssh -G -F /tmp/orden.conf $h | grep -E '^(user|port|connecttimeout) '; done
   ```
   ```
   -- lab-server
   user alumno
   port 2222
   connecttimeout none
   -- server
   user antes
   port 2222
   connecttimeout 9
   ```
   Antes de seguir, explica en tus notas cada una de las seis líneas. Pista: `ssh` lee de arriba abajo **una vez**, y cada `Match host` mira el `HostName` que haya **en ese momento**.

2. **TODO 1 de `starter/config`: llave según host y usuario.** Escribe, debajo de los alias:
   ```
   Match host server,bastion user alumno
       IdentityFile ~/.ssh/lab
       IdentitiesOnly yes
   ```
   - `host server,bastion`: el host final, llegues por alias o por nombre. En `Match`, las listas van con **comas**.
   - `user alumno`: el usuario remoto. Ningún bloque fija `User`, así que es tu usuario local (`alumno`), salvo que uses `-l`.

   Comprueba cuatro casos:
   ```bash
   for h in lab-server server bastion; do printf '%-11s ' $h; ssh -G -F starter/config $h | grep -E '^(identityfile|identitiesonly) ' | paste -sd' '; done
   ssh -G -F starter/config -l root server | grep -E '^identitiesonly '
   ```
   ```
   lab-server  identitiesonly yes identityfile ~/.ssh/lab
   server      identitiesonly yes identityfile ~/.ssh/lab
   bastion     identitiesonly yes identityfile ~/.ssh/lab
   identitiesonly no
   ```
   Con `-l root`, el criterio `user alumno` falla y el bloque entero no se aplica. Conecta sin alias:
   ```bash
   ssh -F starter/config server hostname
   ```
   ```
   server
   ```

3. **TODO 2: `Match exec`.** Un "modo viaje" que se activa creando un archivo. Escríbelo **antes** de `Host *`:
   ```
   Match exec "test -f ~/.ssh/modo-viaje"
       ConnectTimeout 30
       ServerAliveInterval 15
   ```
   - `test -f ARCHIVO` sale con 0 si el archivo existe.
   - `ServerAliveInterval 15`: cada 15 s sin tráfico, `ssh` envía un mensaje al servidor. Mantiene viva la conexión en redes que cortan las inactivas y detecta antes una caída.

   Comprueba con y sin el archivo:
   ```bash
   ssh -G -F starter/config lab-server | grep -E '^(connecttimeout|serveraliveinterval) '
   touch ~/.ssh/modo-viaje
   ssh -G -F starter/config lab-server | grep -E '^(connecttimeout|serveraliveinterval) '
   rm ~/.ssh/modo-viaje
   ```
   ```
   serveraliveinterval 0
   connecttimeout 5
   serveraliveinterval 15
   connecttimeout 30
   ```
   Si lo escribes **después** de `Host *`, `ConnectTimeout` se queda en 5: compruébalo.

4. **Lo que cuesta `exec`.** La orden corre en cada `ssh`, incluido `ssh -G`:
   ```bash
   printf 'Match exec "sleep 2"\n    User lento\n' > /tmp/lento.conf
   time ssh -G -F /tmp/lento.conf x >/dev/null
   ```
   ```
   real	0m2.008s
   user	0m0.005s
   sys	0m0.003s
   ```
   Dos segundos en cada conexión, `scp` y `git push`. Usa órdenes que respondan al momento (`test`, `grep -q` en un archivo); evita las que esperan a la red.

5. **Nombres que no llegan a `exec`.** Un nombre de host con caracteres de shell podría ejecutar algo si un token `%h` lo llevara a un `exec`. OpenSSH 9.6 lo para antes:
   ```bash
   ssh -G -F starter/config 'server;id'; echo "código: $?"
   ```
   ```
   hostname contains invalid characters
   código: 255
   ```

## Criterios de éxito

- [ ] Explicaste las seis líneas del paso 1
- [ ] `starter/config` aplica `~/.ssh/lab` a `server` y `bastion` solo con usuario `alumno` (paso 2)
- [ ] El modo viaje cambia `ConnectTimeout` y `ServerAliveInterval` según exista el archivo (paso 3)
- [ ] Sabes por qué una orden lenta en `Match exec` es un problema (paso 4)

## Reto extra

Haz que el modo viaje se active solo en una red concreta: con `Match exec`, comprueba si `/etc/resolv.conf` contiene un `search` determinado (`grep -q`). Mide con `time ssh -G` que la orden no retrasa la conexión.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — `Include` y `conf.d/`](../lab-03-include-y-conf-d/README.md) | [Lab 05 — Perfiles con `Tag` y `-P`](../lab-05-perfiles-con-tag/README.md) → |

[↑ Semana 05](../../README.md)
