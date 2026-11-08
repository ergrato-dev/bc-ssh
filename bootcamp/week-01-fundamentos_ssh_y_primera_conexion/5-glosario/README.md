# Glosario — Semana 01

| Término | Definición en una línea | Ejemplo |
|---------|------------------------|---------|
| **SSH** | Protocolo para usar una máquina remota con todo el tráfico cifrado y ambos extremos autenticados | `ssh alumno@server` |
| **OpenSSH** | La implementación de SSH más usada; incluye `ssh`, `sshd`, `ssh-keygen` y más | `ssh -V` |
| **Telnet** | Protocolo de shell remota de 1969 que envía todo en claro, contraseñas incluidas | Puerto 23 |
| **cliente (`ssh`)** | Programa que inicia la conexión desde tu equipo | `ssh server hostname` |
| **servidor (`sshd`)** | Proceso que escucha en el puerto 22 y atiende cada conexión en un proceso hijo | `ps -C sshd` |
| **puerto 22** | Puerto TCP por defecto de SSH | `nc -zv server 22` |
| **banner** | Primera línea que envía cada lado: versión del protocolo y del software | `SSH-2.0-OpenSSH_9.6p1 ...` |
| **host key** | Par de llaves que identifica al servidor; la privada nunca sale de él | `/etc/ssh/ssh_host_ed25519_key` |
| **huella (*fingerprint*)** | Resumen SHA-256 de una llave pública, para compararla a simple vista | `SHA256:m/sNQegz9...` |
| **`known_hosts`** | Archivo del cliente con las host keys que ya aceptaste | `ssh-keygen -F server` |
| **TOFU** | *Trust on first use*: confiar en la llave la primera vez y exigir que no cambie después | La pregunta `yes/no/[fingerprint]` |
| **canal independiente** | Vía que no pasa por la conexión SSH para confirmar una huella | `docker compose exec server ssh-keygen -lf ...` |
| **man-in-the-middle** | Atacante que se pone entre cliente y servidor haciéndose pasar por cada uno | Lo detecta `REMOTE HOST IDENTIFICATION HAS CHANGED` |
| **KEX** | Intercambio de llaves: cliente y servidor acuerdan una llave de sesión sin enviarla | `kex: algorithm: sntrup761x25519-sha512@openssh.com` |
| **llave de sesión** | Llave simétrica efímera que cifra los datos de una conexión | Se descarta al cerrar |
| **cifrado simétrico** | Una misma llave cifra y descifra; rápido | `chacha20-poly1305@openssh.com` |
| **criptografía asimétrica** | Par de llaves privada y pública; en SSH se usa para acordar llaves y firmar | `ssh-ed25519` |
| **firma digital** | Prueba, hecha con la llave privada, que cualquiera verifica con la pública | El servidor firma el KEX con su host key |
| **hash** | Función que resume datos en una cadena fija; un cambio mínimo cambia todo el resumen | SHA-256 |
| **AEAD** | Cifrado que también garantiza la integridad; por eso `MAC: <implicit>` | `aes256-gcm@openssh.com` |
| **secreto hacia adelante** | Robar la llave a largo plazo no permite descifrar sesiones grabadas antes | Llaves de sesión efímeras |
| **separación de privilegios** | `sshd` atiende cada conexión con un proceso de pocos permisos | `sshd: alumno [priv]` y `sshd: alumno@pts/0` |
| **pty** | Pseudo-terminal que el servidor reserva para sesiones interactivas | `ssh -t server top` |
| **secuencia de escape** | Orden para el cliente escrita tras un salto de línea con `~` | `~.` corta la conexión |
| **código 255** | Código de salida de `ssh` cuando el fallo es suyo, no del comando remoto | `ssh -p 2222 server true; echo $?` |
| **`~/.ssh/config`** | Archivo de configuración del cliente con alias y opciones por host | `Host lab-server` |
| **`ssh -G`** | Imprime la configuración final para un host sin conectarse | `ssh -G -F config lab-server` |
| **`ConnectTimeout`** | Segundos que espera `ssh` a que el TCP conecte antes de rendirse | `ConnectTimeout 5` |
| **contenedor** | Proceso aislado con su propio sistema de archivos, nombre y red | `server`, `bastion`, `interno` |
| **`docker compose`** | Herramienta que levanta y gestiona los contenedores de `compose.yaml` | `docker compose up -d` |
| **`sshpass`** | Ayudante que teclea la contraseña por ti; **solo para el laboratorio** | `SSHPASS=alumno sshpass -e ssh server` |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 01](../README.md)
