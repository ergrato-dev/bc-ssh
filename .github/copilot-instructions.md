# 🔐 Copilot Instructions - Bootcamp SSH: De Zero a Hero

## 📋 Descripción del Proyecto

Este es un **bootcamp profesional de SSH** diseñado para administradores de sistemas y desarrolladores. El curso tiene una duración de **10 semanas** con **4 horas semanales** (40 horas totales), llevando a los estudiantes desde nivel principiante hasta avanzado.

### Parámetros del Bootcamp

| Parámetro        | Valor                                       |
| ---------------- | ------------------------------------------- |
| Duración total   | 10 semanas                                  |
| Horas por semana | 4 horas                                     |
| Total horas      | 40 horas                                    |
| Teoría           | 1h/semana (25%) - 3 módulos de 20 min       |
| Prácticas        | 1.5h/semana (37.5%) - 3 prácticas de 30 min |
| Proyecto         | 1.5h/semana (37.5%)                         |

---

## 📁 Estructura de Archivos Obligatoria

> **IMPORTANTE**: Todas las semanas del bootcamp se ubican en la carpeta `bootcamp/`
> Ruta base: `/home/epti/Documents/epti-dev/bc-channel/bc-ssh/bootcamp/`

Cada semana DEBE seguir esta estructura exacta:

```
bootcamp/
└── week-XX-tema_principal/
├── README.md                    # 📋 Índice principal de la semana
├── RUBRICA-EVALUACION.md        # 📊 Criterios de evaluación (100 pts)
│
├── 0-assets/                    # 🎨 Diagramas y recursos visuales
│   ├── README.md
│   └── *.svg (numerados 01-, 02-, etc.)
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
│   ├── README.md
│   ├── GUIA-IMPLEMENTACION.md
│   └── EJEMPLOS-CONFIGS.md
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
│   ├── ebooks-free/
│   ├── videografia/
│   └── webgrafia/
│
└── 5-glosario/                  # 📖 Terminología SSH
    └── README.md                # 30-40 términos técnicos
```

---

## 📚 Contenido por Semanas

### Semana 1: Fundamentos de SSH y Primera Conexión

- **Objetivo**: Comprender qué es SSH y realizar la primera conexión exitosa
- **Teoría**: Historia SSH, arquitectura cliente-servidor, criptografía básica
- **Prácticas**: Instalación cliente SSH, primera conexión, archivo `~/.ssh/config`

### Semana 2: Autenticación con Llaves SSH

- **Objetivo**: Dominar autenticación con criptografía de llave pública/privada
- **Teoría**: Contraseña vs llaves, RSA/Ed25519, anatomía de llaves
- **Prácticas**: Generación de llaves, `ssh-copy-id`, autenticación multi-factor

### Semana 3: Configuración Avanzada del Cliente SSH

- **Objetivo**: Optimizar experiencia con configuración avanzada
- **Teoría**: Archivo `~/.ssh/config`, timeouts, ProxyJump/ProxyCommand
- **Prácticas**: Aliases, ProxyJump, multiplexing

### Semana 4: Transferencia de Archivos (SCP, SFTP, rsync)

- **Objetivo**: Dominar herramientas de transferencia segura
- **Teoría**: Diferencias SCP/SFTP/rsync, sincronización incremental
- **Prácticas**: SCP básico, sesión SFTP, rsync sobre SSH

### Semana 5: Configuración del Servidor SSH (sshd)

- **Objetivo**: Configurar y endurecer la seguridad del servidor SSH
- **Teoría**: `sshd_config`, directivas de seguridad, logs y auditoría
- **Prácticas**: Cambiar puerto, deshabilitar root, AllowUsers/DenyUsers

### Semana 6: Port Forwarding y Túneles SSH

- **Objetivo**: Crear túneles seguros entre redes
- **Teoría**: Local (-L), Remote (-R), Dynamic (-D) port forwarding
- **Prácticas**: Túnel a base de datos, exponer servicio local, SOCKS proxy

### Semana 7: SSH Agent y Gestión de Llaves

