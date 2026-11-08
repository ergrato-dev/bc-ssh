# Webgrafía — Semana 04

| Recurso | Descripción |
|---------|-------------|
| [ssh-agent(1)](https://man.openbsd.org/ssh-agent) | `-a`, `-t`, `-k` y qué variables imprime. La sección de seguridad explica quién puede usar el socket |
| [ssh-add(1)](https://man.openbsd.org/ssh-add) | `-l`, `-L`, `-d`, `-D`, `-t`, `-x`, `-X`, `-c` y la sintaxis completa de `-h` |
| [ssh_config(5)](https://man.openbsd.org/ssh_config) | `AddKeysToAgent`, `ForwardAgent` e `IdentityAgent`, con su advertencia sobre el forwarding |
| [sshd_config(5)](https://man.openbsd.org/sshd_config) | `AllowAgentForwarding` y `PubkeyAuthOptions` (semana 07) |
| [OpenSSH — SSH agent restriction](https://www.openssh.com/agent-restrict.html) | El texto de los autores de OpenSSH sobre `ssh-add -h`: el problema del forwarding, cómo lo resuelve y sus límites |
| [OpenSSH 8.9 — notas de la versión](https://www.openssh.com/txt/release-8.9) | La versión que introduce las restricciones por destino |
| [OpenSSH 8.2 — notas de la versión](https://www.openssh.com/txt/release-8.2) | La versión que introduce las llaves FIDO2 (`ecdsa-sk` y `ed25519-sk`) |
| [Yubico — Securing SSH with FIDO2](https://developers.yubico.com/SSH/Securing_SSH_with_FIDO2.html) | Guía del fabricante: llaves residentes, PIN y uso en varios equipos |
| [GitHub — Using SSH agent forwarding](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/using-ssh-agent-forwarding) | El uso más habitual del forwarding (`git pull` desde un servidor) y sus advertencias |
| [ArchWiki — SSH keys](https://wiki.archlinux.org/title/SSH_keys) | Cómo arrancar un único agente por sesión en Linux (systemd, `.bashrc`) y llaves FIDO2 |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — videos](../videografia/README.md) | [Glosario](../../5-glosario/README.md) → |

[↑ Semana 04](../../README.md)
