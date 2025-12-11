# 💻 Prácticas - Semana 04

## Transferencia de Archivos: SCP, SFTP y rsync

![Prácticas](https://img.shields.io/badge/Prácticas-3_ejercicios-orange?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-1.5_horas-blue?style=for-the-badge)

---

## 🎯 Objetivo

Practicar las tres herramientas principales de transferencia de archivos sobre SSH, entendiendo cuándo usar cada una.

---

## 📋 Lista de Prácticas

| #   | Práctica                                            | Dificultad | Duración | Tema           |
| --- | --------------------------------------------------- | ---------- | -------- | -------------- |
| 01  | [Transferencias con SCP](practica-01-scp-basico.md) | ⭐         | 30 min   | Copia rápida   |
| 02  | [Sesiones SFTP](practica-02-sftp-interactivo.md)    | ⭐⭐       | 30 min   | Interactivo    |
| 03  | [Backups con rsync](practica-03-rsync-backups.md)   | ⭐⭐⭐     | 30 min   | Sincronización |

---

## 📊 Progresión de Dificultad

```
Práctica 01: ⭐ Básico
├── SCP local a remoto
├── SCP remoto a local
└── Opciones básicas (-r, -P, -p)

Práctica 02: ⭐⭐ Intermedio
├── Sesión SFTP interactiva
├── Navegación y transferencias
└── Modo batch automatizado

Práctica 03: ⭐⭐⭐ Avanzado
├── rsync sobre SSH
├── Sincronización incremental
└── Backups con --link-dest
```

---

## 🔧 Preparación del Entorno

### Requisitos

- [ ] Acceso SSH a un servidor remoto
- [ ] Autenticación por llave configurada
- [ ] Archivos de prueba preparados

### Crear Archivos de Prueba

```bash
# Crear directorio de pruebas
mkdir -p ~/ssh-lab/semana-04/{archivos,backups,logs}

# Crear archivos de diferentes tipos
cd ~/ssh-lab/semana-04/archivos

# Archivos de texto
echo "Archivo de configuración de prueba" > config.txt
echo "Log de aplicación simulado" > app.log
for i in {1..5}; do
    echo "Documento $i contenido" > documento-$i.txt
done

# Crear subdirectorio
mkdir -p proyecto/{src,config,docs}
echo "<?php echo 'Hola'; ?>" > proyecto/src/index.php
echo "server: localhost" > proyecto/config/app.yml
echo "# Documentación" > proyecto/docs/README.md

# Crear archivo más grande (1MB)
dd if=/dev/urandom of=archivo-grande.bin bs=1M count=1 2>/dev/null

# Verificar estructura
tree ~/ssh-lab/semana-04/ 2>/dev/null || ls -laR ~/ssh-lab/semana-04/
```

### Verificar Conectividad

```bash
# Probar conexión SSH
ssh tu-servidor "echo 'Conexión exitosa'"

# Crear directorio de trabajo en remoto
ssh tu-servidor "mkdir -p ~/lab-transferencias"
```

---

## ✅ Checklist de Completación

### Práctica 01: SCP

- [ ] Subir archivo individual con SCP
- [ ] Descargar archivo del servidor
- [ ] Copiar directorio recursivamente
- [ ] Usar puerto no estándar

### Práctica 02: SFTP

- [ ] Conectar y navegar en sesión SFTP
- [ ] Transferir archivos con get/put
- [ ] Gestionar archivos remotos
- [ ] Ejecutar comandos en modo batch

### Práctica 03: rsync

- [ ] Sincronizar directorio sobre SSH
- [ ] Usar exclusiones
- [ ] Ejecutar con --dry-run
- [ ] Crear backup incremental

---

## 💡 Tips para las Prácticas

### General

- Siempre verifica el resultado después de transferir
- Usa `--dry-run` en rsync antes de ejecutar
- Aprovecha tu `~/.ssh/config` para simplificar comandos

### Debugging

```bash
# Ver lo que hace cada herramienta
scp -v archivo servidor:/destino/
sftp -v servidor
rsync -avvz origen/ servidor:/destino/
```

---

## 🧭 Navegación

| ⬅️ Anterior                     |         🏠 Índice         |                        Siguiente ➡️ |
| :------------------------------ | :-----------------------: | ----------------------------------: |
| [Teoría](../1-teoria/README.md) | [Semana 04](../README.md) | [Proyecto](../3-proyecto/README.md) |

---

<div align="center">

**💻 Prácticas - Semana 04**

_Transferencia de Archivos_

</div>
