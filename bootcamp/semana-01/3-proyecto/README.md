# 🔨 Proyecto Integrador - Semana 01

![Proyecto](https://img.shields.io/badge/Proyecto-Integrador-purple?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-1.5_horas-blue?style=for-the-badge)
![Puntos](https://img.shields.io/badge/Puntos-50-orange?style=for-the-badge)

---

## 🎯 Título: Gestión Centralizada de Conexiones SSH

### Descripción

En este proyecto integrador, aplicarás todo lo aprendido en la Semana 01 para crear una configuración SSH profesional que te permita gestionar múltiples servidores de forma eficiente.

Simularás ser un administrador de sistemas junior que acaba de unirse a una empresa y necesita configurar su entorno de trabajo para acceder a la infraestructura de servidores.

---

## 📋 Escenario

**Empresa:** TechStartup S.A.  
**Rol:** Administrador de Sistemas Junior  
**Tarea:** Configurar acceso SSH a la infraestructura

La empresa tiene los siguientes servidores:

| Servidor | Función | IP | Puerto | Usuario |
|----------|---------|-----|--------|---------|
| **web-prod** | Servidor web producción | Tu VPS real | 22 | root |
| **web-staging** | Servidor web staging | 10.0.1.10 | 22 | deploy |
| **db-prod** | Base de datos producción | 10.0.1.20 | 22 | dba |
| **monitoring** | Servidor de monitoreo | 10.0.1.30 | 2222 | monitor |

> **Nota:** Usa tu servidor VPS real para `web-prod`. Los demás son ficticios para practicar la sintaxis del archivo config.

---

## 🎯 Objetivos del Proyecto

Al completar este proyecto, habrás:

1. ✅ Verificado la instalación correcta de OpenSSH
2. ✅ Establecido conexión exitosa a un servidor real
3. ✅ Creado un archivo `~/.ssh/config` profesional
4. ✅ Documentado todo el proceso en un README personal
5. ✅ Capturado evidencias de cada paso

---

## 📦 Entregables

### 1. Archivo de Configuración SSH
`~/.ssh/config` con al menos 4 hosts configurados

### 2. Documentación Personal
`README.md` con:
- Datos de tus servidores (censurados)
- Comandos utilizados
- Capturas de pantalla
- Problemas encontrados y soluciones

### 3. Evidencias
- Captura de `ssh -V`
- Captura de conexión exitosa
- Captura de `cat ~/.ssh/config` (censurado)
- Captura de `ssh -G alias` para verificar configuración

---

## 📊 Rúbrica de Evaluación (50 puntos)

| Criterio | Puntos | Descripción |
|----------|--------|-------------|
| **Funcionalidad** | 20 pts | Conexión SSH exitosa + config funcional |
| **Configuración** | 10 pts | Archivo config con 4+ hosts bien estructurado |
| **Documentación** | 10 pts | README claro con comandos y explicaciones |
| **Evidencias** | 5 pts | Capturas de pantalla de cada paso |
| **Organización** | 5 pts | Estructura limpia, comentarios en config |

### Escala de Calificación

| Puntos | Nivel |
|--------|-------|
| 45-50 | 🏆 Excelente |
| 40-44 | 🌟 Muy Bueno |
| 35-39 | ✅ Bueno |
| 30-34 | ⚠️ Suficiente |
| 0-29 | ❌ Insuficiente |

---

## 📁 Estructura de Entrega

```
proyecto-semana-01/
├── README.md              # Tu documentación personal
├── ssh-config.txt         # Copia de tu ~/.ssh/config
└── evidencias/
    ├── 01-ssh-version.png
    ├── 02-conexion-exitosa.png
    ├── 03-ssh-config.png
    └── 04-ssh-g-alias.png
```

---

## ⏭️ Recursos

- [📘 Guía de Implementación](GUIA-IMPLEMENTACION.md)
- [📝 Ejemplos de Configuración](EJEMPLOS-CONFIGS.md)

---

<div align="center">

**Semana 01 • Proyecto Integrador**

[← Volver a Prácticas](../2-practicas/README.md) • [Guía de Implementación →](GUIA-IMPLEMENTACION.md)

</div>
