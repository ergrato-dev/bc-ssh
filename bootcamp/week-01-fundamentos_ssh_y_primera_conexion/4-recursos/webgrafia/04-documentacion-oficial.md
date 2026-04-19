# 📖 Documentación Oficial - Semana 01

![Tipo](https://img.shields.io/badge/Tipo-Documentación_Oficial-blue?style=flat-square)
![Fuente](https://img.shields.io/badge/Fuente-OpenSSH/IETF-green?style=flat-square)

---

## 📚 Documentación de Referencia

Fuentes oficiales y autorizadas sobre SSH y OpenSSH.

---

## 🔐 OpenSSH

### Manual Pages (Man Pages)

La documentación definitiva de OpenSSH:

#### ssh(1) - Cliente SSH

- **URL:** https://man.openbsd.org/ssh
- **Contenido:** Todas las opciones del comando `ssh`
- **Uso local:** `man ssh`

#### ssh_config(5) - Configuración del Cliente

- **URL:** https://man.openbsd.org/ssh_config
- **Contenido:** Directivas del archivo `~/.ssh/config`
- **Uso local:** `man ssh_config`

#### sshd(8) - Servidor SSH (Preview)

- **URL:** https://man.openbsd.org/sshd
- **Contenido:** Opciones del demonio SSH
- **Uso local:** `man sshd`
- **Nota:** Lo veremos en detalle en Semana 05

#### sshd_config(5) - Configuración del Servidor (Preview)

- **URL:** https://man.openbsd.org/sshd_config
- **Contenido:** Directivas de `/etc/ssh/sshd_config`
- **Uso local:** `man sshd_config`
- **Nota:** Lo veremos en detalle en Semana 05

---

### OpenSSH Release Notes

Notas de versión y cambios:

- **URL:** https://www.openssh.com/releasenotes.html
- **Por qué importa:** Nuevas funcionalidades y correcciones de seguridad

### OpenSSH Features

Lista de características de OpenSSH:

- **URL:** https://www.openssh.com/features.html

---

## 📜 RFCs (Request for Comments)

Los estándares técnicos que definen el protocolo SSH:

### RFC 4251 - SSH Protocol Architecture

- **URL:** https://www.rfc-editor.org/rfc/rfc4251
- **Contenido:** Arquitectura general del protocolo SSH
- **Nivel:** Avanzado (referencia)

### RFC 4252 - SSH Authentication Protocol

- **URL:** https://www.rfc-editor.org/rfc/rfc4252
- **Contenido:** Métodos de autenticación SSH
- **Nivel:** Avanzado (referencia)

### RFC 4253 - SSH Transport Layer Protocol

- **URL:** https://www.rfc-editor.org/rfc/rfc4253
- **Contenido:** Capa de transporte, cifrado, integridad
- **Nivel:** Avanzado (referencia)

### RFC 4254 - SSH Connection Protocol

- **URL:** https://www.rfc-editor.org/rfc/rfc4254
- **Contenido:** Canales, port forwarding, sesiones
- **Nivel:** Avanzado (referencia)

---

## 🎓 SSH Academy

Recursos educativos oficiales de SSH.com:

### SSH Academy Main

- **URL:** https://www.ssh.com/academy/ssh
- **Contenido:** Tutoriales y explicaciones

### SSH Protocol

- **URL:** https://www.ssh.com/academy/ssh/protocol
- **Contenido:** Funcionamiento del protocolo

### SSH Keys

- **URL:** https://www.ssh.com/academy/ssh/keys
- **Contenido:** Todo sobre llaves SSH

### SSH Config

- **URL:** https://www.ssh.com/academy/ssh/config
- **Contenido:** Configuración del cliente

---

## 🐧 Documentación por Distribución

### Ubuntu

- **URL:** https://help.ubuntu.com/community/SSH
- **Específico para:** Usuarios de Ubuntu/Debian

### Red Hat / Fedora / CentOS

- **URL:** https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/securing_networks/assembly_using-secure-communications-between-two-systems-with-openssh_securing-networks
- **Específico para:** Usuarios de RHEL/Fedora

### Arch Linux

- **URL:** https://wiki.archlinux.org/title/OpenSSH
- **Específico para:** Usuarios de Arch (wiki muy completa)

---

## 💻 Cómo Usar las Man Pages

### Ver man page completa

```bash
man ssh
```

### Buscar dentro de la man page

```bash
# Abrir man page
man ssh

# Una vez dentro, presionar / y escribir el término
# Ejemplo: /HostName
# Presionar n para siguiente coincidencia
```

### Buscar término específico

```bash
# Buscar en todas las man pages
man -k ssh

# Ver sección específica
man 5 ssh_config
```

### Exportar man page a texto

```bash
man ssh > ssh-manual.txt
```

---

## 📋 Checklist de Documentación

Para la Semana 01, revisa al menos:

- [ ] `man ssh` - Opciones básicas del cliente
- [ ] `man ssh_config` - Directivas del archivo config
- [ ] SSH Academy - SSH Protocol (conceptos)
- [ ] SSH Academy - SSH Config (referencia)

---

## 💡 Tip: Usar la documentación

La documentación oficial puede parecer abrumadora al principio.

**Estrategia recomendada:**

1. **No leas todo:** Usa como referencia cuando tengas dudas específicas
2. **Busca ejemplos:** Las man pages tienen secciones de EXAMPLES
3. **Marca favoritos:** Guarda los enlaces más útiles
4. **Regresa después:** Cada semana entenderás más

---

<div align="center">

[← Artículos SSH](03-articulos-ssh.md) • [Volver a Recursos](README.md) • [Herramientas SSH →](05-herramientas-ssh.md)

</div>
