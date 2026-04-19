# 📚 Módulo 02: Arquitectura Cliente-Servidor

![Duración](https://img.shields.io/badge/Duración-20_min-blue?style=flat-square)
![Nivel](https://img.shields.io/badge/Nivel-Principiante-green?style=flat-square)

> _"SSH sigue el modelo cliente-servidor: tú (cliente) te conectas a una máquina remota (servidor). Entender esta arquitectura es fundamental para diagnosticar problemas de conexión."_

---

## 🎯 Objetivos del Módulo

Al finalizar este módulo, serás capaz de:

- [ ] Identificar los componentes del cliente y servidor SSH
- [ ] Comprender el flujo completo de una conexión SSH
- [ ] Conocer los puertos y protocolos involucrados
- [ ] Localizar los archivos de configuración importantes

---

## 📊 Diagrama: Arquitectura Cliente-Servidor

![Arquitectura SSH](../0-assets/01-arquitectura-ssh.svg)

---

## 📋 Contenido

### 2.1 Componentes del Sistema SSH

SSH tiene dos componentes principales que trabajan juntos:

```
┌─────────────────┐                    ┌─────────────────┐
│   TU MÁQUINA    │                    │ SERVIDOR REMOTO │
│   (Cliente)     │                    │    (Servidor)   │
├─────────────────┤                    ├─────────────────┤
│ • ssh           │ ←── TCP/22 ───→   │ • sshd          │
│ • ssh-keygen    │    (cifrado)       │ • sshd_config   │
│ • ssh-agent     │                    │ • authorized_   │
│ • ~/.ssh/       │                    │   keys          │
└─────────────────┘                    └─────────────────┘
```

#### Resumen de Roles

| Componente    | Ubicación      | Función                        |
| ------------- | -------------- | ------------------------------ |
| **Cliente**   | Tu computadora | Inicia la conexión             |
| **Servidor**  | Máquina remota | Acepta conexiones              |
| **Protocolo** | Red            | Reglas de comunicación (SSH-2) |
| **Puerto**    | TCP/22         | Canal de comunicación          |

---

### 2.2 El Cliente SSH

El cliente SSH es el programa que usas para conectarte a servidores remotos.

#### Comando Principal: `ssh`

```bash
# Sintaxis básica
ssh [opciones] [usuario@]hostname [comando]

# Ejemplos
ssh servidor.com                    # Conectar con tu usuario actual
ssh admin@192.168.1.100            # Conectar como 'admin'
ssh -p 2222 usuario@servidor.com   # Puerto no estándar
ssh usuario@servidor.com ls /var   # Ejecutar comando remoto
```

#### Herramientas del Cliente

| Herramienta   | Función                   | Ejemplo                              |
| ------------- | ------------------------- | ------------------------------------ |
| `ssh`         | Conexión remota           | `ssh usuario@servidor`               |
| `ssh-keygen`  | Generar llaves            | `ssh-keygen -t ed25519`              |
| `ssh-copy-id` | Copiar llave pública      | `ssh-copy-id usuario@servidor`       |
| `ssh-agent`   | Gestión de llaves         | `eval $(ssh-agent)`                  |
| `ssh-add`     | Añadir llaves al agent    | `ssh-add ~/.ssh/id_ed25519`          |
| `scp`         | Copiar archivos           | `scp archivo usuario@servidor:/ruta` |
| `sftp`        | Transferencia interactiva | `sftp usuario@servidor`              |

#### Archivos del Cliente (~/.ssh/)

```bash
~/.ssh/
├── config              # Configuración personalizada (aliases, opciones)
├── known_hosts         # Fingerprints de servidores conocidos
├── id_ed25519          # Tu llave PRIVADA (¡nunca compartir!)
├── id_ed25519.pub      # Tu llave pública (puedes compartir)
└── authorized_keys     # (Solo si tu máquina también es servidor)
```

**Permisos Críticos:**

```bash
# Los permisos incorrectos = SSH rechaza las llaves
chmod 700 ~/.ssh              # Solo tú puedes acceder al directorio
chmod 600 ~/.ssh/id_ed25519   # Solo tú puedes leer la llave privada
chmod 644 ~/.ssh/id_ed25519.pub  # La pública puede ser leída
chmod 644 ~/.ssh/known_hosts  # Puede ser leído
chmod 600 ~/.ssh/config       # Solo tú
```

#### Verificar tu Cliente SSH

```bash
# Ver versión instalada
ssh -V
# Salida: OpenSSH_8.9p1 Ubuntu-3ubuntu0.1, OpenSSL 3.0.2

# Ver dónde está instalado
which ssh
# Salida: /usr/bin/ssh

# Probar conectividad básica (sin conectar)
ssh -v usuario@servidor.com 2>&1 | head -20
```

---

### 2.3 El Servidor SSH (sshd)

El servidor SSH es un **daemon** (servicio en segundo plano) que espera conexiones entrantes.

#### El Daemon sshd

```bash
# sshd = SSH Daemon (servidor)
# Escucha en puerto 22 por defecto
# Proceso que corre continuamente esperando conexiones
```

**Gestión del Servicio:**

```bash
# Verificar estado (systemd)
sudo systemctl status sshd

# Iniciar/Detener/Reiniciar
sudo systemctl start sshd
sudo systemctl stop sshd
sudo systemctl restart sshd    # Necesario después de cambiar config

# Habilitar al inicio del sistema
sudo systemctl enable sshd

# Ver si está escuchando
sudo ss -tlnp | grep ssh
# Salida: LISTEN  0  128  0.0.0.0:22  0.0.0.0:*  users:(("sshd",pid=1234,fd=3))
```

#### Archivos del Servidor (/etc/ssh/)

```bash
/etc/ssh/
├── sshd_config         # Configuración principal del servidor
├── ssh_config          # Configuración por defecto del cliente
├── ssh_host_ed25519_key      # Llave privada del servidor (ED25519)
├── ssh_host_ed25519_key.pub  # Llave pública del servidor
├── ssh_host_rsa_key          # Llave privada del servidor (RSA)
├── ssh_host_rsa_key.pub      # Llave pública del servidor
└── moduli              # Parámetros para Diffie-Hellman
```

#### Configuración Básica de sshd_config

```bash
# Ver configuración actual (sin comentarios)
sudo grep -v '^#' /etc/ssh/sshd_config | grep -v '^$'

# Directivas importantes:
Port 22                     # Puerto de escucha
PermitRootLogin no          # ¿Permitir login como root?
PasswordAuthentication yes  # ¿Permitir contraseñas?
PubkeyAuthentication yes    # ¿Permitir llaves públicas?
```

#### Host Keys (Llaves del Servidor)

Cada servidor SSH tiene su propia identidad criptográfica:

```bash
# Ver fingerprint de las llaves del servidor
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
# Salida: 256 SHA256:abc123... root@servidor (ED25519)

# Este fingerprint es lo que verificas en la primera conexión
```

---

### 2.4 Flujo de Conexión

![Flujo de Conexión SSH](../0-assets/02-flujo-conexion.svg)

#### Los 7 Pasos de una Conexión SSH

Cuando ejecutas `ssh usuario@servidor`, ocurre lo siguiente:

```
Paso 1: Conexión TCP
────────────────────
Cliente                          Servidor
   │                                │
   │──── SYN (TCP puerto 22) ──────→│
   │←─── SYN-ACK ──────────────────│
   │──── ACK ─────────────────────→│
   │                                │
   └── Conexión TCP establecida ────┘
```

```
Paso 2: Intercambio de Versiones
────────────────────────────────
Cliente                          Servidor
   │                                │
   │←── SSH-2.0-OpenSSH_8.9 ───────│
   │─── SSH-2.0-OpenSSH_8.9 ──────→│
   │                                │
   └── Ambos soportan SSH-2 ────────┘
```

```
Paso 3: Negociación de Algoritmos
─────────────────────────────────
Cliente                          Servidor
   │                                │
   │←──────── "Yo soporto:" ───────│
   │          AES-256, ChaCha20... │
   │                                │
   │─── "Yo también, usemos:" ────→│
   │    AES-256-GCM + Ed25519      │
   │                                │
   └── Algoritmos acordados ────────┘
```

```
Paso 4: Intercambio de Llaves (Diffie-Hellman)
──────────────────────────────────────────────
Cliente                          Servidor
   │                                │
   │←────── Valores DH ────────────│
   │─────── Valores DH ───────────→│
   │                                │
   └── Llave de sesión generada ────┘
       (ambos tienen la misma llave
        sin haberla transmitido)
```

```
Paso 5: Verificación del Servidor
─────────────────────────────────
Cliente                          Servidor
   │                                │
   │←── Firma con host key ────────│
   │                                │
   │ ¿El fingerprint coincide      │
   │  con ~/.ssh/known_hosts?      │
   │                                │
   │ SI → Continuar                 │
   │ NO → Advertencia al usuario   │
   └────────────────────────────────┘
```

```
Paso 6: Autenticación del Usuario
─────────────────────────────────
Cliente                          Servidor
   │                                │
   │─── Método: publickey ────────→│
   │    Llave: id_ed25519.pub      │
   │                                │
   │    ¿Está en authorized_keys?  │
   │                                │
   │←── Challenge cifrado ─────────│
   │─── Challenge descifrado ─────→│
   │                                │
   │←── ✅ Autenticado ────────────│
   └────────────────────────────────┘
```

```
Paso 7: Sesión Establecida
──────────────────────────
Cliente                          Servidor
   │                                │
   │←── Shell interactivo ─────────│
   │                                │
   │   Todo el tráfico está        │
   │   cifrado con AES-256         │
   │                                │
   usuario@servidor:~$ _
```

#### Ver el Flujo en Tiempo Real

Puedes ver todo este proceso con la opción verbose:

```bash
# -v = verbose (1 nivel)
ssh -v usuario@servidor.com

# -vv = más detalle (2 niveles)
ssh -vv usuario@servidor.com

# -vvv = máximo detalle (3 niveles) - para debugging
ssh -vvv usuario@servidor.com
```

**Ejemplo de salida:**

```
debug1: Connecting to servidor.com port 22.
debug1: Connection established.
debug1: Local version string SSH-2.0-OpenSSH_8.9
debug1: Remote protocol version 2.0, remote software version OpenSSH_8.9
debug1: SSH2_MSG_KEXINIT sent
debug1: SSH2_MSG_KEXINIT received
debug1: kex: algorithm: curve25519-sha256
debug1: kex: host key algorithm: ssh-ed25519
debug1: Host 'servidor.com' is known and matches the ED25519 host key.
debug1: Authentications that can continue: publickey,password
debug1: Trying private key: /home/usuario/.ssh/id_ed25519
debug1: Authentication succeeded (publickey).
```

---

## 💡 Puntos Clave para Recordar

1. **Cliente (ssh)**: Inicia conexiones desde tu máquina
2. **Servidor (sshd)**: Daemon que acepta conexiones, puerto 22
3. **~/.ssh/**: Directorio del cliente con llaves y configuración
4. **/etc/ssh/**: Directorio del servidor con configuración global
5. **Permisos son críticos**: 700 para ~/.ssh/, 600 para llaves privadas
6. **El flujo tiene 7 pasos**: TCP → Versiones → Algoritmos → DH → Host → Auth → Sesión

---

## 🧪 Comprueba tu Conocimiento

1. ¿Qué comando usas para conectarte a un servidor SSH?
2. ¿En qué directorio se guardan las llaves del cliente?
3. ¿Cuál es el puerto por defecto de SSH?
4. ¿Qué archivo contiene la configuración del servidor SSH?
5. ¿Qué permisos debe tener tu llave privada?

<details>
<summary>Ver respuestas</summary>

1. `ssh usuario@servidor`
2. `~/.ssh/`
3. Puerto 22 (TCP)
4. `/etc/ssh/sshd_config`
5. `600` (solo lectura/escritura para el propietario)

</details>

---

## 🧭 Navegación

| ⬅️ Anterior                              | 📚 Índice           | Siguiente ➡️                              |
| ---------------------------------------- | ------------------- | ----------------------------------------- |
| [Historia](01-historia-evolucion-ssh.md) | [Teoría](README.md) | [Criptografía](03-criptografia-basica.md) |
