# 📦 Semana 04: Transferencia de Archivos

## SCP, SFTP y rsync sobre SSH

![SSH](https://img.shields.io/badge/SSH-OpenSSH-red?style=for-the-badge&logo=openssh)
![Nivel](https://img.shields.io/badge/Nivel-Intermedio-yellow?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-4_horas-blue?style=for-the-badge)

---

## 📋 Descripción General

Esta semana dominarás las **tres herramientas fundamentales** para transferir archivos de forma segura sobre SSH: **SCP** para copias rápidas, **SFTP** para sesiones interactivas, y **rsync** para sincronización inteligente e incremental.

Cada herramienta tiene su lugar en el arsenal de un administrador de sistemas. SCP es perfecto para copiar un archivo rápidamente, SFTP brilla cuando necesitas navegar y explorar antes de transferir, y rsync es imbatible para backups y sincronización de grandes volúmenes de datos.

Al finalizar esta semana, sabrás exactamente cuándo usar cada herramienta y cómo optimizar transferencias para diferentes escenarios.

---

## 🎯 Objetivos de Aprendizaje

Al completar esta semana, serás capaz de:

- [ ] Transferir archivos con SCP en ambas direcciones (local↔remoto)
- [ ] Manejar sesiones interactivas SFTP con comandos avanzados
- [ ] Sincronizar directorios con rsync de forma incremental
- [ ] Usar rsync sobre SSH para backups seguros
- [ ] Optimizar transferencias con compresión y límites de ancho de banda
- [ ] Automatizar backups con scripts y cron
- [ ] Elegir la herramienta correcta según el caso de uso

---

## 📚 Contenido de la Semana

### 1️⃣ Teoría (1 hora)

| Módulo                                    | Tema                              | Duración |
| ----------------------------------------- | --------------------------------- | -------- |
| [01](1-teoria/01-scp-fundamentos.md)      | SCP: Secure Copy                  | 20 min   |
| [02](1-teoria/02-sftp-sesiones.md)        | SFTP: Sesiones Interactivas       | 20 min   |
| [03](1-teoria/03-rsync-sincronizacion.md) | rsync: Sincronización Inteligente | 20 min   |

### 2️⃣ Prácticas (1.5 horas)

| Práctica                                          | Descripción            | Dificultad | Duración |
| ------------------------------------------------- | ---------------------- | ---------- | -------- |
| [01](2-practicas/practica-01-scp-basico.md)       | Transferencias con SCP | ⭐         | 30 min   |
| [02](2-practicas/practica-02-sftp-interactivo.md) | Sesiones SFTP          | ⭐⭐       | 30 min   |
| [03](2-practicas/practica-03-rsync-backups.md)    | Backups con rsync      | ⭐⭐⭐     | 30 min   |

### 3️⃣ Proyecto Semanal (1.5 horas)

| Documento                                  | Descripción                    |
| ------------------------------------------ | ------------------------------ |
| [README](3-proyecto/README.md)             | Sistema de Backup Automatizado |
| [Guía](3-proyecto/GUIA-IMPLEMENTACION.md)  | Implementación paso a paso     |
| [Ejemplos](3-proyecto/EJEMPLOS-CONFIGS.md) | Scripts y configuraciones      |

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

| Documento                        | Descripción                               |
| -------------------------------- | ----------------------------------------- |
| [Glosario](5-glosario/README.md) | 35+ términos de transferencia de archivos |

---

## 🗂️ Estructura de Archivos

```
week-06-transferencia_archivos_scp_sftp_rsync/
├── README.md
├── RUBRICA-EVALUACION.md
│
├── 0-assets/
│   ├── README.md
│   ├── 01-comparativa-herramientas.svg
│   ├── 02-flujo-rsync.svg
│   └── 03-arquitectura-backup.svg
│
├── 1-teoria/
│   ├── README.md
│   ├── 01-scp-fundamentos.md
│   ├── 02-sftp-sesiones.md
│   └── 03-rsync-sincronizacion.md
│
├── 2-practicas/
│   ├── README.md
│   ├── practica-01-scp-basico.md
│   ├── practica-02-sftp-interactivo.md
│   └── practica-03-rsync-backups.md
│
├── 3-proyecto/
│   ├── README.md
│   ├── GUIA-IMPLEMENTACION.md
│   └── EJEMPLOS-CONFIGS.md
│
├── 4-recursos/
│   ├── README.md
│   ├── videos/
│   ├── webgrafia/
│   ├── herramientas/
│   ├── ebooks-free/
│   └── videografia/
│
└── 5-glosario/
    └── README.md
```

---

## 🔗 Prerequisitos

Antes de iniciar esta semana, asegúrate de:

- ✅ Haber completado [Semana 01: Fundamentos de SSH](../week-01-fundamentos_ssh_y_primera_conexion/README.md)
- ✅ Haber completado [Semana 02: Autenticación con Llaves](../week-03-autenticacion_con_llaves_ssh/README.md)
- ✅ Haber completado [Semana 03: Configuración Avanzada](../week-05-configuracion_avanzada_cliente_ssh/README.md)
- ✅ Tener acceso a al menos un servidor remoto
- ✅ Tener archivos de prueba para transferir

---

## ⚖️ Comparativa de Herramientas

| Característica        | SCP               | SFTP               | rsync          |
| --------------------- | ----------------- | ------------------ | -------------- |
| **Uso principal**     | Copia rápida      | Sesión interactiva | Sincronización |
| **Incremental**       | ❌                | ❌                 | ✅             |
| **Interactivo**       | ❌                | ✅                 | ❌             |
| **Resume**            | ❌                | ✅                 | ✅             |
| **Compresión**        | ❌                | ❌                 | ✅             |
| **Preserva permisos** | ✅                | ✅                 | ✅             |
| **Ideal para**        | Archivos pequeños | Exploración        | Backups        |

---

## ⏱️ Distribución del Tiempo

```
Semana 04 (4 horas totales)
├── Teoría ████████░░░░░░░░░░░░ 25% (1h)
├── Prácticas ██████████████░░░░ 37.5% (1.5h)
└── Proyecto ██████████████░░░░ 37.5% (1.5h)
```

---

## 🧭 Navegación

| ⬅️ Anterior                                                 |          🏠 Inicio           |                                      Siguiente ➡️ |
| :---------------------------------------------------------- | :--------------------------: | ------------------------------------------------: |
| [Semana 03: Configuración Avanzada](../week-05-configuracion_avanzada_cliente_ssh/README.md) | [Bootcamp SSH](../README.md) | [Semana 05: Servidor SSH](../week-07-configuracion_servidor_ssh/README.md) |

---

<div align="center">

**📦 Semana 04: Transferencia de Archivos**

_Domina SCP, SFTP y rsync_

</div>
