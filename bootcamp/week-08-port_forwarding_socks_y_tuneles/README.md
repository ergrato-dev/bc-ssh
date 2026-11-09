# Semana 08 — Port forwarding, SOCKS y túneles

## Descripción

Hasta ahora, SSH llevaba una shell, un comando o archivos. Esta semana lleva otras conexiones dentro. Llegas con `psql` a una base de datos PostgreSQL que solo alcanza `server`, enseñas a `server` una web de tu equipo, y navegas por su red con un proxy SOCKS. Ves qué tramo cifra un túnel y cuál no, qué deja hacer el servidor y por qué un túnel que parece vivo puede estar muerto. Tu kit gana `tun-pg`, un túnel a PostgreSQL, y `bin/tunnel`, que lo mantiene abierto con `autossh` y no deja procesos colgados cuando algo falla.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Abrir túneles locales (`-L`) y remotos (`-R`), y decir quién escucha, quién conecta y quién resuelve cada nombre
- Usar con `psql` una base de datos que no está publicada, y explicar qué tramo va en claro y cómo protegerlo
- Elegir dónde escucha un túnel, y explicar el riesgo de `0.0.0.0` y de `GatewayPorts`
- Montar un proxy SOCKS con `-D` y usarlo con `curl`, `nc` y `ALL_PROXY` sin filtrar tus consultas DNS
- Escribir túneles en `ssh_config` y manejarlos en un master con `ssh -O forward` y `-O cancel`
- Limitar los túneles en el servidor (`AllowTcpForwarding`, `PermitOpen`) y por llave (`permitopen`)
- Detectar un corte sin aviso con `ServerAliveInterval` y mantener un túnel con `autossh`
- Añadir a tu `ssh-infra-kit` `conf.d/20-tuneles.conf` y `bin/tunnel`

## Prerrequisitos

- [Semana 07](../week-07-servidor_sshd_config_y_hardening/README.md) completa: el kit con `server/sshd_config.d/` y `bin/sshd-deploy`
- Multiplexing de la [semana 05](../week-05-configuracion_avanzada_cliente_ssh/README.md): esta semana importa saber cuándo una conexión va por un master
- El laboratorio reconstruido y levantado: `docker compose up -d --build` (esta semana la imagen añade `psql` y `autossh`, y `compose.yaml` añade `db`, un PostgreSQL en la red `datos`, que solo alcanza `server`)

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-reenvio-local-y-remoto.md](1-teoria/01-reenvio-local-y-remoto.md) · [02-socks-config-y-limites.md](1-teoria/02-socks-config-y-limites.md) · [03-tuneles-persistentes.md](1-teoria/03-tuneles-persistentes.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-reenvio-local](2-practicas/lab-01-reenvio-local/) | 60 min |
| 2 | Lab | [lab-02-postgres-por-tunel](2-practicas/lab-02-postgres-por-tunel/) | 60 min |
| 3 | Lab | [lab-03-reenvio-remoto](2-practicas/lab-03-reenvio-remoto/) | 60 min |
| 4 | Lab | [lab-04-socks](2-practicas/lab-04-socks/) | 60 min |
| 5 | Lab | [lab-05-tuneles-en-config](2-practicas/lab-05-tuneles-en-config/) | 60 min |
| 6 | Lab | [lab-06-limites-del-servidor](2-practicas/lab-06-limites-del-servidor/) | 60 min |
| 7 | Lab | [lab-07-tuneles-persistentes](2-practicas/lab-07-tuneles-persistentes/) | 60 min |
| — | Proyecto | [ssh-infra-kit: túneles persistentes a PostgreSQL](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (-L y -R, SOCKS y límites del servidor, túneles persistentes)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — -L a una web interna, -f -N, puerto ocupado y dirección de escucha
[60 min] lab-02 — psql contra db por server, el tramo en claro y ~/.pgpass
[60 min] lab-03 — -R, GatewayPorts y el SOCKS remoto
[60 min] lab-04 — -D, socks5 frente a socks5h, nc y ALL_PROXY
[60 min] lab-05 — Túneles en ssh_config, ClearAllForwardings, -O forward y ~C
[60 min] lab-06 — AllowTcpForwarding, PermitOpen y una llave solo para el túnel
[60 min] lab-07 — Cortes con y sin aviso, ServerAliveInterval y autossh
[3 h]    Proyecto: conf.d/20-tuneles.conf (tun-pg) y bin/tunnel
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 08
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 15 requisitos verificables de la semana. Abren túneles de verdad con tu kit contra un `sshd` propio dentro del contenedor `client`, y lo cortan para ver si vuelve: solo funcionan dentro del laboratorio. Al terminar deben pasar todos, y el túnel debe llegar a PostgreSQL:

```bash
cd bootcamp/week-08-port_forwarding_socks_y_tuneles/3-proyecto/starter
bin/kit-link
bin/tunnel up tun-pg
psql -h 127.0.0.1 -p 15432 -U alumno tienda -c 'select * from productos'
bin/tunnel down tun-pg
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 07 — Servidor: `sshd_config` y hardening](../week-07-servidor_sshd_config_y_hardening/README.md) | **Semana 08 — Port forwarding, SOCKS y túneles** | Semana 09 — Bastion hosts y arquitecturas segmentadas (próximamente) |

[← Volver al índice del bootcamp](../README.md)
