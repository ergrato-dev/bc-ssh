# Webgrafía — Semana 08

| Recurso | Descripción |
|---------|-------------|
| [ssh(1)](https://man.openbsd.org/ssh.1) | `-L`, `-R`, `-D`, `-N`, `-f`, `-O forward`/`cancel` y las secuencias de escape (`~C`) |
| [ssh_config(5)](https://man.openbsd.org/ssh_config.5) | `LocalForward`, `DynamicForward`, `ExitOnForwardFailure`, `ServerAliveInterval`, `SessionType`, `ClearAllForwardings` |
| [sshd_config(5)](https://man.openbsd.org/sshd_config.5) | `AllowTcpForwarding`, `PermitOpen`, `PermitListen`, `GatewayPorts`: lo que decide el servidor (lab 06) |
| [sshd(8) — AUTHORIZED_KEYS FILE FORMAT](https://man.openbsd.org/sshd.8#AUTHORIZED_KEYS_FILE_FORMAT) | `permitopen`, `permitlisten`, `port-forwarding` y `restrict` en una llave |
| [autossh(1)](https://manpages.ubuntu.com/manpages/noble/man1/autossh.1.html) | `-M 0`, `AUTOSSH_GATETIME`, `AUTOSSH_PIDFILE`, `AUTOSSH_LOGFILE` y cuándo relanza `ssh` |
| [PostgreSQL — The Password File](https://www.postgresql.org/docs/current/libpq-pgpass.html) | El formato de `~/.pgpass` y por qué exige permisos 600 |
| [PostgreSQL — Secure TCP/IP Connections with SSH Tunnels](https://www.postgresql.org/docs/current/ssh-tunnels.html) | El túnel del lab 02 en la documentación oficial, y su aviso sobre el tramo sin cifrar |
| [curl — SOCKS proxy](https://everything.curl.dev/usingcurl/proxies/socks.html) | `--socks5` frente a `--socks5-hostname` y `socks5h://` |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — videos](../videografia/README.md) | [Glosario](../../5-glosario/README.md) → |

[↑ Semana 08](../../README.md)
