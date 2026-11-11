# Webgrafía — Semana 13

| Recurso | Descripción |
|---------|-------------|
| [OpenSSH: Post-Quantum Cryptography](https://www.openssh.org/pq.html) | La página oficial: qué algoritmos, desde qué versión, el aviso de 10.1 y `WarnWeakCrypto`. Teoría 02 y lab 04 |
| [OpenSSH: release notes](https://www.openssh.org/releasenotes.html) | Qué se retiró y cuándo (DSA, `ssh-rsa`, grupos Diffie-Hellman). La tabla de la teoría 02 sale de aquí |
| [ssh_config(5)](https://man.openbsd.org/ssh_config) | `KexAlgorithms` (y las formas `+`, `-`, `^`), `HostKeyAlgorithms`, `PubkeyAcceptedAlgorithms`, `UpdateHostKeys`, `Compression`, `HostKeyAlias` |
| [sshd_config(5)](https://man.openbsd.org/sshd_config) | `HostKey`, `RequiredRSASize`, `StrictModes`, `LogLevel` y las listas de algoritmos del servidor |
| [sshd(8)](https://man.openbsd.org/sshd) | `-d`, `-t`, `-T` y `-C`: las herramientas del lab 02 |
| [tc-netem(8)](https://man7.org/linux/man-pages/man8/tc-netem.8.html) | `delay`, `rate`, `loss`: cómo simular una red lenta. Lab 05 |
| [ssh-audit](https://github.com/jtesta/ssh-audit) | La herramienta de la semana 11, contra el equipo viejo del lab 03 |
| [The state of the post-quantum Internet (Cloudflare)](https://blog.cloudflare.com/pq-2024/) | Cuánto tráfico de Internet es ya postcuántico y qué costó desplegarlo (tamaño y tiempo), visto desde TLS |
| [IETF: ML-KEM hybrid key exchange for SSH](https://datatracker.ietf.org/doc/draft-ietf-sshm-mlkem-hybrid-kex/) | El borrador que estandariza `mlkem768x25519-sha256` |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — videos](../videografia/README.md) | [Glosario](../../5-glosario/README.md) → |

[↑ Semana 13](../../README.md)
