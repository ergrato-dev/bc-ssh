# Lab 06 — Multiplexing

⏱ Duración estimada: ~60 min

## Objetivo

Activar el multiplexing, medir cuánto tiempo ahorra, ver el master y su socket y controlarlo con `ssh -O`.

## Contexto

- `ControlMaster`, `ControlPath`, `ControlPersist` y `ssh -O`: [teoría 03](../../1-teoria/03-multiplexing.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-el-primer-valor-gana/README.md), con `cd` a esta carpeta.

1. **Sin multiplexing.** 20 conexiones seguidas:
   ```bash
   time (for i in $(seq 20); do ssh -F starter/config lab-server true; done)
   ```
   ```
   real	0m6.775s
   user	0m1.250s
   sys	0m0.060s
   ```
   - `true` no hace nada: casi todo el tiempo es conectar, intercambiar llaves y autenticarse.
   - `real` es el tiempo que esperaste. Tus números serán otros; compáralos con los del paso 4.

2. **TODO de `starter/config`.** Completa el bloque `Host *`:
   ```
       ControlMaster auto
       ControlPath ~/.ssh/cm/%C
       ControlPersist 10m
   ```
   ```bash
   ssh -G -F starter/config lab-server | grep '^control'
   ```
   ```
   controlmaster auto
   controlpath /home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c
   controlpersist 600
   ```
   En `ControlPath`, `-G` sí sustituye los tokens: `%C` es ya el hash.

3. **La carpeta no existe:**
   ```bash
   ssh -F starter/config lab-server hostname; echo "código: $?"
   ```
   ```
   unix_listener: cannot bind to path /home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c.ZROHaIlSXcNrt7vD: No such file or directory
   código: 255
   ```
   `ssh` no crea la carpeta del socket, y sin socket no conecta. Créala solo para ti:
   ```bash
   mkdir -m 700 ~/.ssh/cm
   ssh -F starter/config lab-server hostname
   ```
   ```
   server
   ```

4. **Con multiplexing.** El master quedó abierto en el paso 3. Repite la medida:
   ```bash
   time (for i in $(seq 20); do ssh -F starter/config lab-server true; done)
   ```
   ```
   real	0m0.149s
   user	0m0.031s
   sys	0m0.054s
   ```
   Unas 45 veces menos.

5. **El master y su socket:**
   ```bash
   ls -l ~/.ssh/cm
   ps -o pid,args -u alumno | grep '[s]sh:'
   ssh -F starter/config -O check lab-server; echo "código: $?"
   ```
   ```
   total 0
   srw------- 1 alumno alumno 0 Nov  8 06:23 e02bc41ef904cf7479525f22b4660ffc0adc7c8c
       235 ssh: /home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c [mux]
   Master running (pid=235)
   código: 0
   ```
   - `s` al principio de los permisos: un socket. `rw-------`: solo tú.
   - `[s]sh:` en `grep` evita que `grep` se encuentre a sí mismo.
   - El master es un proceso `ssh` en segundo plano, sin terminal.

6. **Una sesión por el master.** `-v` lo muestra:
   ```bash
   ssh -v -F starter/config lab-server true 2>&1 | grep -E 'mux|Connecting to'
   ```
   ```
   debug1: auto-mux: Trying existing master at '/home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c'
   debug1: mux_client_request_session: master session id: 2
   ```
   No hay `Connecting to`: no se abrió ninguna conexión TCP.

7. **Cerrar el master:**
   ```bash
   ssh -F starter/config -O exit lab-server
   ssh -F starter/config -O check lab-server; echo "código: $?"
   ```
   ```
   Exit request sent.
   Control socket connect(/home/alumno/.ssh/cm/e02bc41ef904cf7479525f22b4660ffc0adc7c8c): No such file or directory
   código: 255
   ```

8. **`ControlPersist no`.** Sin persistencia, el master es el propio `ssh` y termina con él:
   ```bash
   ssh -F starter/config -o ControlPersist=no lab-server true; ls ~/.ssh/cm | wc -l
   ```
   ```
   0
   ```
   Útil para una sesión interactiva larga: las demás terminales viajan por ella mientras está abierta.

9. **Rutas legibles frente a `%C`.** Un nombre legible:
   ```bash
   ssh -F starter/config -o ControlPath='~/.ssh/cm/%r@%h:%p' lab-server true; ls ~/.ssh/cm
   ssh -F starter/config -o ControlPath='~/.ssh/cm/%r@%h:%p' -O exit lab-server
   ```
   ```
   alumno@server:22
   Exit request sent.
   ```
   Se lee mejor, pero crece con el nombre del host. Un socket Unix no admite rutas de 108 bytes o más:
   ```bash
   ssh -F starter/config -o ControlPath="/tmp/$(printf 'x%.0s' $(seq 110))" lab-server true; echo "código: $?"
   ```
   ```
   ControlPath too long ('/tmp/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' >= 108 bytes)
   código: 255
   ```
   `printf 'x%.0s' $(seq 110)` escribe 110 equis. `%C` siempre ocupa 40 caracteres.

## Criterios de éxito

- [ ] `starter/config` multiplexa y mediste la diferencia (pasos 1 a 4)
- [ ] Viste el socket, el proceso master y `-O check` (paso 5)
- [ ] Cerraste el master con `-O exit` (paso 7)
- [ ] Explicas cuándo usar `ControlPersist no` y por qué `%C` (pasos 8 y 9)

## Reto extra

Deja una sesión ocupada en segundo plano y para el master mientras tanto:

```bash
ssh -F starter/config lab-server 'sleep 20; echo sigo viva' &
ssh -F starter/config -O check lab-server
ssh -F starter/config -O stop lab-server
ssh -F starter/config lab-server true
ssh -F starter/config -O check lab-server
wait
```

¿Termina la sesión de `sleep`? ¿El `ssh` posterior usó el master viejo o creó otro (compara los `pid`)? ¿Cuándo usarías `stop` en lugar de `exit`?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 05 — Perfiles con `Tag` y `-P`](../lab-05-perfiles-con-tag/README.md) | [Lab 07 — Lo que decide el master](../lab-07-lo-que-decide-el-master/README.md) → |

[↑ Semana 05](../../README.md)
