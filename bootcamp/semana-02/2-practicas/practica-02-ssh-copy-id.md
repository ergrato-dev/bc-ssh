# 🚀 Práctica 02: Despliegue con ssh-copy-id

![SSH](https://img.shields.io/badge/SSH-Autenticación-red?style=for-the-badge&logo=openssh)
![Nivel](https://img.shields.io/badge/Nivel-⭐⭐_Intermedio-yellow?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-30_min-blue?style=for-the-badge)

## 📋 Descripción

En esta práctica aprenderás a **desplegar tu llave pública en un servidor remoto** para habilitar la autenticación sin contraseña. Usarás `ssh-copy-id` (el método recomendado) y también aprenderás el método manual para entender qué sucede internamente.

Al finalizar, podrás conectarte a tu servidor usando tu llave SSH en lugar de contraseña.

---

## 🎯 Objetivos de Aprendizaje

Al completar esta práctica serás capaz de:

- [ ] Desplegar tu llave pública usando `ssh-copy-id`
- [ ] Entender el proceso manual de autorización de llaves
- [ ] Verificar que la autenticación por llave funciona
- [ ] Diagnosticar problemas de conexión con modo verbose
- [ ] Configurar el servidor para rechazar autenticación por contraseña

---

## 📚 Requisitos Previos

| Requisito                         | Verificación                   |
| --------------------------------- | ------------------------------ |
| Práctica 01 completada            | `ls ~/.ssh/id_ed25519.pub`     |
| Servidor remoto accesible         | VPS, VM o contenedor con SSH   |
| Acceso por contraseña al servidor | Usuario y contraseña conocidos |

### Preparar entorno de prueba (si no tienes servidor)

**Opción A: Contenedor Docker**

```bash
# Crear contenedor con SSH habilitado
docker run -d --name ssh-test -p 2222:22 \
  rastasheep/ubuntu-sshd:18.04

# Usuario: root | Contraseña: root
# Conectar: ssh root@localhost -p 2222
```

**Opción B: Máquina Virtual**

```bash
# Usar cualquier VM Linux con SSH instalado
# Asegúrate de que el servicio SSH esté corriendo
sudo systemctl status sshd
```

---

## 🛠️ Paso 1: Verificar Conectividad Básica

Antes de desplegar la llave, verifica que puedes conectarte con contraseña:

```bash
# Conexión básica (ajusta usuario, servidor y puerto)
ssh usuario@servidor

# Si usas puerto no estándar
ssh usuario@servidor -p 2222

# Si estás usando el contenedor Docker
ssh root@localhost -p 2222
```

**Verificación exitosa:**

```
usuario@servidor's password:
Welcome to Ubuntu 22.04 LTS
usuario@servidor:~$
```

---

## 🔑 Paso 2: Desplegar Llave con ssh-copy-id

### Método Recomendado

```bash
# Sintaxis básica
ssh-copy-id usuario@servidor

# Especificar llave específica
ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@servidor

# Con puerto personalizado
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 2222 usuario@servidor
```

### Proceso Esperado

```
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/tu-usuario/.ssh/id_ed25519.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
usuario@servidor's password:

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'usuario@servidor'"
and check to make sure that only the key(s) you wanted were added.
```

### ¿Qué hace ssh-copy-id internamente?

1. Lee tu llave pública (`~/.ssh/id_ed25519.pub`)
2. Se conecta al servidor usando contraseña
3. Crea `~/.ssh/` en el servidor si no existe
4. Añade tu llave pública a `~/.ssh/authorized_keys`
5. Configura permisos correctos (700, 600)

---

## 📝 Paso 3: Método Manual (Entender el Proceso)

Si `ssh-copy-id` no está disponible, puedes hacerlo manualmente:

### En tu máquina local

```bash
# Copiar el contenido de tu llave pública
cat ~/.ssh/id_ed25519.pub
# Selecciona y copia todo el contenido
```

### En el servidor remoto

```bash
# Conectar con contraseña
ssh usuario@servidor

# Crear directorio ~/.ssh si no existe
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Crear/editar authorized_keys
nano ~/.ssh/authorized_keys
# (pega tu llave pública aquí)

# Configurar permisos
chmod 600 ~/.ssh/authorized_keys

# Salir
exit
```

### Método con un solo comando (pipeline)

```bash
# Todo en una línea
cat ~/.ssh/id_ed25519.pub | ssh usuario@servidor "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

---

## ✅ Paso 4: Verificar Autenticación por Llave

### Prueba de conexión

```bash
# Conectar (no debería pedir contraseña, solo passphrase de la llave)
ssh usuario@servidor

# Si configuraste passphrase en tu llave:
# Enter passphrase for key '/home/tu-usuario/.ssh/id_ed25519':
```

### Conexión exitosa con modo verbose

```bash
# Ver proceso de autenticación detallado
ssh -v usuario@servidor 2>&1 | grep -E "(Offering|Authentications|accepted)"

# Salida esperada:
# debug1: Offering public key: /home/usuario/.ssh/id_ed25519 ED25519 SHA256:xxx
# debug1: Server accepts key: /home/usuario/.ssh/id_ed25519 ED25519 SHA256:xxx
# debug1: Authentications that can continue: publickey
# debug1: Authentication succeeded (publickey).
```

### Verificar en el servidor

```bash
# Conectar al servidor y verificar authorized_keys
ssh usuario@servidor

# Ver llaves autorizadas
cat ~/.ssh/authorized_keys

# Deberías ver tu llave pública:
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... tu-nombre@tu-email.com
```

---

## 🔒 Paso 5: Configurar Servidor para Solo Llaves (Opcional)

Una vez que la autenticación por llave funciona, puedes deshabilitar la autenticación por contraseña:

### ⚠️ ADVERTENCIA

> **Solo hazlo si estás seguro de que tu llave funciona.**
> Si deshabilitas contraseñas y pierdes tu llave, **perderás acceso al servidor**.

### Editar configuración del servidor

```bash
# En el servidor
sudo nano /etc/ssh/sshd_config

# Buscar y modificar estas líneas:
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
```

### Reiniciar servicio SSH

```bash
# Reiniciar para aplicar cambios
sudo systemctl restart sshd

# Verificar estado
sudo systemctl status sshd
```

### Probar desde otra terminal (¡importante!)

```bash
# ANTES de cerrar tu sesión actual, abre otra terminal y prueba
ssh usuario@servidor

# Si funciona, puedes cerrar la sesión anterior
# Si NO funciona, usa la sesión anterior para revertir cambios
```

---

## 🧪 Paso 6: Ejercicios de Verificación

### Ejercicio 1: Añadir segunda llave

```bash
# En tu máquina local, genera una segunda llave
ssh-keygen -t ed25519 -f ~/.ssh/id_secundaria -C "secundaria@email.com"

# Despliégala al mismo servidor
ssh-copy-id -i ~/.ssh/id_secundaria.pub usuario@servidor

# Verifica que hay 2 llaves en authorized_keys
ssh usuario@servidor "wc -l ~/.ssh/authorized_keys"
# Esperado: 2
```

### Ejercicio 2: Conectar usando llave específica

```bash
# Forzar uso de llave secundaria
ssh -i ~/.ssh/id_secundaria usuario@servidor

# Verificar cuál llave se usó (modo verbose)
ssh -v -i ~/.ssh/id_secundaria usuario@servidor 2>&1 | grep "Offering"
```

### Ejercicio 3: Intentar con llave incorrecta

```bash
# Crear llave temporal
ssh-keygen -t ed25519 -f /tmp/llave_temp -N ""

# Intentar conectar (debería fallar si contraseñas están deshabilitadas)
ssh -i /tmp/llave_temp -o PasswordAuthentication=no usuario@servidor

# Esperado: Permission denied (publickey)
```

---

## 🐛 Troubleshooting

### Error: "Permission denied (publickey)"

```bash
# Diagnóstico
ssh -vvv usuario@servidor 2>&1 | grep -E "(Trying|Offering|Permission)"

# Causas comunes:
# 1. Llave no está en authorized_keys
# 2. Permisos incorrectos en el servidor
# 3. Usando llave incorrecta

# Verificar en el servidor:
ls -la ~/.ssh/
# drwx------ (700) para .ssh/
# -rw------- (600) para authorized_keys
```

### Error: "Agent admitted failure to sign"

```bash
# El ssh-agent no tiene la llave cargada
ssh-add ~/.ssh/id_ed25519

# Verificar llaves en el agente
ssh-add -l
```

### Error: "Host key verification failed"

```bash
# El servidor cambió su llave (o es la primera conexión)
# Eliminar entrada antigua
ssh-keygen -R servidor

# Conectar de nuevo y aceptar nueva llave
ssh usuario@servidor
```

### Permisos incorrectos en el servidor

```bash
# Conectar con contraseña si aún es posible
ssh usuario@servidor

# Corregir permisos
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R $USER:$USER ~/.ssh
```

### Verificar logs del servidor

```bash
# Ver intentos de conexión SSH
sudo tail -f /var/log/auth.log

# O en sistemas con journald
sudo journalctl -u sshd -f
```

---

## 📊 Resumen de Comandos

| Comando                                     | Descripción                |
| ------------------------------------------- | -------------------------- |
| `ssh-copy-id usuario@servidor`              | Desplegar llave pública    |
| `ssh-copy-id -i llave.pub usuario@servidor` | Desplegar llave específica |
| `ssh -v usuario@servidor`                   | Conexión con debug         |
| `ssh -i ~/.ssh/llave usuario@servidor`      | Usar llave específica      |
| `cat ~/.ssh/authorized_keys`                | Ver llaves autorizadas     |
| `ssh-add -l`                                | Listar llaves en agente    |

---

## 📁 Estado de Archivos

Después de esta práctica:

**En tu máquina local:**

```
~/.ssh/
├── id_ed25519          # Llave privada
├── id_ed25519.pub      # Llave pública
├── known_hosts         # Fingerprint del servidor
└── (config)            # Configuración opcional
```

**En el servidor:**

```
~/.ssh/
├── authorized_keys     # Tu llave pública está aquí
└── (otros archivos)
```

---

## ✅ Checklist de Verificación

Antes de pasar a la siguiente práctica, verifica:

- [ ] `ssh-copy-id` ejecutado exitosamente
- [ ] Conexión sin contraseña funciona (solo pide passphrase)
- [ ] `authorized_keys` en el servidor contiene tu llave
- [ ] Permisos correctos en el servidor (700/600)
- [ ] Puedes ver el proceso de autenticación con `ssh -v`

---

## 🔗 Navegación

| ← Anterior                                                  | Actual          | Siguiente →                                                      |
| ----------------------------------------------------------- | --------------- | ---------------------------------------------------------------- |
| [Práctica 01: Generación](practica-01-generacion-llaves.md) | **Práctica 02** | [Práctica 03: Múltiples Llaves](practica-03-multiples-llaves.md) |

---

<div align="center">

**🎉 ¡Excelente!** Ya puedes conectarte a tu servidor sin contraseña.

En la siguiente práctica aprenderás a gestionar múltiples llaves para diferentes servicios.

[🏠 Volver al inicio de Semana 02](../README.md)

</div>
