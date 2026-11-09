# Lab 04 — Un proxy SOCKS con `ssh -D`

⏱ Duración estimada: ~60 min

## Objetivo

Abrir un proxy SOCKS con `ssh -D` y usarlo con `curl` y `nc` para llegar a varios destinos que solo alcanza `server`. Ver la diferencia entre resolver los nombres en tu equipo o en el servidor, y qué programas pueden usar SOCKS y cuáles no.

## Contexto

- SOCKS, `socks5` y `socks5h`: [teoría 02](../../1-teoria/02-socks-config-y-limites.md#-d-un-proxy-socks-que-sale-por-el-servidor).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-reenvio-local/README.md), con la web de `server` en marcha.

1. **El proxy.**
   ```bash
   ssh -f -N -D 1080 server
   ss -ltn | grep 1080
   curl -s --socks5-hostname localhost:1080 http://localhost:8080
   ```
   ```
   LISTEN 0      128        127.0.0.1:1080       0.0.0.0:*          
   LISTEN 0      128            [::1]:1080          [::]:*          
   hola desde server
   ```
   - `-D 1080`: `ssh` escucha en el `1080` de tu equipo y habla SOCKS. No dices a dónde va: lo dice cada programa en cada conexión.
   - `curl --socks5-hostname localhost:1080`: usa ese proxy, y deja que el proxy resuelva los nombres. `localhost` lo resolvió `server`: llegaste a **su** web, no a la tuya.

2. **Quién resuelve el nombre.** Ahora un destino que solo existe en la red de `server`, con y sin `-hostname`:
   ```bash
   curl -sS -m 3 --socks5 localhost:1080 http://db:5432; echo "código: $?"
   curl -sS -m 3 --socks5-hostname localhost:1080 http://db:5432; echo "código: $?"
   ```
   ```
   curl: (97) Could not resolve host: db
   código: 97
   curl: (52) Empty reply from server
   código: 52
   ```
   - `--socks5`: `curl` resuelve `db` **en tu equipo**, no puede, y ni siquiera llega a usar el proxy.
   - `--socks5-hostname`: `curl` manda el nombre; `server` lo resuelve y conecta. `Empty reply` es PostgreSQL, que no habla HTTP y no contesta nada. Llegaste.
   - Con un nombre de Internet, `--socks5` **sí** funcionaría, pero preguntando a tu DNS: la red en la que estás sabría a qué webs vas. Usa siempre la variante que resuelve en el servidor.

3. **`nc` también habla SOCKS.** Comprueba un puerto a través del proxy:
   ```bash
   nc -zv -X 5 -x localhost:1080 db 5432
   ```
   ```
   Connection to db 5432 port [tcp/postgresql] succeeded!
   ```
   `-X 5`: SOCKS versión 5; `-x`: la dirección del proxy. `nc` manda el nombre sin resolverlo. Es la herramienta para comprobar qué alcanza `server` sin abrir un `-L` por cada destino.

4. **Sin decirlo en cada orden.** Muchos programas leen el proxy de una variable de entorno:
   ```bash
   ALL_PROXY=socks5h://localhost:1080 curl -s http://localhost:8080
   ```
   ```
   hola desde server
   ```
   La `h` de `socks5h://` es la de `--socks5-hostname`: resuelve en el servidor. `git` también la entiende (`git config http.proxy socks5h://localhost:1080`), y los navegadores tienen su propia configuración de proxy SOCKS, con la casilla de resolver los nombres por el proxy.

5. **Lo que `server` no alcanza.** `interno` está en otra red (`privada`, la de la semana 09), y `nada.invalid` no existe:
   ```bash
   curl -sS -m 3 --socks5-hostname localhost:1080 http://interno:22; echo "código: $?"
   curl -sS -m 3 --socks5-hostname localhost:1080 http://nada.invalid; echo "código: $?"
   ```
   ```
   curl: (97) connection to proxy closed
   código: 97
   curl: (97) connection to proxy closed
   código: 97
   ```
   El proxy llega exactamente a lo que llega `server`, ni más ni menos. Y no distingue "no existe" de "no puedo llegar": `ssh` cierra el canal y ya.

6. **El canal por dentro.**
   ```bash
   pkill -f 'ssh -f -N -D'
   ssh -v -E ~/w/d.log -f -N -D 1080 server
   curl -s --socks5-hostname localhost:1080 http://localhost:8080 >/dev/null
   grep -E 'socks|channel 2' ~/w/d.log | cut -c1-110
   pkill -f 'ssh -v -E'
   ```
   ```
   debug1: Local connections to LOCALHOST:1080 forwarded to remote address socks:0
   debug1: Connection to port 1080 forwarding to socks port 0 requested.
   debug1: channel 2: new dynamic-tcpip [dynamic-tcpip] (inactive timeout: 0)
   debug1: channel 2: free: direct-tcpip: listening port 1080 for localhost port 8080, connect from ::1 port 4
   ```
   El canal nace como `dynamic-tcpip`: aún no sabe a dónde va. Cuando `curl` dice `localhost:8080`, se convierte en un `direct-tcpip` normal, igual que los del lab 01.

7. **Qué no puede usar SOCKS.** `psql` no sabe hablar con un proxy. Para la base de datos, un `-L` como el del lab 02. Regla práctica:

   | Necesitas | Usa |
   |---|---|
   | Un servicio concreto, con cualquier programa | `-L` |
   | Muchos destinos, con navegador, `curl` o `git` | `-D` |

## Criterios de éxito

- [ ] Abres un proxy SOCKS y llegas con él a la web interna de `server` (paso 1)
- [ ] Explicas la diferencia entre `--socks5` y `--socks5-hostname`, y por qué importa fuera del laboratorio (paso 2)
- [ ] Usas `nc -X 5 -x` y `ALL_PROXY` (pasos 3 y 4)
- [ ] Explicas hasta dónde llega el proxy (paso 5)
- [ ] Eliges entre `-L` y `-D` según el programa y el destino (paso 7)

## Reto extra

Usa el proxy SOCKS para que `ssh` llegue a un servidor: `ssh -o ProxyCommand='nc -X 5 -x localhost:1080 %h %p' server`. Funciona, pero hay una forma mucho mejor de saltar por un servidor, que no necesita ningún túnel previo. ¿Cuál es? La verás la semana que viene.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 03 — Reenvío remoto: enseñar al servidor algo de tu equipo](../lab-03-reenvio-remoto/README.md) | [Lab 05 — Túneles en `ssh_config` y con el master](../lab-05-tuneles-en-config/README.md) → |

[↑ Semana 08](../../README.md)
