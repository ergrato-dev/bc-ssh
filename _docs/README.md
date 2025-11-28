# 🔐 Semana 1: Fundamentos de SSH y Primera Conexión

![SSH](https://img.shields.io/badge/SSH-OpenSSH-red?style=for-the-badge&logo=openssh)
![Nivel](https://img.shields.io/badge/Nivel-Principiante-green?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-4_horas-blue?style=for-the-badge)
![Prácticas](https://img.shields.io/badge/Prácticas-3-orange?style=for-the-badge)

---

## 📋 Descripción General

Esta primera semana del bootcamp SSH marca el inicio de tu viaje hacia el dominio de la conexión remota segura. Comenzarás comprendiendo qué es SSH, por qué reemplazó a protocolos inseguros como Telnet, y cómo funciona su arquitectura cliente-servidor.

SSH (Secure Shell) es el estándar de facto en la industria para acceder remotamente a servidores, y entenderlo desde sus fundamentos te permitirá trabajar de forma segura con infraestructura cloud, administrar servidores Linux, y automatizar tareas críticas de sistemas.

Al finalizar esta semana, serás capaz de conectarte exitosamente a servidores remotos usando autenticación por contraseña, entenderás los conceptos básicos de criptografía que protegen tus conexiones, y habrás creado tu primer archivo de configuración SSH para simplificar tus conexiones futuras.

---

## 🎯 Objetivos de Aprendizaje

Al completar esta semana, serás capaz de:

- [ ] Explicar qué es SSH y por qué es superior a protocolos como Telnet
- [ ] Describir la arquitectura cliente-servidor de SSH y sus componentes
- [ ] Comprender los conceptos básicos de criptografía simétrica y asimétrica
- [ ] Instalar y configurar el cliente SSH en tu sistema operativo
- [ ] Conectarte a servidores remotos usando usuario y contraseña
- [ ] Crear y configurar el archivo `~/.ssh/config` para gestionar múltiples conexiones
- [ ] Solucionar problemas comunes en conexiones SSH iniciales

---

## ⏱️ Distribución del Tiempo

| Actividad                  | Duración | Porcentaje |
|----------------------------|----------|------------|
| **📚 Teoría**              | 1.0h     | 25%        |
| Módulo 1: Historia y evolución | 20 min   |            |
| Módulo 2: Arquitectura SSH | 20 min   |            |
| Módulo 3: Criptografía básica | 20 min   |            |
| **💻 Prácticas**           | 1.5h     | 37.5%      |
| Práctica 1: Instalación    | 30 min   |            |
| Práctica 2: Primera conexión | 30 min   |            |
| Práctica 3: Archivo config | 30 min   |            |
| **🔨 Proyecto Integrador** | 1.5h     | 37.5%      |
| **TOTAL**                  | **4.0h** | **100%**   |

---

## 📚 Contenido Teórico

| # | Módulo | Temas Clave | Duración |
|---|--------|-------------|----------|
| 1 | [Historia y Evolución](1-teoria/01-historia-evolucion-ssh.md) | Telnet vs SSH, cronología, por qué SSH ganó | 20 min |
| 2 | [Arquitectura Cliente-Servidor](1-teoria/02-arquitectura-cliente-servidor.md) | Componentes, flujo de conexión, puertos | 20 min |
| 3 | [Criptografía Básica](1-teoria/03-criptografia-basica.md) | Simétrica vs asimétrica, cifrado de sesión | 20 min |

**Tiempo total teoría**: 60 minutos

---

## 💻 Prácticas

| # | Práctica | Dificultad | Tiempo | Descripción |
|---|----------|------------|--------|-------------|
| 1 | [Instalación de Cliente SSH](2-practicas/practica-01-instalacion-cliente.md) | ⭐ | 30 min | Instalar OpenSSH en Linux, macOS y Windows |
| 2 | [Primera Conexión Remota](2-practicas/practica-02-primera-conexion.md) | ⭐ | 30 min | Conectar a servidor usando usuario/contraseña |
| 3 | [Configuración Archivo Config](2-practicas/practica-03-archivo-config.md) | ⭐⭐ | 30 min | Crear `~/.ssh/config` para conexiones rápidas |

**Tiempo total prácticas**: 90 minutos

---

## 🔨 Proyecto Integrador

**Título**: Gestión Centralizada de Conexiones SSH

**Descripción**: Conectarte a 3 servidores diferentes (que puedes crear con VPS gratuitos o máquinas virtuales locales) usando un archivo de configuración centralizado que simplifique el acceso. Documentarás cada paso para demostrar comprensión del proceso.

**Archivos del proyecto**:
- [📋 Especificaciones y Requisitos](3-proyecto/README.md)
- [🛠️ Guía de Implementación](3-proyecto/GUIA-IMPLEMENTACION.md)
- [📝 Ejemplos de Configuración](3-proyecto/EJEMPLOS-CONFIGS.md)

**Tiempo estimado**: 90 minutos

**Criterios de éxito**:
- Conexión exitosa a 3 servidores diferentes
- Archivo config funcional con hosts nombrados
- Documentación completa del proceso en README
- Screenshots de conexiones exitosas

---

## 📖 Recursos Complementarios

| # | Tipo | Tema | Enlace |
|---|------|------|--------|
| 1 | 📹 Videos | [Conceptos Fundamentales SSH](4-recursos/01-videos-conceptos.md) | NetworkChuck, Hussein Nasser |
| 2 | 📹 Videos | [Tutoriales Prácticos](4-recursos/02-videos-practicos.md) | Demos paso a paso |
| 3 | 📄 Artículos | [Introducción a SSH](4-recursos/03-articulos-ssh.md) | DigitalOcean, Linode guides |
| 4 | 📚 Documentación | [OpenSSH Official Docs](4-recursos/04-documentacion-oficial.md) | Manual pages, RFC |
| 5 | 🛠️ Herramientas | [Clientes SSH Recomendados](4-recursos/05-herramientas-ssh.md) | PuTTY, iTerm2, etc. |
| 6 | 🎮 Playgrounds | [Entornos de Práctica](4-recursos/06-playgrounds-online.md) | Labs online gratuitos |
| 7 | 👥 Comunidades | [Foros y Grupos](4-recursos/07-comunidades-sysadmin.md) | r/sysadmin, ServerFault |
| 8 | 📺 Canales | [YouTube Channels](4-recursos/08-canales-youtube.md) | Mejores canales DevOps |

---

## 📖 Glosario de la Semana

Consulta el [Glosario Completo](5-glosario/README.md) con 35 términos técnicos de SSH que aprenderás esta semana, incluyendo:

- **SSH**: Secure Shell, protocolo de red criptográfico
- **Telnet**: Protocolo antiguo sin cifrado (inseguro)
- **Cliente SSH**: Programa que inicia conexión (ssh command)
- **Servidor SSH**: Daemon que escucha conexiones (sshd)
- **Puerto 22**: Puerto estándar de SSH
- **Criptografía simétrica**: Mismo key para cifrar/descifrar
- **Criptografía asimétrica**: Par de llaves pública/privada
- Y 28 términos más...

---

## 🎨 Assets y Diagramas

| # | Diagrama | Descripción | Usado en |
|---|----------|-------------|----------|
| 1 | [Telnet vs SSH](0-assets/01-telnet-vs-ssh.svg) | Comparación visual de protocolos | Módulo 1 |
| 2 | [Arquitectura SSH](0-assets/02-arquitectura-ssh.svg) | Cliente → Servidor, componentes | Módulo 2 |
| 3 | [Flujo de Autenticación](0-assets/03-flujo-autenticacion.svg) | Paso a paso del handshake SSH | Módulo 2 |
| 4 | [Criptografía Híbrida](0-assets/04-criptografia-hibrida.svg) | Combinación simétrica + asimétrica | Módulo 3 |

Ver todos los diagramas en [0-assets/README.md](0-assets/README.md)

---

## 📊 Evaluación

Esta semana se evalúa sobre **100 puntos** distribuidos así:

| Componente | Peso | Puntos | Criterios |
|------------|------|--------|-----------|
| **Teoría** | 20% | 20 pts | Comprensión de conceptos fundamentales |
| **Prácticas** | 30% | 30 pts | 10 pts por cada práctica completada |
| **Proyecto** | 50% | 50 pts | Funcionalidad (25) + Documentación (25) |

Ver detalles completos en [RUBRICA-EVALUACION.md](RUBRICA-EVALUACION.md)

**Escala de calificación**:
- 90-100: 🏆 Excelente
- 80-89: 🌟 Muy Bueno
- 70-79: ✅ Bueno
- 60-69: ⚠️ Suficiente
- 0-59: ❌ Insuficiente

---

## ✅ Checklist de Completitud

### Teoría
- [ ] Leído Módulo 1: Historia y evolución
- [ ] Leído Módulo 2: Arquitectura cliente-servidor
- [ ] Leído Módulo 3: Criptografía básica
- [ ] Ejecutados todos los comandos de ejemplo
- [ ] Revisados todos los diagramas

### Prácticas
- [ ] Práctica 1: Cliente SSH instalado y verificado
- [ ] Práctica 2: Conexión exitosa a servidor remoto
- [ ] Práctica 3: Archivo config creado y funcional

### Proyecto
- [ ] Conexión exitosa a 3 servidores diferentes
- [ ] Archivo `~/.ssh/config` configurado correctamente
- [ ] README del proyecto documentado
- [ ] Screenshots de evidencia subidos

### Recursos
- [ ] Revisado al menos 2 videos recomendados
- [ ] Leído al menos 1 artículo complementario
- [ ] Consultado glosario de términos

---

## 🧭 Navegación del Bootcamp

```
┌──────────────────────────────────────────────────┐
│            BOOTCAMP SSH - 10 SEMANAS             │
├──────────────────────────────────────────────────┤
│                                                  │
│  ┏━━━━━━━━━━┓                                   │
│  ┃ SEMANA 1 ┃ → S2 → S3 → S4 → S5              │
│  ┗━━━━━━━━━━┛    ↓                               │
│                  S6 → S7 → S8 → S9 → S10        │
│                                                  │
│  Estás en: Fundamentos SSH y Primera Conexión   │
│  Siguiente: Autenticación con Llaves SSH        │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Progreso general**: █░░░░░░░░░ 10% (Semana 1 de 10)

---

## 💡 Tips de la Semana

### ✅ Buenas Prácticas

1. **Practica en un servidor real**: Aunque puedes usar máquinas virtuales locales, te recomiendo crear un VPS económico (DigitalOcean, Linode, Vultr) por $5/mes. La experiencia con un servidor real en internet es invaluable.

2. **Documenta tus primeros errores**: Los mensajes de error en SSH pueden ser crípticos al inicio. Crea un documento personal donde registres cada error que encuentres y cómo lo resolviste. Te ahorrará tiempo después.

3. **No temas al terminal**: Si vienes de entornos gráficos, el terminal puede intimidar. Recuerda que SSH es fundamentalmente una herramienta de línea de comandos, así que invertir tiempo ahora en sentirte cómodo con bash/terminal dará frutos toda tu carrera.

### ⚠️ Errores Comunes

1. **"Connection refused"**: Generalmente significa que el servidor SSH no está corriendo en el destino, o estás usando el puerto equivocado. Verifica que sshd esté activo: `systemctl status sshd`

2. **"Permission denied"**: Revisa que el usuario exista en el servidor y que la contraseña sea correcta. Este error también aparece si el servidor no permite autenticación por contraseña.

3. **"Host key verification failed"**: Sucede cuando la huella digital del servidor cambió. Si sabes que es seguro, elimina la entrada antigua con: `ssh-keygen -R hostname`

4. **Olvidar especificar usuario**: Si no especificas usuario en la conexión (`ssh servidor.com`), SSH intentará con tu usuario local actual. Siempre especifica: `ssh usuario@servidor.com`

### 🎯 Reto Extra (+5 pts)

Configura tu archivo `~/.ssh/config` para incluir un servidor de "práctica" que automáticamente:
- Use un puerto no estándar (ejemplo: 2222)
- Configure keep-alive para mantener la conexión viva
- Active compresión para ahorrar ancho de banda

Documenta cómo cada opción mejora tu experiencia.

---

## 🔗 Enlaces Rápidos

### Documentación Oficial
- [OpenSSH Manual](https://www.openssh.com/manual.html)
- [SSH Config File Syntax](https://linux.die.net/man/5/ssh_config)
- [SSH Command Manual](https://linux.die.net/man/1/ssh)

### Tutoriales Recomendados
- [DigitalOcean SSH Essentials](https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys)
- [SSH Academy - Basics](https://www.ssh.com/academy/ssh)

### Herramientas Útiles
- [MobaXterm](https://mobaxterm.mobatek.net/) - Cliente SSH completo para Windows
- [iTerm2](https://iterm2.com/) - Terminal avanzado para macOS
- [Windows Terminal](https://github.com/microsoft/terminal) - Terminal moderno de Microsoft

### Comunidades
- [r/sysadmin](https://reddit.com/r/sysadmin)
- [ServerFault](https://serverfault.com/)
- [Unix & Linux Stack Exchange](https://unix.stackexchange.com/)

---

## 🚀 Preparación para la Siguiente Semana

La **Semana 2** tratará sobre **Autenticación con Llaves SSH**, donde aprenderás:

- Cómo funciona la criptografía de llave pública/privada
- Generación de pares de llaves SSH (RSA, Ed25519, ECDSA)
- Instalación de llaves públicas en servidores remotos
- Desactivación de autenticación por contraseña para mayor seguridad

**Para prepararte**:
- Asegúrate de tener acceso a al menos un servidor remoto
- Verifica que puedes conectarte exitosamente con contraseña
- Lee sobre el concepto de criptografía asimétrica (opcional pero útil)

---

## 📞 Soporte y Ayuda

### ¿Tienes Problemas?

1. **Revisa el glosario**: Muchas dudas se resuelven entendiendo la terminología correcta
2. **Consulta los recursos**: Los videos y artículos cubren casos de uso comunes
3. **Revisa los errores comunes**: La sección "Errores Comunes" arriba tiene soluciones rápidas
4. **Pregunta en comunidad**: Los foros de r/sysadmin y ServerFault son muy activos

### Contacto del Instructor

- **Email**: bootcamp-ssh@ejemplo.com
- **Horario de consultas**: Martes y Jueves 18:00-20:00 COT
- **Foro privado**: [Discord del Bootcamp](#)

---

## 📝 Notas del Instructor

Esta primera semana es crucial para establecer bases sólidas. No te apresures a terminar todo en una sesión. Es mejor dedicar 60 minutos al día durante 4 días que intentar completar las 4 horas de corrido.

SSH es una herramienta que se aprende USÁNDOLA. Por cada concepto teórico que leas, asegúrate de ejecutar los comandos de ejemplo. Rompe cosas, equivócate, investiga mensajes de error. Esta es la única forma real de aprender.

Recuerda: incluso los administradores de sistemas más experimentados siguen consultando manual pages de SSH regularmente. No hay vergüenza en no saber algo; la vergüenza está en no querer aprenderlo.

¡Éxito en tu primera semana!

---

<div align="center">

### 🔐 Semana 1: Fundamentos de SSH y Primera Conexión

**⬅️ Inicio del Bootcamp** | **[Semana 2: Autenticación con Llaves →](../semana-02/README.md)**

---

**Bootcamp SSH: De Zero a Hero** | Semana 1 de 10

© 2025 BC Channel EPTI | Todos los derechos reservados

</div>