- **Objetivo**: Gestionar múltiples llaves de forma eficiente
- **Teoría**: ssh-agent, agent forwarding, limitaciones de seguridad
- **Prácticas**: ssh-add, agent forwarding, llaves con passphrase

### Semana 8: Bastion Hosts y Arquitecturas de Acceso

- **Objetivo**: Implementar arquitecturas con servidores bastion/jump
- **Teoría**: Bastion hosts, DMZ, ProxyJump vs ProxyCommand
- **Prácticas**: Configurar bastion, ProxyJump, rotación de llaves

### Semana 9: Automatización con SSH (Scripts y Ansible)

- **Objetivo**: Automatizar tareas administrativas usando SSH
- **Teoría**: Comandos remotos, Ansible, deployments/backups
- **Prácticas**: Scripts remotos, playbooks Ansible, rolling deployment

### Semana 10: Seguridad Avanzada y Auditoría

- **Objetivo**: Implementar seguridad avanzada y monitoreo
- **Teoría**: 2FA, análisis de logs, hardening avanzado
- **Prácticas**: Google Authenticator, fail2ban, alertas automáticas
- **Proyecto Final Integrador**: Infraestructura completa DevOps Corp

---

## 📝 Convenciones de Nomenclatura

### Archivos

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

---

## 📊 Sistema de Evaluación

### Distribución por Semana (100 pts)

| Componente | Peso | Puntos              |
| ---------- | ---- | ------------------- |
| Teoría     | 20%  | 20 pts              |
| Prácticas  | 30%  | 30 pts (10 pts c/u) |
| Proyecto   | 50%  | 50 pts              |

### Rúbrica de Proyecto (50 pts)

| Criterio               | Puntos |
| ---------------------- | ------ |
| Funcionalidad Completa | 20 pts |
| Seguridad              | 10 pts |
| Documentación          | 10 pts |
| Código Limpio          | 5 pts  |
| Creatividad/Extras     | 5 pts  |

### Escala de Calificación

| Rango  | Nivel           |
| ------ | --------------- |
| 90-100 | 🏆 Excelente    |
| 80-89  | 🌟 Muy Bueno    |
| 70-79  | ✅ Bueno        |
| 60-69  | ⚠️ Suficiente   |
| 0-59   | ❌ Insuficiente |

### Indicadores de Dificultad en Prácticas

- ⭐ Básico (30 min)
- ⭐⭐ Intermedio (30 min)
- ⭐⭐⭐ Avanzado (30 min)

---

## 🎨 Formato de READMEs

Todos los READMEs DEBEN seguir este formato:

1. **Título con emoji** relevante
2. **Badges** (tecnología, nivel, duración) usando shields.io
3. **Descripción general** (2-3 párrafos)
4. **Objetivos de aprendizaje** (formato checkbox)
5. **Contenido principal** (secciones organizadas)
6. **Enlaces** a otros documentos relacionados
7. **Navegación** (anterior/siguiente)

### Ejemplo de Badges

```markdown
![SSH](https://img.shields.io/badge/SSH-OpenSSH-red?style=for-the-badge&logo=openssh)
![Nivel](https://img.shields.io/badge/Nivel-Principiante-green?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-4_horas-blue?style=for-the-badge)
```

---

## 💻 Tecnologías y Herramientas del Bootcamp

### Software Requerido

**Cliente SSH:**

- OpenSSH (Linux/macOS nativo)
- PuTTY (Windows alternativo)
- Windows OpenSSH Client (Windows 10+)

**Servidores para Prácticas:**

- VPS: DigitalOcean, AWS, Linode
- Máquinas virtuales: VirtualBox, VMware
- Contenedores Docker con SSH habilitado

**Herramientas Complementarias:**

- fail2ban: Protección contra brute force
- Ansible: Automatización de configuraciones
- rsync: Sincronización de archivos
- ssh-agent: Gestión de llaves
- Google Authenticator: 2FA

### Sistemas Operativos Soportados

**Clientes:**

- Linux (Ubuntu 20.04+, Fedora, Debian)
- macOS (cualquier versión reciente)
- Windows 10+ (con WSL2 recomendado)

**Servidores:**

- Ubuntu Server 22.04 LTS (recomendado)
- Debian 11+
- CentOS/Rocky Linux 8+

