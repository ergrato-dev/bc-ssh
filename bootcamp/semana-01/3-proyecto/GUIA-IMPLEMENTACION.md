# 🛠️ Guía de Implementación - Proyecto Semana 01

![Guía](https://img.shields.io/badge/Tipo-Guía_Paso_a_Paso-blue?style=flat-square)
![Tiempo](https://img.shields.io/badge/Tiempo-90_minutos-green?style=flat-square)

---

## 📋 Paso a Paso

Sigue esta guía para completar el proyecto integrador de la Semana 01.

---

## Paso 1: Verificar Instalación de SSH (10 min)

### 1.1 Comprobar versión instalada

```bash
# Verificar versión de OpenSSH
ssh -V

# Guardar captura de pantalla → 01-ssh-version.png
```

### 1.2 Verificar directorio SSH

```bash
# Verificar que existe el directorio .ssh
ls -la ~/.ssh

# Si no existe, crearlo con permisos correctos
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Verificar permisos
ls -la ~ | grep .ssh
# Debe mostrar: drwx------ .ssh
```

### 1.3 Documentar en tu README

```markdown
## 1. Verificación de Instalación

- **Versión SSH:** OpenSSH_X.Xp1
- **Sistema Operativo:** [Tu SO]
- **Directorio ~/.ssh:** ✅ Creado con permisos 700
```

---

## Paso 2: Primera Conexión a Servidor Real (20 min)

### 2.1 Preparar datos de conexión

```
Servidor: web-prod (tu VPS real)
IP: _______________
Puerto: 22
Usuario: _______________
```

### 2.2 Realizar conexión

```bash
# Conectar al servidor
ssh usuario@ip-servidor

# Primera vez: Aceptar huella digital
# The authenticity of host... → escribir "yes"

# Ingresar contraseña cuando se solicite
```

### 2.3 Verificar conexión exitosa

Una vez conectado, ejecuta:

```bash
# Verificar usuario
whoami

# Verificar hostname
hostname

# Verificar IP
hostname -I

# Ver información del sistema
uname -a

# Guardar captura de pantalla → 02-conexion-exitosa.png
```

### 2.4 Cerrar conexión

```bash
exit
```

### 2.5 Documentar en tu README

```markdown
## 2. Primera Conexión

- **Servidor:** web-prod
- **IP:** XXX.XXX.XXX.XXX (censurada)
- **Usuario:** root
- **Conexión exitosa:** ✅
- **Huella digital guardada en:** ~/.ssh/known_hosts
```

---

## Paso 3: Crear Archivo de Configuración SSH (30 min)

### 3.1 Crear el archivo config

```bash
# Abrir editor
nano ~/.ssh/config
```

### 3.2 Añadir configuración de los 4 servidores

Copia y personaliza esta plantilla:

```ssh-config
# ============================================
# SSH Configuration File
# Proyecto Semana 01 - Bootcamp SSH
# Autor: [Tu Nombre]
# Fecha: [Fecha actual]
# ============================================

# --------------------------------------------
# PRODUCCIÓN
# --------------------------------------------

# Servidor Web - Producción (REAL)
Host web-prod
    HostName TU-IP-REAL-AQUI
    User root
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Base de Datos - Producción (FICTICIO)
Host db-prod
    HostName 10.0.1.20
    User dba
    Port 22
    ServerAliveInterval 60

# --------------------------------------------
# STAGING / DESARROLLO
# --------------------------------------------

# Servidor Web - Staging (FICTICIO)
Host web-staging
    HostName 10.0.1.10
    User deploy
    Port 22

# --------------------------------------------
# INFRAESTRUCTURA
# --------------------------------------------

# Servidor de Monitoreo (FICTICIO)
Host monitoring
    HostName 10.0.1.30
    User monitor
    Port 2222
    ServerAliveInterval 120

# --------------------------------------------
# CONFIGURACIÓN GLOBAL
# --------------------------------------------

Host *
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 30
```

### 3.3 Guardar y establecer permisos

```bash
# En nano: Ctrl+O, Enter, Ctrl+X

# Establecer permisos correctos
chmod 600 ~/.ssh/config

# Verificar permisos
ls -la ~/.ssh/config
# Debe mostrar: -rw------- config
```

### 3.4 Verificar configuración

```bash
# Ver el contenido del archivo
cat ~/.ssh/config

# Guardar captura → 03-ssh-config.png

# Verificar configuración de un host específico
ssh -G web-prod

# Guardar captura → 04-ssh-g-alias.png
```

### 3.5 Probar conexión usando alias

```bash
# Ahora puedes conectarte simplemente con:
ssh web-prod

# En lugar de:
ssh root@tu-ip-real -p 22
```

---

## Paso 4: Documentar el Proceso (20 min)

### 4.1 Crear estructura de entrega

```bash
# Crear carpeta del proyecto
mkdir -p ~/proyecto-semana-01/evidencias

# Copiar archivo config (censurado)
cat ~/.ssh/config | sed 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/XXX.XXX.XXX.XXX/g' > ~/proyecto-semana-01/ssh-config.txt
```

### 4.2 Crear README del proyecto

Crea el archivo `~/proyecto-semana-01/README.md`:

```markdown
# 🔐 Proyecto Semana 01 - Gestión Centralizada SSH

**Autor:** [Tu Nombre]  
**Fecha:** [Fecha]  
**Bootcamp:** SSH - De Zero a Hero

---

## 📋 Resumen

Este proyecto demuestra la configuración de un entorno SSH profesional
para gestionar múltiples servidores de forma eficiente.

---

## 1. Verificación de Instalación

| Item | Valor |
|------|-------|
| Versión SSH | OpenSSH_X.Xp1 |
| Sistema Operativo | [Tu SO] |
| Directorio ~/.ssh | ✅ Permisos 700 |

**Comando utilizado:**
\`\`\`bash
ssh -V
\`\`\`

---

## 2. Primera Conexión

| Item | Valor |
|------|-------|
| Servidor | web-prod |
| IP | XXX.XXX.XXX.XXX |
| Puerto | 22 |
| Usuario | root |
| Conexión | ✅ Exitosa |

**Comandos ejecutados en el servidor:**
\`\`\`bash
whoami    # root
hostname  # [nombre-servidor]
uname -a  # Linux...
\`\`\`

---

## 3. Configuración SSH

### Servidores Configurados

| Alias | Función | Puerto |
|-------|---------|--------|
| web-prod | Servidor web producción | 22 |
| web-staging | Servidor web staging | 22 |
| db-prod | Base de datos | 22 |
| monitoring | Monitoreo | 2222 |

### Verificación

\`\`\`bash
ssh -G web-prod
# user root
# hostname XXX.XXX.XXX.XXX
# port 22
\`\`\`

---

## 4. Evidencias

- [01-ssh-version.png](evidencias/01-ssh-version.png)
- [02-conexion-exitosa.png](evidencias/02-conexion-exitosa.png)
- [03-ssh-config.png](evidencias/03-ssh-config.png)
- [04-ssh-g-alias.png](evidencias/04-ssh-g-alias.png)

---

## 5. Problemas y Soluciones

### Problema 1: [Descripción]
**Solución:** [Cómo lo resolviste]

### Problema 2: [Descripción]
**Solución:** [Cómo lo resolviste]

---

## 6. Conclusiones

[Escribe qué aprendiste y cómo aplicarías esto en un entorno real]

---

## 📚 Referencias

- [OpenSSH Manual](https://www.openssh.com/manual.html)
- [SSH Config Documentation](https://man.openbsd.org/ssh_config)
```

---

## Paso 5: Verificación Final (10 min)

### Checklist de Entrega

Antes de entregar, verifica:

- [ ] `ssh -V` muestra versión de OpenSSH
- [ ] `~/.ssh` tiene permisos 700
- [ ] `~/.ssh/config` tiene permisos 600
- [ ] Conexión exitosa a servidor real con `ssh web-prod`
- [ ] Archivo config tiene 4 hosts configurados
- [ ] README completo con todos los pasos
- [ ] 4 capturas de pantalla en carpeta evidencias
- [ ] IPs reales censuradas en documentación pública

### Estructura final

```
proyecto-semana-01/
├── README.md              ✅
├── ssh-config.txt         ✅
└── evidencias/
    ├── 01-ssh-version.png       ✅
    ├── 02-conexion-exitosa.png  ✅
    ├── 03-ssh-config.png        ✅
    └── 04-ssh-g-alias.png       ✅
```

---

## 🎯 Criterios de Éxito

| Criterio | Cumplido |
|----------|----------|
| Conexión SSH exitosa | ⬜ |
| Config con 4+ hosts | ⬜ |
| Permisos correctos | ⬜ |
| README documentado | ⬜ |
| Evidencias completas | ⬜ |

---

<div align="center">

**Semana 01 • Guía de Implementación**

[← Volver al Proyecto](README.md) • [Ejemplos de Config →](EJEMPLOS-CONFIGS.md)

</div>
