<div align="center">

![Bootcamp SSH Banner](assets/banner-header.svg)

[![SSH](https://img.shields.io/badge/SSH-OpenSSH_9.6+-red?style=for-the-badge&logo=openssh&logoColor=white)](https://www.openssh.com/)
[![Nivel](https://img.shields.io/badge/Nivel-Zero_→_Advanced-green?style=for-the-badge)](/)
[![Duración](https://img.shields.io/badge/Duración-168_horas-blue?style=for-the-badge)](/)
[![Semanas](https://img.shields.io/badge/Semanas-14-orange?style=for-the-badge)](/)
[![Docker](https://img.shields.io/badge/Laboratorio-Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](docs/setup-entorno.md)

**El bootcamp definitivo para dominar SSH desde cero hasta nivel profesional**

[🚀 Comenzar](#-inicio-rápido) •
[📚 Contenido](#-contenido-del-bootcamp) •
[💻 Requisitos](#-requisitos) •
[📖 Recursos](#-recursos)

</div>

---

## 🎯 ¿Qué es este Bootcamp?

Bootcamp **Zero to Advanced** de **14 semanas** sobre **SSH** con OpenSSH. Autoestudio de **12 h/semana** (168 h): empiezas sin haber usado SSH y terminas operando acceso seguro a infraestructura con llaves, bastion, certificados, hardening, 2FA y automatización.

Todo ocurre en un **laboratorio Docker** con servidores reales: no necesitas alquilar nada.

| Aspecto | Detalle |
|---|---|
| Duración | 14 semanas |
| Horas por semana | 12 h: teoría 1.5 h, conocimiento 0.5 h, labs 7 h, proyecto 3 h |
| Proyecto | `ssh-infra-kit`, construido semana a semana ([detalle](docs/proyecto-hilo-conductor.md)) |
| Evaluación | Conocimiento 30% · Desempeño 40% · Producto 30%, con autograding ([detalle](docs/autograding.md)) |

---

## 📚 Contenido del Bootcamp

| Fase | Semanas | Temas |
|---|---|---|
| Fundamentos | 01–04 | Primera conexión, protocolo y `known_hosts`, llaves, agente y FIDO2 |
| Cliente | 05–06 | `~/.ssh/config` avanzado, multiplexing, scp/sftp/rsync/sshfs |
| Servidor | 07 | `sshd_config`, `Match`, chroot SFTP, hardening |
| Redes | 08–09 | Port forwarding, SOCKS, túneles a PostgreSQL, bastion y ProxyJump |
| Seguridad avanzada | 10–11 | Certificados SSH y CA, 2FA, fail2ban, auditoría |
| Automatización y operación | 12–13 | Scripting, CI/CD, Ansible, algoritmos post-cuánticos, troubleshooting |
| Integración | 14 | Proyecto integrador |

Índice con estado de cada semana: [bootcamp/README.md](bootcamp/README.md).

---

## 🚀 Inicio Rápido

Requisitos: **Docker** con Docker Compose y **git**. No se requiere experiencia previa con SSH. Guía completa: [docs/setup-entorno.md](docs/setup-entorno.md).

```bash
git clone https://github.com/ergrato-dev/bc-ssh.git
cd bc-ssh
docker compose up -d --build      # levanta server, bastion e interno
docker compose run --rm client    # entra al cliente SSH del laboratorio
```

Empieza por [la Semana 01](bootcamp/week-01-fundamentos_ssh_y_primera_conexion/README.md).

---

## 📁 Estructura del Repositorio

```
bc-ssh/
├── README.md
├── CLAUDE.md                # reglas de contenido del bootcamp
├── compose.yaml             # laboratorio: client, server, bastion, interno
├── lab/                     # imagen Docker del laboratorio
├── assets/                  # recursos gráficos
├── docs/                    # setup, autograding, proyecto, versiones
├── scripts/                 # verificar-semana, verificar-enlaces, generar-navegacion
└── bootcamp/                # una carpeta por semana
```

### Estructura de cada Semana

```
week-NN-tema_principal/
├── README.md                # objetivos, contenidos, navegación
├── rubrica-evaluacion.md    # Conocimiento 30 / Desempeño 40 / Producto 30
├── checks.json              # autograding
├── 0-assets/                # diagramas SVG
├── 1-teoria/
├── 2-practicas/             # lab-NN/ con starter/ y solucion/
├── 3-proyecto/              # incremento de ssh-infra-kit
├── 4-recursos/
└── 5-glosario/
```

Verifica tu entrega con `./scripts/verificar-semana.sh NN`.

---

## 📖 Recursos

### Documentación Oficial

- 📚 [OpenSSH Manual](https://www.openssh.com/manual.html)
- 📚 [SSH Protocol RFC 4251](https://www.rfc-editor.org/rfc/rfc4251.html)
- 📚 [SSH Academy](https://www.ssh.com/academy/ssh)

### Comunidades

- 💬 [r/sysadmin](https://reddit.com/r/sysadmin) - Reddit
- 💬 [ServerFault](https://serverfault.com/) - Stack Exchange

### Canales YouTube Recomendados

- 🎬 [NetworkChuck](https://www.youtube.com/@NetworkChuck) - Tutoriales SSH
- 🎬 [Learn Linux TV](https://www.youtube.com/@LearnLinuxTV) - Administración Linux
- 🎬 [TechWorld with Nana](https://www.youtube.com/@TechWorldwithNana) - DevOps
- 🎬 [Jeff Geerling](https://www.youtube.com/@JeffGeerling) - Ansible

---

## 🤝 Contribuir

Los pull requests externos se cierran automáticamente. Si encuentras un error, abre un issue. Vulnerabilidades: [SECURITY.md](SECURITY.md). Convivencia: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

---

## 📄 Licencia

[CC BY-NC-SA 4.0](LICENSE). English version: [README_EN.md](README_EN.md).

---

<div align="center">

**🔐 Bootcamp SSH: De Zero a Hero**

Diseñado con ❤️ para la comunidad de administradores de sistemas

[![GitHub stars](https://img.shields.io/github/stars/ergrato-dev/bc-ssh?style=social)](https://github.com/ergrato-dev/bc-ssh)
[![GitHub forks](https://img.shields.io/github/forks/ergrato-dev/bc-ssh?style=social)](https://github.com/ergrato-dev/bc-ssh)

_14 semanas • 168 horas • Zero to Advanced_

</div>
