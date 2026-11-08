# Labs — Semana 04: `ssh-agent`, agent forwarding y llaves FIDO2

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-arrancar-el-agente](lab-01-arrancar-el-agente/) | Arrancar `ssh-agent` con `eval`, cargar una llave con frase y entrar sin escribirla | ~60 min |
| 2 | [lab-02-la-frase-una-sola-vez](lab-02-la-frase-una-sola-vez/) | `AddKeysToAgent`, caducidad, bloqueo e `IdentityAgent=none` | ~60 min |
| 3 | [lab-03-un-agente-para-todas-las-terminales](lab-03-un-agente-para-todas-las-terminales/) | Un socket con ruta fija, el socket huérfano y `agente-vivo.sh` | ~60 min |
| 4 | [lab-04-agent-forwarding](lab-04-agent-forwarding/) | Saltar a `bastion` con `-A`, ver el socket reenviado y activarlo solo para un host | ~60 min |
| 5 | [lab-05-restringir-destinos](lab-05-restringir-destinos/) | Una llave que solo vale para `client → server → bastion` con `ssh-add -h` | ~60 min |
| 6 | [lab-06-confirmar-cada-uso](lab-06-confirmar-cada-uso/) | `ssh-add -c` con un `SSH_ASKPASS` propio que registra cada firma | ~60 min |
| 7 | [lab-07-llaves-fido2](lab-07-llaves-fido2/) | Reconocer y preparar llaves `-sk`; usarlas con un dispositivo real | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** con `docker compose up -d` y `docker compose run --rm client` **en tu equipo**, y `cd` a la carpeta del lab **en el cliente**.
- El cliente es un contenedor nuevo cada vez: `~/.ssh` y el agente empiezan vacíos y desaparecen con `exit`. Haz cada lab en una sola sesión.
- `server` y `bastion` conservan su `authorized_keys` entre sesiones. Los labs que los usan empiezan con `docker compose up -d --force-recreate ...` para partir de cero.
- Usuario `alumno`, contraseña `alumno`. **Es una contraseña débil a propósito y solo existe en el laboratorio.** Los labs usan `sshpass` para no teclearla; fuera del laboratorio, nunca.
- **Nunca subas una llave privada a git.**
- Si un lab tiene `starter/`, trabaja ahí. `solucion/` es la referencia.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Llaves FIDO2: la privada dentro de un dispositivo](../1-teoria/03-llaves-fido2-sk.md) | [Lab 01 — Arrancar el agente](lab-01-arrancar-el-agente/README.md) → |

[↑ Semana 04](../README.md)
