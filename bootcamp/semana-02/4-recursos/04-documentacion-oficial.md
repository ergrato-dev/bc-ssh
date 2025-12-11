# 📖 Documentación Oficial - Semana 02

## 🔒 OpenSSH

### Manuales Principales

| Documento         | Descripción             | Enlace                                               |
| ----------------- | ----------------------- | ---------------------------------------------------- |
| **ssh-keygen(1)** | Generación de llaves    | [man ssh-keygen](https://man.openbsd.org/ssh-keygen) |
| **ssh(1)**        | Cliente SSH             | [man ssh](https://man.openbsd.org/ssh)               |
| **ssh_config(5)** | Configuración cliente   | [man ssh_config](https://man.openbsd.org/ssh_config) |
| **sshd(8)**       | Daemon SSH              | [man sshd](https://man.openbsd.org/sshd)             |
| **ssh-agent(1)**  | Agente de llaves        | [man ssh-agent](https://man.openbsd.org/ssh-agent)   |
| **ssh-add(1)**    | Añadir llaves al agente | [man ssh-add](https://man.openbsd.org/ssh-add)       |

### Sitio Oficial OpenSSH

| Recurso            | URL                                                                        |
| ------------------ | -------------------------------------------------------------------------- |
| Página principal   | [openssh.com](https://www.openssh.com/)                                    |
| Manual completo    | [openssh.com/manual.html](https://www.openssh.com/manual.html)             |
| Notas de seguridad | [openssh.com/security.html](https://www.openssh.com/security.html)         |
| Changelog          | [openssh.com/releasenotes.html](https://www.openssh.com/releasenotes.html) |

---

## 📜 RFCs Relevantes

### Protocolo SSH

| RFC                                                | Título                       | Descripción                |
| -------------------------------------------------- | ---------------------------- | -------------------------- |
| [RFC 4251](https://www.rfc-editor.org/rfc/rfc4251) | SSH Protocol Architecture    | Arquitectura general       |
| [RFC 4252](https://www.rfc-editor.org/rfc/rfc4252) | SSH Authentication Protocol  | Protocolo de autenticación |
| [RFC 4253](https://www.rfc-editor.org/rfc/rfc4253) | SSH Transport Layer Protocol | Capa de transporte         |
| [RFC 4254](https://www.rfc-editor.org/rfc/rfc4254) | SSH Connection Protocol      | Protocolo de conexión      |

### Algoritmos Criptográficos

| RFC                                                | Título                    | Descripción              |
| -------------------------------------------------- | ------------------------- | ------------------------ |
| [RFC 8709](https://www.rfc-editor.org/rfc/rfc8709) | Ed25519 and Ed448 for SSH | Algoritmos Ed25519/Ed448 |
| [RFC 8332](https://www.rfc-editor.org/rfc/rfc8332) | RSA Keys with SHA-256/512 | RSA moderno              |
| [RFC 5656](https://www.rfc-editor.org/rfc/rfc5656) | ECDSA for SSH             | Curvas elípticas         |

---

## 🐙 GitHub Docs

### Autenticación SSH

| Documento                   | URL                                                                                                                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Sobre SSH                   | [docs.github.com/.../about-ssh](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh)                                                              |
| Verificar llaves existentes | [docs.github.com/.../checking-for-existing-ssh-keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/checking-for-existing-ssh-keys)                    |
| Generar nueva llave         | [docs.github.com/.../generating-a-new-ssh-key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) |
| Añadir llave a cuenta       | [docs.github.com/.../adding-a-new-ssh-key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)                 |
| Probar conexión             | [docs.github.com/.../testing-your-ssh-connection](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)                          |

---

## 🔧 Acceso Rápido desde Terminal

```bash
# Ver manual de ssh-keygen
man ssh-keygen

# Ver manual de ssh_config
man ssh_config

# Ver manual de ssh-agent
man ssh-agent

# Ver opciones de ssh-keygen
ssh-keygen --help
```

---

## 💡 Recomendación

Para esta semana, consulta principalmente:

1. **man ssh-keygen** - Todas las opciones de generación
2. **man ssh_config** - Configuración del cliente
3. **GitHub Docs** - Si usas GitHub

---

[← Volver a Recursos](README.md)
