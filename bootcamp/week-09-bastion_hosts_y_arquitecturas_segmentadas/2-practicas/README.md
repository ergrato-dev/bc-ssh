# Labs — Semana 09: bastion hosts y arquitecturas segmentadas

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-red-segmentada](lab-01-red-segmentada/) | Quién alcanza a quién, dos sesiones encadenadas y por qué no copiar llaves al bastion | ~60 min |
| 2 | [lab-02-proxyjump](lab-02-proxyjump/) | `ssh -J`, la host key de `interno` verificada por ti, qué ve el bastion, archivos y saltos encadenados | ~60 min |
| 3 | [lab-03-proxycommand-y-w](lab-03-proxycommand-y-w/) | `ssh -W`, `ProxyCommand`, `nc` y SOCKS como salto, `HostKeyAlias` y errores de un salto | ~60 min |
| 4 | [lab-04-saltos-en-config](lab-04-saltos-en-config/) | `ProxyJump` en `ssh_config`, `-J none`, `Match ... !exec` y multiplexing a través del salto | ~60 min |
| 5 | [lab-05-agente-reenviado](lab-05-agente-reenviado/) | `root` en el bastion usa tu agente; `-J` frente a `-A`, `ssh-add -h` y `AllowAgentForwarding` | ~60 min |
| 6 | [lab-06-bastion-endurecido](lab-06-bastion-endurecido/) | Una cuenta que solo salta: `nologin`, `ForceCommand`, `PermitTTY`, `AllowTcpForwarding local` y `PermitOpen` | ~60 min |
| 7 | [lab-07-auditoria-y-cortes](lab-07-auditoria-y-cortes/) | `LogLevel DEBUG1` para saltadores, saltos activos, cortar un acceso y el bastion caído | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** del [lab 01](lab-01-red-segmentada/README.md): `docker compose up -d --force-recreate bastion interno server` y `docker compose run --rm client` **en tu equipo**; `known_hosts` y una llave en `bastion`, `server` e `interno` **en el cliente**.
- El lab 07 sigue con el bastion del lab 06: no lo recrees entre los dos.
- Ten **otra terminal en tu equipo** en la raíz del repositorio: en los labs 02 y 07 lees huellas y logs de los servidores desde ella.
- Si un lab deja procesos `ssh` en segundo plano, ciérralos antes del siguiente: `pkill -x ssh`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Endurecer el bastion](../1-teoria/03-endurecer-el-bastion.md) | [Lab 01 — Una red que no ves](lab-01-red-segmentada/README.md) → |

[↑ Semana 09](../README.md)
