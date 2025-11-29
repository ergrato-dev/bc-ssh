# 🔨 Proyecto Semanal - Semana 02

![SSH](https://img.shields.io/badge/SSH-Proyecto-red?style=for-the-badge&logo=openssh)
![Tipo](https://img.shields.io/badge/Tipo-Integrador-purple?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-1.5_horas-blue?style=for-the-badge)

## 🎯 Proyecto: Sistema de Autenticación SSH Multi-Entorno

### Descripción General

En este proyecto configurarás un **sistema completo de autenticación SSH con llaves** para un escenario profesional real: un desarrollador que necesita acceso seguro a múltiples entornos (GitHub, servidor de producción y servidor de desarrollo).

Implementarás todas las mejores prácticas aprendidas en la teoría y prácticas de esta semana.

---

## 📋 Objetivos del Proyecto

Al completar este proyecto serás capaz de:

- [ ] Diseñar una estrategia de llaves SSH para múltiples entornos
- [ ] Implementar autenticación por llaves en GitHub
- [ ] Configurar acceso SSH a servidores remotos
- [ ] Crear un archivo `~/.ssh/config` profesional
- [ ] Documentar tu infraestructura de llaves
- [ ] Automatizar la gestión con ssh-agent

---

## 🏗️ Escenario del Proyecto

### Contexto

Eres un desarrollador que acaba de unirse a **DevOps Corp** y necesitas configurar tu entorno de trabajo. La empresa tiene la siguiente infraestructura:

| Servicio            | Host                  | Usuario   | Propósito                 |
| ------------------- | --------------------- | --------- | ------------------------- |
| GitHub Personal     | github.com            | git       | Proyectos personales      |
| GitHub Empresa      | github.com            | git       | Repositorios corporativos |
| Servidor Producción | prod.devopscorp.local | deploy    | Despliegues               |
| Servidor Desarrollo | dev.devopscorp.local  | developer | Desarrollo                |

### Requisitos de Seguridad de la Empresa

1. ✅ Llaves separadas para personal y trabajo
2. ✅ Todas las llaves deben tener passphrase
3. ✅ Algoritmo Ed25519 obligatorio
4. ✅ Comentarios identificativos en todas las llaves
5. ✅ Documentación de cada llave

---

## 📁 Entregables

### 1. Estructura de Llaves (30%)

Crear las siguientes llaves:

```
~/.ssh/
├── id_personal            # Proyectos personales
├── id_personal.pub
├── id_devopscorp          # GitHub de la empresa
├── id_devopscorp.pub
├── id_prod                # Servidor producción
├── id_prod.pub
├── id_dev                 # Servidor desarrollo
├── id_dev.pub
├── config                 # Configuración completa
└── SSH_KEYS_DOC.md        # Documentación
```

### 2. Archivo de Configuración (30%)

Un archivo `~/.ssh/config` completo con:

- Configuración para cada host
- Aliases descriptivos
- Opciones de seguridad
- Comentarios explicativos

### 3. Documentación (20%)

Archivo `SSH_KEYS_DOC.md` con:

- Inventario de llaves
- Propósito de cada llave
- Fingerprints
- Fecha de creación
- Procedimiento de rotación

### 4. Script de Verificación (20%)

Script bash que:

- Verifique existencia de llaves
- Muestre fingerprints
- Pruebe conexiones
- Reporte estado del sistema

---

## 🚀 Guía de Implementación

Consulta la [Guía de Implementación Detallada](GUIA-IMPLEMENTACION.md) para instrucciones paso a paso.

---

## 📊 Rúbrica de Evaluación

| Criterio                | Puntos | Descripción                             |
| ----------------------- | ------ | --------------------------------------- |
| **Llaves Generadas**    | 10     | 4 pares de llaves con nombres correctos |
| **Passphrase**          | 5      | Todas las llaves protegidas             |
| **Permisos**            | 5      | 600/644/700 correctos                   |
| **Archivo Config**      | 10     | Configuración completa y funcional      |
| **GitHub Configurado**  | 5      | Al menos una cuenta conectada           |
| **Documentación**       | 10     | Inventario completo con fingerprints    |
| **Script Verificación** | 5      | Script funcional y útil                 |
| **Total**               | **50** |                                         |

### Escala de Calificación

| Rango | Nivel           |
| ----- | --------------- |
| 45-50 | 🏆 Excelente    |
| 40-44 | 🌟 Muy Bueno    |
| 35-39 | ✅ Bueno        |
| 30-34 | ⚠️ Suficiente   |
| 0-29  | ❌ Insuficiente |

---

## 📝 Ejemplos de Configuración

Consulta [Ejemplos de Configuración](EJEMPLOS-CONFIGS.md) para plantillas y ejemplos listos para usar.

---

## ⚠️ Consideraciones Importantes

### Entorno de Prueba

Si no tienes acceso a servidores reales, puedes:

1. **Usar contenedores Docker** con SSH habilitado
2. **Configurar VMs locales** con VirtualBox
3. **Usar solo GitHub** y simular los servidores en el config

### Seguridad

- **NUNCA** subas llaves privadas a ningún repositorio
- Añade `~/.ssh/id_*` a tu `.gitignore` global
- Guarda tus passphrases en un gestor de contraseñas

### Backup

```bash
# Respaldar llaves (en lugar seguro, encriptado)
tar -czf ssh_backup_$(date +%Y%m%d).tar.gz ~/.ssh/
# Guardar en disco encriptado o servicio seguro
```

---

## 🔗 Archivos del Proyecto

| Archivo                                          | Descripción               |
| ------------------------------------------------ | ------------------------- |
| [GUIA-IMPLEMENTACION.md](GUIA-IMPLEMENTACION.md) | Instrucciones paso a paso |
| [EJEMPLOS-CONFIGS.md](EJEMPLOS-CONFIGS.md)       | Plantillas y ejemplos     |

---

## ✅ Checklist de Entrega

Antes de entregar, verifica:

- [ ] 4 pares de llaves generadas
- [ ] Todas con passphrase
- [ ] Archivo `~/.ssh/config` funcional
- [ ] GitHub autenticado con SSH
- [ ] Documentación `SSH_KEYS_DOC.md` completa
- [ ] Script de verificación funcionando
- [ ] Permisos correctos en todos los archivos

---

## 🔗 Navegación

| ← Anterior                              | Actual         | Siguiente →                           |
| --------------------------------------- | -------------- | ------------------------------------- |
| [2-Prácticas](../2-practicas/README.md) | **3-Proyecto** | [4-Recursos](../4-recursos/README.md) |

---

<div align="center">

**🎯 Este proyecto vale 50 puntos (50% de la nota semanal)**

¡Demuestra que dominas la autenticación SSH con llaves!

[🏠 Volver al inicio de Semana 02](../README.md)

</div>
