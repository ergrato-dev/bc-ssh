# 💻 Práctica 02: Primera Conexión Remota con SSH

![Dificultad](https://img.shields.io/badge/Dificultad-⭐_Básica-green?style=flat-square)
![Duración](https://img.shields.io/badge/Duración-30_minutos-blue?style=flat-square)
![Puntos](https://img.shields.io/badge/Puntos-10-orange?style=flat-square)

---

## 🎯 Objetivo

Realizar tu primera conexión SSH exitosa a un servidor remoto usando autenticación por contraseña. Aprenderás a interpretar los mensajes del cliente SSH y a verificar la identidad del servidor.

---

## 📋 Prerequisitos

- ✅ Práctica 01 completada (cliente SSH instalado)
- ✅ Acceso a un servidor SSH (VPS, VM local, o servidor de prueba)
- ✅ Credenciales: IP del servidor, usuario y contraseña
- ✅ Conexión a internet

---

## 🖥️ Opciones de Servidor para Práctica

### Opción A: VPS Cloud (Recomendado)

Crea un servidor económico para practicar:

| Proveedor    | Costo  | Enlace                   |
| ------------ | ------ | ------------------------ |
| DigitalOcean | $6/mes | https://digitalocean.com |
| Linode       | $5/mes | https://linode.com       |
| Vultr        | $5/mes | https://vultr.com        |

**Configuración recomendada:**

- Sistema: Ubuntu 22.04 LTS
- RAM: 1GB (mínimo)
- Autenticación: Password (para esta práctica)

### Opción B: Máquina Virtual Local

```bash
# Usando Multipass (Ubuntu VMs fáciles)
# Instalar Multipass
sudo snap install multipass  # Linux
brew install multipass       # macOS

# Crear VM con Ubuntu
multipass launch --name servidor-ssh

# Obtener IP de la VM
multipass info servidor-ssh
```

### Opción C: Contenedor Docker

```bash
# Crear contenedor con SSH habilitado
docker run -d \
  --name ssh-server \
  -p 2222:22 \
  -e SSH_USERS=estudiante:password123 \
  panubo/sshd

# Conectar al contenedor
ssh estudiante@localhost -p 2222
```

---

## 🔌 Anatomía del Comando SSH

```bash
ssh [opciones] usuario@servidor [-p puerto]
```

| Componente  | Descripción                        | Ejemplo                            |
| ----------- | ---------------------------------- | ---------------------------------- |
| `ssh`       | Comando principal                  | `ssh`                              |
| `usuario`   | Nombre de usuario en el servidor   | `root`, `ubuntu`, `admin`          |
| `@`         | Separador                          | `@`                                |
| `servidor`  | IP o hostname del servidor         | `192.168.1.100`, `mi-servidor.com` |
| `-p puerto` | Puerto SSH (opcional, default: 22) | `-p 2222`                          |

---

## 🚀 Tu Primera Conexión

### Paso 1: Preparar los datos de conexión

Anota la información de tu servidor:

```
IP/Hostname: _________________ (ej: 134.122.15.92)
Puerto:      _________________ (ej: 22)
Usuario:     _________________ (ej: root)
Contraseña:  _________________ (ej: MiPassword123)
```

### Paso 2: Ejecutar el comando SSH

```bash
# Conexión básica (puerto 22 por defecto)
ssh usuario@ip-del-servidor

# Ejemplo real
ssh root@134.122.15.92

# Si el puerto es diferente a 22
ssh root@134.122.15.92 -p 2222
```

### Paso 3: Verificar la huella digital del servidor

La primera vez que te conectas, verás este mensaje:

```
The authenticity of host '134.122.15.92 (134.122.15.92)' can't be established.
ED25519 key fingerprint is SHA256:Kj3nF8dL9mS2pQ4rT6vY8wZ1xC3bN5mL7kJ9hG0fXYZ.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

**¿Qué significa esto?**

SSH te está preguntando si confías en este servidor. La "huella digital" (fingerprint) es un identificador único del servidor que deberías verificar si es posible.

**Acción:** Escribe `yes` y presiona Enter.

```
yes
```

Verás:

```
Warning: Permanently added '134.122.15.92' (ED25519) to the list of known hosts.
```

El servidor ahora está guardado en `~/.ssh/known_hosts`.

### Paso 4: Ingresar la contraseña

```
root@134.122.15.92's password:
```

Escribe tu contraseña y presiona Enter.

> **Nota:** No verás caracteres mientras escribes la contraseña. Esto es normal y es una medida de seguridad.

### Paso 5: ¡Conexión exitosa!

Verás algo como:

```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-88-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

Last login: Thu Nov 28 10:30:15 2025 from 186.84.xxx.xxx
root@servidor:~#
```

**¡Felicidades!** Estás conectado al servidor remoto.

---

## 🔍 Explorando la Sesión SSH

Una vez conectado, ejecuta estos comandos para verificar tu conexión:

### Verificar usuario actual

```bash
whoami
# Salida: root (o el usuario con el que te conectaste)
```

### Verificar hostname del servidor

```bash
hostname
# Salida: servidor (nombre del servidor)
```

### Verificar IP del servidor

```bash
hostname -I
# Salida: 134.122.15.92 10.0.0.5
```

### Ver información del sistema

```bash
uname -a
# Salida: Linux servidor 5.15.0-88-generic #98-Ubuntu SMP...
```

### Ver tu dirección IP de origen

```bash
echo $SSH_CLIENT
# Salida: 186.84.xxx.xxx 54321 22
# (tu IP, puerto origen, puerto destino)
```

### Ver variables de entorno SSH

```bash
env | grep SSH
# SSH_CONNECTION=186.84.xxx.xxx 54321 134.122.15.92 22
# SSH_CLIENT=186.84.xxx.xxx 54321 22
# SSH_TTY=/dev/pts/0
```

---

## 🚪 Cerrar la Conexión SSH

Hay varias formas de terminar una sesión SSH:

### Método 1: Comando exit

```bash
exit
# Salida: logout
# Connection to 134.122.15.92 closed.
```

### Método 2: Comando logout

```bash
logout
```

### Método 3: Atajo de teclado

```
Ctrl + D
```

### Método 4: Secuencia de escape SSH

Si la conexión se congela, usa la secuencia de escape:

```
~.
```

(Presiona Enter, luego `~`, luego `.`)

---

## 🔑 Opciones Útiles del Comando SSH

### Modo verbose (para debug)

```bash
# Un nivel de detalle
ssh -v usuario@servidor

# Dos niveles de detalle
ssh -vv usuario@servidor

# Máximo detalle
ssh -vvv usuario@servidor
```

**Ejemplo de salida verbose:**

```
debug1: Connecting to 134.122.15.92 [134.122.15.92] port 22.
debug1: Connection established.
debug1: Authenticating to 134.122.15.92:22 as 'root'
debug1: SSH2_MSG_KEXINIT sent
debug1: SSH2_MSG_KEXINIT received
...
```

### Especificar puerto

```bash
ssh usuario@servidor -p 2222
```

### Ejecutar comando remoto sin abrir shell

```bash
# Ejecutar un comando y volver
ssh usuario@servidor "hostname && uptime"

# Ejemplo
ssh root@134.122.15.92 "df -h"
```

### Conexión con timeout

```bash
# Desconectar si no hay respuesta en 10 segundos
ssh -o ConnectTimeout=10 usuario@servidor
```

---

## 🐛 Troubleshooting

### Error: "Connection refused"

```
ssh: connect to host 134.122.15.92 port 22: Connection refused
```

**Causas posibles:**

1. El servicio SSH no está corriendo en el servidor
2. El firewall bloquea el puerto 22
3. El puerto SSH es diferente (prueba con `-p`)

**Solución:**

```bash
# Verificar si el puerto está abierto
nc -zv 134.122.15.92 22

# Probar otro puerto
ssh usuario@servidor -p 2222
```

### Error: "Connection timed out"

```
ssh: connect to host 134.122.15.92 port 22: Connection timed out
```

**Causas posibles:**

1. IP incorrecta
2. El servidor está apagado
3. Firewall bloquea la conexión

**Solución:**

```bash
# Verificar conectividad
ping 134.122.15.92

# Verificar con traceroute
traceroute 134.122.15.92
```

### Error: "Permission denied"

```
Permission denied (publickey,password).
```

**Causas posibles:**

1. Contraseña incorrecta
2. Usuario no existe
3. Autenticación por password deshabilitada

**Solución:**

```bash
# Verificar que el usuario existe
# Verificar la contraseña
# Usar modo verbose para más info
ssh -v usuario@servidor
```

### Error: "Host key verification failed"

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

**Causa:** La huella digital del servidor cambió (reinstalación, IP reasignada, etc.)

**Solución:**

```bash
# Eliminar la entrada antigua
ssh-keygen -R 134.122.15.92

# Volver a conectar
ssh usuario@servidor
```

---

## 📝 Checklist de Verificación

Antes de continuar, confirma que puedes:

- [ ] Conectarte al servidor con `ssh usuario@servidor`
- [ ] Ver el mensaje de huella digital y aceptarlo
- [ ] Ingresar la contraseña correctamente
- [ ] Ejecutar comandos como `whoami`, `hostname`
- [ ] Cerrar la sesión con `exit`
- [ ] Reconectarte sin ver el mensaje de huella (ya guardado)

---

## 🎯 Entregable

Captura de pantalla mostrando:

1. El comando SSH usado para conectarte
2. La sesión activa con `whoami` y `hostname` ejecutados
3. El cierre de sesión con `exit`

---

## ⏭️ Siguiente Práctica

[Práctica 03: Configuración del Archivo Config →](practica-03-archivo-config.md)

---

<div align="center">

**Semana 01 • Práctica 02 de 03**

[← Práctica anterior](practica-01-instalacion-cliente.md) • [Volver al índice](README.md)

</div>
