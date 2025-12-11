# 📖 Documentación Oficial

## Referencias Oficiales de SSH

![Docs](https://img.shields.io/badge/Tipo-Oficial-green?style=for-the-badge)

---

## 📚 Documentación Principal

### OpenSSH

| Documento          | Descripción                         | Enlace                                                         |
| ------------------ | ----------------------------------- | -------------------------------------------------------------- |
| **ssh_config(5)**  | Manual del archivo de configuración | `man ssh_config`                                               |
| **ssh(1)**         | Manual del cliente SSH              | `man ssh`                                                      |
| **OpenSSH Manual** | Documentación completa              | [openssh.com/manual.html](https://www.openssh.com/manual.html) |
| **OpenSSH FAQ**    | Preguntas frecuentes                | [openssh.com/faq.html](https://www.openssh.com/faq.html)       |

### Man Pages Esenciales

```bash
# Configuración del cliente
man ssh_config

# Cliente SSH
man ssh

# Servidor SSH
man sshd_config

# Generación de llaves
man ssh-keygen

# Agente SSH
man ssh-agent
```

---

## 📋 Directivas Clave de ssh_config

### Conexión

| Directiva      | Descripción                       |
| -------------- | --------------------------------- |
| `Host`         | Patrón para aplicar configuración |
| `HostName`     | Nombre real del servidor          |
| `Port`         | Puerto SSH                        |
| `User`         | Usuario para conexión             |
| `IdentityFile` | Ruta a llave privada              |

### ProxyJump

| Directiva        | Descripción                      |
| ---------------- | -------------------------------- |
| `ProxyJump`      | Host(s) intermedios              |
| `ProxyCommand`   | Comando para establecer conexión |
| `ProxyUseFdpass` | Pasar fd en vez de stdin         |

### Multiplexing

| Directiva        | Descripción                |
| ---------------- | -------------------------- |
| `ControlMaster`  | Habilitar control master   |
| `ControlPath`    | Ruta del socket de control |
| `ControlPersist` | Tiempo de persistencia     |

---

## 🔗 RFCs de SSH

| RFC                                                | Título                      | Relevancia    |
| -------------------------------------------------- | --------------------------- | ------------- |
| [RFC 4251](https://www.rfc-editor.org/rfc/rfc4251) | SSH Protocol Architecture   | Fundamental   |
| [RFC 4252](https://www.rfc-editor.org/rfc/rfc4252) | SSH Authentication Protocol | Autenticación |
| [RFC 4253](https://www.rfc-editor.org/rfc/rfc4253) | SSH Transport Layer         | Transporte    |
| [RFC 4254](https://www.rfc-editor.org/rfc/rfc4254) | SSH Connection Protocol     | Conexión      |

---

## 🔍 Consulta Rápida

```bash
# Ver todas las opciones disponibles
man ssh_config | grep -A2 "^\s\+[A-Z]"

# Buscar opción específica
man ssh_config | grep -A5 "ControlMaster"

# Ver configuración efectiva para un host
ssh -G hostname
```

---

<div align="center">

**📖 Documentación Oficial**

_La fuente definitiva_

</div>
