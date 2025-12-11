# 📤 SCP: Secure Copy

## Módulo 01 - Copia Rápida de Archivos

![Duración](https://img.shields.io/badge/Duración-20_min-blue?style=for-the-badge)
![Nivel](https://img.shields.io/badge/Nivel-Principiante-green?style=for-the-badge)

---

## 🎯 Objetivos del Módulo

Al finalizar este módulo, serás capaz de:

- Entender qué es SCP y cómo funciona
- Copiar archivos de local a remoto y viceversa
- Usar opciones avanzadas de SCP
- Conocer las limitaciones de SCP

---

## 📖 ¿Qué es SCP?

**SCP (Secure Copy Protocol)** es una herramienta de línea de comandos que permite copiar archivos entre hosts de forma segura usando SSH para el transporte.

### Características

- ✅ **Simple**: Sintaxis similar a `cp`
- ✅ **Seguro**: Todo el tráfico cifrado por SSH
- ✅ **Rápido**: Conexión directa, sin overhead
- ❌ **Sin resume**: No puede continuar transferencias interrumpidas
- ❌ **Copia completa**: No detecta archivos ya existentes

---

## 🔧 Sintaxis Básica

### Formato General

```bash
scp [opciones] origen destino
```

### Identificar Rutas Remotas

Las rutas remotas se especifican como `usuario@host:ruta`:

```bash
# Remoto
usuario@servidor:/ruta/al/archivo

# Local
/ruta/local/archivo
./archivo
archivo.txt
```

---

## 📤 Local a Remoto (Upload)

### Copiar un Archivo

```bash
# Sintaxis
scp archivo_local usuario@servidor:/ruta/destino/

# Ejemplos
scp documento.pdf admin@192.168.1.100:/home/admin/
scp config.yml deploy@servidor:/var/www/app/
scp ./backup.tar.gz root@backup-server:/backups/
```

### Copiar con Nombre Diferente

```bash
# Renombrar en destino
scp archivo.txt admin@servidor:/home/admin/nuevo_nombre.txt
```

### Copiar Múltiples Archivos

```bash
# Varios archivos al mismo destino
scp archivo1.txt archivo2.txt archivo3.txt admin@servidor:/destino/

# Con wildcard
scp *.log admin@servidor:/var/log/app/
```

---

## 📥 Remoto a Local (Download)

### Descargar un Archivo

```bash
# Sintaxis
scp usuario@servidor:/ruta/archivo destino_local

# Ejemplos
scp admin@servidor:/var/log/app.log ./logs/
scp deploy@web:/etc/nginx/nginx.conf ./configs/
scp root@db:/backup/dump.sql /backups/
```

### Descargar al Directorio Actual

```bash
# Usar . para directorio actual
scp admin@servidor:/home/admin/archivo.txt .
```

---

## 📁 Copiar Directorios (-r)

### Recursivo

```bash
# Copiar directorio completo (local a remoto)
scp -r ./mi-proyecto/ admin@servidor:/var/www/

# Copiar directorio (remoto a local)
scp -r admin@servidor:/var/www/app/ ./backup/
```

> ⚠️ **Nota**: Sin `-r`, SCP no puede copiar directorios.

---

## ⚙️ Opciones Importantes

### Tabla de Opciones

| Opción | Descripción                       | Ejemplo                        |
| ------ | --------------------------------- | ------------------------------ |
| `-r`   | Recursivo (directorios)           | `scp -r ./dir/ host:`          |
| `-P`   | Puerto SSH                        | `scp -P 2222 file host:`       |
| `-p`   | Preservar timestamps/permisos     | `scp -p file host:`            |
| `-C`   | Compresión                        | `scp -C largefile host:`       |
| `-l`   | Límite de ancho de banda (Kbit/s) | `scp -l 1000 file host:`       |
| `-q`   | Modo silencioso                   | `scp -q file host:`            |
| `-v`   | Modo verbose                      | `scp -v file host:`            |
| `-i`   | Especificar llave SSH             | `scp -i ~/.ssh/key file host:` |

### Ejemplos de Opciones

```bash
# Puerto no estándar
scp -P 2222 archivo.txt admin@servidor:/home/admin/

# Preservar atributos
scp -p archivo.txt admin@servidor:/home/admin/

# Con compresión (útil para archivos grandes de texto)
scp -C logs.tar admin@servidor:/backups/

# Limitar ancho de banda a 1 Mbps
scp -l 8000 video.mp4 admin@servidor:/media/

# Combinando opciones
scp -rpC ./proyecto/ admin@servidor:/var/www/
```

---

## 🔐 Usando ~/.ssh/config

SCP respeta tu archivo de configuración SSH:

```ssh-config
# ~/.ssh/config
Host produccion
    HostName 192.168.100.10
    User deploy
    Port 2222
    IdentityFile ~/.ssh/id_deploy
```

```bash
# Sin config
scp -P 2222 -i ~/.ssh/id_deploy archivo.txt deploy@192.168.100.10:/app/

# Con config (mucho más simple)
scp archivo.txt produccion:/app/
```

---

## 🔄 Entre Servidores Remotos

SCP puede copiar directamente entre dos servidores remotos:

```bash
# De servidor1 a servidor2
scp admin@servidor1:/archivo.txt deploy@servidor2:/destino/

# Con opción -3 (pasar por local)
scp -3 admin@servidor1:/archivo.txt deploy@servidor2:/destino/
```

> **Nota**: Sin `-3`, los servidores se conectan directamente entre sí. Con `-3`, el tráfico pasa por tu máquina local.

---

## ⚠️ Limitaciones de SCP

### No Puede:

1. **Resumir transferencias** interrumpidas
2. **Detectar archivos existentes** (siempre sobrescribe)
3. **Sincronizar** (no detecta diferencias)
4. **Excluir archivos** (no tiene --exclude)
5. **Mostrar progreso** detallado por archivo

### Cuándo NO Usar SCP

| Situación                                | Alternativa  |
| ---------------------------------------- | ------------ |
| Transferencias grandes que pueden fallar | rsync o SFTP |
| Sincronizar directorios                  | rsync        |
| Navegar antes de transferir              | SFTP         |
| Backups incrementales                    | rsync        |

---

## 🛡️ Seguridad

### Buenas Prácticas

```bash
# ✅ Usar llaves SSH (no contraseñas)
scp -i ~/.ssh/id_ed25519 archivo.txt servidor:/destino/

# ✅ Verificar destino antes de sobrescribir
ssh servidor "ls -la /destino/"
scp archivo.txt servidor:/destino/

# ✅ Usar puerto no estándar si está configurado
scp -P 2222 archivo.txt servidor:/destino/
```

---

## 🧪 Ejemplos Prácticos

### Ejemplo 1: Backup Rápido de Configuración

```bash
# Respaldar config de nginx
scp -r root@webserver:/etc/nginx/ ./backup-nginx-$(date +%Y%m%d)/
```

### Ejemplo 2: Deploy de Aplicación

```bash
# Subir nuevo release
scp -r ./dist/ deploy@produccion:/var/www/app/releases/v1.2.3/
```

### Ejemplo 3: Transferir Logs para Análisis

```bash
# Descargar logs del último día
scp admin@servidor:/var/log/app/$(date +%Y-%m-%d).log ./analysis/
```

---

## 📝 Resumen de Comandos

```bash
# Upload (local → remoto)
scp archivo servidor:/destino/

# Download (remoto → local)
scp servidor:/archivo ./destino/

# Directorio recursivo
scp -r ./dir/ servidor:/destino/

# Con puerto y preservar atributos
scp -P 2222 -p archivo servidor:/destino/

# Limitar ancho de banda
scp -l 10000 archivo servidor:/destino/
```

---

## 🎯 Resumen

| Concepto | Descripción                    |
| -------- | ------------------------------ |
| SCP      | Copia segura sobre SSH         |
| `-r`     | Recursivo para directorios     |
| `-P`     | Puerto SSH (mayúscula)         |
| `-p`     | Preservar permisos (minúscula) |
| `-C`     | Compresión                     |
| `-l`     | Límite de ancho de banda       |
| Config   | Respeta ~/.ssh/config          |

---

## 🧭 Navegación

| ⬅️ Anterior         |      🏠 Índice      |                     Siguiente ➡️ |
| :------------------ | :-----------------: | -------------------------------: |
| [README](README.md) | [Teoría](README.md) | [02 - SFTP](02-sftp-sesiones.md) |

---

<div align="center">

**📤 SCP: Secure Copy**

_Copia rápida y segura_

</div>
