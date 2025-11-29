# 💻 Prácticas - Semana 02

![SSH](https://img.shields.io/badge/SSH-Llaves-red?style=for-the-badge&logo=openssh)
![Prácticas](https://img.shields.io/badge/Prácticas-3_ejercicios-orange?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-1.5_horas-blue?style=for-the-badge)

## 📋 Índice de Prácticas

Esta semana realizarás **3 prácticas progresivas** para dominar la autenticación con llaves SSH. Cada práctica dura aproximadamente **30 minutos** y aumenta gradualmente en dificultad.

---

## 🎯 Objetivos Generales

Al completar estas prácticas serás capaz de:

- [ ] Generar pares de llaves SSH con diferentes algoritmos
- [ ] Configurar autenticación por llaves en servidores remotos
- [ ] Gestionar múltiples llaves para diferentes servicios
- [ ] Proteger llaves privadas con passphrase
- [ ] Diagnosticar problemas comunes de autenticación

---

## 📚 Lista de Prácticas

| #   | Práctica                                                       | Dificultad      | Duración | Descripción                                      |
| --- | -------------------------------------------------------------- | --------------- | -------- | ------------------------------------------------ |
| 1   | [Generación de Llaves SSH](practica-01-generacion-llaves.md)   | ⭐ Básico       | 30 min   | Crear tu primer par de llaves Ed25519            |
| 2   | [Despliegue con ssh-copy-id](practica-02-ssh-copy-id.md)       | ⭐⭐ Intermedio | 30 min   | Configurar autenticación en servidor remoto      |
| 3   | [Gestión de Múltiples Llaves](practica-03-multiples-llaves.md) | ⭐⭐⭐ Avanzado | 30 min   | Llaves separadas para GitHub, trabajo y personal |

---

## 🔧 Requisitos Previos

### Software Necesario

```bash
# Verificar que tienes OpenSSH instalado
ssh -V
# OpenSSH_8.9p1 Ubuntu-3ubuntu0.1, OpenSSL 3.0.2

# Verificar ssh-keygen
ssh-keygen --help
```

### Conocimientos Previos

- ✅ Completar [Semana 01: Fundamentos SSH](../semana-01/README.md)
- ✅ Leer los 3 módulos teóricos de esta semana
- ✅ Acceso a un servidor remoto (VPS, VM local o contenedor)

### Entorno de Práctica

Puedes usar cualquiera de estas opciones:

1. **VPS real** (DigitalOcean, AWS, Linode)
2. **Máquina virtual** local (VirtualBox, VMware)
3. **Contenedor Docker** con SSH habilitado
4. **WSL2** en Windows

---

## 🗺️ Flujo de Aprendizaje

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRÁCTICAS SEMANA 02                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  Práctica 1  │───▶│  Práctica 2  │───▶│  Práctica 3  │      │
│  │   GENERAR    │    │   DESPLEGAR  │    │   GESTIONAR  │      │
│  │    ⭐        │    │     ⭐⭐      │    │    ⭐⭐⭐     │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                   │                   │               │
│         ▼                   ▼                   ▼               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ Par de llaves│    │ Acceso sin   │    │ Múltiples    │      │
│  │ Ed25519      │    │ contraseña   │    │ identidades  │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Criterios de Evaluación

Cada práctica vale **10 puntos** (30 puntos total):

| Criterio        | Puntos | Descripción                              |
| --------------- | ------ | ---------------------------------------- |
| Completitud     | 4 pts  | Todos los pasos realizados correctamente |
| Verificación    | 3 pts  | Comandos de verificación ejecutados      |
| Documentación   | 2 pts  | Capturas/notas del proceso               |
| Troubleshooting | 1 pt   | Resolver al menos un problema            |

---

## ⚠️ Errores Comunes a Evitar

### 1. Permisos Incorrectos

```bash
# ❌ ERROR: Permisos demasiado abiertos
chmod 777 ~/.ssh/id_ed25519
# SSH rechazará la llave

# ✅ CORRECTO: Permisos restrictivos
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 700 ~/.ssh
```

### 2. Llave Pública vs Privada

```bash
# ❌ ERROR: Copiar la llave privada al servidor
scp ~/.ssh/id_ed25519 servidor:~/.ssh/
# NUNCA hagas esto - compromete tu seguridad

# ✅ CORRECTO: Solo copiar la llave pública
ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@servidor
```

### 3. Passphrase Olvidada

```bash
# ⚠️ IMPORTANTE: No hay forma de recuperar una passphrase olvidada
# Tendrás que generar un nuevo par de llaves

# 💡 TIP: Usa un gestor de contraseñas para guardarla
```

---

## 🛠️ Comandos de Referencia Rápida

```bash
# Generar llave Ed25519 (recomendado)
ssh-keygen -t ed25519 -C "tu@email.com"

# Generar llave RSA 4096 bits
ssh-keygen -t rsa -b 4096 -C "tu@email.com"

# Copiar llave pública al servidor
ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@servidor

# Verificar fingerprint de una llave
ssh-keygen -lf ~/.ssh/id_ed25519.pub

# Cambiar passphrase de una llave existente
ssh-keygen -p -f ~/.ssh/id_ed25519

# Probar conexión con verbose
ssh -vvv usuario@servidor

# Listar llaves en el agente
ssh-add -l
```

---

## 📁 Archivos que Crearás

Al finalizar las prácticas tendrás estos archivos:

```
~/.ssh/
├── id_ed25519              # Llave privada principal
├── id_ed25519.pub          # Llave pública principal
├── id_github               # Llave para GitHub
├── id_github.pub           # Llave pública GitHub
├── id_trabajo              # Llave para trabajo
├── id_trabajo.pub          # Llave pública trabajo
├── config                  # Configuración de hosts
├── known_hosts             # Fingerprints de servidores
└── authorized_keys         # (en el servidor)
```

---

## 🔗 Navegación

| ← Anterior                        | Actual          | Siguiente →                           |
| --------------------------------- | --------------- | ------------------------------------- |
| [1-Teoría](../1-teoria/README.md) | **2-Prácticas** | [3-Proyecto](../3-proyecto/README.md) |

---

<div align="center">

**💡 Consejo**: Realiza las prácticas en orden. Cada una construye sobre la anterior.

[🏠 Volver al inicio de Semana 02](../README.md)

</div>
