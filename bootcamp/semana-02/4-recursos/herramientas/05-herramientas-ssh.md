# 🔧 Herramientas SSH - Semana 02

## 🛠️ Software para Gestión de Llaves

### Gestores de Llaves SSH

| Herramienta             | Plataforma  | Descripción                       | URL                                                                        |
| ----------------------- | ----------- | --------------------------------- | -------------------------------------------------------------------------- |
| **ssh-agent**           | Linux/macOS | Agente nativo OpenSSH             | Incluido en OpenSSH                                                        |
| **Keychain**            | Linux       | Gestor de ssh-agent para shells   | [funtoo.org/Keychain](https://www.funtoo.org/Keychain)                     |
| **1Password SSH Agent** | Multi       | Integración con 1Password         | [1password.com](https://developer.1password.com/docs/ssh/)                 |
| **Secretive**           | macOS       | Almacena llaves en Secure Enclave | [github.com/maxgoedjen/secretive](https://github.com/maxgoedjen/secretive) |

### Clientes SSH con GUI

| Herramienta   | Plataforma | Descripción                     | URL                                                     |
| ------------- | ---------- | ------------------------------- | ------------------------------------------------------- |
| **PuTTY**     | Windows    | Cliente SSH clásico             | [putty.org](https://www.putty.org/)                     |
| **Termius**   | Multi      | Cliente moderno multiplataforma | [termius.com](https://termius.com/)                     |
| **MobaXterm** | Windows    | Terminal con X server           | [mobaxterm.mobatek.net](https://mobaxterm.mobatek.net/) |
| **Royal TSX** | macOS      | Gestor de conexiones            | [royalapps.com](https://royalapps.com/ts/mac/features)  |

### Herramientas de Línea de Comandos

| Herramienta     | Propósito               | Instalación           |
| --------------- | ----------------------- | --------------------- |
| **ssh-keygen**  | Generar llaves          | Incluido en OpenSSH   |
| **ssh-copy-id** | Desplegar llaves        | Incluido en OpenSSH   |
| **ssh-add**     | Gestionar agente        | Incluido en OpenSSH   |
| **ssh-keyscan** | Obtener host keys       | Incluido en OpenSSH   |
| **sshpass**     | Automatizar contraseñas | `apt install sshpass` |

---

## 🔐 Gestores de Contraseñas con SSH

| Herramienta   | Soporte SSH        | URL                                                 |
| ------------- | ------------------ | --------------------------------------------------- |
| **1Password** | ✅ Agent integrado | [1password.com](https://1password.com/)             |
| **Bitwarden** | ✅ Via CLI         | [bitwarden.com](https://bitwarden.com/)             |
| **KeePassXC** | ✅ Agent integrado | [keepassxc.org](https://keepassxc.org/)             |
| **pass**      | ✅ Con extensiones | [passwordstore.org](https://www.passwordstore.org/) |

---

## 🔍 Herramientas de Auditoría

| Herramienta   | Propósito                    | URL                                                                |
| ------------- | ---------------------------- | ------------------------------------------------------------------ |
| **ssh-audit** | Auditar configuración SSH    | [github.com/jtesta/ssh-audit](https://github.com/jtesta/ssh-audit) |
| **Lynis**     | Auditoría de seguridad Linux | [cisofy.com/lynis](https://cisofy.com/lynis/)                      |
| **OpenSCAP**  | Compliance de seguridad      | [open-scap.org](https://www.open-scap.org/)                        |

### Uso de ssh-audit

```bash
# Instalar
pip install ssh-audit

# Auditar servidor
ssh-audit servidor.ejemplo.com

# Auditar configuración local
ssh-audit localhost
```

---

## 📱 Apps Móviles

| App             | Plataforma  | Descripción          |
| --------------- | ----------- | -------------------- |
| **Termius**     | iOS/Android | Cliente SSH completo |
| **JuiceSSH**    | Android     | Cliente SSH gratuito |
| **Prompt 3**    | iOS         | Cliente SSH premium  |
| **Blink Shell** | iOS         | Terminal con Mosh    |

---

## 💡 Recomendaciones para Esta Semana

### Esenciales (ya incluidos)

- `ssh-keygen` - Generación de llaves
- `ssh-copy-id` - Despliegue de llaves
- `ssh-agent` / `ssh-add` - Gestión de agente

### Opcionales pero Útiles

- **Keychain** - Si usas Linux y quieres persistencia
- **KeePassXC** - Si quieres guardar passphrases
- **ssh-audit** - Para verificar seguridad

---

[← Volver a Recursos](README.md)
