# 🗂️ Práctica 03: Gestión de Múltiples Llaves

![SSH](https://img.shields.io/badge/SSH-Multi--Key-red?style=for-the-badge&logo=openssh)
![Nivel](https://img.shields.io/badge/Nivel-⭐⭐⭐_Avanzado-red?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-30_min-blue?style=for-the-badge)

## 📋 Descripción

En esta práctica aprenderás a **gestionar múltiples llaves SSH** para diferentes servicios y servidores. Configurarás llaves separadas para GitHub, tu trabajo y uso personal, utilizando el archivo `~/.ssh/config` para automatizar la selección de la llave correcta.

Esta es una práctica esencial para profesionales que trabajan con múltiples entornos y necesitan mantener sus identidades SSH organizadas y seguras.

---

## 🎯 Objetivos de Aprendizaje

Al completar esta práctica serás capaz de:

- [ ] Crear y nombrar llaves para propósitos específicos
- [ ] Configurar `~/.ssh/config` para múltiples hosts
- [ ] Seleccionar automáticamente la llave correcta por destino
- [ ] Configurar GitHub con llave SSH dedicada
- [ ] Gestionar llaves en ssh-agent eficientemente
- [ ] Organizar tu directorio `~/.ssh` profesionalmente

---

## 📚 Requisitos Previos

| Requisito                     | Verificación                 |
| ----------------------------- | ---------------------------- |
| Prácticas 01 y 02 completadas | Llave principal funcionando  |
| Cuenta de GitHub              | github.com/settings/keys     |
| Servidor remoto (opcional)    | Para probar llave de trabajo |

---

## 🛠️ Paso 1: Planificar Estructura de Llaves

Antes de crear llaves, planifica tu estructura:

### Escenario Típico

| Llave        | Propósito        | Servidor/Servicio       |
| ------------ | ---------------- | ----------------------- |
| `id_ed25519` | Personal/default | Servidores personales   |
| `id_github`  | GitHub           | github.com              |
| `id_trabajo` | Trabajo          | servidores corporativos |
| `id_gitlab`  | GitLab           | gitlab.com (si aplica)  |

### Estructura Final Objetivo

```
~/.ssh/
├── config                  # Configuración de hosts
├── id_ed25519             # Llave personal (default)
├── id_ed25519.pub
├── id_github              # Llave para GitHub
├── id_github.pub
├── id_trabajo             # Llave para trabajo
├── id_trabajo.pub
├── known_hosts            # Fingerprints de servidores
└── authorized_keys        # (solo si este es un servidor)
```

---

## 🔐 Paso 2: Crear Llaves Dedicadas

### Llave para GitHub

```bash
# Generar llave específica para GitHub
ssh-keygen -t ed25519 -C "tu-email-github@email.com" -f ~/.ssh/id_github

# Verificar creación
ls -la ~/.ssh/id_github*
# -rw-------  id_github
# -rw-r--r--  id_github.pub
```

### Llave para Trabajo

```bash
# Generar llave para entorno laboral
ssh-keygen -t ed25519 -C "tu-nombre@empresa.com" -f ~/.ssh/id_trabajo

# Verificar
ls -la ~/.ssh/id_trabajo*
```

### Verificar todas las llaves

```bash
# Listar todas las llaves con sus fingerprints
for key in ~/.ssh/id_*.pub; do
  echo "=== $key ==="
  ssh-keygen -lf "$key"
done
```

---

## ⚙️ Paso 3: Configurar ~/.ssh/config

El archivo `config` es la clave para gestionar múltiples llaves automáticamente.

### Crear archivo de configuración

```bash
# Crear/editar archivo config
nano ~/.ssh/config
```

### Configuración Completa

```bash
# ~/.ssh/config
# ============================================
# Configuración SSH para múltiples identidades
# ============================================

# === GITHUB ===
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github
    IdentitiesOnly yes

# Alias alternativo para GitHub
Host gh
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github
    IdentitiesOnly yes

# === GITLAB (si lo usas) ===
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_gitlab
    IdentitiesOnly yes

# === TRABAJO ===
Host trabajo
    HostName servidor.empresa.com
    User tu-usuario
    Port 22
    IdentityFile ~/.ssh/id_trabajo
    IdentitiesOnly yes

# Servidores de desarrollo de trabajo
Host dev-trabajo
    HostName dev.empresa.com
    User developer
    IdentityFile ~/.ssh/id_trabajo
    IdentitiesOnly yes

# === PERSONAL ===
Host mi-vps
    HostName 192.168.1.100
    User admin
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

# Raspberry Pi en casa
Host raspi
    HostName 192.168.1.50
    User pi
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

# === CONFIGURACIÓN GLOBAL ===
Host *
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes
```

### Configurar permisos

```bash
chmod 600 ~/.ssh/config
```

---

## 🐙 Paso 4: Configurar GitHub con Llave SSH

### Copiar llave pública

```bash
# Copiar al portapapeles (Linux con xclip)
cat ~/.ssh/id_github.pub | xclip -selection clipboard

# O simplemente mostrar para copiar manualmente
cat ~/.ssh/id_github.pub
```

### Añadir a GitHub

1. Ve a [github.com/settings/keys](https://github.com/settings/keys)
2. Click en **"New SSH key"**
3. **Title**: "Mi laptop personal" (o descripción identificativa)
4. **Key type**: Authentication Key
5. **Key**: Pega tu llave pública
6. Click en **"Add SSH key"**

### Verificar conexión a GitHub

```bash
# Probar conexión SSH con GitHub
ssh -T git@github.com

# Respuesta esperada:
# Hi tu-usuario! You've successfully authenticated, but GitHub does not provide shell access.
```

### Verificar que usa la llave correcta

```bash
# Ver qué llave se está usando
ssh -v git@github.com 2>&1 | grep "Offering"

# Esperado:
# debug1: Offering public key: /home/usuario/.ssh/id_github ED25519
```

---

## 🔄 Paso 5: Gestionar Llaves con ssh-agent

### Iniciar ssh-agent

```bash
# Verificar si ssh-agent está corriendo
echo $SSH_AUTH_SOCK

# Si no está corriendo, iniciarlo
eval "$(ssh-agent -s)"
# Agent pid 12345
```

### Añadir llaves al agente

```bash
# Añadir llave personal (pedirá passphrase)
ssh-add ~/.ssh/id_ed25519

# Añadir llave de GitHub
ssh-add ~/.ssh/id_github

# Añadir llave de trabajo
ssh-add ~/.ssh/id_trabajo

# Verificar llaves cargadas
ssh-add -l
```

### Configurar persistencia (Linux con GNOME/KDE)

```bash
# Añadir a ~/.bashrc o ~/.zshrc
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
    ssh-add ~/.ssh/id_github 2>/dev/null
fi
```

### Listar y eliminar llaves del agente

```bash
# Listar llaves con fingerprints
ssh-add -l

# Listar llaves con llaves públicas completas
ssh-add -L

# Eliminar una llave específica
ssh-add -d ~/.ssh/id_trabajo

# Eliminar TODAS las llaves del agente
ssh-add -D
```

---

## 🧪 Paso 6: Ejercicios de Verificación

### Ejercicio 1: Probar cada configuración de host

```bash
# GitHub (debería usar id_github)
ssh -v git@github.com 2>&1 | grep -E "(Reading|Offering|accepted)"

# Host de trabajo (debería usar id_trabajo)
ssh -v trabajo 2>&1 | grep -E "(Reading|Offering|accepted)"

# VPS personal (debería usar id_ed25519)
ssh -v mi-vps 2>&1 | grep -E "(Reading|Offering|accepted)"
```

### Ejercicio 2: Clonar repositorio con alias

```bash
# Usando la configuración de ~/.ssh/config
git clone git@github.com:tu-usuario/tu-repo.git

# Usando el alias "gh"
git clone gh:tu-usuario/tu-repo.git
```

### Ejercicio 3: Forzar uso de llave específica

```bash
# Ignorar config y usar llave específica
ssh -i ~/.ssh/id_trabajo -o IdentitiesOnly=yes usuario@servidor

# Útil para debugging
```

### Ejercicio 4: Ver qué llave se usaría

```bash
# Dry-run para ver qué configuración se aplica
ssh -G github.com | grep -E "(hostname|user|identityfile)"

# Salida esperada:
# hostname github.com
# user git
# identityfile ~/.ssh/id_github
```

---

## 🏢 Paso 7: Escenarios Avanzados

### Múltiples cuentas de GitHub

Si tienes cuenta personal y de trabajo en GitHub:

```bash
# ~/.ssh/config

# GitHub Personal
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github_personal
    IdentitiesOnly yes

# GitHub Trabajo
Host github.com-trabajo
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github_trabajo
    IdentitiesOnly yes
```

Uso:

```bash
# Clonar repo personal
git clone git@github.com-personal:mi-usuario/repo-personal.git

# Clonar repo de trabajo
git clone git@github.com-trabajo:empresa/repo-trabajo.git
```

### Configurar git para usar host correcto

```bash
# En un repo personal
cd repo-personal
git remote set-url origin git@github.com-personal:mi-usuario/repo-personal.git

# En un repo de trabajo
cd repo-trabajo
git remote set-url origin git@github.com-trabajo:empresa/repo-trabajo.git
```

---

## 🐛 Troubleshooting

### Error: "Too many authentication failures"

```bash
# Problema: SSH intenta muchas llaves antes de la correcta
# Solución: Usar IdentitiesOnly yes

# En ~/.ssh/config
Host servidor
    IdentityFile ~/.ssh/llave_especifica
    IdentitiesOnly yes
```

### Error: "Could not open a connection to your authentication agent"

```bash
# Iniciar ssh-agent
eval "$(ssh-agent -s)"

# Añadir llave
ssh-add ~/.ssh/id_ed25519
```

### Error: GitHub dice "Permission denied"

```bash
# Verificar que la llave correcta está cargada
ssh-add -l

# Verificar que la llave está en GitHub
ssh -T git@github.com

# Si falla, verificar configuración
ssh -v git@github.com 2>&1 | grep "Offering"
```

### Error: "Bad configuration option"

```bash
# Verificar sintaxis de ~/.ssh/config
# Errores comunes:
# - Tabulaciones en lugar de espacios
# - Opciones mal escritas
# - Rutas incorrectas

# Probar configuración
ssh -G hostname
```

### Verificar todas las llaves

```bash
# Script de diagnóstico
echo "=== Llaves en ~/.ssh ==="
ls -la ~/.ssh/id_*

echo -e "\n=== Llaves en ssh-agent ==="
ssh-add -l

echo -e "\n=== Configuración para github.com ==="
ssh -G github.com | grep -E "(hostname|user|identityfile)"
```

---

## 📊 Resumen de Comandos

| Comando                       | Descripción                       |
| ----------------------------- | --------------------------------- |
| `ssh-keygen -f ~/.ssh/nombre` | Crear llave con nombre específico |
| `ssh-add ~/.ssh/llave`        | Añadir llave al agente            |
| `ssh-add -l`                  | Listar llaves en agente           |
| `ssh-add -d llave`            | Eliminar llave del agente         |
| `ssh -G host`                 | Ver configuración para un host    |
| `ssh -T git@github.com`       | Probar conexión a GitHub          |
| `ssh -v host`                 | Conexión verbose (debug)          |

---

## 📁 Estado Final de ~/.ssh

```
~/.ssh/
├── config                  # ✅ Configuración de hosts
├── id_ed25519             # ✅ Llave personal
├── id_ed25519.pub
├── id_github              # ✅ Llave GitHub
├── id_github.pub
├── id_trabajo             # ✅ Llave trabajo
├── id_trabajo.pub
├── known_hosts            # ✅ Fingerprints
└── authorized_keys        # (si es servidor)
```

---

## ✅ Checklist de Verificación

Antes de finalizar, verifica:

- [ ] Al menos 3 pares de llaves creados y nombrados
- [ ] Archivo `~/.ssh/config` configurado correctamente
- [ ] GitHub autenticado con llave dedicada (`ssh -T git@github.com`)
- [ ] ssh-agent corriendo y llaves cargadas
- [ ] Puedes conectar a diferentes hosts con `ssh nombre-alias`
- [ ] Cada conexión usa la llave correcta (verificado con `-v`)

---

## 🔗 Navegación

| ← Anterior                                             | Actual          | Siguiente →                           |
| ------------------------------------------------------ | --------------- | ------------------------------------- |
| [Práctica 02: ssh-copy-id](practica-02-ssh-copy-id.md) | **Práctica 03** | [3-Proyecto](../3-proyecto/README.md) |

---

<div align="center">

**🎉 ¡Excelente trabajo!** Has completado todas las prácticas de la Semana 02.

Ahora tienes un sistema profesional de gestión de llaves SSH.

[🏠 Volver al inicio de Semana 02](../README.md) | [📋 Ir al Proyecto](../3-proyecto/README.md)

</div>
