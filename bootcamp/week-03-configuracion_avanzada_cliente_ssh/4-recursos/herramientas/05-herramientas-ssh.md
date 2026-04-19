# 🔧 Herramientas SSH

## Software y Utilidades para Configuración SSH

![Herramientas](https://img.shields.io/badge/Tipo-Software-orange?style=for-the-badge)

---

## 🛠️ Clientes SSH

### Linux/macOS

| Herramienta          | Descripción              | Instalación         |
| -------------------- | ------------------------ | ------------------- |
| **OpenSSH**          | Cliente estándar         | Incluido en sistema |
| **Mosh**             | SSH tolerante a latencia | `apt install mosh`  |
| **Eternal Terminal** | Reconexión automática    | `apt install et`    |

### Windows

| Herramienta          | Descripción           | Enlace                                                  |
| -------------------- | --------------------- | ------------------------------------------------------- |
| **Windows OpenSSH**  | Cliente nativo Win10+ | Incluido                                                |
| **PuTTY**            | Cliente clásico       | [putty.org](https://www.putty.org/)                     |
| **MobaXterm**        | Terminal con extras   | [mobaxterm.mobatek.net](https://mobaxterm.mobatek.net/) |
| **Windows Terminal** | Terminal moderna      | Microsoft Store                                         |

### Multiplataforma

| Herramienta   | Descripción              | Enlace                                  |
| ------------- | ------------------------ | --------------------------------------- |
| **Termius**   | Cliente moderno con sync | [termius.com](https://termius.com/)     |
| **Royal TSX** | Gestión de conexiones    | [royalapps.com](https://royalapps.com/) |

---

## 📝 Editores de Config

### CLI

| Herramienta    | Descripción                            |
| -------------- | -------------------------------------- |
| `vim` / `nvim` | Editor potente con syntax highlighting |
| `nano`         | Editor simple y accesible              |
| `micro`        | Nano moderno                           |

### GUI

| Herramienta           | Descripción             |
| --------------------- | ----------------------- |
| **VS Code**           | Extensión SSH remote    |
| **SSH Config Editor** | Editor visual de config |

---

## 🔐 Gestión de Llaves

| Herramienta   | Descripción                  | Uso                         |
| ------------- | ---------------------------- | --------------------------- |
| `ssh-keygen`  | Generar llaves               | `ssh-keygen -t ed25519`     |
| `ssh-agent`   | Gestión de llaves en memoria | `eval $(ssh-agent)`         |
| `ssh-add`     | Añadir llaves al agente      | `ssh-add ~/.ssh/id_ed25519` |
| `ssh-copy-id` | Copiar llave a servidor      | `ssh-copy-id user@host`     |

---

## 🔍 Debugging y Análisis

| Herramienta     | Descripción            | Uso                 |
| --------------- | ---------------------- | ------------------- |
| `ssh -v`        | Verbose mode           | `ssh -v host`       |
| `ssh -G`        | Ver config efectiva    | `ssh -G host`       |
| `ssh -O check`  | Estado de multiplexing | `ssh -O check host` |
| `nc` / `netcat` | Probar conectividad    | `nc -zv host 22`    |

---

## 📊 Monitoreo

| Herramienta      | Descripción                |
| ---------------- | -------------------------- |
| `ss` / `netstat` | Ver conexiones SSH activas |
| `lsof`           | Listar sockets SSH         |
| `who` / `w`      | Usuarios conectados        |

```bash
# Ver conexiones SSH activas
ss -tn | grep :22

# Ver sockets de control
ls -la ~/.ssh/sockets/

# Ver sesiones SSH
w
```

---

<div align="center">

**🔧 Herramientas SSH**

_Software para mejorar tu flujo de trabajo_

</div>
