# Práctica 2: Primera Conexión Remota con SSH

![Dificultad](https://img.shields.io/badge/Dificultad-⭐_Básica-green?style=flat-square)
![Duración](https://img.shields.io/badge/Duración-30_minutos-blue?style=flat-square)
![Prerequisitos](https://img.shields.io/badge/Prerequisitos-Práctica_1_completada-orange?style=flat-square)

---

## 🎯 Objetivo de la Práctica

En esta práctica realizarás tu primera conexión SSH a un servidor remoto usando autenticación por usuario y contraseña. Al finalizar, habrás experimentado el flujo completo de una conexión SSH y entenderás los mensajes que el cliente muestra durante el proceso.

**Habilidades que desarrollarás:**
- Ejecutar el comando `ssh` con sus parámetros básicos
- Interpretar y responder a los mensajes de autenticación de SSH
- Verificar la huella digital (fingerprint) de un servidor
- Navegar en una sesión SSH remota
- Cerrar correctamente una sesión SSH

---

## 📋 Prerequisitos

Antes de comenzar esta práctica, asegúrate de tener:

- ✅ Cliente SSH instalado en tu sistema (verificado en Práctica 1)
- ✅ Acceso a un servidor remoto con SSH habilitado
- ✅ Credenciales del servidor (usuario y contraseña)
- ✅ Conexión a internet

---

## 🔧 Preparación: Obtener un Servidor para Práctica

Si aún no tienes un servidor SSH al cual conectarte, aquí tienes tres opciones:

### Opción A: Usar un VPS Cloud (Recomendado)

Los proveedores cloud ofrecen servidores virtuales económicos perfectos para práctica:

**DigitalOcean** (mi recomendación):
1. Crea cuenta en https://digitalocean.com
2. Crea un Droplet (servidor virtual):
   - Imagen: Ubuntu 22.04 LTS
   - Plan: Basic ($6/mes o $0.009/hora)
   - Región: New York 1 (o la más cercana a Colombia)
   - Autenticación: **Password** (para esta práctica)
3. Anota la dirección IP pública que te asignen
4. Anota la contraseña root que te envíen por email

**Otras opciones**:
- Linode: https://linode.com (similar a DigitalOcean)
- Vultr: https://vultr.com (tiene servidores en Colombia)
- AWS EC2: https://aws.amazon.com/ec2/ (gratis el primer año con restricciones)

### Opción B: Máquina Virtual Local

Si prefieres no gastar dinero aún, puedes crear una VM local:

1. Instala VirtualBox: https://www.virtualbox.org/
2. Descarga Ubuntu Server 22.04 ISO
3. Crea una VM con:
   - RAM: 1GB mínimo
   - Disco: 10GB
   - Red: Bridge Adapter (para que tenga IP en tu red local)
4. Durante instalación, activa OpenSSH Server
5. Anota la IP local que obtenga (ejecuta `ip addr show` en la VM)

### Opción C: Usar un Servidor de Prueba Público

**⚠️ SOLO para esta práctica inicial:**

Algunos sitios ofrecen servidores SSH de prueba temporal. Son útiles para aprender pero **NUNCA** los uses para datos reales:

- http://sshpublic.com (ofrece acceso SSH temporal)
- https://www.remoteiot.com/ssh-test-server

**Nota importante**: Para las siguientes prácticas y proyectos, necesitarás tu propio servidor donde tengas control total. Por eso recomiendo opción A o B.

---

## 📝 Información Necesaria para Conectarse

Para esta práctica, necesitas conocer:

**Datos del servidor:**
```
Dirección IP o hostname: ___________________ (ejemplo: 134.122.15.92)
Puerto SSH: _________ (si no lo sabes, asume puerto 22)
Usuario: ____________ (ejemplo: root, ubuntu, o el que te asignaron)
Contraseña: _________ (la que configuraste o te enviaron)
```

**Ejemplo con datos ficticios que usaré en esta guía:**
```
IP: 134.122.15.92
Puerto: 22
Usuario: root
Contraseña: MiPassword123!
```

---

## 🚀 Paso a Paso de la Práctica

### Paso 1: Abrir la Terminal

**En Linux/macOS:**
- Abre la aplicación "Terminal"
- Verás un prompt similar a: `usuario@computadora:~$`

**En Windows:**
- Abre "PowerShell" o "Windows Terminal"
- O usa "Command Prompt" (CMD)
- Verás algo como: `C:\Users\TuNombre>`

### Paso 2: Verificar que SSH Está Disponible

Ejecuta este comando para confirmar que el cliente SSH está instalado:

```bash
ssh -V
```

Deberías ver una salida como:

```
OpenSSH_8.9p1 Ubuntu-3ubuntu0.4, OpenSSL 3.0.2 15 Mar 2022
```

El número de versión puede variar, lo importante es que no diga "command not found". Si dice eso, regresa a la Práctica 1 para instalar SSH.

### Paso 3: Ejecutar tu Primera Conexión SSH

**El comando básico tiene esta estructura:**

```bash
ssh usuario@direccion_servidor
```

**Usando mis datos de ejemplo:**

```bash
ssh root@134.122.15.92
```

**Desglosando el comando:**
- `ssh`: El programa cliente SSH
- `root`: El nombre de usuario en el servidor remoto
- `@`: Separador entre usuario y servidor
- `134.122.15.92`: La dirección IP del servidor (o podría ser un nombre de dominio como ejemplo.com)

**🔑 Ahora presiona Enter y observa lo que sucede...**

### Paso 4: Verificar el Fingerprint del Servidor (Primera Conexión)

La **primera vez** que te conectas a un servidor nuevo, verás un mensaje similar a este:

```
The authenticity of host '134.122.15.92 (134.122.15.92)' can't be established.
ED25519 key fingerprint is SHA256:Kj3nF8dL9mS2pQ4rT6vY8wZ1xC3bN5mL7kJ9hG0f.
This key is known by the following other names:
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

**¿Qué significa este mensaje?**

Este es un mecanismo de seguridad crucial de SSH. Déjame explicártelo por partes:

**"The authenticity of host... can't be established"**

SSH te está diciendo: "Nunca te has conectado a este servidor antes, así que no puedo verificar que realmente sea quien dice ser."

**"ED25519 key fingerprint is SHA256:..."**

Esta es la "huella digital" única del servidor. Es como una identificación digital. El servidor tiene un par de llaves criptográficas (público/privada), y el fingerprint es un resumen de su llave pública.

**"Are you sure you want to continue connecting?"**

SSH te pregunta si confías en este servidor. Aquí tienes tres opciones:

1. **yes** → Confías en el servidor y quieres guardar su fingerprint para futuras conexiones
2. **no** → No confías y quieres abortar la conexión
3. **[fingerprint]** → Puedes escribir el fingerprint completo si quieres verificación máxima

**¿Cómo saber si puedes confiar?**

- Si tú mismo creaste el servidor (VPS), puedes confiar
- Si te conectas a un servidor de tu empresa, verifica con tu administrador de sistemas
- Si es tu primera vez con ese servidor, idealmente deberías verificar el fingerprint por un canal alternativo (por ejemplo, si el admin te lo envió por email)

**Para esta práctica de aprendizaje:**

Escribe `yes` y presiona Enter.

```
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

Verás un mensaje de confirmación:

```
Warning: Permanently added '134.122.15.92' (ED25519) to the list of known hosts.
```

Esto significa que SSH guardó el fingerprint de este servidor en un archivo local (`~/.ssh/known_hosts`). En conexiones futuras a este mismo servidor, SSH ya no te preguntará porque reconocerá el fingerprint guardado.

### Paso 5: Ingresar la Contraseña

Ahora SSH te pedirá la contraseña del usuario:

```
root@134.122.15.92's password:
```

**Aspectos importantes al ingresar la contraseña:**

1. **No verás caracteres mientras escribes**: Es normal. Por seguridad, SSH no muestra nada (ni siquiera asteriscos *****) mientras escribes tu contraseña. Escribe con cuidado y presiona Enter.

2. **Distingue mayúsculas y minúsculas**: Las contraseñas en Linux son case-sensitive. "Password" ≠ "password".

3. **Tienes máximo 3 intentos**: Si fallas la contraseña 3 veces, la conexión se cerrará y tendrás que intentar de nuevo.

**Ingresa tu contraseña y presiona Enter.**

### Paso 6: ¡Conexión Exitosa!

Si la contraseña fue correcta, habrás iniciado sesión en el servidor remoto. Verás algo similar a esto:

```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Wed Nov 27 10:30:15 UTC 2025

  System load:  0.0               Processes:             95
  Usage of /:   8.2% of 24.05GB   Users logged in:       0
  Memory usage: 20%               IPv4 address for eth0: 134.122.15.92
  Swap usage:   0%

Last login: Wed Nov 27 09:15:22 2025 from 45.230.45.123
root@servidor-ubuntu:~#
```

**Desglosando lo que ves:**

- **Mensaje de bienvenida**: "Welcome to Ubuntu 22.04..."
- **System information**: Estadísticas del servidor (carga, uso de disco, memoria, etc.)
- **Last login**: Cuándo fue el último acceso a este servidor
- **Prompt**: `root@servidor-ubuntu:~#`
  - `root`: Usuario actual
  - `servidor-ubuntu`: Nombre del servidor (hostname)
  - `~`: Directorio actual (~ significa home directory)
  - `#`: Indica que eres usuario root (con privilegios de administrador)
    - Si fueras un usuario normal, verías `$` en lugar de `#`

**¡Felicidades! Estás dentro de un servidor remoto.**

Todo lo que escribas ahora se ejecutará en ese servidor, no en tu computadora local.

### Paso 7: Explorar el Servidor Remoto

Ahora que estás conectado, vamos a ejecutar algunos comandos básicos para familiarizarnos con el entorno:

**Verificar dónde estás:**

```bash
pwd
```

Output esperado:
```
/root
```

Este comando muestra el directorio actual (Print Working Directory). `/root` es el home directory del usuario root.

**Listar archivos del directorio actual:**

```bash
ls -la
```

Output esperado (puede variar):
```
total 24
drwx------  3 root root 4096 Nov 27 09:15 .
drwxr-xr-x 19 root root 4096 Oct 15 08:22 ..
-rw-r--r--  1 root root 3106 Oct 15 08:17 .bashrc
-rw-r--r--  1 root root  161 Jul  9 15:30 .profile
drwx------  2 root root 4096 Oct 15 08:17 .ssh
```

Este comando lista todos los archivos incluyendo los ocultos (los que empiezan con punto).

**Ver información del sistema:**

```bash
uname -a
```

Output esperado:
```
Linux servidor-ubuntu 5.15.0-91-generic #101-Ubuntu SMP Tue Nov 14 13:30:08 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
```

Muestra información del kernel Linux que ejecuta el servidor.

**Ver cuánto espacio en disco tienes:**

```bash
df -h
```

Output esperado (ejemplo):
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda1        25G  2.1G   23G   9% /
```

Muestra el espacio en disco en formato legible (-h = human readable).

**Ver quién está conectado al servidor:**

```bash
who
```

Output esperado:
```
root     pts/0        2025-11-27 10:30 (TU_IP_PUBLICA)
```

Muestra los usuarios actualmente conectados. Deberías verte a ti mismo con tu IP pública.

### Paso 8: Crear un Archivo de Prueba

Vamos a crear un archivo simple para demostrar que realmente estás controlando el servidor remoto:

```bash
echo "Mi primera conexión SSH - $(date)" > primera-conexion.txt
```

Este comando crea un archivo llamado `primera-conexion.txt` con la fecha y hora actual.

**Verificar que se creó:**

```bash
cat primera-conexion.txt
```

Output esperado:
```
Mi primera conexión SSH - Wed Nov 27 10:35:42 UTC 2025
```

**¡Importante!** Este archivo existe en el servidor remoto, NO en tu computadora local. Si desconectas y vuelves a conectar, seguirá ahí.

### Paso 9: Verificar tu IP Pública desde el Servidor

Un comando útil para entender la diferencia entre local y remoto:

```bash
curl -s https://api.ipify.org && echo
```

Este comando consulta tu IP pública desde el servidor. Verás la IP del servidor, no la de tu computadora.

### Paso 10: Cerrar la Sesión SSH Correctamente

Existen tres formas de cerrar una sesión SSH:

**Método 1 - Comando `exit` (Recomendado):**

```bash
exit
```

O simplemente:

```bash
logout
```

Verás un mensaje como:

```
logout
Connection to 134.122.15.92 closed.
```

Y regresarás al prompt de tu computadora local.

**Método 2 - Atajo de teclado:**

Presiona: `Ctrl + D`

Esto envía un EOF (End of File) que cierra la sesión.

**Método 3 - Cerrar la ventana del terminal:**

Esto funciona, pero no es elegante. Siempre es mejor cerrar explícitamente con `exit`.

---

## 🔍 Análisis de lo que Sucedió

Ahora que completaste tu primera conexión, entendamos qué pasó "bajo el capó":

### El Proceso Completo de Conexión

**1. Resolución de destino:**
Tu computadora tradujo la IP o hostname a una dirección de red válida.

**2. Establecimiento de conexión TCP:**
Se estableció una conexión TCP al puerto 22 del servidor.

**3. Handshake SSH:**
Cliente y servidor negociaron:
- Versión del protocolo SSH (probablemente SSH-2)
- Algoritmos de cifrado a usar
- Algoritmos de compresión

**4. Intercambio de llaves:**
El servidor envió su llave pública (de ahí el fingerprint que viste).
Cliente y servidor generaron llaves de sesión compartidas usando criptografía asimétrica.

**5. Establecimiento de canal cifrado:**
A partir de este punto, TODO el tráfico está cifrado con las llaves de sesión.

**6. Autenticación:**
Ingresaste tu contraseña, que viajó cifrada al servidor.
El servidor verificó la contraseña contra su base de datos de usuarios.

**7. Sesión iniciada:**
El servidor lanzó una shell bash para ti.
Cada comando que ejecutaste viajó cifrado al servidor, se ejecutó allí, y los resultados regresaron cifrados a tu terminal.

---

## 📊 Criterios de Evaluación

| Criterio | Puntos | Descripción |
|----------|---------|-------------|
| **Conexión exitosa** | 4 pts | Lograste conectarte al servidor remoto |
| **Verificación de fingerprint** | 2 pts | Comprendiste y aceptaste el fingerprint del servidor |
| **Navegación remota** | 2 pts | Ejecutaste comandos en el servidor |
| **Creación de archivo** | 1 pt | Creaste el archivo de prueba |
| **Cierre correcto** | 1 pt | Cerraste la sesión con `exit` |
| **TOTAL** | **10 pts** | |

---

## ⚠️ Problemas Comunes y Soluciones

### Problema 1: "Connection refused"

**Error:**
```
ssh: connect to host 134.122.15.92 port 22: Connection refused
```

**Causas posibles:**
- El servidor SSH no está corriendo en el destino
- Estás intentando conectarte al puerto equivocado
- Un firewall está bloqueando la conexión

**Soluciones:**
1. Verifica que el servidor SSH esté corriendo (si tienes acceso físico/consola): `systemctl status sshd`
2. Verifica el puerto correcto con tu proveedor
3. Intenta especificar el puerto explícitamente: `ssh -p 2222 usuario@servidor` (si el puerto es 2222)

### Problema 2: "Permission denied (publickey)"

**Error:**
```
Permission denied (publickey).
```

**Causa:**
El servidor está configurado para NO aceptar autenticación por contraseña, solo por llaves SSH.

**Solución temporal:**
Si tienes acceso de administrador al servidor, modifica `/etc/ssh/sshd_config` para permitir passwords:
```
PasswordAuthentication yes
```

Y reinicia sshd: `systemctl restart sshd`

**Solución correcta:**
Aprende a usar llaves SSH (lo haremos en la Semana 2).

### Problema 3: "Host key verification failed"

**Error:**
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Host key verification failed.
```

**Causa:**
El fingerprint del servidor cambió desde tu última conexión. Esto puede significar:
- El servidor fue reinstalado
- Estás siendo víctima de un ataque MITM (Man-in-the-Middle)

**Solución (SI ESTÁS SEGURO que es safe):**
```bash
ssh-keygen -R 134.122.15.92
```

Esto elimina el fingerprint antiguo. La próxima conexión te pedirá aceptar el nuevo.

### Problema 4: "Timeout"

**Error:**
```
ssh: connect to host 134.122.15.92 port 22: Connection timed out
```

**Causas:**
- La IP del servidor es incorrecta
- Tu conexión a internet está bloqueada
- El servidor está apagado

**Soluciones:**
1. Verifica la IP con `ping 134.122.15.92`
2. Prueba desde otra red (datos móviles)
3. Contacta a tu proveedor cloud

---

## 🎯 Desafíos Extra (+2 pts Bonus)

Si terminaste la práctica y quieres ir más allá:

### Desafío 1: Conectarse con Puerto No Estándar

Si tu servidor usa un puerto diferente al 22, conéctate especificando el puerto:

```bash
ssh -p 2222 usuario@servidor
```

### Desafío 2: Usar Opciones Verbose

Conéctate con modo verbose para ver todo el proceso de conexión:

```bash
ssh -v usuario@servidor
```

Analiza el output. ¿Puedes identificar las etapas que mencionamos?

### Desafío 3: Ejecutar un Comando sin Iniciar Sesión

SSH permite ejecutar un comando y salir inmediatamente:

```bash
ssh usuario@servidor "uname -a && date"
```

Pruébalo. ¿Qué ventajas tiene esto para automatización?

---

## ✅ Checklist de Completitud

Antes de dar por terminada esta práctica, verifica que:

- [ ] Conectaste exitosamente a un servidor remoto
- [ ] Comprendiste el mensaje de fingerprint y lo aceptaste
- [ ] Ejecutaste al menos 5 comandos en el servidor
- [ ] Creaste el archivo `primera-conexion.txt`
- [ ] Cerraste la sesión correctamente con `exit`
- [ ] Puedes explicar en tus propias palabras qué es un fingerprint
- [ ] Guardaste las credenciales de tu servidor para futuras prácticas

---

## 📝 Entregable

Crea un documento (puede ser `.md` o `.txt`) llamado `practica-02-evidencia.md` que contenga:

**1. Captura de pantalla mostrando:**
- La aceptación del fingerprint
- El prompt del servidor remoto
- La ejecución del comando `cat primera-conexion.txt`

**2. Responde brevemente (2-3 oraciones cada una):**

a) ¿Qué es el fingerprint de un servidor SSH y para qué sirve?

b) ¿Por qué no se ven caracteres mientras escribes la contraseña?

c) ¿Qué diferencia hay entre ejecutar `ls` en tu terminal local vs en la sesión SSH?

**3. Datos de tu servidor (para uso en siguientes prácticas):**
```
IP/Hostname:
Usuario:
Puerto:
Proveedor:
```

---

## 🔗 Referencias

- [SSH Command Manual](https://linux.die.net/man/1/ssh)
- [Understanding SSH Fingerprints](https://www.ssh.com/academy/ssh/host-key)
- [OpenSSH Connection Process](https://www.openssh.com/specs.html)

---

## 🚀 Siguiente Paso

¡Excelente trabajo! Ahora que sabes conectarte a servidores remotos, estás listo para aprender a optimizar esta experiencia.

**Continúa con**: [Práctica 3: Configuración del Archivo ~/.ssh/config](practica-03-archivo-config.md)

En la siguiente práctica aprenderás a crear un archivo de configuración que te permitirá conectarte a tus servidores con comandos simples como `ssh miservidor` en lugar de escribir `ssh usuario@ip.larga.dificil.de.recordar`.

---

<div align="center">

**💻 Práctica 2 de 3 - Semana 1**

**[⬅️ Práctica 1](practica-01-instalacion-cliente.md)** | **[Índice Prácticas](README.md)** | **[Práctica 3 →](practica-03-archivo-config.md)**

</div>
