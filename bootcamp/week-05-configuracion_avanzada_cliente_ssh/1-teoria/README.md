# 📚 Teoría - Semana 03

## Configuración Avanzada del Cliente SSH

![Teoría](https://img.shields.io/badge/Teoría-3_módulos-purple?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-1_hora-blue?style=for-the-badge)

---

## 🎯 Objetivo

Dominar el archivo de configuración del cliente SSH (`~/.ssh/config`) para crear conexiones eficientes, seguras y productivas a múltiples servidores.

---

## 📖 Módulos Teóricos

| #   | Módulo                                                         | Duración | Descripción                       |
| --- | -------------------------------------------------------------- | -------- | --------------------------------- |
| 01  | [El Archivo ~/.ssh/config](01-archivo-ssh-config.md)           | 20 min   | Sintaxis, directivas y estructura |
| 02  | [ProxyJump y ProxyCommand](02-proxyjump-proxycommand.md)       | 20 min   | Conexiones a través de bastiones  |
| 03  | [Multiplexing y Optimización](03-multiplexing-optimizacion.md) | 20 min   | Reutilización de conexiones       |

---

## 🧠 Conceptos Clave

### Archivo ~/.ssh/config

- Configuración persistente del cliente SSH
- Reemplaza parámetros de línea de comandos
- Aplica configuraciones automáticamente

### Bloques Host

- Definen configuración por servidor/grupo
- Soportan wildcards y patrones
- Se procesan en orden (primera coincidencia gana)

### ProxyJump

- Conexiones a través de servidores intermedios
- Reemplaza el antiguo ProxyCommand para casos simples
- Permite encadenamiento de múltiples saltos

### Multiplexing

- Reutiliza una conexión SSH para múltiples sesiones
- Reduce tiempo de conexión drásticamente
- Ahorra recursos de autenticación

---

## 📊 Diagrama de Conceptos

```
┌─────────────────────────────────────────────────────────────┐
│                    ~/.ssh/config                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Host *     │  │ Host web-*  │  │ Host produccion     │  │
│  │  (global)   │  │ (patrón)    │  │ (específico)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│         │                │                    │              │
│         ▼                ▼                    ▼              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Opciones de Conexión                     │   │
│  │  • HostName, User, Port                              │   │
│  │  • IdentityFile, IdentitiesOnly                      │   │
│  │  • ProxyJump, ProxyCommand                           │   │
│  │  • ControlMaster, ControlPath                        │   │
│  │  • ServerAliveInterval, Compression                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisitos

Antes de comenzar, asegúrate de:

- [ ] Comprender autenticación con llaves SSH (Semana 02)
- [ ] Tener acceso a servidores remotos para pruebas
- [ ] Conocer comandos básicos de SSH

---

## 🧭 Navegación

| Módulo                                                    | Siguiente |
| --------------------------------------------------------- | --------- |
| [01 - El Archivo ~/.ssh/config](01-archivo-ssh-config.md) | ➡️        |

---

<div align="center">

**📚 Teoría - Semana 03**

_Configuración Avanzada del Cliente SSH_

</div>
