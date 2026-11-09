# Labs — Semana 08: port forwarding, SOCKS y túneles

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-reenvio-local](lab-01-reenvio-local/) | `ssh -L` a una web que solo escucha en `server`, `-f -N`, puerto ocupado y dirección de escucha | ~60 min |
| 2 | [lab-02-postgres-por-tunel](lab-02-postgres-por-tunel/) | `psql` contra `db` a través de `server`, quién conecta, el tramo en claro y `~/.pgpass` | ~60 min |
| 3 | [lab-03-reenvio-remoto](lab-03-reenvio-remoto/) | `ssh -R`, `GatewayPorts` y el SOCKS remoto | ~60 min |
| 4 | [lab-04-socks](lab-04-socks/) | `ssh -D`, `socks5` frente a `socks5h`, `nc -X 5` y `ALL_PROXY` | ~60 min |
| 5 | [lab-05-tuneles-en-config](lab-05-tuneles-en-config/) | `LocalForward`, `DynamicForward`, `ClearAllForwardings`, `-O forward` y `~C` | ~60 min |
| 6 | [lab-06-limites-del-servidor](lab-06-limites-del-servidor/) | `AllowTcpForwarding`, `PermitOpen` y una llave que solo abre el túnel | ~60 min |
| 7 | [lab-07-tuneles-persistentes](lab-07-tuneles-persistentes/) | Cortes con y sin aviso, `ServerAliveInterval` y `autossh` | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** del [lab 01](lab-01-reenvio-local/README.md): `docker compose up -d --build --force-recreate server` y `docker compose run --rm client` **en tu equipo**; `known_hosts`, llave y la web de `server` **en el cliente**.
- `--build`, la primera vez: la imagen añade `psql` y `autossh`, y `compose.yaml` el servicio `db` (PostgreSQL), que solo alcanza `server`.
- Ten **otra terminal en tu equipo** en la raíz del repositorio: en el lab 07 reinicias y congelas `server` desde ella.
- Antes de pasar al siguiente lab, cierra los túneles que queden: `pkill -x ssh`. Un puerto ocupado por un túnel olvidado es el error más común de la semana.
- Usuario `alumno`, contraseña `alumno` en `server` y en PostgreSQL. **Son contraseñas débiles a propósito y solo existen en el laboratorio.**
- Las llaves de los labs no tienen frase de paso para no escribirla en cada paso: solo en el laboratorio. **Nunca subas una llave privada a git.**

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Túneles que no se caen](../1-teoria/03-tuneles-persistentes.md) | [Lab 01 — Reenvío local: un servicio que solo escucha en el servidor](lab-01-reenvio-local/README.md) → |

[↑ Semana 08](../README.md)
