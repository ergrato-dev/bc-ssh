# 🔨 Proyecto Semanal: Configuración SSH Multi-Entorno

## Semana 03 - Proyecto Integrador

![Proyecto](https://img.shields.io/badge/Proyecto-50_puntos-gold?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-1.5_horas-blue?style=for-the-badge)

---

## 📋 Descripción del Proyecto

En este proyecto crearás una **configuración SSH profesional completa** que gestione múltiples entornos (desarrollo, staging, producción) con diferentes niveles de seguridad, acceso mediante bastiones, y optimizaciones de multiplexing.

Simularás el escenario de una empresa con infraestructura distribuida:

- **Desarrollo**: Acceso directo, configuración flexible
- **Staging**: Acceso vía bastion, seguridad media
- **Producción**: Acceso vía bastion con 2FA conceptual, máxima seguridad

---

## 🎯 Objetivos del Proyecto

Al completar este proyecto, habrás demostrado capacidad para:

- [ ] Diseñar una configuración SSH modular y mantenible
- [ ] Implementar diferentes niveles de seguridad por entorno
- [ ] Configurar acceso a través de bastiones con ProxyJump
- [ ] Optimizar conexiones con multiplexing
- [ ] Documentar configuraciones para equipos

---

## 🏗️ Arquitectura del Proyecto

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           TU ESTACIÓN DE TRABAJO                         │
│                         ~/.ssh/config (completo)                         │
└──────────────────────────────────┬──────────────────────────────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
          ▼                        ▼                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   DESARROLLO    │     │    STAGING      │     │   PRODUCCIÓN    │
│   (Directo)     │     │  (vía Bastion)  │     │ (vía Bastion)   │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ dev-web         │     │ bastion-stg ────┼──┐  │ bastion-prod ───┼──┐
│ dev-db          │     │                 │  │  │                 │  │
│ dev-cache       │     │  stg-web ◄──────┼──┘  │  prod-web ◄─────┼──┘
└─────────────────┘     │  stg-db  ◄──────┼──┘  │  prod-db  ◄─────┼──┘
                        │  stg-cache ◄────┼──┘  │  prod-cache ◄───┼──┘
                        └─────────────────┘     └─────────────────┘
```

---

## 📝 Especificaciones Técnicas

### Entorno de Desarrollo

| Host        | IP/Hostname   | Usuario   | Puerto |
| ----------- | ------------- | --------- | ------ |
| `dev-web`   | 192.168.10.10 | developer | 22     |
| `dev-db`    | 192.168.10.20 | developer | 22     |
| `dev-cache` | 192.168.10.30 | developer | 22     |

**Características:**

- Acceso directo (sin bastion)
- Llave: `~/.ssh/id_ed25519_dev`
- StrictHostKeyChecking: no (desarrollo)
- Multiplexing: 5 minutos

### Entorno de Staging

| Host          | IP/Hostname             | Usuario  | Puerto |
| ------------- | ----------------------- | -------- | ------ |
| `bastion-stg` | stg-bastion.empresa.com | security | 22     |
| `stg-web`     | 10.20.1.10              | deploy   | 22     |
| `stg-db`      | 10.20.1.20              | dba      | 22     |
| `stg-cache`   | 10.20.1.30              | deploy   | 22     |

**Características:**

- Acceso vía bastion-stg
- Llave para bastion: `~/.ssh/id_ed25519_stg_bastion`
- Llave para internos: `~/.ssh/id_ed25519_stg`
- StrictHostKeyChecking: accept-new
- Multiplexing: 15 minutos

### Entorno de Producción

| Host           | IP/Hostname              | Usuario  | Puerto |
| -------------- | ------------------------ | -------- | ------ |
| `bastion-prod` | prod-bastion.empresa.com | security | 2222   |
| `prod-web`     | 10.30.1.10               | deploy   | 22     |
| `prod-db`      | 10.30.1.20               | dba      | 22     |
| `prod-cache`   | 10.30.1.30               | deploy   | 22     |

**Características:**

- Acceso vía bastion-prod (puerto 2222)
- Llave: `~/.ssh/id_ed25519_prod`
- StrictHostKeyChecking: yes (máxima seguridad)
- Sin ForwardAgent
- Multiplexing: 30 minutos

---

## 📦 Entregables

### 1. Archivo de Configuración Principal

```
~/.ssh/config
```

Debe incluir:

- Configuración global (`Host *`)
- Bastiones de cada entorno
- Servidores de cada entorno con ProxyJump
- Patrones wildcard para grupos
- Comentarios descriptivos

### 2. Estructura Modular (Opcional pero Valorado)

```
~/.ssh/
├── config              # Archivo principal con Include
├── config.d/
│   ├── 00-global.conf
│   ├── 10-desarrollo.conf
│   ├── 20-staging.conf
│   └── 30-produccion.conf
└── sockets/            # Directorio para multiplexing
```

### 3. Documentación

- README explicando la configuración
- Guía de troubleshooting
- Comandos de verificación

---

## ✅ Criterios de Evaluación (50 pts)

| Categoría         | Puntos | Criterios                                                   |
| ----------------- | ------ | ----------------------------------------------------------- |
| **Funcionalidad** | 20 pts | Todos los hosts accesibles, ProxyJump funcional             |
| **Seguridad**     | 10 pts | Permisos correctos, llaves separadas, StrictHostKeyChecking |
| **Documentación** | 10 pts | Comentarios, README, troubleshooting                        |
| **Código Limpio** | 5 pts  | Organización, consistencia, sin redundancia                 |
| **Extras**        | 5 pts  | Include, scripts, automatización                            |

---

## 📚 Recursos

| Recurso                                                             | Descripción           |
| ------------------------------------------------------------------- | --------------------- |
| [Guía de Implementación](GUIA-IMPLEMENTACION.md)                    | Paso a paso detallado |
| [Ejemplos de Configuración](EJEMPLOS-CONFIGS.md)                    | Configs de referencia |
| [Teoría: ~/.ssh/config](../1-teoria/01-archivo-ssh-config.md)       | Fundamentos           |
| [Teoría: ProxyJump](../1-teoria/02-proxyjump-proxycommand.md)       | Bastiones             |
| [Teoría: Multiplexing](../1-teoria/03-multiplexing-optimizacion.md) | Optimización          |

---

## ⏱️ Distribución del Tiempo Sugerida

| Fase           | Tiempo | Actividad                         |
| -------------- | ------ | --------------------------------- |
| Planificación  | 15 min | Diseñar estructura, definir hosts |
| Implementación | 45 min | Crear configuración               |
| Testing        | 20 min | Probar conexiones                 |
| Documentación  | 10 min | README y comentarios              |

---

## 🧭 Navegación

| ⬅️ Anterior                           |         🏠 Índice         |                                     Siguiente ➡️ |
| :------------------------------------ | :-----------------------: | -----------------------------------------------: |
| [Prácticas](../2-practicas/README.md) | [Semana 03](../README.md) | [Guía de Implementación](GUIA-IMPLEMENTACION.md) |

---

<div align="center">

**🔨 Proyecto: Configuración SSH Multi-Entorno**

_Infraestructura profesional_

</div>
