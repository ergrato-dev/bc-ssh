# 📤 Práctica 01: Transferencias con SCP

## ⭐ Nivel Básico - 30 minutos

![SCP](https://img.shields.io/badge/SCP-Secure_Copy-blue?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-30_min-green?style=for-the-badge)

---

## 🎯 Objetivos

Al completar esta práctica, serás capaz de:

- [ ] Copiar archivos de local a remoto
- [ ] Descargar archivos de remoto a local
- [ ] Copiar directorios completos
- [ ] Usar opciones avanzadas de SCP

---

## 📋 Prerequisitos

- [ ] Servidor SSH accesible
- [ ] Autenticación configurada (preferiblemente llaves)
- [ ] Archivos de prueba creados (ver README de prácticas)

---

## 🔧 Parte 1: Upload (Local → Remoto)

### Ejercicio 1.1: Copiar un Archivo

```bash
# Ir al directorio de trabajo
cd ~/ssh-lab/semana-04/archivos

# Copiar archivo al servidor
scp config.txt tu-servidor:~/lab-transferencias/

# Verificar en el servidor
ssh tu-servidor "ls -la ~/lab-transferencias/"
```

**Resultado esperado:**

```
-rw-r--r-- 1 usuario usuario 36 dic 10 10:00 config.txt
```

### Ejercicio 1.2: Copiar con Nombre Diferente

```bash
# Copiar renombrando en destino
scp config.txt tu-servidor:~/lab-transferencias/config-backup.txt

# Verificar
ssh tu-servidor "ls ~/lab-transferencias/*.txt"
```

### Ejercicio 1.3: Copiar Múltiples Archivos

```bash
# Copiar varios archivos
scp documento-1.txt documento-2.txt tu-servidor:~/lab-transferencias/

# Usando wildcard
scp documento-*.txt tu-servidor:~/lab-transferencias/

# Verificar
ssh tu-servidor "ls ~/lab-transferencias/documento*"
```

---

## 📥 Parte 2: Download (Remoto → Local)

### Ejercicio 2.1: Descargar un Archivo

```bash
# Crear directorio de descargas
mkdir -p ~/ssh-lab/semana-04/downloads

# Descargar archivo del servidor
scp tu-servidor:~/lab-transferencias/config.txt ~/ssh-lab/semana-04/downloads/

# Verificar
ls -la ~/ssh-lab/semana-04/downloads/
```

### Ejercicio 2.2: Descargar al Directorio Actual

```bash
# Ir a directorio de descargas
cd ~/ssh-lab/semana-04/downloads

# Descargar usando . para directorio actual
scp tu-servidor:~/lab-transferencias/config-backup.txt .

# Verificar
ls -la
```

### Ejercicio 2.3: Descargar Múltiples Archivos

```bash
# Descargar con wildcard
scp "tu-servidor:~/lab-transferencias/documento-*.txt" ~/ssh-lab/semana-04/downloads/

# Verificar
ls ~/ssh-lab/semana-04/downloads/documento*
```

> **Nota**: Las comillas son necesarias para que el wildcard se expanda en el servidor, no en local.

---

## 📁 Parte 3: Directorios (-r)

### Ejercicio 3.1: Subir Directorio Completo

```bash
cd ~/ssh-lab/semana-04/archivos

# Copiar directorio recursivamente
scp -r proyecto/ tu-servidor:~/lab-transferencias/

# Verificar estructura
ssh tu-servidor "ls -laR ~/lab-transferencias/proyecto/"
```

**Resultado esperado:**

```
/home/usuario/lab-transferencias/proyecto/:
total X
drwxr-xr-x 2 usuario usuario  config
drwxr-xr-x 2 usuario usuario  docs
drwxr-xr-x 2 usuario usuario  src

/home/usuario/lab-transferencias/proyecto/src:
-rw-r--r-- 1 usuario usuario  index.php
...
```

### Ejercicio 3.2: Descargar Directorio

```bash
# Descargar directorio del servidor
scp -r tu-servidor:~/lab-transferencias/proyecto/ ~/ssh-lab/semana-04/downloads/

# Verificar
tree ~/ssh-lab/semana-04/downloads/proyecto/ 2>/dev/null || \
    ls -laR ~/ssh-lab/semana-04/downloads/proyecto/
```

---

## ⚙️ Parte 4: Opciones Avanzadas

### Ejercicio 4.1: Preservar Timestamps y Permisos (-p)

```bash
# Ver timestamps originales
ls -la ~/ssh-lab/semana-04/archivos/config.txt

# Copiar preservando atributos
scp -p config.txt tu-servidor:~/lab-transferencias/config-preserved.txt

# Verificar que timestamps se conservan
ssh tu-servidor "ls -la ~/lab-transferencias/config-preserved.txt"
```

### Ejercicio 4.2: Puerto No Estándar (-P)

```bash
# Si tu servidor usa puerto diferente (ejemplo: 2222)
# scp -P 2222 config.txt tu-servidor:~/lab-transferencias/

# O usando tu ~/.ssh/config (más limpio)
# Tu config ya debería tener el puerto configurado
scp config.txt tu-servidor:~/lab-transferencias/
```

### Ejercicio 4.3: Con Compresión (-C)

```bash
# Subir archivo grande con compresión
scp -C archivo-grande.bin tu-servidor:~/lab-transferencias/

# Verificar
ssh tu-servidor "ls -lh ~/lab-transferencias/archivo-grande.bin"
```

### Ejercicio 4.4: Limitar Ancho de Banda (-l)

```bash
# Limitar a 500 Kbit/s (≈62 KB/s)
scp -l 500 archivo-grande.bin tu-servidor:~/lab-transferencias/grande-limitado.bin

# Observar la velocidad reducida
```

---

## 🔍 Parte 5: Verificación y Debugging

### Ejercicio 5.1: Modo Verbose (-v)

```bash
# Ver detalles de conexión
scp -v config.txt tu-servidor:~/lab-transferencias/config-verbose.txt
```

**Observar:**

- Negociación de cifrado
- Autenticación
- Proceso de transferencia

### Ejercicio 5.2: Verificar Integridad

```bash
# Calcular checksum local
md5sum archivo-grande.bin

# Calcular en remoto
ssh tu-servidor "md5sum ~/lab-transferencias/archivo-grande.bin"

# Los checksums deben coincidir
```

---

## 🏆 Desafío Final

### Escenario: Backup de Configuración

Simula hacer un backup de configuraciones de un servidor:

```bash
# 1. Crear directorio de backup con fecha
FECHA=$(date +%Y%m%d)
mkdir -p ~/ssh-lab/semana-04/backups/backup-$FECHA

# 2. Descargar todas las configuraciones
scp -rp "tu-servidor:~/lab-transferencias/*.txt" ~/ssh-lab/semana-04/backups/backup-$FECHA/

# 3. Verificar
ls -la ~/ssh-lab/semana-04/backups/backup-$FECHA/
```

---

## 🧹 Limpieza

```bash
# En el servidor (opcional)
ssh tu-servidor "rm -rf ~/lab-transferencias/*"

# Local: mantener para siguientes prácticas
```

---

## 📝 Verificación de Completación

| Tarea                        | Completada |
| ---------------------------- | :--------: |
| Upload de archivo individual |     ☐      |
| Upload con nombre diferente  |     ☐      |
| Upload de múltiples archivos |     ☐      |
| Download de archivo          |     ☐      |
| Download con wildcard        |     ☐      |
| Directorio recursivo (-r)    |     ☐      |
| Preservar atributos (-p)     |     ☐      |
| Verificar integridad         |     ☐      |

---

## ❓ Troubleshooting

### Error: Permission denied

```bash
# Verificar permisos en destino
ssh tu-servidor "ls -la ~ && ls -la ~/lab-transferencias"

# Verificar que puedes escribir
ssh tu-servidor "touch ~/lab-transferencias/test && rm ~/lab-transferencias/test"
```

### Error: No such file or directory

```bash
# Crear directorio destino
ssh tu-servidor "mkdir -p ~/lab-transferencias"
```

### Transferencia muy lenta

```bash
# Probar con compresión
scp -C archivo servidor:/destino/

# Verificar si hay limitación de red
ping -c 3 tu-servidor
```

---

## 🧭 Navegación

| ⬅️ Anterior         |       🏠 Índice        |                                   Siguiente ➡️ |
| :------------------ | :--------------------: | ---------------------------------------------: |
| [README](README.md) | [Prácticas](README.md) | [Práctica 02](practica-02-sftp-interactivo.md) |

---

<div align="center">

**📤 Práctica 01: Transferencias con SCP**

_Copia rápida y segura_

</div>
