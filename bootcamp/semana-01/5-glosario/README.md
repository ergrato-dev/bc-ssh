# 📖 Glosario SSH - Semana 01

![Tipo](https://img.shields.io/badge/Tipo-Glosario-orange?style=flat-square)
![Términos](https://img.shields.io/badge/Términos-40+-green?style=flat-square)
![Nivel](https://img.shields.io/badge/Nivel-Principiante-blue?style=flat-square)

---

## 📚 Terminología SSH para Principiantes

Glosario de términos técnicos que encontrarás en esta semana del bootcamp.

---

## A

### Autenticación

- **Definición:** Proceso de verificar la identidad de un usuario o sistema
- **En SSH:** Puede ser por contraseña o por llave pública
- **Ejemplo:** Cuando ingresas tu contraseña al conectarte por SSH

### Agent (SSH Agent)

- **Definición:** Programa que mantiene tus llaves privadas en memoria
- **Uso:** `ssh-agent` gestiona las llaves para no escribir passphrase cada vez
- **Comando:** `eval $(ssh-agent -s)`
- **Ver también:** ssh-add

### Algoritmo de Cifrado

- **Definición:** Método matemático para cifrar y descifrar datos
- **Ejemplos SSH:** AES-256, ChaCha20
- **En contexto:** SSH negocia automáticamente el algoritmo más seguro

### ASCII

- **Definición:** American Standard Code for Information Interchange
- **En SSH:** Las llaves se almacenan en formato ASCII/texto
- **Ejemplo:** El contenido de `~/.ssh/id_ed25519.pub` es texto ASCII

---

## B

### Banner

- **Definición:** Mensaje mostrado antes o después de la autenticación
- **Configuración:** `Banner /etc/ssh/banner.txt` en sshd_config
- **Uso:** Advertencias legales, información del sistema

### Bastion Host

- **Definición:** Servidor intermedio para acceder a redes privadas
- **Sinónimo:** Jump host, jump box
- **Uso:** Punto único de entrada a infraestructura protegida
- **Semana del bootcamp:** Semana 8

### Bits

- **Definición:** Unidad básica de información (0 o 1)
- **En SSH:** Las llaves se miden en bits (ej: RSA 4096 bits)
- **A mayor bits:** Mayor seguridad, pero más lento

---

## C

### Cliente SSH

- **Definición:** Programa que inicia la conexión SSH
- **Ejemplos:** OpenSSH client, PuTTY, Termius
- **Comando:** `ssh usuario@servidor`

### Conexión

- **Definición:** Enlace establecido entre cliente y servidor
- **En SSH:** Conexión cifrada punto a punto
- **Verificar:** `ssh -v usuario@servidor` para ver detalles

### Config (Archivo)

- **Definición:** Archivo de configuración del cliente SSH
- **Ubicación:** `~/.ssh/config`
- **Permite:** Aliases, opciones por host, simplificar comandos

### Criptografía

- **Definición:** Ciencia de proteger información mediante códigos
- **En SSH:** Usa criptografía de llave pública y simétrica
- **Ver también:** Cifrado asimétrico, Cifrado simétrico

### Criptografía Asimétrica

- **Definición:** Cifrado que usa dos llaves diferentes (pública/privada)
- **Uso en SSH:** Autenticación y intercambio de llaves
- **Algoritmos:** RSA, Ed25519, ECDSA

### Criptografía Simétrica

- **Definición:** Cifrado que usa la misma llave para cifrar y descifrar
- **Uso en SSH:** Cifrado de la sesión después del handshake
- **Algoritmos:** AES, ChaCha20

---

## D

### Daemon

- **Definición:** Proceso que corre en segundo plano
- **En SSH:** `sshd` es el daemon del servidor SSH
- **Gestión:** `systemctl status sshd`

### Diffie-Hellman

- **Definición:** Algoritmo para intercambio seguro de llaves
- **En SSH:** Usado para establecer la llave de sesión
- **Historia:** Inventado en 1976

---

## E

### Ed25519

- **Definición:** Algoritmo de firma digital moderno y seguro
- **Ventajas:** Rápido, llaves pequeñas, muy seguro
- **Generar:** `ssh-keygen -t ed25519`
- **Recomendación:** Preferido sobre RSA para nuevas llaves

### Escape Character

- **Definición:** Carácter especial para comandos dentro de SSH
- **Por defecto:** `~` (tilde)
- **Comandos:** `~.` terminar, `~?` ayuda, `~#` listar conexiones

---

## F

### Fingerprint

- **Definición:** Huella digital única de una llave SSH
- **Formato:** Hash corto de la llave pública
- **Uso:** Verificar autenticidad del servidor
- **Ejemplo:** `SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s`

### Firewall

- **Definición:** Sistema que controla tráfico de red
- **Para SSH:** Debe permitir puerto 22 (o el configurado)
- **Herramientas:** `ufw`, `iptables`, `firewalld`

### Forwarding

- **Definición:** Redireccionar tráfico a través del túnel SSH
- **Tipos:** Local (-L), Remote (-R), Dynamic (-D)
- **Semana del bootcamp:** Semana 6

---

## G

### GNU/Linux

- **Definición:** Sistema operativo libre basado en kernel Linux
- **Relevancia:** Donde SSH es más usado
- **Distros populares:** Ubuntu, Debian, Fedora, CentOS

---

## H

### Handshake

- **Definición:** Proceso inicial de negociación entre cliente y servidor
- **En SSH:** Intercambio de versiones, algoritmos, llaves
- **Ver:** `ssh -vvv` muestra el handshake detallado

### Hash

- **Definición:** Función que convierte datos en cadena de longitud fija
- **En SSH:** MD5, SHA256 para fingerprints
- **Propiedad:** No reversible (one-way)

### Host

- **Definición:** Computadora en una red
- **En SSH:** El servidor al que te conectas
- **Ejemplo:** `ssh usuario@host`

### Host Key

- **Definición:** Par de llaves que identifica al servidor SSH
- **Ubicación:** `/etc/ssh/ssh_host_*_key`
- **Verificación:** El cliente compara con `known_hosts`

---

## I

### IP (Internet Protocol)

- **Definición:** Protocolo para identificar dispositivos en red
- **IPv4:** `192.168.1.1` (4 octetos)
- **IPv6:** `2001:db8::1` (8 grupos hexadecimales)

---

## K

### Keepalive

- **Definición:** Paquetes para mantener conexión activa
- **Config cliente:** `ServerAliveInterval 60`
- **Config servidor:** `ClientAliveInterval 60`
- **Evita:** Desconexiones por inactividad

### Key (Llave)

- **Definición:** Dato criptográfico para cifrar/descifrar
- **Tipos en SSH:** Pública y Privada
- **Archivos:** `id_ed25519` (privada), `id_ed25519.pub` (pública)

### Known Hosts

- **Definición:** Archivo que guarda fingerprints de servidores conocidos
- **Ubicación:** `~/.ssh/known_hosts`
- **Propósito:** Prevenir ataques man-in-the-middle
- **Gestión:** `ssh-keygen -R hostname` para eliminar entradas

---

## L

### Llave Privada

- **Definición:** Parte secreta del par de llaves
- **NUNCA compartir:** Debe permanecer solo en tu máquina
- **Permisos:** `chmod 600 ~/.ssh/id_ed25519`
- **Ubicación típica:** `~/.ssh/id_ed25519`

### Llave Pública

- **Definición:** Parte compartible del par de llaves
- **Se copia a:** `~/.ssh/authorized_keys` del servidor
- **Formato:** `ssh-ed25519 AAAA... comentario`
- **Ubicación:** `~/.ssh/id_ed25519.pub`

---

## M

### Man-in-the-Middle (MITM)

- **Definición:** Ataque donde alguien intercepta comunicación
- **SSH previene:** Verificando host keys en `known_hosts`
- **Advertencia:** "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"

### Multiplexing

- **Definición:** Múltiples sesiones SSH sobre una conexión
- **Configuración:** `ControlMaster auto` en ~/.ssh/config
- **Beneficio:** Conexiones más rápidas, menos autenticaciones

---

## O

### OpenSSH

- **Definición:** Implementación libre de SSH más usada
- **Componentes:** `ssh`, `sshd`, `ssh-keygen`, `ssh-agent`, `scp`, `sftp`
- **Desarrollo:** Proyecto OpenBSD
- **URL:** https://www.openssh.com/

---

## P

### Passphrase

- **Definición:** Contraseña que protege la llave privada
- **Recomendación:** Siempre usar passphrase
- **Ejemplo:** Frase fácil de recordar: "MiGatoTiene3Bigotes!"

### PEM (Privacy Enhanced Mail)

- **Definición:** Formato de archivo para llaves y certificados
- **Características:** Base64 con cabeceras
- **Ejemplo:** `-----BEGIN OPENSSH PRIVATE KEY-----`

### Permisos

- **Definición:** Configuración de acceso a archivos
- **SSH requiere:**
  - `~/.ssh/` → 700
  - Llaves privadas → 600
  - `authorized_keys` → 644

### Port (Puerto)

- **Definición:** Número que identifica un servicio en un host
- **SSH por defecto:** 22
- **Cambiar:** `-p 2222` en cliente, `Port 2222` en servidor

### Protocolo

- **Definición:** Conjunto de reglas para comunicación
- **SSH Protocol 2:** Versión actual, segura
- **SSH Protocol 1:** Obsoleto, inseguro (no usar)

### Proxy

- **Definición:** Intermediario entre cliente y destino
- **ProxyJump:** Saltar a través de otro servidor SSH
- **ProxyCommand:** Comando personalizado para conectar

### PuTTY

- **Definición:** Cliente SSH popular para Windows
- **Formatos propios:** `.ppk` para llaves
- **Conversión:** `puttygen` convierte entre formatos
- **URL:** https://www.putty.org/

---

## R

### RSA

- **Definición:** Algoritmo de criptografía asimétrica
- **Nombre:** Rivest-Shamir-Adleman (sus creadores)
- **En SSH:** `ssh-keygen -t rsa -b 4096`
- **Estado:** Seguro con 4096+ bits, pero Ed25519 es preferido

---

## S

### SCP (Secure Copy)

- **Definición:** Herramienta para copiar archivos por SSH
- **Comando:** `scp archivo usuario@servidor:/ruta/`
- **Semana del bootcamp:** Semana 4

### SFTP (SSH File Transfer Protocol)

- **Definición:** Protocolo para transferencia de archivos sobre SSH
- **Comando:** `sftp usuario@servidor`
- **Ventaja sobre SCP:** Sesión interactiva, resume transfers
- **Semana del bootcamp:** Semana 4

### Shell

- **Definición:** Intérprete de comandos (terminal)
- **Tipos:** bash, zsh, fish
- **En SSH:** Al conectar, obtienes shell del servidor

### SSH (Secure Shell)

- **Definición:** Protocolo para conexiones seguras remotas
- **Creado:** 1995 por Tatu Ylönen
- **Puerto por defecto:** 22
- **Usos:** Acceso remoto, túneles, transferencia de archivos

### ssh-add

- **Definición:** Comando para añadir llaves al ssh-agent
- **Uso:** `ssh-add ~/.ssh/id_ed25519`
- **Listar:** `ssh-add -l`

### ssh-copy-id

- **Definición:** Herramienta para copiar llave pública al servidor
- **Uso:** `ssh-copy-id usuario@servidor`
- **Resultado:** Añade tu llave a `~/.ssh/authorized_keys`

### ssh-keygen

- **Definición:** Herramienta para generar pares de llaves
- **Uso básico:** `ssh-keygen -t ed25519`
- **Ver fingerprint:** `ssh-keygen -lf ~/.ssh/id_ed25519.pub`

### sshd

- **Definición:** Daemon del servidor SSH
- **Configuración:** `/etc/ssh/sshd_config`
- **Gestión:** `systemctl restart sshd`

### sshd_config

- **Definición:** Archivo de configuración del servidor SSH
- **Ubicación:** `/etc/ssh/sshd_config`
- **Directivas comunes:** Port, PermitRootLogin, PasswordAuthentication

---

## T

### TCP (Transmission Control Protocol)

- **Definición:** Protocolo de transporte confiable
- **SSH usa:** TCP para garantizar entrega de paquetes
- **Puerto SSH:** TCP/22

### Terminal

- **Definición:** Interfaz de texto para ejecutar comandos
- **Emuladores:** GNOME Terminal, iTerm2, Windows Terminal
- **En SSH:** Obtienes acceso al terminal del servidor remoto

### Timeout

- **Definición:** Tiempo máximo de espera
- **En SSH:** Tiempo antes de desconectar por inactividad
- **Configurar:** `ConnectTimeout 30` (segundos para conectar)

### TLS/SSL

- **Definición:** Protocolos de cifrado (usados en HTTPS)
- **Diferencia con SSH:** SSH tiene su propio protocolo, no usa TLS
- **Similitud:** Ambos usan criptografía de llave pública

### Tunnel (Túnel)

- **Definición:** Canal cifrado que transporta otro tráfico
- **Tipos SSH:** Local, Remote, Dynamic
- **Uso:** Acceder a servicios internos de forma segura
- **Semana del bootcamp:** Semana 6

---

## U

### Usuario

- **Definición:** Cuenta en el sistema
- **En SSH:** `ssh usuario@servidor`
- **Si omites usuario:** Usa tu usuario local

---

## V

### Verbose

- **Definición:** Modo con más información/output
- **En SSH:** `-v`, `-vv`, `-vvv` (más v = más detalle)
- **Uso:** Debugging de conexiones

### VPS (Virtual Private Server)

- **Definición:** Servidor virtual alquilado
- **Proveedores:** DigitalOcean, AWS, Linode, Vultr
- **Uso:** Práctica de SSH con servidor real

---

## W

### WSL (Windows Subsystem for Linux)

- **Definición:** Linux dentro de Windows
- **Ventaja:** Usar OpenSSH nativo en Windows
- **Versiones:** WSL1, WSL2 (recomendado)

---

## Referencias Rápidas

### Comandos Más Usados

| Comando                     | Descripción           |
| --------------------------- | --------------------- |
| `ssh usuario@host`          | Conectar a servidor   |
| `ssh-keygen -t ed25519`     | Generar llaves        |
| `ssh-copy-id usuario@host`  | Copiar llave pública  |
| `ssh-add ~/.ssh/id_ed25519` | Añadir llave al agent |

### Archivos Importantes

| Archivo                  | Descripción                   |
| ------------------------ | ----------------------------- |
| `~/.ssh/config`          | Configuración cliente         |
| `~/.ssh/id_ed25519`      | Llave privada                 |
| `~/.ssh/id_ed25519.pub`  | Llave pública                 |
| `~/.ssh/known_hosts`     | Servidores conocidos          |
| `~/.ssh/authorized_keys` | Llaves autorizadas (servidor) |

---

<div align="center">

[← Volver a Semana 01](../README.md)

</div>
