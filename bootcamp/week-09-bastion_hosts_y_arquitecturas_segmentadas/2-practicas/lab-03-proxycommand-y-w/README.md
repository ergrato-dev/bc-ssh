# Lab 03 — `ProxyCommand` y `ssh -W`

⏱ Duración estimada: ~60 min

## Objetivo

Desmontar `ProxyJump` en sus piezas: `ssh -W` y `ProxyCommand`. Saltar con otros programas (`nc` en el bastion, el proxy SOCKS de la semana 08), y entender los errores de un salto y el problema de entrar por IP.

## Contexto

- `ssh -W`, `ProxyCommand` y sus *tokens*: [teoría 02](../../1-teoria/02-proxyjump-y-proxycommand.md#ssh--w-un-canal-pegado-a-la-entrada-y-la-salida).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-red-segmentada/README.md).

1. **`ssh -W` a pelo.** Pídele al bastion un canal hasta `interno:22` y mira qué llega:
   ```bash
   timeout 3 ssh -W interno:22 bastion </dev/null | head -1
   ```
   ```
   SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.20
   ```
   - `-W interno:22`: une la entrada y salida de `ssh` a un canal hasta ese destino. Sin sesión, sin puerto local.
   - Lo que llega es el saludo del `sshd` de `interno`. Tienes un tubo hasta él; falta alguien que hable SSH por el tubo.
   - `timeout 3` lo corta a los 3 s; `</dev/null`, sin nada que mandar; `head -1`, solo la primera línea.

2. **`ProxyCommand`: alguien que hable por el tubo.**
   ```bash
   ssh -o ProxyCommand='ssh -W %h:%p bastion' interno hostname
   ssh -v -o ProxyCommand='ssh -W %h:%p bastion' interno true 2>&1 | grep 'proxy command'
   ```
   ```
   interno
   debug1: Executing proxy command: exec ssh -W interno:22 bastion
   ```
   - `ProxyCommand`: en lugar de abrir TCP con `interno`, `ssh` ejecuta ese programa y habla SSH por su entrada y salida.
   - `%h` y `%p` se cambian por el host y el puerto del destino. Las comillas simples evitan que tu shell toque el `%`.
   - Es lo mismo que `-J bastion`: compara con el paso 1 del lab 02. `-J` es la forma corta (OpenSSH 7.3+), y además pasa tu `-v` y tu `-F` al salto.

3. **El método antiguo: `nc` en el bastion.** Antes de `-W` (OpenSSH 5.4), el salto se hacía ejecutando `nc` en el bastion:
   ```bash
   ssh -o ProxyCommand='ssh bastion nc %h %p' interno hostname
   ssh bastion 'which nc'
   ```
   ```
   interno
   /usr/bin/nc
   ```
   Funciona, pero necesita que la cuenta del bastion **ejecute un comando**: una shell y `nc` instalado. Con `-W`, `sshd` abre el canal él mismo, sin ejecutar nada. En el lab 06 el bastion deja de ejecutar comandos, y este método deja de funcionar.

4. **Saltar con otro programa: el SOCKS de la semana 08.** `ProxyCommand` acepta cualquier programa que conecte su entrada y salida con el destino. Abre un proxy SOCKS en el bastion y usa `nc` como cliente:
   ```bash
   ssh -f -N -D 1080 bastion
   ssh -o ProxyCommand='nc -X 5 -x localhost:1080 %h %p' interno hostname
   pkill -f '^ssh -f -N -D'
   ```
   ```
   interno
   ```
   - `nc -X 5 -x localhost:1080`: conecta a través del proxy SOCKS5 (semana 08, lab 04). El nombre `interno` lo resuelve el bastion.
   - Funciona, pero necesita un proceso abierto de antes y deja el `1080` abierto en tu equipo. `-J` lo hace todo en una orden. El `^` de `pkill` hace que el patrón tenga que estar al principio de la orden: así no mata a tu shell si el patrón aparece en ella.

5. **Entrar por IP.** El bastion resuelve `interno` como `172.19.0.3` (lab 01). Entra con la IP:
   ```bash
   ssh -J bastion 172.19.0.3 hostname; echo "código: $?"
   ssh -o HostKeyAlias=interno -J bastion 172.19.0.3 hostname
   ```
   ```
   Host key verification failed.
   código: 255
   interno
   ```
   - Sin terminal, `ssh` no puede preguntar y falla; con una, te preguntaría como si fuera un servidor nuevo. `known_hosts` tiene la llave guardada con el nombre `interno`, no con `172.19.0.3`, y con un salto `ssh` no sabe la IP para buscarla por ahí.
   - `HostKeyAlias=interno`: busca (y guarda) la host key con ese nombre, conectes como conectes. Útil también para un túnel (`localhost:2222` que en realidad es `interno`).

6. **Cuando el salto falla.** Dos errores distintos:
   ```bash
   ssh -o ProxyCommand='ssh -W %h:%p nadie' interno true; echo "código: $?"
   ssh -J bastion nada true; echo "código: $?"
   ```
   ```
   ssh: Could not resolve hostname nadie: Name or service not known
   Connection closed by UNKNOWN port 65535
   código: 255
   channel 0: open failed: connect failed: Name or service not known
   stdio forwarding failed
   Connection closed by UNKNOWN port 65535
   código: 255
   ```
   - El primero: el `ssh` del salto no llega al bastion (`nadie` no existe).
   - El segundo: llega al bastion, pero **el bastion** no resuelve `nada`. `channel 0: open failed` es el bastion rechazando o sin poder abrir el canal; `stdio forwarding failed`, el `ssh -W` rindiéndose.
   - `Connection closed by UNKNOWN port 65535`: el `ssh` de fuera, que ve cerrarse su tubo sin saber por qué. `UNKNOWN port 65535` es como nombra a un `ProxyCommand`. Lee siempre la línea **anterior**: dice qué tramo falló.

## Criterios de éxito

- [ ] Explicas qué hace `ssh -W` y qué es la línea que imprime (paso 1)
- [ ] Escribes el `ProxyCommand` equivalente a `-J` y explicas `%h` y `%p` (paso 2)
- [ ] Explicas qué necesita del bastion el método con `nc` y por qué `-W` no (paso 3)
- [ ] Saltas a través del proxy SOCKS con `nc -X 5` (paso 4)
- [ ] Explicas por qué falla entrar por IP y qué hace `HostKeyAlias` (paso 5)
- [ ] Distingues, por los mensajes, si falló el salto o el destino (paso 6)

## Reto extra

`ProxyUseFdpass yes` hace que el `ProxyCommand` le pase a `ssh` el socket ya conectado y termine, en lugar de quedarse copiando bytes. Lee `man ssh_config`: ¿por qué no sirve con `ssh -W`? ¿Con qué programa sí tendría sentido?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 02 — ProxyJump: un `ssh` dentro de otro](../lab-02-proxyjump/README.md) | [Lab 04 — Saltos en `ssh_config`](../lab-04-saltos-en-config/README.md) → |

[↑ Semana 09](../../README.md)
