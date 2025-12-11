# 📚 Teoría - Semana 04

## Transferencia de Archivos: SCP, SFTP y rsync

![Teoría](https://img.shields.io/badge/Teoría-3_módulos-purple?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-1_hora-blue?style=for-the-badge)

---

## 🎯 Objetivo

Dominar las tres herramientas principales para transferir archivos de forma segura sobre SSH, entendiendo cuándo usar cada una.

---

## 📖 Módulos Teóricos

| #   | Módulo                                                          | Duración | Descripción                |
| --- | --------------------------------------------------------------- | -------- | -------------------------- |
| 01  | [SCP: Secure Copy](01-scp-fundamentos.md)                       | 20 min   | Copia rápida de archivos   |
| 02  | [SFTP: Sesiones Interactivas](02-sftp-sesiones.md)              | 20 min   | Transferencia interactiva  |
| 03  | [rsync: Sincronización Inteligente](03-rsync-sincronizacion.md) | 20 min   | Sincronización incremental |

---

## 🧠 Conceptos Clave

### SCP (Secure Copy)

- Copia simple y rápida sobre SSH
- Sin capacidad de resumir transferencias
- Ideal para archivos individuales pequeños

### SFTP (SSH File Transfer Protocol)

- Sesión interactiva como FTP pero segura
- Permite navegar, explorar y transferir
- Soporta resume de transferencias

### rsync (Remote Sync)

- Sincronización inteligente e incremental
- Solo transfiere diferencias (delta)
- Perfecto para backups y grandes volúmenes

---

## 📊 Diagrama de Decisión

```
¿Qué necesitas transferir?
        │
        ├── Un archivo pequeño rápidamente
        │   └── ✅ SCP
        │
        ├── Explorar y elegir qué transferir
        │   └── ✅ SFTP
        │
        ├── Sincronizar directorios
        │   └── ✅ rsync
        │
        ├── Backup incremental
        │   └── ✅ rsync
        │
        └── Transferencia que puede interrumpirse
            ├── ✅ SFTP (resume)
            └── ✅ rsync (incremental)
```

---

## ⚖️ Comparativa Rápida

| Característica            |  SCP   | SFTP | rsync  |
| ------------------------- | :----: | :--: | :----: |
| Velocidad (archivo único) | ⭐⭐⭐ | ⭐⭐ |  ⭐⭐  |
| Interactividad            |   ❌   |  ✅  |   ❌   |
| Resume                    |   ❌   |  ✅  |   ✅   |
| Incremental               |   ❌   |  ❌  |   ✅   |
| Compresión                |   ❌   |  ❌  |   ✅   |
| Backups                   |   ⭐   |  ⭐  | ⭐⭐⭐ |

---

## 📋 Prerequisitos

Antes de comenzar, asegúrate de:

- [ ] Tener acceso SSH a un servidor remoto
- [ ] Conocer la configuración de `~/.ssh/config`
- [ ] Tener archivos de prueba preparados

---

## 🧭 Navegación

| Módulo                            | Siguiente |
| --------------------------------- | --------- |
| [01 - SCP](01-scp-fundamentos.md) | ➡️        |

---

<div align="center">

**📚 Teoría - Semana 04**

_Transferencia de Archivos_

</div>
