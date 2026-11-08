# Labs — Semana 05: configuración avanzada del cliente

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-el-primer-valor-gana](lab-01-el-primer-valor-gana/) | Qué archivos lee `ssh`, en qué orden, y un error de orden encontrado con `ssh -G` | ~60 min |
| 2 | [lab-02-patrones-y-tokens](lab-02-patrones-y-tokens/) | Bloques con `lab-*`, exclusión con `!` y tokens en `HostName` e `IdentityFile` | ~60 min |
| 3 | [lab-03-include-y-conf-d](lab-03-include-y-conf-d/) | `~/.ssh/conf.d/`, orden alfabético, `Include` vacío y rutas relativas con `-F` | ~60 min |
| 4 | [lab-04-match](lab-04-match/) | `Match host`, `originalhost`, `user` y `exec`, y cuándo se evalúa cada uno | ~60 min |
| 5 | [lab-05-perfiles-con-tag](lab-05-perfiles-con-tag/) | Perfiles `ssh -P depurar` y `ssh -P viaje`, y un perfil por defecto con `Tag` | ~60 min |
| 6 | [lab-06-multiplexing](lab-06-multiplexing/) | `ControlMaster`, `ControlPath`, `ControlPersist`, medir el ahorro y `ssh -O` | ~60 min |
| 7 | [lab-07-lo-que-decide-el-master](lab-07-lo-que-decide-el-master/) | Revocación, agent forwarding y permisos con un master abierto | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** con `docker compose up -d --force-recreate server bastion` y `docker compose run --rm client` **en tu equipo**, y `cd` a la carpeta del lab **en el cliente**.
- El cliente es un contenedor nuevo cada vez: `~/.ssh`, los masters y el agente empiezan vacíos y desaparecen con `exit`. Haz cada lab en una sola sesión.
- `ssh -G` no conecta: úsalo para comprobar cada cambio antes de conectar.
- Usuario `alumno`, contraseña `alumno`. **Es una contraseña débil a propósito y solo existe en el laboratorio.** Los labs usan `sshpass` para no teclearla; fuera del laboratorio, nunca.
- Las llaves de los labs no tienen frase de paso para no escribirla en cada paso: solo en el laboratorio. **Nunca subas una llave privada a git.**
- Si un lab tiene `starter/`, trabaja ahí. `solucion/` es la referencia.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Multiplexing: una conexión, muchas sesiones](../1-teoria/03-multiplexing.md) | [Lab 01 — El primer valor gana](lab-01-el-primer-valor-gana/README.md) → |

[↑ Semana 05](../README.md)
