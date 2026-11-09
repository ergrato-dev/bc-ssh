# Lab 02 — PostgreSQL a través de `server`

⏱ Duración estimada: ~60 min

## Objetivo

Usar con `psql` una base de datos PostgreSQL que tu equipo no puede alcanzar, a través de `server`. Ver quién conecta de verdad con la base de datos, qué tramo cifra el túnel y cuál no, y guardar la contraseña sin escribirla en cada orden.

## Contexto

- El destino de `-L` lo resuelve el servidor: [teoría 01](../../1-teoria/01-reenvio-local-y-remoto.md#-l-un-puerto-de-tu-equipo-que-sale-por-el-servidor).
- Qué tramo cifra el túnel: [teoría 01](../../1-teoria/01-reenvio-local-y-remoto.md#lo-que-el-túnel-cifra-y-lo-que-no).
- `db` es el servicio de PostgreSQL de `compose.yaml`: está en la red `datos`, donde solo está `server`. Tiene la base `tienda`, con una tabla `productos`. Usuario `alumno`, contraseña `alumno`: **solo del laboratorio**.

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-reenvio-local/README.md).

1. **`db` no existe para tu equipo.** `nc -z` comprueba si un puerto acepta conexiones, sin mandar nada:
   ```bash
   nc -zv -w 2 db 5432
   ssh server 'nc -zv -w 2 db 5432'
   ```
   ```
   nc: getaddrinfo for host "db" port 5432: Name or service not known
   Connection to db (172.25.0.2) 5432 port [tcp/postgresql] succeeded!
   ```
   - Tu equipo ni siquiera sabe la IP de `db`: no está en ninguna de sus redes. `server` sí llega. Es lo normal en producción: la base de datos no escucha en Internet.
   - `-v` explica qué pasa; `-w 2` se rinde a los 2 s. Las IP serán otras en tu laboratorio.

2. **El túnel y la primera consulta.**
   ```bash
   ssh -f -N -L 15432:db:5432 server
   export PGPASSWORD=alumno
   psql -h 127.0.0.1 -p 15432 -U alumno tienda -c 'select * from productos'
   ```
   ```
    id | nombre  | precio 
   ----+---------+--------
     1 | teclado |  45.00
     2 | ratón   |  19.90
     3 | monitor | 189.00
   (3 rows)
   ```
   - `15432` y no `5432`: si en tu equipo ya corre un PostgreSQL, su puerto está ocupado. El kit usa esta misma regla: el puerto del servicio más 10000.
   - `psql -h 127.0.0.1 -p 15432`: conecta con el puerto del túnel. `-U alumno` el usuario, `tienda` la base de datos, `-c` la consulta (sin `-c`, abre su consola interactiva; `\q` para salir).
   - `PGPASSWORD`: la contraseña para `psql`. **Solo en el laboratorio**: una variable de entorno la pueden leer otros procesos tuyos. El paso 5 lo hace mejor.

3. **Quién conecta con `db`.** PostgreSQL te dice desde qué IP le llega la conexión:
   ```bash
   psql -h 127.0.0.1 -p 15432 -U alumno tienda -tAc 'select inet_client_addr()'
   ssh server 'hostname -I'
   hostname -I
   ```
   ```
   172.25.0.3
   172.25.0.3 172.20.0.3 
   172.20.0.7 
   ```
   - `-t` sin cabeceras, `-A` sin alinear: solo el valor.
   - La conexión llega desde `172.25.0.3`, la IP de **`server`** en la red `datos`, no desde tu equipo (`172.20.0.7`). Si la base de datos limita quién entra (`pg_hba.conf`, un firewall), tiene que permitir a `server`.

4. **Lo que el túnel no cifra.** Escucha con `tcpdump` el tráfico entre `server` y `db` mientras haces una consulta:
   ```bash
   (ssh server 'sudo timeout 4 tcpdump -i any -nn -A port 5432 2>/dev/null' > ~/w/dump &)
   sleep 1.5
   psql -h 127.0.0.1 -p 15432 -U alumno tienda -tAc "select nombre from productos where precio > 100"
   sleep 3
   grep -aoE 'select nombre[^.]*' ~/w/dump
   ```
   ```
   monitor
   select nombre from productos where precio > 100
   ```
   - `tcpdump`: captura los paquetes de una interfaz. `-i any` todas, `-nn` sin nombres, `-A` el contenido como texto, `port 5432` solo PostgreSQL. `timeout 4` lo para a los 4 s. `sudo` no pide contraseña: **solo en el laboratorio**.
   - La consulta viaja **legible** entre `server` y `db`. La contraseña no aparece: PostgreSQL la comprueba con SCRAM, sin mandarla. Pero todas las consultas y resultados, sí.
   - El túnel cifra de tu equipo a `server`. En producción, el tramo de dentro se protege con TLS en PostgreSQL o con una red que nadie más vea, como `datos` aquí.

5. **La contraseña en `~/.pgpass`.**
   ```bash
   unset PGPASSWORD
   echo '127.0.0.1:15432:tienda:alumno:alumno' > ~/.pgpass
   chmod 600 ~/.pgpass
   psql -h 127.0.0.1 -p 15432 -U alumno tienda -tAc 'select count(*) from productos'
   ```
   ```
   3
   ```
   - Cada línea: `host:puerto:base:usuario:contraseña`. `psql` la usa cuando coinciden los cuatro primeros campos; `*` vale para cualquiera.
   - Ahora prueba con permisos abiertos:
   ```bash
   chmod 644 ~/.pgpass
   psql -h 127.0.0.1 -p 15432 -U alumno -w tienda -tAc 'select 1'
   chmod 600 ~/.pgpass
   ```
   ```
   WARNING: password file "/home/alumno/.pgpass" has group or world access; permissions should be u=rw (0600) or less
   psql: error: connection to server at "127.0.0.1", port 15432 failed: fe_sendauth: no password supplied
   ```
   Como `ssh` con una llave privada legible por otros (semana 03), `psql` se niega a usarlo. `-w`: no preguntes la contraseña, falla.

6. **Cuando el túnel muere.**
   ```bash
   pgrep -a ssh
   pkill -f 'ssh -f -N -L 15432'
   psql -h 127.0.0.1 -p 15432 -U alumno -w tienda -tAc 'select 1'
   ```
   ```
   53 ssh -f -N -L 15432:db:5432 server
   psql: error: connection to server at "127.0.0.1", port 15432 failed: Connection refused
   	Is the server running on that host and accepting TCP/IP connections?
   ```
   `psql` no sabe nada de túneles: solo ve que nadie escucha en `15432`. Ese es el mensaje que verás cuando un túnel se cae. En el lab 07 haces que vuelva solo.

## Criterios de éxito

- [ ] Explicas por qué `nc db 5432` falla desde tu equipo y `-L 15432:db:5432` funciona (pasos 1 y 2)
- [ ] Explicas desde qué IP ve PostgreSQL la conexión y qué consecuencia tiene (paso 3)
- [ ] Viste una consulta en claro entre `server` y `db`, y sabes cómo se protege ese tramo (paso 4)
- [ ] Usas `~/.pgpass` con los permisos correctos (paso 5)
- [ ] Reconoces el error de `psql` cuando el túnel no está (paso 6)

## Reto extra

PostgreSQL también escucha en un socket Unix (`/var/run/postgresql/.s.PGSQL.5432`) dentro de su propio contenedor. `ssh` reenvía también sockets Unix: `-L /home/alumno/w/pg.sock:db:5432` crea un socket en tu equipo. ¿Cómo le dices a `psql` que lo use? (Pista: `-h` acepta una carpeta, y el socket tiene que llamarse `.s.PGSQL.PUERTO`).

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — Reenvío local: un servicio que solo escucha en el servidor](../lab-01-reenvio-local/README.md) | [Lab 03 — Reenvío remoto: enseñar al servidor algo de tu equipo](../lab-03-reenvio-remoto/README.md) → |

[↑ Semana 08](../../README.md)
