# 📚 Módulo 03: Anatomía de las Llaves SSH

![Duración](https://img.shields.io/badge/Duración-20_min-blue?style=flat-square)
![Nivel](https://img.shields.io/badge/Nivel-Principiante-green?style=flat-square)

> _"Entender la estructura de tus llaves te permite gestionarlas con confianza y detectar problemas antes de que ocurran."_

---

## 🎯 Objetivos del Módulo

Al finalizar este módulo, serás capaz de:

- [ ] Identificar los archivos que componen un par de llaves
- [ ] Interpretar el contenido de una llave pública
- [ ] Entender el formato de authorized_keys
- [ ] Gestionar permisos correctos para archivos SSH
- [ ] Usar comandos para inspeccionar llaves

---

## 📊 Diagrama: Authorized Keys

![Authorized Keys](../0-assets/03-authorized-keys.svg)

---

## 📋 Contenido

### 3.1 Los Archivos del Par de Llaves

#### Estructura en ~/.ssh/

```bash
~/.ssh/
├── id_ed25519           # 🔐 Llave PRIVADA (SECRETA)
├── id_ed25519.pub       # 🔓 Llave PÚBLICA (compartir)
├── config               # ⚙️ Configuración del cliente
├── known_hosts          # 📋 Servidores conocidos
└── authorized_keys      # 🔑 Llaves autorizadas (si eres servidor)
```

#### Nomenclatura de Archivos

| Algoritmo      | Privada          | Pública              |
| -------------- | ---------------- | -------------------- |
| Ed25519        | `id_ed25519`     | `id_ed25519.pub`     |
| RSA            | `id_rsa`         | `id_rsa.pub`         |
| ECDSA          | `id_ecdsa`       | `id_ecdsa.pub`       |
| DSA (obsoleto) | `id_dsa`         | `id_dsa.pub`         |
| Personalizada  | `nombre_ed25519` | `nombre_ed25519.pub` |

---

### 3.2 La Llave Privada

#### ⚠️ NUNCA Compartir

```
┌─────────────────────────────────────────────────────────────┐
│                    🔐 LLAVE PRIVADA                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ❌ NUNCA subir a GitHub/GitLab                            │
│  ❌ NUNCA enviar por email                                 │
│  ❌ NUNCA copiar a otro usuario                            │
│  ❌ NUNCA pegar en foros/chats                             │
│                                                             │
│  ✅ Mantener solo en tu máquina                            │
│  ✅ Proteger con passphrase                                │
│  ✅ Permisos 600 (solo tú puedes leer)                     │
│  ✅ Hacer backup cifrado en lugar seguro                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Contenido de una Llave Privada

```bash
$ cat ~/.ssh/id_ed25519
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABDx
zF3k+K... [datos cifrados] ...
-----END OPENSSH PRIVATE KEY-----
```

#### Anatomía de la Llave Privada

```
-----BEGIN OPENSSH PRIVATE KEY-----     ← Cabecera (identifica el tipo)
b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jd    ← Datos en Base64
HIsAAAAGYmNyeXB0AAAAGAAAABDxzF3k+Kxm    │
... [múltiples líneas] ...               │ Contenido cifrado
JvbmUAAAAEc3NoOgAAAGAAAABwNDpF+k0FqZ    │ si tiene passphrase
-----END OPENSSH PRIVATE KEY-----       ← Pie
```

#### Formato Interno (OpenSSH)

```
Llave privada Ed25519 contiene:
├── Tipo de cifrado (si tiene passphrase)
├── Parámetros de derivación de clave
├── Llave pública (sí, está incluida)
├── Llave privada propiamente
├── Comentario
└── Padding y checksum
```

---

### 3.3 La Llave Pública

#### Formato de la Llave Pública

```bash
$ cat ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPsF5pJwT3QhK2m4n1oZvL8eD9kX7j+Pm3Y1qRsWxZt admin@empresa.com
```

#### Anatomía Detallada

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... admin@empresa.com
└────┬────┘ └────────────┬───────────┘ └───────┬────────┘
     │                   │                      │
 Algoritmo           Llave                 Comentario
                   (Base64)               (identificador)
```

| Parte          | Descripción                    | Ejemplo                  |
| -------------- | ------------------------------ | ------------------------ |
| **Algoritmo**  | Tipo de llave                  | `ssh-ed25519`, `ssh-rsa` |
| **Llave**      | Datos criptográficos en Base64 | `AAAAC3NzaC1...`         |
| **Comentario** | Identificador legible          | `usuario@hostname`       |

#### Comparación de Longitud

```bash
# Ed25519 (68 caracteres de llave)
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPsF5pJwT3QhK2m4n1oZvL8eD9kX7j+Pm3Y1qRsWxZt user@host

# RSA-4096 (736+ caracteres de llave)
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLpFt5X8YrJwV3xNlD...
...[muchas líneas más]...
...9Q2k5E7C1qNPx3K0g4o8w== user@host
```

---

### 3.4 El Archivo authorized_keys

#### Ubicación y Propósito

```bash
# En el SERVIDOR, para cada usuario:
/home/usuario/.ssh/authorized_keys

# Contiene las llaves públicas que pueden conectarse
# Una llave por línea
```

#### Formato del Archivo

```bash
$ cat ~/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1... laptop-personal
ssh-ed25519 AAAAC3NzaC1... desktop-trabajo
ssh-rsa AAAAB3NzaC1yc2E... servidor-backup
```

#### Opciones Avanzadas (por llave)

```bash
# Formato con opciones:
# [opciones] tipo llave comentario

# Ejemplos:
# Llave sin restricciones
ssh-ed25519 AAAAC3NzaC1... usuario@laptop

# Llave restringida a un comando
command="/usr/bin/backup.sh" ssh-ed25519 AAAAC3NzaC1... backup-server

# Llave con restricción de IP
from="192.168.1.*" ssh-ed25519 AAAAC3NzaC1... oficina

# Llave sin port forwarding
no-port-forwarding ssh-ed25519 AAAAC3NzaC1... limitado

# Múltiples opciones
from="10.0.0.*",no-pty,command="/bin/df" ssh-ed25519 AAAAC3... monitoreo
```

#### Opciones Comunes

| Opción                  | Descripción                     |
| ----------------------- | ------------------------------- |
| `command="..."`         | Solo puede ejecutar ese comando |
| `from="patrón"`         | Solo desde esas IPs             |
| `no-port-forwarding`    | Deshabilitar túneles            |
| `no-pty`                | Sin terminal interactiva        |
| `no-agent-forwarding`   | No reenviar ssh-agent           |
| `no-X11-forwarding`     | No reenviar X11                 |
| `environment="VAR=val"` | Establecer variable             |

---

### 3.5 Permisos Críticos

#### Permisos Requeridos

```bash
# Directorio .ssh
drwx------  ~/.ssh/              # 700 - solo propietario

# Llave privada (CRÍTICO)
-rw-------  ~/.ssh/id_ed25519    # 600 - solo propietario lee/escribe

# Llave pública
-rw-r--r--  ~/.ssh/id_ed25519.pub # 644 - todos pueden leer

# Archivo config
-rw-------  ~/.ssh/config        # 600 - solo propietario

# Known hosts
-rw-r--r--  ~/.ssh/known_hosts   # 644 - todos pueden leer

# Authorized keys (en servidor)
-rw-------  ~/.ssh/authorized_keys # 600 - solo propietario
```

#### Comandos para Corregir Permisos

```bash
# Corregir todos los permisos de una vez
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/authorized_keys 2>/dev/null
chmod 644 ~/.ssh/*.pub
chmod 644 ~/.ssh/known_hosts
```

#### Errores Comunes de Permisos

```bash
# Error típico si los permisos son incorrectos:
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/home/user/.ssh/id_ed25519' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.

# Solución:
chmod 600 ~/.ssh/id_ed25519
```

---

### 3.6 Comandos para Inspeccionar Llaves

#### Ver Fingerprint de una Llave

```bash
# Fingerprint de tu llave pública
ssh-keygen -lf ~/.ssh/id_ed25519.pub

# Salida:
256 SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s admin@empresa.com (ED25519)
│    └────────────────────┬──────────────────────┘ └───────┬─────────┘  └───┬───┘
│                         │                                │               │
Bits                 Fingerprint                      Comentario      Algoritmo
```

#### Opciones de ssh-keygen -l

```bash
# Ver fingerprint en diferentes formatos
ssh-keygen -lf ~/.ssh/id_ed25519.pub                    # SHA256 (default)
ssh-keygen -lf ~/.ssh/id_ed25519.pub -E md5             # MD5 (legacy)
ssh-keygen -lf ~/.ssh/id_ed25519.pub -E sha256          # SHA256 explícito

# Mostrar art visual (útil para verificación)
ssh-keygen -lvf ~/.ssh/id_ed25519.pub

# Salida con art:
256 SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s (ED25519)
+--[ED25519 256]--+
|      ..o.       |
|     o o.o       |
|    . =.+ .      |
|     o B.+.      |
|    . +.S.+      |
|   . o =.o .     |
|    o.B.=.  .    |
|   ..=oO.+.. .   |
|    .E*=+.oo.    |
+----[SHA256]-----+
```

#### Verificar Llave Privada vs Pública

```bash
# Extraer llave pública desde la privada
ssh-keygen -yf ~/.ssh/id_ed25519

# Comparar con la pública existente
diff <(ssh-keygen -yf ~/.ssh/id_ed25519) ~/.ssh/id_ed25519.pub

# Si no hay salida = coinciden ✅
```

#### Cambiar Passphrase

```bash
# Cambiar passphrase de una llave existente
ssh-keygen -p -f ~/.ssh/id_ed25519

# Interactivo:
Enter old passphrase: ********
Enter new passphrase: ********
Enter same passphrase again: ********
Your identification has been saved with the new passphrase.
```

#### Cambiar Comentario

```bash
# Cambiar el comentario de una llave
ssh-keygen -c -f ~/.ssh/id_ed25519

# Interactivo:
Enter passphrase: ********
Comment "old@comment" -> "new@comment"
The comment in your key file has been changed.
```

---

### 3.7 El Archivo known_hosts

#### Propósito

Almacena los fingerprints de servidores a los que te has conectado, previeniendo ataques MITM.

```bash
$ cat ~/.ssh/known_hosts
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
servidor.com,192.168.1.100 ssh-ed25519 AAAAC3NzaC1...
```

#### Formato

```
hostname[,IP] algoritmo llave_publica
```

#### Comandos Útiles

```bash
# Eliminar una entrada (si el servidor cambió)
ssh-keygen -R hostname

# Ver fingerprint de un servidor remoto
ssh-keyscan -t ed25519 hostname

# Añadir manualmente
ssh-keyscan -t ed25519 hostname >> ~/.ssh/known_hosts
```

---

## 💡 Puntos Clave para Recordar

1. **Llave privada = SECRETA** - nunca compartir, permisos 600
2. **Llave pública = compartible** - va en authorized_keys del servidor
3. **authorized_keys** - una llave pública por línea, puede tener opciones
4. **Permisos son críticos** - SSH rechaza llaves con permisos incorrectos
5. **Fingerprint** - usa `ssh-keygen -lf` para verificar llaves
6. **known_hosts** - protege contra MITM, limpiar con `ssh-keygen -R`

---

## 🧪 Comprueba tu Conocimiento

1. ¿Qué permisos debe tener la llave privada?
2. ¿Dónde se coloca la llave pública en el servidor?
3. ¿Qué contiene el comentario de una llave pública?
4. ¿Cómo verificas el fingerprint de tu llave?
5. ¿Qué opción de authorized_keys restringe una llave a ejecutar solo un comando?

<details>
<summary>Ver respuestas</summary>

1. **600** (solo el propietario puede leer y escribir).
2. En `~/.ssh/authorized_keys` del usuario en el servidor.
3. Un identificador legible, típicamente `usuario@hostname` o un email.
4. Con `ssh-keygen -lf ~/.ssh/id_ed25519.pub`.
5. `command="/ruta/al/comando"` al inicio de la línea de la llave.

</details>

---

## 🧭 Navegación

| ⬅️ Anterior                                     | 📚 Índice           | Siguiente ➡️                          |
| ----------------------------------------------- | ------------------- | ------------------------------------- |
| [Algoritmos de Llaves](02-algoritmos-llaves.md) | [Teoría](README.md) | [Prácticas](../2-practicas/README.md) |
