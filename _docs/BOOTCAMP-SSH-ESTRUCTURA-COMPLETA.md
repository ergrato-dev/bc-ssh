# 🔐 Bootcamp SSH: De Zero a Hero
## Estructura Completa - 10 Semanas | 4 horas/semana

> **Bootcamp profesional de SSH para administradores de sistemas y desarrolladores**  
> Versión: 1.0 | Duración: 40 horas totales | Nivel: Principiante a Avanzado

---

## 📋 Índice General

1. [Visión General del Bootcamp](#-visión-general-del-bootcamp)
2. [Estructura por Semanas](#-estructura-por-semanas)
3. [Distribución de Contenidos](#-distribución-de-contenidos)
4. [Tecnologías y Herramientas](#-tecnologías-y-herramientas)
5. [Metodología de Enseñanza](#-metodología-de-enseñanza)
6. [Criterios de Evaluación](#-criterios-de-evaluación)
7. [Proyecto Final Integrador](#-proyecto-final-integrador)

---

## 🎯 Visión General del Bootcamp

### ¿Por qué SSH es fundamental?

SSH (Secure Shell) es la herramienta estándar de facto para:
- Acceso remoto seguro a servidores
- Transferencia segura de archivos
- Automatización de tareas administrativas
- Gestión de infraestructura cloud
- Túneles seguros para aplicaciones

Este bootcamp te llevará desde los conceptos más básicos de conexión remota hasta configuraciones avanzadas de seguridad y automatización empresarial.

### Parámetros del Bootcamp

| Parámetro           | Valor                    |
|---------------------|--------------------------|
| Duración total      | 10 semanas               |
| Horas por semana    | 4 horas                  |
| Total horas         | 40 horas                 |
| Dedicación teoría   | 1h/semana (~25%)         |
| Dedicación práctica | 1.5h/semana (~37.5%)     |
| Dedicación proyecto | 1.5h/semana (~37.5%)     |
| Número de prácticas | 3 por semana             |
| Módulos teóricos    | 3 por semana             |
| Proyecto integrador | 1 por semana             |

### Perfil del Estudiante

**Conocimientos previos deseables:**
- Nociones básicas de línea de comandos (bash/terminal)
- Comprensión general de redes (qué es una IP, puerto)
- Familiaridad con sistemas operativos Linux/Unix (básico)

**No se requiere:**
- Experiencia previa con SSH
- Conocimientos avanzados de criptografía
- Experiencia como administrador de sistemas

---

## 📚 Estructura por Semanas

### 📅 Semana 1: Fundamentos de SSH y Primera Conexión

**🎯 Objetivo:** Comprender qué es SSH, por qué existe y realizar la primera conexión exitosa.

**📖 Teoría (1h):**
1. Historia y evolución de protocolos remotos (Telnet → SSH)
2. Arquitectura cliente-servidor de SSH
3. Conceptos de criptografía simétrica y asimétrica (introducción)

**💻 Prácticas (1.5h):**
1. Instalación de cliente SSH en diferentes sistemas operativos (⭐)
2. Primera conexión a servidor remoto con usuario/contraseña (⭐)
3. Configuración básica del archivo `~/.ssh/config` (⭐⭐)

**🔨 Proyecto (1.5h):**
Conectarse a 3 servidores diferentes usando configuración centralizada en archivo config, documentando cada paso realizado.

**📊 Evaluación:**
- Teoría: 20 pts (conceptos básicos SSH)
- Prácticas: 30 pts (10 pts c/u)
- Proyecto: 50 pts (conexión exitosa + documentación)

---

### 📅 Semana 2: Autenticación con Llaves SSH

**🎯 Objetivo:** Dominar la autenticación mediante criptografía de llave pública/privada.

**📖 Teoría (1h):**
1. Diferencias entre autenticación por contraseña vs llaves
2. Funcionamiento de criptografía asimétrica RSA/Ed25519
3. Anatomía de una llave pública SSH

**💻 Prácticas (1.5h):**
1. Generación de par de llaves SSH con diferentes algoritmos (⭐)
2. Instalación de llave pública en servidor remoto (`ssh-copy-id`) (⭐⭐)
3. Configuración de autenticación multi-factor con llaves + contraseña (⭐⭐⭐)

**🔨 Proyecto (1.5h):**
Crear infraestructura de llaves para 5 servidores diferentes, cada uno con algoritmo distinto (RSA, Ed25519, ECDSA), deshabilitando autenticación por contraseña.

**📊 Evaluación:**
- Teoría: 20 pts (conceptos criptografía)
- Prácticas: 30 pts (10 pts c/u)
- Proyecto: 50 pts (llaves funcionando + seguridad)

---

### 📅 Semana 3: Configuración Avanzada del Cliente SSH

**🎯 Objetivo:** Optimizar la experiencia de usuario mediante configuración avanzada del cliente.

**📖 Teoría (1h):**
1. Estructura completa del archivo `~/.ssh/config`
2. Opciones de conexión: timeouts, keep-alive, compression
3. ProxyJump y ProxyCommand para saltos entre servidores

**💻 Prácticas (1.5h):**
1. Configurar aliases para conexiones frecuentes (⭐)
2. Implementar ProxyJump para acceder a servidores internos (⭐⭐)
3. Configurar multiplexing para reutilizar conexiones (⭐⭐⭐)

**🔨 Proyecto (1.5h):**
Crear archivo de configuración que gestione 10 servidores organizados jerárquicamente (bastion → servidores internos), con persistencia de conexiones y compresión activada.

**📊 Evaluación:**
- Teoría: 20 pts (opciones de configuración)
- Prácticas: 30 pts (10 pts c/u)
- Proyecto: 50 pts (config funcional + organización)

---

### 📅 Semana 4: Transferencia de Archivos (SCP, SFTP, rsync)

**🎯 Objetivo:** Dominar las herramientas de transferencia segura de archivos sobre SSH.

**📖 Teoría (1h):**
1. Diferencias entre SCP, SFTP y rsync
2. Uso de rsync para sincronización incremental
3. Compresión y ancho de banda en transferencias

**💻 Prácticas (1.5h):**
1. Transferencia básica con SCP (local→remoto, remoto→local) (⭐)
2. Sesión interactiva con SFTP para gestión de archivos (⭐⭐)
3. Sincronización de directorios con rsync sobre SSH (⭐⭐⭐)

**🔨 Proyecto (1.5h):**
Crear script de backup automatizado que sincronice directorio local con servidor remoto usando rsync, excluyendo archivos temporales y con registro de cambios (log).

**📊 Evaluación:**
- Teoría: 20 pts (diferencias herramientas)
- Prácticas: 30 pts (10 pts c/u)
- Proyecto: 50 pts (script funcional + logs)

---

### 📅 Semana 5: Configuración del Servidor SSH (sshd)

**🎯 Objetivo:** Configurar y endurecer la seguridad del servidor SSH.

**📖 Teoría (1h):**
1. Anatomía del archivo `/etc/ssh/sshd_config`
2. Directivas de seguridad críticas (PermitRootLogin, PasswordAuthentication)
3. Logs y auditoría de accesos SSH

**💻 Prácticas (1.5h):**
1. Cambiar puerto por defecto y configurar firewall (⭐)
2. Deshabilitar autenticación root y por contraseña (⭐⭐)
3. Configurar listas blancas/negras de usuarios (AllowUsers/DenyUsers) (⭐⭐⭐)

**🔨 Proyecto (1.5h):**
Configurar servidor SSH endurecido con las mejores prácticas: puerto no estándar, sin root login, solo autenticación por llaves, límite de intentos con fail2ban, y monitoreo de logs con tail.

**📊 Evaluación:**
- Teoría: 20 pts (directivas sshd_config)
- Prácticas: 30 pts (10 pts c/u)
- Proyecto: 50 pts (servidor seguro + documentación)

---

### 📅 Semana 6: Port Forwarding y Túneles SSH

**🎯 Objetivo:** Utilizar SSH para crear túneles seguros entre redes.

**📖 Teoría (1h):**
1. Conceptos de Local Port Forwarding (-L)
2. Remote Port Forwarding (-R) y casos de uso
3. Dynamic Port Forwarding (-D) como SOCKS proxy

**💻 Prácticas (1.5h):**
1. Acceder a base de datos remota mediante túnel local (⭐)
2. Exponer servicio local a internet mediante túnel remoto (⭐⭐)
3. Configurar SOCKS proxy para navegar a través de servidor remoto (⭐⭐⭐)

**🔨 Proyecto (1.5h):**
Crear túnel persistente que permita acceder a servidor web interno (puerto 8080) desde máquina local, y configurar navegador para usar el servidor como proxy SOCKS.

**📊 Evaluación:**
- Teoría: 20 pts (tipos de forwarding)
- Prácticas: 30 pts (10 pts c/u)
- Proyecto: 50 pts (túneles funcionando + documentación)

---

### 📅 Semana 7: SSH Agent y Gestión de Llaves

**🎯 Objetivo:** Gestionar múltiples llaves SSH de forma eficiente y segura.

**📖 Teoría (1h):**
1. Funcionamiento de ssh-agent
2. Forwarding de agente SSH (Agent Forwarding)
3. Limitaciones de seguridad del agent forwarding

**💻 Prácticas (1.5h):**
1. Iniciar ssh-agent y agregar llaves con ssh-add (⭐)
2. Configurar agent forwarding para saltos entre servidores (⭐⭐)
3. Usar ssh-agent con llaves protegidas por passphrase (⭐⭐⭐)

**🔨 Proyecto (1.5h):**
Configurar entorno de trabajo que inicie ssh-agent automáticamente al login, cargue llaves específicas según hora del día (work/personal), y permita saltar entre 3 servidores sin reautenticación.

**📊 Evaluación:**
- Teoría: 20 pts (ssh-agent y forwarding)
- Prácticas: 30 pts (10 pts c/u)
- Proyecto: 50 pts (automatización + seguridad)

---

### 📅 Semana 8: Bastion Hosts y Arquitecturas de Acceso

**🎯 Objetivo:** Implementar arquitecturas de seguridad con servidores bastion/jump.

**📖 Teoría (1h):**
1. Concepto de bastion host y su rol en seguridad
2. Arquitecturas de red con DMZ y redes privadas
3. ProxyJump vs ProxyCommand en profundidad

**💻 Prácticas (1.5h):**
1. Configurar bastion host con autenticación dual (⭐)
2. Acceder a servidores privados mediante bastion con ProxyJump (⭐⭐)
3. Implementar rotación de llaves en bastion host (⭐⭐⭐)

**🔨 Proyecto (1.5h):**
Diseñar e implementar infraestructura completa: 1 bastion público, 3 servidores privados (web, db, cache), configurar acceso únicamente vía bastion con auditoría de conexiones.

**📊 Evaluación:**
- Teoría: 20 pts (arquitecturas seguras)
- Prácticas: 30 pts (10 pts c/u)
- Proyecto: 50 pts (infraestructura completa)

---

### 📅 Semana 9: Automatización con SSH (Scripts y Ansible)

**🎯 Objetivo:** Automatizar tareas administrativas usando SSH como transporte.

**📖 Teoría (1h):**
1. Ejecución de comandos remotos con SSH
2. Introducción a Ansible y SSH como transporte
3. Casos de uso: deployments, backups, monitoreo

**💻 Prácticas (1.5h):**
1. Ejecutar comandos remotos y capturar output en scripts (⭐)
2. Crear playbook básico de Ansible para configuración de servidores (⭐⭐)
3. Implementar rolling deployment con Ansible sobre SSH (⭐⭐⭐)

**🔨 Proyecto (1.5h):**
Crear suite de automatización: script de health check que verifica estado de 5 servidores, playbook de Ansible que instala software común, y script de deployment que actualiza aplicación en múltiples nodos.

**📊 Evaluación:**
- Teoría: 20 pts (automatización SSH)
- Prácticas: 30 pts (10 pts c/u)
- Proyecto: 50 pts (automatización completa)

---

### 📅 Semana 10: Seguridad Avanzada y Auditoría

**🎯 Objetivo:** Implementar medidas avanzadas de seguridad y monitoreo de SSH.

**📖 Teoría (1h):**
1. Two-Factor Authentication (2FA) con SSH
2. Análisis de logs y detección de intrusiones
3. Hardening avanzado: algoritmos modernos, rate limiting

**💻 Prácticas (1.5h):**
1. Configurar autenticación con Google Authenticator (2FA) (⭐⭐)
2. Implementar fail2ban para bloqueo automático de atacantes (⭐⭐)
3. Configurar alertas automáticas de accesos SSH sospechosos (⭐⭐⭐)

**🔨 Proyecto Final Integrador (1.5h):**
Auditar y endurecer infraestructura completa del bootcamp: implementar 2FA en bastion, configurar fail2ban en todos los servidores, crear dashboard de monitoreo de conexiones SSH, y documentar política de seguridad.

**📊 Evaluación:**
- Teoría: 20 pts (seguridad avanzada)
- Prácticas: 30 pts (10 pts c/u)
- Proyecto: 50 pts (infraestructura endurecida + documentación)

---

## 🛠️ Distribución de Contenidos

### Progresión de Complejidad por Semanas

```
Nivel de Complejidad
    │
100%│                                             ███ Sem 10
    │                                        ███ ███
    │                                   ███ ███ ███
    │                              ███ ███ ███ ███
 75%│                         ███ ███ ███ ███ ███
    │                    ███ ███ ███ ███ ███ ███
    │               ███ ███ ███ ███ ███ ███ ███
    │          ███ ███ ███ ███ ███ ███ ███ ███
 50%│     ███ ███ ███ ███ ███ ███ ███ ███ ███
    │ ███ ███ ███ ███ ███ ███ ███ ███ ███ ███
    └─────────────────────────────────────────────
      S1  S2  S3  S4  S5  S6  S7  S8  S9  S10
```

### Distribución Temática

| Bloque Temático           | Semanas   | Horas | Enfoque Principal          |
|---------------------------|-----------|-------|----------------------------|
| **Fundamentos**           | 1-2       | 8h    | Conexión y autenticación   |
| **Configuración Cliente** | 3-4       | 8h    | Optimización y transferencias |
| **Configuración Servidor**| 5         | 4h    | Seguridad del servidor     |
| **Funcionalidades Avanzadas** | 6-7   | 8h    | Túneles y gestión de llaves |
| **Arquitecturas y Automatización** | 8-9 | 8h | Bastion hosts y scripts    |
| **Seguridad Empresarial** | 10        | 4h    | Hardening y auditoría      |

---

## 💻 Tecnologías y Herramientas

### Software Requerido

**Cliente SSH:**
- OpenSSH (Linux/macOS nativo)
- PuTTY (Windows alternativo)
- Windows OpenSSH Client (Windows 10+)

**Servidores para Prácticas:**
- VPS en Digital Ocean / AWS / Linode (recomendado)
- Máquinas virtuales locales con VirtualBox/VMware
- Contenedores Docker con SSH habilitado

**Herramientas Complementarias:**
- **fail2ban**: Protección contra brute force
- **Ansible**: Automatización de configuraciones
- **rsync**: Sincronización de archivos
- **ssh-agent**: Gestión de llaves
- **Google Authenticator**: 2FA

### Sistemas Operativos

**Para estudiantes:**
- Linux (Ubuntu 20.04+, Fedora, Debian)
- macOS (cualquier versión reciente)
- Windows 10+ (con WSL2 recomendado)

**Para servidores de práctica:**
- Ubuntu Server 22.04 LTS (recomendado)
- Debian 11+
- CentOS/Rocky Linux 8+

---

## 🎓 Metodología de Enseñanza

### Ciclo de Aprendizaje por Semana

```
┌──────────────────────────────────────────────────────────┐
│                    CICLO SEMANAL                          │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1️⃣ TELL (Teoría - 1h)                                   │
│     └─ 3 módulos teóricos de 20 min c/u                  │
│        ├─ Conceptos fundamentales                        │
│        ├─ Explicaciones con diagramas                    │
│        └─ Ejemplos documentados                          │
│        ↓                                                  │
│  2️⃣ SHOW (Demostración - incluido en teoría)            │
│     └─ Código de ejemplo ejecutable                      │
│        └─ Comandos comentados paso a paso                │
│        ↓                                                  │
│  3️⃣ DO (Prácticas - 1.5h)                                │
│     └─ 3 ejercicios progresivos                          │
│        ├─ ⭐ Básico (30 min)                             │
│        ├─ ⭐⭐ Intermedio (30 min)                        │
│        └─ ⭐⭐⭐ Avanzado (30 min)                         │
│        ↓                                                  │
│  4️⃣ APPLY (Proyecto - 1.5h)                              │
│     └─ Integración de conceptos semanales                │
│        └─ Caso de uso realista                           │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

### Principios Pedagógicos

**1. Aprendizaje Constructivista:**
- Cada semana construye sobre las anteriores
- Los proyectos integran múltiples conceptos
- Se fomenta la experimentación y el error como aprendizaje

**2. Progresión Scaffolding:**
- Semanas 1-3: Soporte completo con comandos exactos
- Semanas 4-7: Soporte parcial con guías conceptuales
- Semanas 8-10: Autonomía con documentación de referencia

**3. Hands-On First:**
- 75% del tiempo es práctica (3 de 4 horas)
- La teoría siempre va acompañada de ejemplos ejecutables
- Proyectos basados en casos de uso reales del mercado

---

## 📊 Criterios de Evaluación

### Distribución General (por semana)

| Componente      | Peso | Puntos | Criterios                        |
|-----------------|------|--------|----------------------------------|
| **Teoría**      | 20%  | 20 pts | Comprensión conceptual           |
| **Prácticas**   | 30%  | 30 pts | Ejecución correcta (10 pts c/u)  |
| **Proyecto**    | 50%  | 50 pts | Integración y documentación      |
| **TOTAL**       | 100% | 100 pts|                                  |

### Escala de Calificación

| Rango      | Nivel         | Descripción                               |
|------------|---------------|-------------------------------------------|
| 90-100 pts | 🏆 Excelente  | Dominio completo, código limpio, extras   |
| 80-89 pts  | 🌟 Muy Bueno  | Cumple todos los requisitos correctamente |
| 70-79 pts  | ✅ Bueno      | Cumple requisitos básicos                 |
| 60-69 pts  | ⚠️ Suficiente | Cumple mínimos, con errores menores      |
| 0-59 pts   | ❌ Insuficiente| No cumple requisitos mínimos             |

### Rúbrica de Proyecto (Detalle de 50 pts)

| Criterio                    | Puntos | Descripción                          |
|-----------------------------|--------|--------------------------------------|
| **Funcionalidad Completa**  | 20 pts | Todos los requisitos implementados   |
| **Seguridad**               | 10 pts | Buenas prácticas aplicadas           |
| **Documentación**           | 10 pts | README con comandos y explicaciones  |
| **Código Limpio**           | 5 pts  | Scripts legibles y comentados        |
| **Creatividad/Extras**      | 5 pts  | Mejoras más allá de lo solicitado    |

### Bonificaciones y Penalizaciones

**Bonificaciones (+):**
- +5 pts: Implementación de funcionalidad extra documentada
- +3 pts: Ayudar a otros estudiantes en foros
- +2 pts: Reportar errores en el material del bootcamp

**Penalizaciones (-):**
- -10 pts por día de retraso en entrega
- -5 pts por código sin documentar
- -20 pts por plagio detectado

---

## 🏆 Proyecto Final Integrador (Semana 10)

### Descripción General

El proyecto final consolida todo el aprendizaje del bootcamp creando una infraestructura SSH completa para una empresa ficticia.

### Requisitos del Proyecto

**Escenario:**
Eres el administrador de sistemas de "DevOps Corp", una startup con 15 desarrolladores que necesita infraestructura cloud segura.

**Infraestructura Requerida:**

1. **1 Bastion Host (Servidor de Salto)**
   - Ubuntu Server 22.04
   - Autenticación 2FA con Google Authenticator
   - fail2ban configurado
   - Logs centralizados

2. **3 Servidores de Aplicación**
   - Web Server (puerto 80/443)
   - Database Server (PostgreSQL)
   - Cache Server (Redis)
   - Accesibles SOLO vía bastion

3. **Configuración de Acceso**
   - 3 niveles de usuarios: admin, developer, readonly
   - Cada nivel con llaves SSH diferentes
   - Restricciones de comandos según rol

4. **Automatización**
   - Script de backup diario con rsync
   - Playbook de Ansible para deployment
   - Monitoreo de conexiones activas

5. **Documentación**
   - README con arquitectura (diagrama)
   - Guía de conexión para cada rol
   - Procedimientos de emergencia
   - Política de seguridad SSH

### Entregables

1. **Código de Configuración**
   - Archivos ssh_config
   - Archivos sshd_config de cada servidor
   - Scripts de automatización
   - Playbooks de Ansible

2. **Documentación**
   - README.md principal
   - ARCHITECTURE.md con diagramas
   - SECURITY-POLICY.md
   - USER-GUIDE.md por rol

3. **Evidencias**
   - Screenshots de conexiones exitosas
   - Logs de auditoría
   - Resultados de fail2ban
   - Output de scripts de monitoreo

### Evaluación del Proyecto Final

| Criterio                      | Puntos | Requisitos                           |
|-------------------------------|--------|--------------------------------------|
| **Infraestructura Funcional** | 20 pts | Todos los servidores operativos      |
| **Seguridad Implementada**    | 15 pts | 2FA, fail2ban, sin root login        |
| **Automatización**            | 10 pts | Scripts + Ansible funcionando        |
| **Documentación Completa**    | 10 pts | Todos los docs con calidad profesional |
| **Arquitectura Coherente**    | 5 pts  | Diseño lógico y escalable            |
| **TOTAL**                     | 60 pts | Escala ajustada a 50 pts para rúbrica |

---

## 📁 Estructura de Archivos por Semana

### Plantilla de Carpetas

Cada semana seguirá esta estructura exacta:

```
semana-XX/
├── README.md                    # 📋 Índice principal de la semana
├── RUBRICA-EVALUACION.md        # 📊 Criterios de evaluación (100 pts)
│
├── 0-assets/                    # 🎨 Diagramas y recursos visuales
│   ├── README.md
│   ├── 01-arquitectura-ssh.svg
│   ├── 02-flujo-autenticacion.svg
│   └── 03-diagrama-red.svg
│
├── 1-teoria/                    # 📚 3 módulos teóricos
│   ├── README.md
│   ├── 01-modulo-principal.md
│   ├── 02-modulo-secundario.md
│   └── 03-modulo-complementario.md
│
├── 2-practicas/                 # 💻 3 prácticas progresivas
│   ├── README.md
│   ├── practica-01-basica.md        # ⭐ 30 min
│   ├── practica-02-intermedia.md    # ⭐⭐ 30 min
│   └── practica-03-avanzada.md      # ⭐⭐⭐ 30 min
│
├── 3-proyecto/                  # 🔨 Proyecto integrador semanal
│   ├── README.md                # Especificaciones
│   ├── GUIA-IMPLEMENTACION.md   # Pasos sugeridos
│   └── EJEMPLOS-CONFIGS.md      # Archivos de referencia
│
├── 4-recursos/                  # 📖 Material complementario
│   ├── README.md
│   ├── 01-videos-conceptos.md
│   ├── 02-videos-practicos.md
│   ├── 03-articulos-ssh.md
│   ├── 04-documentacion-oficial.md
│   ├── 05-herramientas-ssh.md
│   ├── 06-playgrounds-online.md
│   ├── 07-comunidades-sysadmin.md
│   ├── 08-canales-youtube.md
│   ├── ebooks-free/             # PDFs recomendados
│   ├── videografia/             # Notas de videos
│   └── webgrafia/               # Enlaces organizados
│
└── 5-glosario/                  # 📖 Terminología SSH
    └── README.md                # 30-40 términos técnicos
```

---

## 🎯 Ruta de Aprendizaje Visual

```
                    🔐 BOOTCAMP SSH: ROADMAP

┌─────────────────────────────────────────────────────────────────┐
│                         FASE 1: FUNDAMENTOS                      │
│                           (Semanas 1-2)                          │
├─────────────────────────────────────────────────────────────────┤
│  📌 Sem 1: Fundamentos SSH y Primera Conexión                   │
│  📌 Sem 2: Autenticación con Llaves                             │
│  🎯 Objetivo: Conectarse de forma segura a servidores remotos   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    FASE 2: CONFIGURACIÓN CLIENTE                 │
│                           (Semanas 3-4)                          │
├─────────────────────────────────────────────────────────────────┤
│  📌 Sem 3: Configuración Avanzada Cliente SSH                   │
│  📌 Sem 4: Transferencia de Archivos (SCP/SFTP/rsync)          │
│  🎯 Objetivo: Optimizar flujo de trabajo con SSH                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   FASE 3: SERVIDOR Y SEGURIDAD                   │
│                           (Semana 5)                             │
├─────────────────────────────────────────────────────────────────┤
│  📌 Sem 5: Configuración del Servidor SSH (sshd)                │
│  🎯 Objetivo: Endurecer seguridad del servidor                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                 FASE 4: FUNCIONALIDADES AVANZADAS                │
│                           (Semanas 6-7)                          │
├─────────────────────────────────────────────────────────────────┤
│  📌 Sem 6: Port Forwarding y Túneles                            │
│  📌 Sem 7: SSH Agent y Gestión de Llaves                        │
│  🎯 Objetivo: Dominar características avanzadas de SSH          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              FASE 5: ARQUITECTURAS Y AUTOMATIZACIÓN              │
│                           (Semanas 8-9)                          │
├─────────────────────────────────────────────────────────────────┤
│  📌 Sem 8: Bastion Hosts y Arquitecturas                        │
│  📌 Sem 9: Automatización con Scripts y Ansible                 │
│  🎯 Objetivo: Implementar infraestructuras empresariales        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                FASE 6: SEGURIDAD EMPRESARIAL                     │
│                           (Semana 10)                            │
├─────────────────────────────────────────────────────────────────┤
│  📌 Sem 10: Seguridad Avanzada y Auditoría + PROYECTO FINAL     │
│  🎯 Objetivo: Certificarse como experto en SSH                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist de Preparación del Bootcamp

### Para el Instructor (8-10 horas por semana)

**Por cada semana:**

- [ ] **Teoría (3h)**
  - [ ] Módulo 01 completo con comandos ejecutables
  - [ ] Módulo 02 completo con comandos ejecutables
  - [ ] Módulo 03 completo con comandos ejecutables
  - [ ] Diagramas SVG creados y vinculados

- [ ] **Prácticas (2h)**
  - [ ] Práctica 01 (⭐) con solución documentada
  - [ ] Práctica 02 (⭐⭐) con solución documentada
  - [ ] Práctica 03 (⭐⭐⭐) con solución documentada

- [ ] **Proyecto (2h)**
  - [ ] Especificaciones claras en README
  - [ ] Guía de implementación paso a paso
  - [ ] Archivos de ejemplo para referencia

- [ ] **Recursos (1h)**
  - [ ] 8 archivos de recursos creados y verificados
  - [ ] Links externos validados (no rotos)
  - [ ] Subcarpetas organizadas

- [ ] **Glosario (1h)**
  - [ ] 30-40 términos técnicos definidos
  - [ ] Ejemplos de comandos en cada término
  - [ ] Índice alfabético

- [ ] **Evaluación (30min)**
  - [ ] Rúbrica con 100 puntos distribuidos
  - [ ] Criterios específicos por componente

### Para el Estudiante (4 horas semanales)

**Cada semana debe completar:**

- [ ] **Teoría (1h)**
  - [ ] Leer los 3 módulos teóricos
  - [ ] Ejecutar todos los comandos de ejemplo
  - [ ] Tomar notas de conceptos clave

- [ ] **Prácticas (1.5h)**
  - [ ] Completar práctica básica (⭐)
  - [ ] Completar práctica intermedia (⭐⭐)
  - [ ] Completar práctica avanzada (⭐⭐⭐)

- [ ] **Proyecto (1.5h)**
  - [ ] Implementar proyecto integrador
  - [ ] Documentar proceso y solución
  - [ ] Subir evidencias a repositorio

---

## 🔗 Recursos Generales del Bootcamp

### Documentación Oficial

- **OpenSSH Manual Pages**: https://www.openssh.com/manual.html
- **SSH Protocol RFC**: https://www.rfc-editor.org/rfc/rfc4251.html
- **SSH Academy**: https://www.ssh.com/academy/ssh

### Herramientas Recomendadas

- **Terminal Emulators**: iTerm2 (macOS), Windows Terminal, Alacritty
- **SSH Clients GUI**: MobaXterm, Termius, PuTTY
- **Key Managers**: KeePassXC, 1Password, Bitwarden
- **Lab Environments**: Vagrant, Docker, Multipass

### Comunidades

- **r/sysadmin** (Reddit)
- **ServerFault** (Stack Exchange)
- **DevOps Subreddit**
- **SSH Academy Forum**

### Canales YouTube Recomendados

- **NetworkChuck**: Tutoriales SSH para principiantes
- **Learn Linux TV**: Administración de servidores
- **TechWorld with Nana**: DevOps y SSH
- **Jeff Geerling**: Ansible y automatización

---

## 📌 Convenciones y Estándares

### Nomenclatura de Archivos

- **Teoría**: `01-tema-kebab-case.md`, `02-tema.md`, `03-tema.md`
- **Prácticas**: `practica-01-nombre-descriptivo.md`
- **Assets**: `01-descripcion-clara.svg` (numeración lógica)

### Formato de Código en Documentación

```bash
# ✅ HACER: Comentar siempre los comandos
ssh usuario@servidor -p 2222  # Conexión por puerto no estándar

# ❌ EVITAR: Código sin explicación
ssh usuario@servidor -p 2222
```

### Estructura de READMEs

Todos los READMEs siguen el formato:

1. Título con emoji
2. Badges (tecnología, nivel, duración)
3. Descripción general (2-3 párrafos)
4. Objetivos de aprendizaje (checkbox)
5. Contenido principal (secciones)
6. Enlaces a otros documentos
7. Navegación (anterior/siguiente)

---

## 🎓 Certificación

### Requisitos para Aprobar

- **Puntuación mínima total**: 70/100 en promedio (todas las semanas)
- **Asistencia mínima**: 90% de las prácticas completadas
- **Proyecto final**: Mínimo 60/100 puntos

### Certificado Incluye

- Nombre del estudiante
- Duración del bootcamp (40 horas)
- Tecnologías dominadas
- Puntuación final obtenida
- Firma digital del instructor

---

## 📝 Notas Finales

### Filosofía del Bootcamp

Este bootcamp está diseñado bajo el principio de que **SSH es una herramienta que se aprende usándola**. Por eso el 75% del tiempo es práctica hands-on con servidores reales.

### Consejos para el Éxito

1. **No te saltes las prácticas básicas**: Aunque parezcan simples, construyen memoria muscular
2. **Documenta todo**: Crea tu propio "manual personal de SSH"
3. **Rompe cosas**: Los errores enseñan más que los aciertos
4. **Usa servidores reales**: VPS de $5/mes es la mejor inversión
5. **Practica diariamente**: 30 min al día es mejor que 4 horas un solo día

### Siguientes Pasos Después del Bootcamp

Una vez completado, estarás preparado para:

- **Administración de servidores Linux remotos**
- **Implementación de CI/CD con SSH**
- **Gestión de infraestructura cloud**
- **Automatización con Ansible**
- **DevOps roles entry-level**

---

<div align="center">

**🔐 Bootcamp SSH: De Zero a Hero**

_Versión 1.0 | Diseñado para aprendizaje práctico intensivo_

**Duración**: 10 semanas | **Dedicación**: 4 horas/semana | **Total**: 40 horas

</div>
