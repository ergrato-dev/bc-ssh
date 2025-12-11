# 🔨 Proyecto Semana 04

## Sistema de Sincronización Multi-Entorno

![Proyecto](https://img.shields.io/badge/Proyecto-Integrador-gold?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-1.5_horas-blue?style=for-the-badge)
![Puntos](https://img.shields.io/badge/Puntos-50_pts-green?style=for-the-badge)

---

## 📋 Descripción

En este proyecto implementarás un **sistema de sincronización automatizado** para gestionar transferencias entre múltiples entornos: desarrollo local, servidor de staging y producción.

Crearás scripts que automaticen:

- Despliegue de código a servidores
- Backups incrementales automatizados
- Sincronización de configuraciones

---

## 🎯 Objetivos de Aprendizaje

Al completar este proyecto:

- [ ] Implementar estrategias de transferencia apropiadas (SCP, SFTP, rsync)
- [ ] Crear scripts de automatización robustos
- [ ] Diseñar sistema de backups incrementales
- [ ] Documentar procesos de sincronización

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    WORKSTATION LOCAL                        │
│  ~/proyecto-web/                                            │
│  ├── src/           ← Código fuente                        │
│  ├── config/        ← Configuraciones                      │
│  └── scripts/       ← Scripts de sincronización            │
└─────────────────────────────────────────────────────────────┘
              │                          │
              │ deploy-staging.sh        │ deploy-prod.sh
              ▼                          ▼
┌─────────────────────────┐    ┌─────────────────────────┐
│   SERVIDOR STAGING      │    │   SERVIDOR PRODUCCIÓN   │
│                         │    │                         │
│  ~/staging/             │    │  ~/production/          │
│  ├── app/              │    │  ├── app/              │
│  ├── config/           │    │  ├── config/           │
│  └── backups/          │    │  └── backups/          │
└─────────────────────────┘    └─────────────────────────┘
              │                          │
              ▼                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKUP CENTRALIZADO                      │
│  ~/backups/                                                 │
│  ├── staging/         ← Backups de staging                 │
│  ├── production/      ← Backups de producción              │
│  └── latest/          ← Enlaces simbólicos                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Estructura del Proyecto

```
proyecto-sync/
├── proyecto-web/                    # Aplicación simulada
│   ├── src/
│   │   ├── index.html
│   │   ├── app.js
│   │   └── styles.css
│   ├── config/
│   │   ├── development.json
│   │   ├── staging.json
│   │   └── production.json
│   └── assets/
│       └── images/
│
├── scripts/                         # Scripts de sincronización
│   ├── deploy-staging.sh
│   ├── deploy-prod.sh
│   ├── backup-incremental.sh
│   ├── sync-configs.sh
│   └── restore-backup.sh
│
├── exclude-files/                   # Archivos de exclusión
│   ├── deploy.exclude
│   └── backup.exclude
│
├── logs/                            # Logs de sincronización
│   └── .gitkeep
│
└── README.md                        # Documentación
```

---

## ✅ Requisitos del Proyecto

### Funcionales (20 puntos)

1. **Deploy a Staging** (5 pts)

   - Script que sincroniza código con servidor staging
   - Usa rsync con exclusiones apropiadas
   - Genera log de cada despliegue

2. **Deploy a Producción** (5 pts)

   - Similar a staging pero con confirmación
   - Crea backup antes de desplegar
   - Verifica integridad post-deploy

3. **Backup Incremental** (5 pts)

   - Backups con `--link-dest` para eficiencia
   - Retención de últimos N backups
   - Rotación automática

4. **Restauración** (5 pts)
   - Script para restaurar desde backup específico
   - Lista backups disponibles
   - Confirmación antes de restaurar

### Seguridad (10 puntos)

5. **Exclusiones** (4 pts)

   - No transferir archivos sensibles (.env, credenciales)
   - Excluir caches y temporales

6. **Validaciones** (3 pts)

   - Verificar conectividad antes de ejecutar
   - Validar permisos en destino

7. **Logging** (3 pts)
   - Registrar todas las operaciones
   - Incluir timestamps y resultados

### Documentación (10 puntos)

8. **README** (5 pts)

   - Instrucciones de uso
   - Ejemplos de comandos

9. **Comentarios** (5 pts)
   - Scripts bien documentados
   - Explicación de opciones usadas

### Código Limpio (5 puntos)

10. **Estructura** (5 pts)
    - Scripts modulares
    - Variables configurables
    - Manejo de errores

### Extras (5 puntos)

11. **Funcionalidades adicionales**
    - Notificaciones (por correo o webhook)
    - Comparación pre-deploy
    - Modo dry-run global

---

## 📚 Documentación Incluida

| Documento                                        | Descripción           |
| ------------------------------------------------ | --------------------- |
| [Guía de Implementación](GUIA-IMPLEMENTACION.md) | Paso a paso detallado |
| [Ejemplos de Configuración](EJEMPLOS-CONFIGS.md) | Scripts de referencia |

---

## 🚀 Entregables

1. **Directorio `proyecto-sync/`** con toda la estructura
2. **5 scripts funcionales** y probados
3. **Archivos de exclusión** configurados
4. **README.md** con documentación
5. **Logs de ejemplo** de ejecución

---

## 📊 Criterios de Evaluación

| Criterio               | Peso     | Puntos     |
| ---------------------- | -------- | ---------- |
| Funcionalidad completa | 40%      | 20 pts     |
| Seguridad              | 20%      | 10 pts     |
| Documentación          | 20%      | 10 pts     |
| Código limpio          | 10%      | 5 pts      |
| Extras                 | 10%      | 5 pts      |
| **TOTAL**              | **100%** | **50 pts** |

---

## ⏱️ Planificación Sugerida

| Tiempo | Actividad                             |
| ------ | ------------------------------------- |
| 15 min | Crear estructura y archivos de prueba |
| 20 min | Implementar deploy-staging.sh         |
| 15 min | Implementar deploy-prod.sh            |
| 20 min | Implementar backup-incremental.sh     |
| 10 min | Implementar restore-backup.sh         |
| 10 min | Documentación y pruebas finales       |

---

## 🧭 Navegación

| ⬅️ Anterior                           |         🏠 Índice         |                        Siguiente ➡️ |
| :------------------------------------ | :-----------------------: | ----------------------------------: |
| [Prácticas](../2-practicas/README.md) | [Semana 04](../README.md) | [Recursos](../4-recursos/README.md) |

---

<div align="center">

**🔨 Proyecto Semana 04**

_Sistema de Sincronización Multi-Entorno_

</div>
