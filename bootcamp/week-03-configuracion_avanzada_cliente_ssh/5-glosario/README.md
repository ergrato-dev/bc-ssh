# 📖 Glosario - Semana 03

## Terminología de Configuración SSH

![Glosario](https://img.shields.io/badge/Términos-40+-informational?style=for-the-badge)

---

## A

### AddKeysToAgent

Directiva que añade llaves automáticamente al ssh-agent cuando se usan por primera vez.

```ssh-config
Host *
    AddKeysToAgent yes
```

### Alias (SSH)

Nombre corto definido en `~/.ssh/config` para referirse a un servidor.

```ssh-config
Host mi-alias
    HostName 192.168.1.100
# Uso: ssh mi-alias
```

---

## B

### Bastion Host

Servidor de acceso único a una red privada. También llamado **jump host** o **jump server**.

```
Internet → Bastion → Red Privada
```

### BatchMode

Desactiva prompts interactivos. Útil para scripts automatizados.

```ssh-config
Host script-host
    BatchMode yes
```

---

## C

### Cipher

Algoritmo de cifrado usado para la conexión SSH.

```ssh-config
Host *
    Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
```

### Compression

Habilita compresión de datos en la conexión SSH.

```ssh-config
Host conexion-lenta
    Compression yes
```

### ConnectTimeout

Tiempo máximo en segundos para establecer conexión.

```ssh-config
Host *
    ConnectTimeout 10
```

### ControlMaster

Habilita multiplexing SSH para reutilizar conexiones.

```ssh-config
Host *
    ControlMaster auto
```

**Valores**: `yes`, `no`, `auto`, `autoask`, `ask`

### ControlPath

Ubicación del socket de control para multiplexing.

```ssh-config
Host *
    ControlPath ~/.ssh/sockets/%C
```

**Variables**: `%r` (user), `%h` (host), `%p` (port), `%C` (hash)

### ControlPersist

Tiempo que persiste la conexión master después de cerrar sesiones.

```ssh-config
Host *
    ControlPersist 10m
```

**Valores**: `yes`, `no`, o tiempo (`10m`, `1h`, `600`)

---

## D

### DMZ

**Demilitarized Zone** - Red intermedia entre Internet y red interna donde típicamente reside el bastion.

---

## E

### ExitOnForwardFailure

Termina conexión si falla el port forwarding.

```ssh-config
Host tunnel-host
    ExitOnForwardFailure yes
```

---

## F

### ForwardAgent

Permite que el servidor remoto use tu ssh-agent local.

```ssh-config
Host trusted-host
    ForwardAgent yes
# ⚠️ Riesgo de seguridad en hosts no confiables
```

---

## G

### GlobalKnownHostsFile

Archivo de known_hosts a nivel de sistema.

```
/etc/ssh/ssh_known_hosts
```

---

## H

### HashKnownHosts

Hashea los nombres de host en known_hosts por seguridad.

```ssh-config
Host *
    HashKnownHosts yes
```

### Host

Palabra clave que inicia un bloque de configuración en `~/.ssh/config`.

```ssh-config
Host servidor
    HostName 192.168.1.100
```

### HostName

Nombre real o IP del servidor (distinto del alias).

```ssh-config
Host alias
    HostName real.hostname.com
```

---

## I

### IdentitiesOnly

Solo usar las llaves especificadas con `IdentityFile`.

```ssh-config
Host *
    IdentitiesOnly yes
```

### IdentityFile

Ruta a la llave privada para autenticación.

```ssh-config
Host github.com
    IdentityFile ~/.ssh/id_ed25519_github
```

### Include

Incluye otros archivos de configuración.

```ssh-config
Include ~/.ssh/config.d/*.conf
```

---

## J

### Jump Host

Ver **Bastion Host**. Servidor intermedio para acceder a redes privadas.

---

## K

### KeepAlive

Mantener conexión viva enviando paquetes periódicos.

```ssh-config
Host *
    TCPKeepAlive yes
```

### KnownHostsCommand

Comando externo para verificar llaves de host.

---

## L

### LocalForward

Túnel local: puerto local redirige a puerto remoto.

```ssh-config
Host db-server
    LocalForward 3306 localhost:3306
# Uso: mysql -h localhost -P 3306
```

### LogLevel

Nivel de detalle de logs SSH.

```ssh-config
Host debug-host
    LogLevel VERBOSE
```

**Valores**: `QUIET`, `FATAL`, `ERROR`, `INFO`, `VERBOSE`, `DEBUG`, `DEBUG2`, `DEBUG3`

---

## M

### Master (SSH)

Conexión principal en multiplexing que otras sesiones reutilizan.

### Match

Bloque condicional en configuración SSH.

```ssh-config
Match host *.internal exec "vpn-connected"
    ProxyJump none
```

### Multiplexing

Técnica para compartir una conexión SSH entre múltiples sesiones.

---

## N

### NoHostAuthenticationForLocalhost

Deshabilita verificación de host para localhost.

---

## O

### OpenSSH

Implementación más común del protocolo SSH. Estándar en Linux/Unix/macOS.

---

## P

### PasswordAuthentication

Permite autenticación por contraseña.

```ssh-config
Host secure-host
    PasswordAuthentication no
```

### Port

Puerto SSH del servidor (default: 22).

```ssh-config
Host custom-port
    Port 2222
```

### PreferredAuthentications

Orden de métodos de autenticación a intentar.

```ssh-config
Host *
    PreferredAuthentications publickey,keyboard-interactive
```

### ProxyCommand

Comando para establecer conexión al servidor (método clásico de salto).

```ssh-config
Host interno
    ProxyCommand ssh -W %h:%p bastion
```

### ProxyJump

Método moderno (OpenSSH 7.3+) para saltar a través de bastiones.

```ssh-config
Host interno
    ProxyJump bastion
```

### ProxyUseFdpass

Optimización para ProxyCommand.

---

## R

### RemoteForward

Túnel remoto: puerto en servidor redirige a puerto local.

```ssh-config
Host web-server
    RemoteForward 8080 localhost:3000
```

---

## S

### SendEnv

Variables de entorno a enviar al servidor remoto.

```ssh-config
Host *
    SendEnv LANG LC_*
```

### ServerAliveCountMax

Número de keepalives sin respuesta antes de desconectar.

```ssh-config
Host *
    ServerAliveCountMax 3
```

### ServerAliveInterval

Intervalo en segundos entre keepalives.

```ssh-config
Host *
    ServerAliveInterval 60
```

### Socket (Control)

Archivo especial que permite comunicación entre procesos. Usado por multiplexing.

```bash
ls ~/.ssh/sockets/
# admin@servidor-22
```

### ssh -G

Comando para ver configuración efectiva de un host.

```bash
ssh -G hostname
```

### ssh -O

Comandos de control para multiplexing.

```bash
ssh -O check hostname  # Verificar estado
ssh -O exit hostname   # Cerrar master
```

### ssh_config

Archivo de configuración del cliente SSH.

- Usuario: `~/.ssh/config`
- Sistema: `/etc/ssh/ssh_config`

### StrictHostKeyChecking

Control de verificación de llaves de host.

```ssh-config
Host dev-*
    StrictHostKeyChecking no

Host prod-*
    StrictHostKeyChecking yes
```

**Valores**: `yes`, `no`, `accept-new`, `ask`

---

## T

### TCPKeepAlive

Envía keepalives a nivel TCP para detectar conexiones muertas.

```ssh-config
Host *
    TCPKeepAlive yes
```

### Tunnel

Tipo de túnel a crear (para VPN sobre SSH).

```ssh-config
Host vpn
    Tunnel yes
```

---

## U

### UpdateHostKeys

Actualiza automáticamente llaves de host cuando rotan.

```ssh-config
Host *
    UpdateHostKeys yes
```

### User

Usuario para conexión SSH.

```ssh-config
Host servidor
    User admin
```

### UserKnownHostsFile

Archivo personal de known_hosts.

```ssh-config
Host dev-*
    UserKnownHostsFile /dev/null
```

---

## V

### VisualHostKey

Muestra representación ASCII de la huella del servidor.

```ssh-config
Host secure-host
    VisualHostKey yes
```

---

## W

### Wildcard

Patrones para aplicar configuración a múltiples hosts.

```ssh-config
Host dev-*        # Cualquier host que empiece con dev-
Host *.local      # Cualquier host terminando en .local
Host *            # Todos los hosts
```

---

## Índice Rápido por Categoría

### Conexión

`Host`, `HostName`, `Port`, `User`, `ConnectTimeout`

### Autenticación

`IdentityFile`, `IdentitiesOnly`, `PreferredAuthentications`, `PasswordAuthentication`

### Salto (ProxyJump)

`ProxyJump`, `ProxyCommand`, `Bastion Host`, `Jump Host`

### Multiplexing

`ControlMaster`, `ControlPath`, `ControlPersist`, `Socket`

### Seguridad

`StrictHostKeyChecking`, `ForwardAgent`, `HashKnownHosts`, `VisualHostKey`

### Keep-Alive

`ServerAliveInterval`, `ServerAliveCountMax`, `TCPKeepAlive`

### Túneles

`LocalForward`, `RemoteForward`, `Tunnel`

---

<div align="center">

**📖 Glosario - Semana 03**

_Terminología de configuración SSH_

</div>
