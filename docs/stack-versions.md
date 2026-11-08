# Versiones del stack

| Componente | Versión | Dónde se fija | Por qué |
|---|---|---|---|
| Ubuntu | 24.04 LTS | `lab/Dockerfile` | LTS con soporte hasta 2029 |
| OpenSSH | 9.6p1 | paquete de Ubuntu 24.04 | Mínimo del curso: ed25519, `-sk`, `sntrup761x25519-sha512` por defecto |
| uv | 0.12.2 | `lab/Dockerfile` | Único gestor de Python del curso |
| Docker Compose | v2+ | equipo del estudiante | Sintaxis `compose.yaml` y anclas YAML |

Features de OpenSSH posteriores a 9.6 (por ejemplo `mlkem768x25519-sha256`, 9.9+) se marcan en la teoría como "OpenSSH 9.9+" con la alternativa para 9.6.
