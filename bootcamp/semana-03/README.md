# 🔧 Semana 03: Configuración Avanzada del Cliente SSH

![SSH](https://img.shields.io/badge/SSH-OpenSSH-red?style=for-the-badge&logo=openssh)
![Nivel](https://img.shields.io/badge/Nivel-Intermedio-yellow?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-4_horas-blue?style=for-the-badge)

## 📋 Descripción General

Esta semana nos sumergimos en el **archivo de configuración del cliente SSH** (`~/.ssh/config`), una herramienta fundamental que transformará tu experiencia con SSH. Aprenderás a crear aliases para tus servidores, configurar saltos a través de bastiones con **ProxyJump**, y optimizar conexiones con **multiplexing**.

El archivo `~/.ssh/config` es donde los administradores de sistemas profesionales guardan su productividad. En lugar de recordar IPs, puertos, usuarios y opciones para cada servidor, defines todo una vez y conectas con un simple `ssh nombre-servidor`.

Al finalizar esta semana, tendrás un archivo de configuración SSH profesional que te ahorrará horas de trabajo y reducirá errores de conexión.

---

## 🎯 Objetivos de Aprendizaje

Al completar esta semana, serás capaz de:

- [ ] Dominar la sintaxis y estructura del archivo `~/.ssh/config`
- [ ] Crear aliases y configuraciones personalizadas por host
- [ ] Implementar conexiones a través de servidores intermedios (ProxyJump)
- [ ] Configurar multiplexing para reutilizar conexiones SSH
- [ ] Usar wildcards y patrones para configuraciones grupales
- [ ] Optimizar timeouts y keep-alives para conexiones estables
- [ ] Gestionar múltiples identidades (llaves) por servidor

---

## 📚 Contenido de la Semana

### 1️⃣ Teoría (1 hora)

| Módulo                                         | Tema                        | Duración |
| ---------------------------------------------- | --------------------------- | -------- |
| [01](1-teoria/01-archivo-ssh-config.md)        | El Archivo ~/.ssh/config    | 20 min   |
| [02](1-teoria/02-proxyjump-proxycommand.md)    | ProxyJump y ProxyCommand    | 20 min   |
| [03](1-teoria/03-multiplexing-optimizacion.md) | Multiplexing y Optimización | 20 min   |

### 2️⃣ Prácticas (1.5 horas)

| Práctica                                         | Descripción                    | Dificultad | Duración |
| ------------------------------------------------ | ------------------------------ | ---------- | -------- |
| [01](2-practicas/practica-01-aliases-basicos.md) | Aliases y Configuración Básica | ⭐         | 30 min   |
| [02](2-practicas/practica-02-proxyjump.md)       | Conexiones con ProxyJump       | ⭐⭐       | 30 min   |
| [03](2-practicas/practica-03-multiplexing.md)    | Multiplexing y Control Master  | ⭐⭐⭐     | 30 min   |

### 3️⃣ Proyecto Semanal (1.5 horas)

| Documento                                  | Descripción                     |
| ------------------------------------------ | ------------------------------- |
| [README](3-proyecto/README.md)             | Configuración SSH Multi-Entorno |
| [Guía](3-proyecto/GUIA-IMPLEMENTACION.md)  | Implementación paso a paso      |
| [Ejemplos](3-proyecto/EJEMPLOS-CONFIGS.md) | Configuraciones de referencia   |

### 4️⃣ Recursos Adicionales

| Recurso                                                           | Descripción            |
| ----------------------------------------------------------------- | ---------------------- |
| [Videos Conceptuales](4-recursos/videos/01-videos-conceptos.md)   | Teoría en video        |
| [Videos Prácticos](4-recursos/videos/02-videos-practicos.md)      | Tutoriales paso a paso |
| [Artículos](4-recursos/webgrafia/03-articulos-ssh.md)             | Lecturas recomendadas  |
| [Documentación](4-recursos/webgrafia/04-documentacion-oficial.md) | Docs oficiales         |
| [Herramientas](4-recursos/herramientas/05-herramientas-ssh.md)    | Software útil          |
| [Playgrounds](4-recursos/webgrafia/06-playgrounds-online.md)      | Práctica online        |
| [Comunidades](4-recursos/webgrafia/07-comunidades-sysadmin.md)    | Foros y grupos         |
| [YouTube](4-recursos/webgrafia/08-canales-youtube.md)             | Canales recomendados   |

### 5️⃣ Glosario

| Documento                        | Descripción                       |
| -------------------------------- | --------------------------------- |
| [Glosario](5-glosario/README.md) | 30+ términos de configuración SSH |

---

## 🗂️ Estructura de Archivos

```
semana-03/
├── README.md                          # Este archivo
├── RUBRICA-EVALUACION.md              # Criterios de evaluación
│
├── 0-assets/                          # Diagramas y recursos visuales
│   ├── README.md
│   ├── 01-estructura-ssh-config.svg
│   ├── 02-flujo-proxyjump.svg
│   └── 03-multiplexing-diagram.svg
│
├── 1-teoria/                          # Módulos teóricos
│   ├── README.md
│   ├── 01-archivo-ssh-config.md
│   ├── 02-proxyjump-proxycommand.md
│   └── 03-multiplexing-optimizacion.md
│
├── 2-practicas/                       # Ejercicios prácticos
│   ├── README.md
│   ├── practica-01-aliases-basicos.md
│   ├── practica-02-proxyjump.md
│   └── practica-03-multiplexing.md
│
├── 3-proyecto/                        # Proyecto integrador
│   ├── README.md
│   ├── GUIA-IMPLEMENTACION.md
│   └── EJEMPLOS-CONFIGS.md
│
├── 4-recursos/                        # Material complementario
│   ├── README.md
│   ├── videos/
│   ├── webgrafia/
│   ├── herramientas/
│   ├── ebooks-free/
│   └── videografia/
│
└── 5-glosario/                        # Terminología
    └── README.md
```

---

## 🔗 Prerequisitos

Antes de iniciar esta semana, asegúrate de:

- ✅ Haber completado [Semana 01: Fundamentos de SSH](../semana-01/README.md)
- ✅ Haber completado [Semana 02: Autenticación con Llaves](../semana-02/README.md)
- ✅ Tener al menos un par de llaves SSH generadas
- ✅ Tener acceso a al menos un servidor remoto (o VM/contenedor)
- ✅ Conocer los comandos básicos de SSH

---

## ⏱️ Distribución del Tiempo

```
Semana 03 (4 horas totales)
├── Teoría ████████░░░░░░░░░░░░ 25% (1h)
├── Prácticas ██████████████░░░░ 37.5% (1.5h)
└── Proyecto ██████████████░░░░ 37.5% (1.5h)
```

---

## 🧭 Navegación

| ⬅️ Anterior                                                   |          🏠 Inicio           |                                                   Siguiente ➡️ |
| :------------------------------------------------------------ | :--------------------------: | -------------------------------------------------------------: |
| [Semana 02: Autenticación con Llaves](../semana-02/README.md) | [Bootcamp SSH](../README.md) | [Semana 04: Transferencia de Archivos](../semana-04/README.md) |

---

<div align="center">

**🔧 Semana 03: Configuración Avanzada del Cliente SSH**

_Transforma tu productividad con ~/.ssh/config_

</div>