---

## 🎓 Principios Pedagógicos

### Metodología TELL-SHOW-DO-APPLY

1. **TELL** (Teoría - 1h): 3 módulos teóricos de 20 min c/u
2. **SHOW** (Demostración): Código de ejemplo ejecutable
3. **DO** (Prácticas - 1.5h): 3 ejercicios progresivos
4. **APPLY** (Proyecto - 1.5h): Integración de conceptos

### Progresión Scaffolding

- **Semanas 1-3**: Soporte completo con comandos exactos
- **Semanas 4-7**: Soporte parcial con guías conceptuales
- **Semanas 8-10**: Autonomía con documentación de referencia

### Principios Clave

- **75% del tiempo es práctica** (3 de 4 horas)
- La teoría siempre va acompañada de **ejemplos ejecutables**
- Proyectos basados en **casos de uso reales del mercado**
- Los **errores son parte del aprendizaje**
- Cada semana **construye sobre la anterior**

---

## ✅ Checklist de Contenido por Semana

Al generar contenido para una semana, asegurar:

- [ ] README principal con todos los enlaces
- [ ] Rúbrica de evaluación (100 pts)
- [ ] 3 módulos teóricos (20 min c/u)
- [ ] 3 prácticas progresivas (30 min c/u)
- [ ] 1 proyecto integrador (1.5h)
- [ ] 8 archivos de recursos mínimo
- [ ] Glosario de 30-40 términos
- [ ] Diagramas SVG necesarios

---

## 📖 Referencias Oficiales

### Documentación

- OpenSSH Manual: https://www.openssh.com/manual.html
- SSH Protocol RFC: https://www.rfc-editor.org/rfc/rfc4251.html
- SSH Academy: https://www.ssh.com/academy/ssh

### Comunidades

- r/sysadmin (Reddit)
- ServerFault (Stack Exchange)

### Canales YouTube Recomendados

- NetworkChuck
- Learn Linux TV
- TechWorld with Nana
- Jeff Geerling (Ansible)

---

## 🚀 Instrucciones para Copilot

### Al generar contenido de teoría:

1. Incluir ejemplos de comandos SSH ejecutables y comentados
2. Usar analogías para explicar conceptos de criptografía
3. Incluir diagramas ASCII cuando sea útil
4. Mantener módulos de máximo 20 minutos de lectura

### Al generar prácticas:

1. Incluir prerequisitos claros
2. Proporcionar comandos paso a paso con explicaciones
3. Incluir sección de troubleshooting para errores comunes
4. Usar el sistema de dificultad ⭐⭐⭐

### Al generar proyectos:

1. Definir especificaciones claras y medibles
2. Incluir guía de implementación paso a paso
3. Proporcionar ejemplos de configuración de referencia
4. Incluir criterios de evaluación específicos

### Al generar glosarios:

1. Incluir 30-40 términos técnicos relevantes
2. Cada término debe tener ejemplo de uso o comando
3. Organizar alfabéticamente
4. Incluir referencias cruzadas entre términos relacionados

### Idioma y Estilo:

- Todo el contenido debe estar en **español**
- Usar lenguaje técnico preciso pero accesible
- Tutear al estudiante (tú, no usted)
- Mantener tono motivacional y práctico

### ⚠️ Límites de Respuesta:

- **SIEMPRE dividir las respuestas** para evitar superar los límites de tokens
- Crear archivos de uno en uno o en grupos pequeños (máximo 3-4 archivos por respuesta)
- Si se solicita crear una semana completa, dividir en múltiples respuestas:
  1. Primera respuesta: README.md + RUBRICA-EVALUACION.md
  2. Segunda respuesta: 1-teoria/ (3 módulos)
  3. Tercera respuesta: 2-practicas/ (3 prácticas)
  4. Cuarta respuesta: 3-proyecto/ + 4-recursos/
  5. Quinta respuesta: 5-glosario/
- Preguntar al usuario si desea continuar antes de cada bloque

---

<div align="center">

**🔐 Bootcamp SSH: De Zero a Hero**

_Versión 1.0 | 10 semanas | 40 horas totales_

</div>
