# Lab 05 — Perfiles con `Tag` y `-P`

⏱ Duración estimada: ~60 min

## Objetivo

Crear perfiles que eliges al conectar (`ssh -P depurar`, `ssh -P viaje`), asignar uno por defecto a un host con `Tag` y comprobar por qué la posición de cada línea decide si el perfil se aplica.

## Contexto

- `Tag`, `-P` y `Match tagged`: [teoría 02](../../1-teoria/02-include-match-y-perfiles.md#perfiles-tag-y--p).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-el-primer-valor-gana/README.md), con `cd` a esta carpeta.

1. **TODO 1: perfil `depurar`.** Al principio de `starter/config`:
   ```
   Match tagged depurar
       LogLevel DEBUG1
   ```
   `LogLevel DEBUG1` equivale a `ssh -v`. Compara:
   ```bash
   ssh -G -F starter/config lab-server | grep -E '^(tag|loglevel) '
   ssh -G -F starter/config -P depurar lab-server | grep -E '^(tag|loglevel) '
   ```
   ```
   loglevel INFO
   loglevel DEBUG
   tag depurar
   ```
   Sin `-P` no hay línea `tag`: la conexión no tiene etiqueta. Al conectar:
   ```bash
   ssh -F starter/config -P depurar lab-server hostname 2>&1 | head -3
   ssh -F starter/config -P depurar lab-server hostname 2>&1 | wc -l
   ```
   ```
   debug1: Connecting to server [172.20.0.2] port 22.
   debug1: fd 3 clearing O_NONBLOCK
   debug1: Connection established.
   66
   ```
   65 líneas de depuración y `server`. La diferencia con `ssh -v`: el perfil puede cambiar varias opciones a la vez, y lo eliges por su nombre.

2. **TODO 2: perfil `viaje`.** Debajo de `depurar`:
   ```
   Match tagged viaje
       ConnectTimeout 30
       ServerAliveInterval 15
       Compression yes
   ```
   - `Compression yes`: comprime el tráfico. Ayuda en enlaces lentos con texto; en una red rápida gasta CPU sin ganar nada.
   - El resto, como el modo viaje del [lab 04](../lab-04-match/README.md).

3. **TODO 3: un perfil por defecto para `lab-bastion`.** Prueba primero donde parece natural, dentro de su bloque. Un archivo de prueba reducido:
   ```bash
   cat > /tmp/tarde.conf <<'EOF'
   Match tagged viaje
       ConnectTimeout 30
   Host lab-bastion
       HostName bastion
       Tag viaje
   EOF
   ssh -G -F /tmp/tarde.conf lab-bastion | grep -E '^(tag|connecttimeout) '
   ssh -G -F /tmp/tarde.conf -P viaje lab-bastion | grep -E '^(tag|connecttimeout) '
   ```
   ```
   tag viaje
   connecttimeout none
   tag viaje
   connecttimeout 30
   ```
   Las dos tienen la etiqueta, pero solo `-P` aplica el perfil: `Tag viaje` se lee **después** de `Match tagged viaje`, y `ssh` no vuelve atrás. Por eso, en `starter/config`, pon el `Tag` en un bloque propio al principio del archivo:
   ```
   Host lab-bastion
       Tag viaje
   ```
   Un alias puede aparecer en varios bloques: el `HostName` sigue en el suyo, más abajo.

4. **Comprueba los tres perfiles:**
   ```bash
   ssh -G -F starter/config lab-bastion | grep -E '^(tag|loglevel|connecttimeout|compression|serveraliveinterval) '
   ssh -G -F starter/config -P depurar lab-bastion | grep -E '^(tag|loglevel|connecttimeout|compression) '
   ```
   ```
   compression yes
   serveraliveinterval 15
   loglevel INFO
   tag viaje
   connecttimeout 30
   compression no
   loglevel DEBUG
   tag depurar
   connecttimeout 5
   ```
   Con `-P depurar`, `lab-bastion` deja de ser `viaje`: cada conexión tiene una sola etiqueta, y la línea de comandos se lee antes que el archivo.

5. **Conecta con cada perfil** para comprobar que todo funciona de verdad:
   ```bash
   ssh -F starter/config lab-bastion hostname
   ssh -F starter/config -P viaje lab-server hostname
   ```
   ```
   bastion
   server
   ```

## Criterios de éxito

- [ ] `ssh -P depurar` y `ssh -P viaje` cambian las opciones de su perfil (pasos 1, 2 y 4)
- [ ] `lab-bastion` usa `viaje` sin `-P`, y `-P depurar` lo sustituye (paso 4)
- [ ] Explicas por qué `Tag viaje` dentro del bloque de `lab-bastion` no bastaba (paso 3)

## Reto extra

`Match final` hace que `ssh` lea toda la configuración una segunda vez al terminar la primera. Vuelve a `/tmp/tarde.conf` y cambia `Match tagged viaje` por `Match final tagged viaje`. ¿Se aplica ahora sin `-P`? ¿Qué inconveniente tiene leer todo dos veces si hay un `Match exec`?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 04 — `Match`](../lab-04-match/README.md) | [Lab 06 — Multiplexing](../lab-06-multiplexing/README.md) → |

[↑ Semana 05](../../README.md)
