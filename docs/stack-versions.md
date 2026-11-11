# Versiones del stack

| Componente | Versión | Dónde se fija | Por qué |
|---|---|---|---|
| Ubuntu | 24.04 LTS | `lab/Dockerfile` | LTS con soporte hasta 2029 |
| OpenSSH | 9.6p1 | paquete de Ubuntu 24.04 | Mínimo del curso: ed25519, `-sk`, `sntrup761x25519-sha512` por defecto |
| PostgreSQL | 17.6 (servidor), 16 (`psql` de Ubuntu 24.04) | `compose.yaml`, `lab/Dockerfile` | Base de datos del curso; `psql` 16 habla sin problema con un servidor 17 |
| autossh | 1.4g | paquete de Ubuntu 24.04 | Túneles persistentes (semana 08) |
| uv | 0.12.2 | `lab/Dockerfile` | Único gestor de Python del curso |
| ssh-audit | 3.3.0 | `lab/Dockerfile` (`uv tool install`) | Auditoría de algoritmos y políticas (semana 11) |
| ansible-core | 2.21.5 | `lab/Dockerfile` (`uv tool install`) | Automatización por SSH: inventario, playbooks y despliegue desde CI (semana 12) |
| fail2ban | 1.0.2 | paquete de Ubuntu 24.04 | Bloqueo de IP que fallan al entrar, con nftables 1.0.9 (semana 11) |
| libpam-google-authenticator | 20191231 | paquete de Ubuntu 24.04 | Segundo factor TOTP vía PAM; `oathtool` 2.6.11 calcula los códigos en el laboratorio (semana 11) |
| Docker Compose | v2+ | equipo del estudiante | Sintaxis `compose.yaml` y anclas YAML |

Features de OpenSSH posteriores a 9.6 (por ejemplo `mlkem768x25519-sha256`, 9.9+) se marcan en la teoría como "OpenSSH 9.9+" con la alternativa para 9.6.
