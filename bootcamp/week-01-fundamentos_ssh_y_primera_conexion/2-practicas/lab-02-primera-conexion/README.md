# Lab 02 — Tu primera conexión

⏱ Duración estimada: ~60 min

## Objetivo

Conectarte por SSH a `server` verificando antes su huella por un canal independiente, entender qué guarda `known_hosts` y qué pasa si respondes `no`.

## Contexto

- La primera vez que te conectas a un host, `ssh` no sabe si al otro lado está el servidor de verdad o un impostor. Te enseña la **huella** (*fingerprint*) de la **host key** del servidor y te pregunta. Esto se llama **TOFU** (*trust on first use*): confías la primera vez y desde entonces `ssh` comprueba que la llave no cambie.
- **Qué:** la huella es un resumen corto (SHA256) de la llave pública del servidor. **Para qué:** compararla con la que te dé el administrador por otro medio. **Impacto:** si respondes `yes` sin comparar, la protección contra suplantación no sirve de nada.
- Aquí "el administrador" eres tú, desde tu equipo con `docker compose exec`: un canal que no pasa por la red SSH.
- Necesitas **dos terminales**: una en tu equipo (marcada **En tu equipo**) y otra dentro del cliente (**En el cliente**).

## Instrucciones

0. **En tu equipo**, desde la raíz del repositorio:
   ```bash
   docker compose up -d
   ```
   Abre una segunda terminal y entra al cliente:
   ```bash
   docker compose run --rm client
   ```

1. **En tu equipo**, pide al propio `server` la huella de su host key:
   ```bash
   docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```
   ```
   256 SHA256:m/sNQegz9dMrhYOD58Pm4keTPbbWHqnCL05A0Q3W1g8 root@server (ED25519)
   ```
   Tu huella será otra: las host keys se generan al crear cada contenedor. `ssh-keygen -l` muestra la huella de una llave y `-f` dice qué archivo leer. `256` son los bits de la llave y `ED25519` el algoritmo. Deja esta terminal a la vista.

2. **En el cliente**, conéctate:
   ```bash
   ssh alumno@server
   ```
   ```
   The authenticity of host 'server (172.20.0.3)' can't be established.
   ED25519 key fingerprint is SHA256:m/sNQegz9dMrhYOD58Pm4keTPbbWHqnCL05A0Q3W1g8.
   This key is not known by any other names.
   Are you sure you want to continue connecting (yes/no/[fingerprint])?
   ```
   `alumno@server` significa "usuario `alumno` en el host `server`". **No respondas todavía.** Compara carácter a carácter la huella con la del paso 1. Si coinciden, escribe `yes` y pulsa Enter:
   ```
   Warning: Permanently added 'server' (ED25519) to the list of known hosts.
   alumno@server's password:
   ```

3. Escribe la contraseña `alumno` (**solo laboratorio**). No se ve nada mientras escribes: es normal, `ssh` no muestra ni asteriscos.
   ```
   Welcome to Ubuntu 24.04.5 LTS (GNU/Linux ... x86_64)
   ...
   alumno@server:~$
   ```
   El prompt ahora dice `server`: cada comando que escribas se ejecuta allí.

4. Mira desde dónde estás conectado:
   ```bash
   hostname
   echo "$SSH_CONNECTION"
   ```
   ```
   server
   172.20.0.6 51606 172.20.0.3 22
   ```
   `sshd` define `SSH_CONNECTION` en cada sesión: IP y puerto del cliente, IP y puerto del servidor. El puerto del cliente es aleatorio; el del servidor es el 22.

5. Cierra la sesión:
   ```bash
   exit
   ```
   ```
   logout
   Connection to server closed.
   ```
   Vuelves a `alumno@client`.

6. Mira qué guardó `ssh` al responder `yes`:
   ```bash
   cat ~/.ssh/known_hosts
   ssh-keygen -F server
   ```
   ```
   |1|oemPp7s5Go6wBambDg6IswbcCAE=|UHGU47qiOmvxO149v4hxA/GpYME= ssh-ed25519 AAAAC3Nz...
   # Host server found: line 1
   |1|oemPp7s5Go6wBambDg6IswbcCAE=|UHGU47qiOmvxO149v4hxA/GpYME= ssh-ed25519 AAAAC3Nz...
   ```
   Una línea por host: nombre, algoritmo y llave pública. El nombre aparece como `|1|...` porque Ubuntu activa `HashKnownHosts yes`: si alguien roba el archivo, no ve a qué hosts entras. Por eso se busca con `ssh-keygen -F` y no con `grep`.

7. Conéctate otra vez:
   ```bash
   ssh alumno@server
   ```
   Ahora pide la contraseña directamente, sin preguntar por la huella: la llave coincide con la guardada. Sal con `exit`.

8. Prueba a decir que no. Conéctate a `bastion`, que todavía no conoces, y responde `no`:
   ```bash
   ssh alumno@bastion
   ```
   ```
   Are you sure you want to continue connecting (yes/no/[fingerprint])? no
   Host key verification failed.
   ```
   `ssh` corta **antes** de pedir contraseña: tu contraseña nunca llega a un servidor que no verificaste.

9. Ahora verifica `bastion` pegando la huella en vez de `yes`. **En tu equipo**:
   ```bash
   docker compose exec bastion ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```
   Copia el texto `SHA256:...` (sin `256` ni `root@bastion`). **En el cliente**, `ssh alumno@bastion` y, en la pregunta, pega la huella y pulsa Enter. Si coincide, `ssh` la acepta y pide la contraseña; si no, vuelve a preguntar. Así comparas sin fiarte de tus ojos. Sal con `exit`.

10. Sal del cliente con `exit`. La próxima vez que entres con `docker compose run --rm client`, `~/.ssh/known_hosts` estará vacío y volverás a ver la pregunta: el contenedor es nuevo.

## Criterios de éxito

- [ ] Comparaste la huella del paso 1 con la del paso 2 antes de escribir `yes`
- [ ] Dentro de la sesión, `hostname` imprimió `server` (paso 4)
- [ ] `ssh-keygen -F server` encuentra una línea en `known_hosts` (paso 6)
- [ ] Responder `no` acaba en `Host key verification failed.` sin pedir contraseña (paso 8)
- [ ] Aceptaste `bastion` pegando la huella (paso 9)

## Reto extra

Ejecuta `ssh-keyscan -t ed25519 server | ssh-keygen -lf -` en el cliente. Te da la huella sin conectarte. ¿Por qué esto **no** sirve para verificar el servidor, aunque la huella sea la misma?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 01 — El laboratorio Docker](../lab-01-laboratorio-docker/README.md) | [Lab 03 — Comandos remotos](../lab-03-comandos-remotos/README.md) → |

[↑ Semana 01](../../README.md)
