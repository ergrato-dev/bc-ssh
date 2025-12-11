# ⚡ Práctica 03: Multiplexing y Control Master

## Reutilizar Conexiones SSH

![Dificultad](https://img.shields.io/badge/Dificultad-⭐⭐⭐_Avanzada-red?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-30_min-blue?style=for-the-badge)

---

## 🎯 Objetivo

Configurar SSH multiplexing para reutilizar conexiones existentes, reduciendo drásticamente el tiempo de conexión y autenticación.

---

## 📋 Prerequisitos

- [ ] Prácticas 01 y 02 completadas
- [ ] Archivo `~/.ssh/config` funcional
- [ ] Acceso a al menos un servidor remoto

---

## 📊 ¿Por Qué Multiplexing?

### Problema: Cada Conexión es Lenta

```bash
# Sin multiplexing - cada conexión toma 1-3 segundos
time ssh servidor exit
# real    0m1.234s

time ssh servidor exit
# real    0m1.198s

time ssh servidor exit
# real    0m1.267s
```

### Solución: Reutilizar la Conexión

```bash
# Con multiplexing - primera conexión normal
time ssh servidor exit
# real    0m1.234s

# Siguientes conexiones - casi instantáneas
time ssh servidor exit
# real    0m0.089s

time ssh servidor exit
# real    0m0.076s
```

---

## 🔨 Parte 1: Preparar el Directorio de Sockets

### Paso 1.1: Crear Directorio

```bash
# Crear directorio para sockets de control
mkdir -p ~/.ssh/sockets

# Establecer permisos seguros
chmod 700 ~/.ssh/sockets

# Verificar
ls -la ~/.ssh/ | grep sockets
# drwx------ 2 usuario usuario 4096 dic 10 10:00 sockets
```

> ⚠️ **Seguridad**: Los sockets permiten acceso a tus conexiones. El directorio DEBE tener permisos 700.

---

## 🔨 Parte 2: Configurar Multiplexing Global

### Paso 2.1: Añadir Configuración

Edita `~/.ssh/config`:

```ssh-config
# ~/.ssh/config

# ============================================
# MULTIPLEXING GLOBAL
# ============================================
Host *
    # Activar multiplexing automático
    ControlMaster auto

    # Ubicación de sockets (uno por conexión)
    ControlPath ~/.ssh/sockets/%r@%h-%p

    # Mantener conexión 10 minutos después de cerrar última sesión
    ControlPersist 10m

# ... resto de tu configuración ...
```

### Paso 2.2: Entender las Opciones

| Opción           | Valor                     | Significado                               |
| ---------------- | ------------------------- | ----------------------------------------- |
| `ControlMaster`  | `auto`                    | Crear master automáticamente si no existe |
| `ControlPath`    | `~/.ssh/sockets/%r@%h-%p` | Socket: usuario@host-puerto               |
| `ControlPersist` | `10m`                     | Mantener master 10 min después de cerrar  |

---

## 🔨 Parte 3: Probar Multiplexing

### Paso 3.1: Primera Conexión (Crear Master)

```bash
# Abrir primera conexión (crea el master)
ssh servidor

# En otra terminal, verificar el socket
ls -la ~/.ssh/sockets/
# srw------- 1 usuario usuario 0 dic 10 10:00 admin@servidor.com-22
```

### Paso 3.2: Segunda Conexión (Reutilizar)

```bash
# En otra terminal (mientras la primera sigue abierta)
ssh servidor

# ¡Conexión instantánea! Reutiliza el master
```

### Paso 3.3: Medir la Diferencia

```bash
# Primera conexión (sin master previo)
time ssh servidor exit
# real    0m1.234s

# Segunda conexión (con master)
time ssh servidor exit
# real    0m0.089s

# ¡10-15x más rápido!
```

---

## 🔨 Parte 4: Gestionar Conexiones Master

### Paso 4.1: Verificar Estado

```bash
# Verificar si existe conexión master
ssh -O check servidor

# Si existe:
# Master running (pid=12345)

# Si no existe:
# Control socket "~/.ssh/sockets/admin@servidor-22" does not exist
```

### Paso 4.2: Cerrar Conexión Master

```bash
# Cerrar gracefully (espera a que terminen sesiones)
ssh -O exit servidor
# Exit request sent.

# Terminar inmediatamente
ssh -O stop servidor
# Stop request sent.
```

### Paso 4.3: Listar Todas las Conexiones Activas

```bash
# Ver todos los sockets
ls -la ~/.ssh/sockets/

# Ejemplo de salida
srw------- 1 usuario usuario 0 dic 10 10:00 admin@servidor1.com-22
srw------- 1 usuario usuario 0 dic 10 09:30 deploy@servidor2.com-22
srw------- 1 usuario usuario 0 dic 10 09:00 root@servidor3.com-2222
```

---

## 🔨 Parte 5: ControlPersist en Acción

### Paso 5.1: Probar Persistencia

```bash
# Conectar y salir inmediatamente
ssh servidor exit

# Verificar que el master sigue activo
ssh -O check servidor
# Master running (pid=12345)

# Esperar 10 minutos...
# El master se cierra automáticamente
```

### Paso 5.2: Diferentes Tiempos de Persistencia

```ssh-config
# Servidores frecuentes - persistencia larga
Host servidor-frecuente
    HostName servidor.com
    ControlPersist 1h

# Servidores esporádicos - persistencia corta
Host servidor-esporadico
    HostName otro-servidor.com
    ControlPersist 5m

# Servidores sensibles - sin persistencia
Host servidor-seguro
    HostName seguro.com
    ControlPersist no
```

---

## 🔨 Parte 6: Port Forwarding con Control Master

### Paso 6.1: Añadir Port Forward a Conexión Existente

```bash
# Primero, establecer conexión
ssh servidor

# En otra terminal, añadir port forward
ssh -O forward -L 8080:localhost:80 servidor
# Forwarding port.

# Verificar
curl localhost:8080
```

### Paso 6.2: Cancelar Port Forward

```bash
# Cancelar el forward
ssh -O cancel -L 8080:localhost:80 servidor
# Cancel forwarding success.
```

---

## 🔨 Parte 7: Configuración Avanzada

### Paso 7.1: ControlPath con Hash (Nombres Cortos)

```ssh-config
Host *
    ControlMaster auto
    # %C = hash de host+port+user (evita nombres largos)
    ControlPath ~/.ssh/sockets/%C
    ControlPersist 10m
```

### Paso 7.2: Diferentes Configuraciones por Grupo

```ssh-config
# Servidores de producción - multiplexing largo
Host prod-*
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%C
    ControlPersist 30m

# Servidores de desarrollo - multiplexing corto
Host dev-*
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%C
    ControlPersist 5m

# GitHub - sin multiplexing (conexiones cortas)
Host github.com
    ControlMaster no
```

### Paso 7.3: Deshabilitar para Hosts Específicos

```ssh-config
# Servidor donde otros usuarios acceden a tu cuenta
Host servidor-compartido
    ControlMaster no

# Servidor con sesiones muy largas (evitar timeout)
Host servidor-etl
    ControlMaster auto
    ControlPersist yes  # Nunca cerrar automáticamente
```

---

## 🔨 Parte 8: Script de Gestión

### Paso 8.1: Crear Script Helper

```bash
# Crear script para gestionar sockets
cat > ~/.local/bin/ssh-sockets << 'EOF'
#!/bin/bash
# Gestión de sockets SSH

SOCKET_DIR="$HOME/.ssh/sockets"

case "$1" in
    list)
        echo "=== Sockets SSH activos ==="
        ls -la "$SOCKET_DIR" 2>/dev/null || echo "No hay sockets"
        ;;
    clean)
        echo "=== Limpiando sockets huérfanos ==="
        find "$SOCKET_DIR" -type s -exec sh -c '
            ssh -O check -o ControlPath="{}" dummy 2>/dev/null || rm -v "{}"
        ' \;
        ;;
    close-all)
        echo "=== Cerrando todas las conexiones ==="
        for socket in "$SOCKET_DIR"/*; do
            [ -S "$socket" ] && ssh -O exit -o ControlPath="$socket" dummy 2>/dev/null
        done
        ;;
    *)
        echo "Uso: $0 {list|clean|close-all}"
        ;;
esac
EOF

chmod +x ~/.local/bin/ssh-sockets
```

### Paso 8.2: Usar el Script

```bash
# Listar sockets activos
ssh-sockets list

# Limpiar sockets huérfanos
ssh-sockets clean

# Cerrar todas las conexiones
ssh-sockets close-all
```

---

## ✅ Verificación Final

### Checklist de Completación

- [ ] Directorio `~/.ssh/sockets` creado con permisos 700
- [ ] `ControlMaster auto` configurado en `~/.ssh/config`
- [ ] `ControlPath` apuntando a directorio de sockets
- [ ] `ControlPersist` configurado
- [ ] Verificado que segunda conexión es más rápida
- [ ] `ssh -O check` muestra master activo
- [ ] `ssh -O exit` cierra el master correctamente

### Pruebas de Verificación

```bash
# 1. Verificar configuración
ssh -G servidor | grep -E "^control"
# controlmaster auto
# controlpath ~/.ssh/sockets/%r@%h-%p
# controlpersist 600

# 2. Crear conexión master
ssh servidor exit

# 3. Verificar socket existe
ls ~/.ssh/sockets/

# 4. Verificar master activo
ssh -O check servidor
# Master running (pid=12345)

# 5. Medir velocidad
time ssh servidor exit
# real    0m0.089s

# 6. Cerrar master
ssh -O exit servidor
```

---

## 🐛 Troubleshooting

### Error: "ControlPath too long"

```bash
# Problema: Path del socket muy largo
# Solución: Usar hash
ControlPath ~/.ssh/sockets/%C

# O usar /tmp (menos seguro)
ControlPath /tmp/ssh-%C
```

### Error: "Control socket connect failed"

```bash
# Socket huérfano - eliminar manualmente
rm ~/.ssh/sockets/usuario@servidor-22

# O limpiar todos los huérfanos
find ~/.ssh/sockets -type s -exec rm {} \;
```

### Multiplexing No Funciona

```bash
# Verificar que la opción está activa
ssh -G servidor | grep controlmaster
# Debe mostrar: controlmaster auto

# Verificar permisos del directorio
ls -la ~/.ssh/ | grep sockets
# Debe ser: drwx------ (700)
```

### Conexión Lenta Aunque Hay Master

```bash
# Verificar que el socket es el correcto
ssh -O check servidor

# Si muestra "does not exist", el path no coincide
# Verificar ControlPath en ambas conexiones
ssh -G servidor | grep controlpath
```

---

## 🎯 Ejercicio Extra (Opcional)

### Benchmark Completo

```bash
# Script de benchmark
for i in {1..5}; do
    echo "Conexión $i:"
    time ssh servidor exit
    echo "---"
done
```

**Resultados esperados:**

```
Conexión 1:
real    0m1.234s  # Primera: crea master
---
Conexión 2:
real    0m0.089s  # Siguientes: reutilizan
---
Conexión 3:
real    0m0.076s
---
```

---

## 🧭 Navegación

| ⬅️ Anterior                             |       🏠 Índice        |                        Siguiente ➡️ |
| :-------------------------------------- | :--------------------: | ----------------------------------: |
| [Práctica 02](practica-02-proxyjump.md) | [Prácticas](README.md) | [Proyecto](../3-proyecto/README.md) |

---

<div align="center">

**⚡ Práctica 03: Multiplexing y Control Master**

_Conexiones SSH ultrarrápidas_

</div>
