# 💻 Práctica 03: Configuración del Archivo SSH Config

![Dificultad](https://img.shields.io/badge/Dificultad-⭐⭐_Intermedia-yellow?style=flat-square)
![Duración](https://img.shields.io/badge/Duración-30_minutos-blue?style=flat-square)
![Puntos](https://img.shields.io/badge/Puntos-10-orange?style=flat-square)

---

## 🎯 Objetivo

Crear y configurar el archivo `~/.ssh/config` para simplificar conexiones SSH. Aprenderás a crear aliases para tus servidores y evitar escribir comandos largos cada vez que te conectes.

---

## 📋 Prerequisitos

- ✅ Práctica 01 y 02 completadas
- ✅ Acceso a al menos un servidor SSH
- ✅ Editor de texto (nano, vim, o VS Code)

---

## 📁 ¿Qué es el archivo ~/.ssh/config?

El archivo `~/.ssh/config` es un archivo de configuración personal que te permite:

- 🏷️ **Crear aliases** para servidores (nombres cortos y fáciles de recordar)
- ⚙️ **Definir opciones predeterminadas** por servidor
- 🔑 **Especificar llaves SSH** diferentes por servidor
- 🚀 **Ahorrar tiempo** evitando comandos largos

### Sin config vs Con config

**Sin archivo config:**

```bash
ssh -i ~/.ssh/mi-llave-especial.pem -p 2222 usuario-con-nombre-largo@servidor.dominio.ejemplo.com
```

**Con archivo config:**

```bash
ssh miservidor
```

¡Mucho más simple! 🎉

---

## 🔧 Crear el Archivo Config

### Paso 1: Crear o editar el archivo

```bash
# Abrir con nano (fácil para principiantes)
nano ~/.ssh/config

# O con vim
vim ~/.ssh/config

# O con VS Code
code ~/.ssh/config
```

### Paso 2: Estructura básica del archivo

```ssh-config
# Comentario: Configuración de mi servidor principal
Host nombre-alias
    HostName ip-o-dominio
    User usuario
    Port 22
```

### Paso 3: Establecer permisos correctos

```bash
# El archivo config debe tener permisos 600
chmod 600 ~/.ssh/config

# Verificar
ls -la ~/.ssh/config
# Salida esperada: -rw------- 1 usuario usuario ... config
```

---

## 📝 Sintaxis del Archivo Config

### Directivas principales

| Directiva             | Descripción             | Ejemplo                          |
| --------------------- | ----------------------- | -------------------------------- |
| `Host`                | Alias para la conexión  | `Host mi-servidor`               |
| `HostName`            | IP o dominio real       | `HostName 192.168.1.100`         |
| `User`                | Usuario SSH             | `User root`                      |
| `Port`                | Puerto SSH              | `Port 22`                        |
| `IdentityFile`        | Ruta a llave privada    | `IdentityFile ~/.ssh/id_ed25519` |
| `ServerAliveInterval` | Intervalo keep-alive    | `ServerAliveInterval 60`         |
| `ServerAliveCountMax` | Máx intentos keep-alive | `ServerAliveCountMax 3`          |

### Ejemplo completo

```ssh-config
# ========================================
# Archivo: ~/.ssh/config
# SSH Configuration File
# ========================================

# ----- Servidor de Producción -----
Host produccion
    HostName 134.122.15.92
    User root
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3

# ----- Servidor de Desarrollo -----
Host desarrollo
    HostName 192.168.1.50
    User developer
    Port 2222

# ----- Servidor de Base de Datos -----
Host db-server
    HostName 10.0.0.5
    User dba
    Port 22

# ----- Configuración global (aplica a todos) -----
Host *
    AddKeysToAgent yes
    ServerAliveInterval 120
```

---

## 🛠️ Ejercicio Práctico: Configura tu Servidor

### Paso 1: Identifica tus datos

Recupera la información de la Práctica 02:

```
IP del servidor:  _________________
Usuario:          _________________
Puerto:           _________________
Alias deseado:    _________________
```

### Paso 2: Crea el archivo config

```bash
nano ~/.ssh/config
```

### Paso 3: Añade tu configuración

```ssh-config
# Mi primer servidor SSH
Host mi-servidor
    HostName TU-IP-AQUI
    User TU-USUARIO-AQUI
    Port 22
    ServerAliveInterval 60
```

**Ejemplo real:**

```ssh-config
# Servidor de práctica del bootcamp
Host practica
    HostName 134.122.15.92
    User root
    Port 22
    ServerAliveInterval 60
```

### Paso 4: Guarda y establece permisos

```bash
# En nano: Ctrl+O (guardar), Enter, Ctrl+X (salir)

# Establecer permisos
chmod 600 ~/.ssh/config
```

### Paso 5: Prueba la conexión con el alias

```bash
# Antes (sin config)
ssh root@134.122.15.92

# Ahora (con config)
ssh practica
```

**¡Mucho más simple!**

---

## 🎨 Ejemplos de Configuraciones Útiles

### Configuración para múltiples servidores

```ssh-config
# ========================================
# SERVIDORES DE PRODUCCIÓN
# ========================================

Host prod-web
    HostName web.miempresa.com
    User deploy
    Port 22

Host prod-db
    HostName db.miempresa.com
    User dba
    Port 22

Host prod-cache
    HostName cache.miempresa.com
    User admin
    Port 22

# ========================================
# SERVIDORES DE DESARROLLO
# ========================================

Host dev
    HostName 192.168.1.100
    User developer
    Port 2222

Host staging
    HostName staging.miempresa.com
    User deploy
    Port 22

# ========================================
# CONFIGURACIÓN GLOBAL
# ========================================

Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
```

### Configuración con llaves SSH (preview semana 2)

```ssh-config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab

Host mi-servidor
    HostName 134.122.15.92
    User root
    IdentityFile ~/.ssh/id_ed25519_servidor
```

### Configuración para mantener conexión activa

```ssh-config
Host servidor-lento
    HostName servidor.ejemplo.com
    User admin
    # Enviar señal cada 60 segundos
    ServerAliveInterval 60
    # Intentar 3 veces antes de desconectar
    ServerAliveCountMax 3
    # Timeout de conexión
    ConnectTimeout 30
```

---

## 🔍 Verificar tu Configuración

### Ver qué configuración se aplicará

```bash
# Mostrar configuración para un host específico
ssh -G nombre-alias

# Ejemplo
ssh -G practica
```

**Salida esperada:**

```
user root
hostname 134.122.15.92
port 22
serveraliveinterval 60
...
```

### Probar conexión en modo verbose

```bash
ssh -v practica
```

Verás que SSH usa la configuración de tu archivo config:

```
debug1: Reading configuration data /home/usuario/.ssh/config
debug1: /home/usuario/.ssh/config line 2: Applying options for practica
```

---

## 🎯 Desafío: Configura 3 Hosts

Para completar esta práctica, configura al menos 3 hosts en tu archivo config:

### Host 1: Tu servidor de práctica real

```ssh-config
Host practica
    HostName TU-IP
    User TU-USUARIO
    Port 22
```

### Host 2: Servidor ficticio (para practicar sintaxis)

```ssh-config
Host web-produccion
    HostName 10.0.0.1
    User webadmin
    Port 22
    ServerAliveInterval 120
```

### Host 3: Otro servidor ficticio

```ssh-config
Host db-produccion
    HostName 10.0.0.2
    User dba
    Port 3306
```

---

## 🐛 Troubleshooting

### Error: "Bad owner or permissions"

```
Bad owner or permissions on /home/usuario/.ssh/config
```

**Solución:**

```bash
chmod 600 ~/.ssh/config
chown $USER:$USER ~/.ssh/config
```

### Error: Conexión usa configuración incorrecta

**Solución:** Verifica el orden de los hosts. SSH usa la primera coincidencia.

```ssh-config
# ❌ INCORRECTO: El Host * al inicio sobreescribe todo
Host *
    User admin

Host mi-servidor
    User root  # Esto NO se aplicará

# ✅ CORRECTO: Host * al final
Host mi-servidor
    User root  # Esto SÍ se aplicará

Host *
    User admin
```

### Error: El alias no funciona

**Verificar:**

```bash
# Ver si el archivo existe
cat ~/.ssh/config

# Ver la configuración que se aplicará
ssh -G nombre-alias

# Probar con verbose
ssh -v nombre-alias
```

---

## 📝 Checklist de Verificación

Confirma que has completado:

- [ ] Archivo `~/.ssh/config` creado
- [ ] Permisos establecidos a 600
- [ ] Al menos 1 host configurado con datos reales
- [ ] Conexión exitosa usando el alias (`ssh practica`)
- [ ] Comando `ssh -G alias` muestra la configuración correcta

---

## 🎯 Entregable

1. Contenido de tu archivo `~/.ssh/config` (censurar IPs reales si deseas)
2. Captura de `ssh -G tu-alias` mostrando la configuración
3. Captura de conexión exitosa usando el alias

---

## 📚 Recursos Adicionales

- [OpenSSH Config Manual](https://man.openbsd.org/ssh_config)
- [SSH Config File Examples](https://www.ssh.com/academy/ssh/config)

---

## ⏭️ Siguiente

[🔨 Proyecto Integrador →](../3-proyecto/README.md)

---

<div align="center">

**Semana 01 • Práctica 03 de 03**

[← Práctica anterior](practica-02-primera-conexion.md) • [Volver al índice](README.md)

</div>
