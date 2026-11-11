# Glosario — Semana 12

| Término | Definición |
|---|---|
| **Código de salida 255** | El que da `ssh` cuando falla él mismo (nombre, red, host key, llave). Cualquier otro es el del comando remoto |
| **`BatchMode yes`** | `ssh` no pregunta nunca nada; si tendría que preguntar, falla. Para scripts, CI y Ansible |
| **`ConnectTimeout`** | Segundos que `ssh` espera a que el servidor responda antes de fallar |
| **`ssh -n`** | Entrada vacía: `ssh` no lee la entrada del script (ni la de un `while read`) |
| **`printf %q`** | Escapa un valor para que el shell remoto lo reciba entero, con espacios y caracteres especiales |
| **`bash -s`** | `bash` que lee el script de su entrada: `ssh HOST bash -s <<'FIN'` ejecuta un script local en el servidor |
| **`xargs -P N`** | Ejecuta hasta N comandos a la vez. Se para si uno sale con 255 |
| **CI / runner** | Integración continua: tareas que se ejecutan en una máquina temporal (el runner) cuando pasa algo en el repositorio |
| **Secreto (*secret*)** | Valor cifrado que el CI guarda y entrega a un job como variable de entorno: llave, `known_hosts`, tokens |
| **Llave de despliegue** | Llave solo para un CI o una tarea automática, sin frase y restringida en `authorized_keys` |
| **Comando forzado** | `command="..."` en `authorized_keys`: se ejecuta ese programa pida lo que pida el cliente |
| **`SSH_ORIGINAL_COMMAND`** | Variable con lo que pidió el cliente cuando hay comando forzado |
| **`restrict`** | Opción de `authorized_keys` que quita terminal, reenvíos de puertos, agente y X11 |
| **`from=`** | Opción de `authorized_keys`: la llave solo vale desde esas direcciones o redes |
| **`trap ... EXIT`** | Orden de bash que ejecuta algo al salir del script, también si falla: borrar los secretos escritos en disco |
| **`HostKeyAlias`** | Nombre con el que `ssh` busca la host key en `known_hosts`, en lugar del nombre del servidor |
| **Workflow** | Archivo YAML de GitHub Actions (`.github/workflows/`) que dice cuándo y qué ejecutar |
| **`permissions` / `concurrency`** | En un workflow: lo que puede hacer el token del job, y que no corran dos a la vez |
| **Ansible** | Herramienta que deja servidores en un estado descrito, por SSH y sin agente: necesita `python3` y `sudo` en ellos |
| **Nodo de control** | El equipo donde se ejecuta Ansible: tu equipo o el runner |
| **Inventario** | Lista de servidores de Ansible, en grupos (`inventario.ini`) |
| **Módulo** | Programa en Python que Ansible envía al servidor: hace una cosa y dice si cambió algo (`copy`, `user`, `ping`) |
| **Ad hoc** | Un módulo suelto desde la terminal, sin playbook: `ansible GRUPO -m MÓDULO -a ARGS` |
| **Playbook / play / tarea** | Archivo YAML con plays; cada play aplica una lista de tareas a un grupo |
| **Handler** | Tarea que solo se ejecuta si otra avisa (`notify`) de que cambió algo; una vez, al final |
| **Idempotencia** | Ejecutar dos veces da el mismo resultado; la segunda no cambia nada (`changed=0`) |
| **`become`** | Ejecutar las tareas como otro usuario (root) a través de `sudo` |
| ***Facts*** | Lo que Ansible averigua de un servidor al empezar (`Gathering Facts`): sistema, red, variables de entorno |
| **`--check --diff`** | Simular el playbook sin cambiar nada y enseñar las diferencias |
| **`validate`** | Opción de `copy` y `template`: un comando que debe aceptar el archivo nuevo antes de ponerlo en su sitio |
| **`serial`** | Cuántos servidores a la vez trata un play; con 1, se para antes del segundo si falla el primero |
| ***Pipelining*** | Enviar el módulo por la entrada de `ssh` en lugar de copiarlo antes a un archivo del servidor |
| **`reset_connection`** | Cierra la conexión (y su master) con el servidor: la tarea siguiente entra con una conexión nueva |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 12](../README.md)
