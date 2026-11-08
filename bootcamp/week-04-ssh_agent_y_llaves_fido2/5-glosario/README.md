# Glosario — Semana 04

| Término | Definición |
|---------|------------|
| **`AddKeysToAgent`** | Opción de `ssh_config`: la primera vez que `ssh` descifra una llave, la carga en el agente (`yes`, `confirm`, o un tiempo como `1h`) |
| **agent forwarding** | Reenvío del agente: con `ssh -A`, el servidor recibe un socket que llega hasta tu agente, y lo que corre allí puede pedirle firmas |
| **`agent-forwarding`** | Opción de `authorized_keys` que vuelve a permitir el forwarding a una llave después de `restrict` |
| **`AllowAgentForwarding`** | Opción de `sshd_config` que permite o prohíbe el forwarding a todas las conexiones del servidor |
| ***application*** | Campo de una llave FIDO2 que la asocia a un uso; en SSH empieza por `ssh:` (por defecto, `ssh:`) |
| **`bound agent to hostkey`** | Línea de `ssh -v`: `ssh` informa al agente de la host key del servidor con el que habla (extensión `session-bind@openssh.com`, OpenSSH 8.9+) |
| **caducidad (del agente)** | Tiempo tras el cual el agente olvida una llave: `ssh-add -t`, `ssh-agent -t` o `AddKeysToAgent 1h` |
| **`ecdsa-sk`** | Tipo de llave FIDO2 con ECDSA P-256, para dispositivos que no admiten Ed25519 |
| **`ed25519-sk`** | Tipo de llave FIDO2 con Ed25519; el recomendado |
| **`eval`** | Orden de la shell que ejecuta como código el texto que recibe; con `ssh-agent`, define sus variables en la shell actual |
| **FIDO2** | Estándar de llaves de seguridad físicas (USB, NFC) que generan y guardan la privada dentro del dispositivo |
| **`ForwardAgent`** | Opción de `ssh_config` equivalente a `-A`: `yes` reenvía el agente a ese host; el valor por defecto es `no` |
| **identificador (*key handle*)** | Lo que guarda el archivo privado de una llave `-sk`: el dato que el dispositivo necesita para encontrar su privada. Sin el dispositivo no sirve para firmar |
| **`IdentityAgent`** | Opción de `ssh_config` que dice qué socket de agente usar; `none` ignora el agente |
| **llave de seguridad** | Dispositivo FIDO2 (YubiKey, SoloKey, Nitrokey, Titan...) que firma sin dejar salir la privada |
| **llave residente** | Llave `-sk` creada con `-O resident`: el identificador se guarda en el dispositivo y se recupera en otro equipo con `ssh-keygen -K` |
| **`no-touch-required`** | Opción de `ssh-keygen -O` y de `authorized_keys` que permite firmar con una llave `-sk` sin tocar el dispositivo |
| **presencia del usuario** | Confirmación física, normalmente un toque, que el dispositivo FIDO2 exige antes de firmar |
| **`ProxyJump`** | Opción de `ssh_config` (`-J`) para llegar a un servidor a través de otro sin reenviar el agente (semana 09) |
| **`PubkeyAuthOptions`** | Opción de `sshd_config` que exige toque (`touch-required`) o PIN (`verify-required`) a todas las llaves `-sk` |
| **restricción por destino** | Límite que `ssh-add -h` pone a una llave en el agente: solo vale para los hosts y saltos indicados |
| **`SSH_AGENT_PID`** | Variable con el número de proceso del agente; la usa `ssh-agent -k` para detenerlo |
| **`SSH_ASKPASS`** | Variable con la ruta de un programa que pregunta al usuario por él (frase, confirmación); el agente la usa con `ssh-add -c` |
| **`SSH_ASKPASS_REQUIRE`** | Variable que decide cuándo usar `SSH_ASKPASS`; `force` lo usa aunque no haya entorno gráfico |
| **`SSH_AUTH_SOCK`** | Variable con la ruta del socket del agente. Vacía: no hay agente |
| **`ssh-add`** | Programa que añade, lista, quita y restringe las llaves de un agente |
| **`ssh-agent`** | Proceso que guarda llaves privadas descifradas y firma con ellas sin entregarlas |
| **`ssh-sk-helper`** | Programa auxiliar de OpenSSH que habla con los dispositivos FIDO2 (usa `libfido2`) |
| **socket Unix** | Archivo especial por el que dos procesos del mismo equipo se envían datos; el agente escucha en uno |
| **socket huérfano** | Socket que sigue en el disco después de que su agente muriera; impide arrancar otro en la misma ruta hasta borrarlo |
| **`verify-required`** | Opción de `ssh-keygen -O`, `authorized_keys` y `PubkeyAuthOptions` que exige el PIN del dispositivo además del toque |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | [Semana 05 — Configuración avanzada del cliente](../../week-05-configuracion_avanzada_cliente_ssh/README.md) → |

[↑ Semana 04](../README.md)
