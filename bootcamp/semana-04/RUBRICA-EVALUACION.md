# 📊 Rúbrica de Evaluación - Semana 04

## Transferencia de Archivos: SCP, SFTP y rsync

![Evaluación](https://img.shields.io/badge/Evaluación-100_puntos-green?style=for-the-badge)
![Semana](https://img.shields.io/badge/Semana-04-blue?style=for-the-badge)

---

## 📋 Resumen de Evaluación

| Componente | Peso     | Puntos      |
| ---------- | -------- | ----------- |
| Teoría     | 20%      | 20 pts      |
| Prácticas  | 30%      | 30 pts      |
| Proyecto   | 50%      | 50 pts      |
| **Total**  | **100%** | **100 pts** |

---

## 📚 Evaluación de Teoría (20 pts)

### Cuestionario de Conocimientos

| Criterio                   | Puntos | Descripción                           |
| -------------------------- | ------ | ------------------------------------- |
| Diferencias SCP/SFTP/rsync | 5 pts  | Cuándo usar cada herramienta          |
| Sintaxis y opciones        | 5 pts  | Flags principales de cada comando     |
| rsync incremental          | 5 pts  | Cómo funciona la sincronización delta |
| Seguridad y permisos       | 5 pts  | Preservación de atributos, cifrado    |

### Niveles de Desempeño - Teoría

| Nivel           | Puntos | Descripción                          |
| --------------- | ------ | ------------------------------------ |
| 🏆 Excelente    | 18-20  | Domina diferencias y casos de uso    |
| 🌟 Muy Bueno    | 15-17  | Comprende bien, pequeñas confusiones |
| ✅ Bueno        | 12-14  | Conocimiento básico correcto         |
| ⚠️ Suficiente   | 10-11  | Lagunas significativas               |
| ❌ Insuficiente | 0-9    | No comprende diferencias básicas     |

---

## 💻 Evaluación de Prácticas (30 pts)

### Práctica 01: Transferencias con SCP (10 pts)

| Criterio           | Puntos | Descripción                                |
| ------------------ | ------ | ------------------------------------------ |
| Local a remoto     | 3 pts  | `scp archivo servidor:destino` funcional   |
| Remoto a local     | 3 pts  | `scp servidor:archivo destino` funcional   |
| Opciones avanzadas | 2 pts  | -r (recursivo), -P (puerto), -p (permisos) |
| Uso de config      | 2 pts  | Aprovecha aliases de ~/.ssh/config         |

### Práctica 02: Sesiones SFTP (10 pts)

| Criterio              | Puntos | Descripción                    |
| --------------------- | ------ | ------------------------------ |
| Conexión y navegación | 3 pts  | cd, ls, pwd, lpwd funcionales  |
| Transferencias        | 3 pts  | get, put, mget, mput correctos |
| Gestión de archivos   | 2 pts  | mkdir, rm, rename en remoto    |
| Batch mode            | 2 pts  | Comandos SFTP desde script     |

### Práctica 03: Backups con rsync (10 pts)

| Criterio              | Puntos | Descripción                     |
| --------------------- | ------ | ------------------------------- |
| Sincronización básica | 3 pts  | rsync -avz funcional            |
| Sobre SSH             | 3 pts  | rsync -e ssh correctamente      |
| Opciones avanzadas    | 2 pts  | --delete, --exclude, --dry-run  |
| Verificación          | 2 pts  | Confirma sincronización exitosa |

### Niveles de Desempeño - Prácticas

| Nivel           | Puntos | Descripción                          |
| --------------- | ------ | ------------------------------------ |
| 🏆 Excelente    | 27-30  | Todas las prácticas perfectas        |
| 🌟 Muy Bueno    | 24-26  | Prácticas completas, mínimos errores |
| ✅ Bueno        | 20-23  | Mayoría funcional                    |
| ⚠️ Suficiente   | 15-19  | Funcionalidad básica                 |
| ❌ Insuficiente | 0-14   | Prácticas incompletas                |

---

## 🔨 Evaluación del Proyecto (50 pts)

### Proyecto: Sistema de Backup Automatizado

#### Funcionalidad Completa (20 pts)

| Criterio            | Puntos | Descripción                            |
| ------------------- | ------ | -------------------------------------- |
| Script de backup    | 6 pts  | rsync funcional con opciones correctas |
| Rotación de backups | 4 pts  | Mantiene N copias, elimina antiguas    |
| Logging             | 4 pts  | Registro de operaciones con timestamps |
| Notificaciones      | 3 pts  | Alerta en caso de error                |
| Restauración        | 3 pts  | Script de restore funcional            |

#### Seguridad (10 pts)

| Criterio                | Puntos | Descripción                   |
| ----------------------- | ------ | ----------------------------- |
| Autenticación por llave | 3 pts  | Sin contraseñas en scripts    |
| Permisos de scripts     | 2 pts  | chmod 700, owner correcto     |
| Exclusiones sensibles   | 3 pts  | No backup de .git, tmp, cache |
| Cifrado en tránsito     | 2 pts  | Usa SSH correctamente         |

#### Documentación (10 pts)

| Criterio               | Puntos | Descripción                |
| ---------------------- | ------ | -------------------------- |
| README del proyecto    | 4 pts  | Instrucciones claras       |
| Comentarios en scripts | 3 pts  | Código documentado         |
| Guía de restauración   | 3 pts  | Pasos para recuperar datos |

#### Código Limpio (5 pts)

| Criterio               | Puntos | Descripción          |
| ---------------------- | ------ | -------------------- |
| Variables descriptivas | 2 pts  | Nombres claros       |
| Manejo de errores      | 2 pts  | set -e, validaciones |
| Estructura             | 1 pts  | Organización lógica  |

#### Creatividad y Extras (5 pts)

| Criterio               | Puntos | Descripción                 |
| ---------------------- | ------ | --------------------------- |
| Backup incremental     | 2 pts  | --link-dest para hard links |
| Compresión inteligente | 1 pts  | Solo archivos grandes       |
| Métricas               | 1 pts  | Tamaño transferido, tiempo  |
| Cron configurado       | 1 pts  | Automatización completa     |

### Niveles de Desempeño - Proyecto

| Nivel           | Puntos | Descripción                   |
| --------------- | ------ | ----------------------------- |
| 🏆 Excelente    | 45-50  | Sistema de backup profesional |
| 🌟 Muy Bueno    | 40-44  | Backup completo y documentado |
| ✅ Bueno        | 35-39  | Backup funcional              |
| ⚠️ Suficiente   | 25-34  | Backup básico                 |
| ❌ Insuficiente | 0-24   | No cumple requisitos          |

---

## 📝 Entregables Requeridos

### Lista de Verificación

- [ ] Script de backup con rsync
- [ ] Script de restauración
- [ ] Configuración de cron (o ejemplo)
- [ ] Archivo de exclusiones
- [ ] README documentando el sistema
- [ ] Logs de ejemplo de ejecución
- [ ] Capturas demostrando:
  - [ ] Backup inicial completo
  - [ ] Backup incremental
  - [ ] Restauración exitosa

### Formato de Entrega

```
entrega-semana-04/
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   └── rotate.sh
├── config/
│   ├── exclude.txt
│   └── crontab.example
├── logs/
│   └── backup-example.log
├── docs/
│   ├── README.md
│   └── restore-guide.md
└── evidencias/
    ├── backup-inicial.png
    ├── backup-incremental.png
    └── restore-demo.png
```

---

## 🎯 Escala de Calificación Final

| Rango  | Calificación        | Descripción                   |
| ------ | ------------------- | ----------------------------- |
| 90-100 | 🏆 **Excelente**    | Sistema de backup profesional |
| 80-89  | 🌟 **Muy Bueno**    | Backup robusto y documentado  |
| 70-79  | ✅ **Bueno**        | Backup funcional              |
| 60-69  | ⚠️ **Suficiente**   | Backup básico                 |
| 0-59   | ❌ **Insuficiente** | No cumple requisitos          |

---

## 💡 Consejos para Maximizar tu Puntuación

### Teoría

- Practica explicando cuándo usar cada herramienta
- Memoriza las flags más importantes de rsync
- Entiende la diferencia entre copia y sincronización

### Prácticas

- Usa `--dry-run` antes de rsync real
- Prueba con archivos pequeños primero
- Verifica con `diff` después de transferir

### Proyecto

- Empieza simple, añade complejidad gradualmente
- Testa el restore antes de entregar
- Documenta mientras desarrollas

---

## 🔗 Recursos de Apoyo

- [Teoría: SCP Fundamentos](1-teoria/01-scp-fundamentos.md)
- [Teoría: rsync](1-teoria/03-rsync-sincronizacion.md)
- [Proyecto: Sistema de Backup](3-proyecto/README.md)
- [Glosario](5-glosario/README.md)

---

<div align="center">

**📊 Rúbrica de Evaluación - Semana 04**

_Transferencia de Archivos_

</div>
