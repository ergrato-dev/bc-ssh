# Labs — Semana 07: el servidor, `sshd_config` y hardening

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-sshd-config](lab-01-sshd-config/) | Archivos, primer valor que gana, `sshd -t` / `sshd -T` y recarga sin cortar sesiones | ~60 min |
| 2 | [lab-02-autenticacion](lab-02-autenticacion/) | Solo llaves, `PermitRootLogin no`, `MaxAuthTries`, `LoginGraceTime` y logs | ~60 min |
| 3 | [lab-03-quien-entra](lab-03-quien-entra/) | `AllowUsers`, `AllowGroups`, `DenyUsers`, redes, `nologin` y volver a entrar | ~60 min |
| 4 | [lab-04-match](lab-04-match/) | `Match` por usuario, grupo y red, `sshd -T -C` y sus cuatro trampas | ~60 min |
| 5 | [lab-05-sftp-chroot](lab-05-sftp-chroot/) | Una cuenta solo SFTP: `internal-sftp`, `ChrootDirectory` y `DisableForwarding` | ~60 min |
| 6 | [lab-06-sesion-y-reenvios](lab-06-sesion-y-reenvios/) | Agente, X11, variables, `MaxSessions` y `ClientAliveInterval` | ~60 min |
| 7 | [lab-07-cambios-sin-quedarte-fuera](lab-07-cambios-sin-quedarte-fuera/) | Quedarte fuera y volver: sesión abierta, consola, vuelta atrás automática | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** del [lab 01](lab-01-sshd-config/README.md): `docker compose up -d --build --force-recreate server` y `docker compose run --rm client` **en tu equipo**; `known_hosts` y llave **en el cliente**.
- `--force-recreate` deja `server` con la configuración original: cada lab empieza limpio, y si un lab te deja fuera sin remedio, es la salida.
- Esta semana administras `server` con `ssh server sudo ...`. En el laboratorio, `sudo` no pide contraseña: **solo en el laboratorio**. En un servidor real, la pide, y se usa `ssh -t server sudo ...`.
- Ten **otra terminal en tu equipo** en la raíz del repositorio para `docker compose logs server` (los motivos de cada rechazo) y `docker compose exec server ...` (la consola, cuando te quedas fuera).
- Antes de cada recarga, `sudo sshd -t`. Siempre: `sudo sshd -t && $R`.
- Usuario `alumno`, contraseña `alumno`. **Es una contraseña débil a propósito y solo existe en el laboratorio.** Esta semana la desactivas.
- Las llaves de los labs no tienen frase de paso para no escribirla en cada paso: solo en el laboratorio. **Nunca subas una llave privada a git.**

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Usuarios solo SFTP y cambios sin quedarte fuera](../1-teoria/03-sftp-chroot-y-cambios-seguros.md) | [Lab 01 — Dónde vive la configuración de `sshd`](lab-01-sshd-config/README.md) → |

[↑ Semana 07](../README.md)
