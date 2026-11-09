# Glosario — Semana 09

| Término | Definición |
|---|---|
| **Red segmentada** | Red repartida en varias redes separadas, con reglas sobre cuál puede hablar con cuál. Contiene un ataque a la red en la que empieza |
| **Red privada** | Red sin ruta desde Internet ni desde las demás. En el laboratorio, `privada` y `datos` (`internal: true` en `compose.yaml`) |
| **Bastion host** | Única máquina accesible por SSH desde fuera que además está en la red privada. También *jump host* o *jump box* |
| **Salto** | Pasar por un host intermedio para llegar a otro. Con `ProxyJump`, las dos conexiones salen de tu equipo |
| **`ProxyJump` (`-J`)** | Opción de `ssh` (7.3+) que salta por uno o varios hosts: lanza `ssh -W` hacia cada salto y monta la conexión al destino dentro. `none` lo desactiva |
| **`ssh -W HOST:PUERTO`** | Abre un canal `direct-tcpip` hasta `HOST:PUERTO` a través del servidor y lo une a la entrada y salida estándar de `ssh` |
| **`ProxyCommand`** | Programa que `ssh` ejecuta en lugar de abrir TCP con el servidor; habla SSH por su entrada y salida. `%h` y `%p` son el host y el puerto |
| **`direct-tcpip`** | Tipo de canal SSH que conecta con un host y puerto desde el servidor. Lo usan `-L`, `-D` y `-W` |
| **Sesiones encadenadas** | `ssh -t bastion ssh interno`: el segundo `ssh` corre en el bastion, que autentica, comprueba la host key y ve todo en claro |
| **`HostKeyAlias`** | Nombre con el que `ssh` busca y guarda la host key, en lugar del que usaste para conectar (una IP, `localhost` de un túnel) |
| **`<no hostip for proxy command>`** | Lo que dice `ssh` cuando no sabe la IP del servidor porque conectó a través de un `ProxyCommand` |
| **`Match exec`** | Condición de `ssh_config` que se cumple si un comando sale con 0. Con `!`, si falla |
| **`ssh-add -h`** | Restricción de destino (OpenSSH 8.9+): por qué saltos se puede usar una llave del agente, como `bastion>interno` |
| **Cuenta de salto** | Cuenta del bastion sin shell que solo puede abrir canales a destinos concretos. Una por persona |
| **`saltadores`** | Grupo del kit para las cuentas de salto; `40-salto.conf` lo limita con `Match Group` |
| **`/usr/sbin/nologin`** | Shell que escribe `This account is currently not available.` y sale con 1. No impide los reenvíos |
| **`PermitOpen`** | Destinos (`host:puerto`) permitidos para `-L`, `-D` y `-W`. Compara el texto que pide el cliente, sin resolverlo |
| **`administratively prohibited`** | Mensaje del cliente cuando el servidor rechaza abrir un canal por su configuración (`PermitOpen`, `AllowTcpForwarding`) |
| **`LogLevel DEBUG1`** | Nivel de log de `sshd` que registra el destino de cada canal (`target interno port 22`). En el kit, solo para los saltadores |
| **`originator 127.0.0.1 port 65535`** | Origen que registra `sshd` para un canal de `ssh -W`, que no viene de ningún puerto real |
| **Punto único de fallo** | Pieza sin la que el sistema entero deja de funcionar. Un solo bastion lo es para la red privada |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 09](../README.md)
