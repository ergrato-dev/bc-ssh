# 🔧 Herramientas SSH - Semana 01

![Tipo](https://img.shields.io/badge/Tipo-Software-orange?style=flat-square)
![Plataformas](https://img.shields.io/badge/Plataformas-Windows/macOS/Linux-blue?style=flat-square)

---

## 🛠️ Software Recomendado

Herramientas y utilidades para trabajar con SSH de forma más eficiente.

---

## 💻 Clientes SSH

### Línea de Comandos (Recomendado)

| Herramienta  | Plataforma          | Descripción                         |
| ------------ | ------------------- | ----------------------------------- |
| **OpenSSH**  | Linux/macOS/Windows | Cliente estándar, incluido en el SO |
| **Git Bash** | Windows             | Incluye OpenSSH + herramientas Unix |
| **WSL2**     | Windows             | Linux real dentro de Windows        |

### Interfaz Gráfica (GUI)

| Herramienta   | Plataforma | Descripción                        | URL                           |
| ------------- | ---------- | ---------------------------------- | ----------------------------- |
| **PuTTY**     | Windows    | Cliente SSH clásico para Windows   | https://putty.org             |
| **MobaXterm** | Windows    | Terminal con SFTP integrado        | https://mobaxterm.mobatek.net |
| **Termius**   | Todas      | Cliente moderno multiplataforma    | https://termius.com           |
| **Royal TSX** | macOS      | Gestor de conexiones avanzado      | https://royalapps.com         |
| **Remmina**   | Linux      | Cliente de escritorio remoto + SSH | https://remmina.org           |

---

## 🖥️ Emuladores de Terminal

### macOS

| Terminal         | Descripción                  | URL                   |
| ---------------- | ---------------------------- | --------------------- |
| **iTerm2**       | El mejor terminal para macOS | https://iterm2.com    |
| **Terminal.app** | Terminal nativo (incluido)   | -                     |
| **Warp**         | Terminal moderno con AI      | https://warp.dev      |
| **Alacritty**    | Terminal GPU-accelerated     | https://alacritty.org |

### Windows

| Terminal             | Descripción                   | URL                 |
| -------------------- | ----------------------------- | ------------------- |
| **Windows Terminal** | Terminal moderno de Microsoft | Microsoft Store     |
| **Git Bash**         | Bash para Windows             | https://git-scm.com |
| **Cmder**            | Emulador portable             | https://cmder.app   |

### Linux

| Terminal           | Descripción                   | DE         |
| ------------------ | ----------------------------- | ---------- |
| **GNOME Terminal** | Terminal de GNOME             | GNOME      |
| **Konsole**        | Terminal de KDE               | KDE        |
| **Alacritty**      | Rápido, GPU-accelerated       | Cualquiera |
| **Kitty**          | Feature-rich, GPU-accelerated | Cualquiera |
| **Terminator**     | Split terminals               | Cualquiera |

---

## 🔑 Gestores de Llaves SSH

| Herramienta   | Plataforma  | Descripción                      |
| ------------- | ----------- | -------------------------------- |
| **ssh-agent** | Todas       | Agente nativo de OpenSSH         |
| **Keychain**  | Linux/macOS | Gestor de ssh-agent              |
| **1Password** | Todas       | Password manager + SSH agent     |
| **KeePassXC** | Todas       | Password manager con soporte SSH |

---

## 📁 Clientes SFTP/SCP (GUI)

| Herramienta   | Plataforma    | Descripción           | URL                           |
| ------------- | ------------- | --------------------- | ----------------------------- |
| **FileZilla** | Todas         | Cliente SFTP popular  | https://filezilla-project.org |
| **WinSCP**    | Windows       | SFTP/SCP con interfaz | https://winscp.net            |
| **Cyberduck** | macOS/Windows | Cliente elegante      | https://cyberduck.io          |
| **Transmit**  | macOS         | Cliente premium       | https://panic.com/transmit    |

---

## 🔍 Herramientas de Diagnóstico

### Análisis de Red

```bash
# Verificar si puerto SSH está abierto
nc -zv servidor 22

# Trace de la conexión
traceroute servidor

# Verificar DNS
nslookup servidor
dig servidor
```

### Debug de SSH

```bash
# Modo verbose (debug)
ssh -v usuario@servidor    # 1 nivel
ssh -vv usuario@servidor   # 2 niveles
ssh -vvv usuario@servidor  # máximo detalle
```

---

## 🧪 Herramientas de Testing

| Herramienta   | Descripción                    | URL                                 |
| ------------- | ------------------------------ | ----------------------------------- |
| **ssh-audit** | Auditoría de configuración SSH | https://github.com/jtesta/ssh-audit |
| **sslscan**   | Escaneo de cifrados            | https://github.com/rbsec/sslscan    |

### Instalación de ssh-audit

```bash
# Con pip
pip install ssh-audit

# Uso
ssh-audit servidor

# Ejemplo de salida:
# (rec) use Ed25519 keys
# (rec) disable SHA1 algorithms
```

---

## 📱 Apps Móviles

| App             | Plataforma  | Descripción             |
| --------------- | ----------- | ----------------------- |
| **Termius**     | iOS/Android | Cliente SSH profesional |
| **JuiceSSH**    | Android     | Cliente SSH gratuito    |
| **Prompt 3**    | iOS         | Cliente SSH premium     |
| **Blink Shell** | iOS         | Terminal con mosh       |

---

## 🎨 Extensiones VS Code

| Extensión        | Descripción                     |
| ---------------- | ------------------------------- |
| **Remote - SSH** | Desarrollo remoto via SSH       |
| **SSH FS**       | Montar sistemas de archivos SSH |

### Instalar Remote SSH

```bash
# En VS Code, buscar:
# "Remote - SSH" por Microsoft

# O desde terminal:
code --install-extension ms-vscode-remote.remote-ssh
```

---

## 🏗️ Infraestructura de Práctica

### Crear Servidores de Prueba

| Opción           | Costo     | Descripción                  |
| ---------------- | --------- | ---------------------------- |
| **DigitalOcean** | $6/mes    | VPS fácil de usar            |
| **Linode**       | $5/mes    | VPS económico                |
| **Vultr**        | $5/mes    | VPS con ubicaciones globales |
| **AWS EC2**      | Free tier | 12 meses gratis (limitado)   |
| **Google Cloud** | Free tier | Créditos gratuitos           |

### Alternativas Locales (Gratis)

| Opción         | Descripción           |
| -------------- | --------------------- |
| **VirtualBox** | VMs locales gratuitas |
| **Multipass**  | VMs Ubuntu fáciles    |
| **Docker**     | Contenedores con SSH  |
| **Vagrant**    | VMs automatizadas     |

---

## 📋 Mi Setup Recomendado

### Para Principiantes

```
Terminal:     Windows Terminal / iTerm2 / GNOME Terminal
Cliente SSH:  OpenSSH (incluido)
Editor:       VS Code + Remote SSH
Servidor:     DigitalOcean Droplet ($6/mes)
```

### Para Desarrollo

```
Terminal:     iTerm2 / Alacritty
Cliente SSH:  OpenSSH + ssh-agent
Editor:       VS Code Remote SSH / Neovim
Servidor:     Múltiples VPS + VMs locales
Extra:        Termius (móvil)
```

---

<div align="center">

[← Documentación Oficial](04-documentacion-oficial.md) • [Volver a Recursos](README.md) • [Playgrounds Online →](06-playgrounds-online.md)

</div>
