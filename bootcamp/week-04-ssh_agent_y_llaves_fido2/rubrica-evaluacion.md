# Rúbrica de Evaluación — Semana 04

> `ssh-agent`, agent forwarding y llaves FIDO2. Se evalúan tres evidencias por separado y hace falta **70% en cada una**. No basta con no escribir la frase: tienes que saber quién puede usar tu agente, qué arriesgas al reenviarlo y cómo limitarlo.

---

## 📊 Distribución de Evidencias

| Evidencia | Peso | Instrumento |
|---|:--:|---|
| 🧠 Conocimiento | 30% | Las 10 preguntas de esta rúbrica, respondidas por escrito |
| 💪 Desempeño | 40% | Los 7 labs, con sus criterios de éxito comprobados en el laboratorio |
| 📦 Producto | 30% | `ssh-infra-kit` con `AddKeysToAgent`, `ForwardAgent no`, `bin/agent-up` y `KEY_TYPE` en `bin/key-new`: 60 pts de autograding + 40 pts de calidad |

**Mínimo 70% en cada evidencia.** No en el promedio.

| Calificación | Rango |
|---|:--:|
| Sobresaliente | 90-100% |
| Notable | 80-89% |
| Aprobado | 70-79% |
| No aprobado | < 70% |

---

## 🧠 Conocimiento (30%)

Diez preguntas, 3 puntos cada una.

| # | Pregunta |
|:--:|---|
| 1 | ¿Qué guarda `ssh-agent` y qué le pide `ssh`? ¿Por qué se dice que la privada "no sale" del agente? |
| 2 | ¿Por qué `ssh-agent` se ejecuta con `eval "$(ssh-agent)"`? ¿Qué pasa si abres otra terminal? |
| 3 | `ssh-add -l` sale con 0, 1 o 2. ¿Qué significa cada código y para qué te sirve en un script? |
| 4 | ¿Quién puede pedir firmas a tu agente en tu equipo? ¿Qué lo impide a los demás usuarios? ¿Qué no puede hacer ni siquiera root? |
| 5 | ¿Qué hacen `AddKeysToAgent 1h` y `ssh-agent -t 1h`? ¿Por qué conviene poner caducidad a las llaves del agente? |
| 6 | Explica qué ocurre en el servidor al conectar con `ssh -A`. ¿Qué puede hacer root de ese servidor mientras estás conectado, y qué no? |
| 7 | Tienes que llegar a `db` pasando por `bastion`. Ordena de más a menos segura estas opciones y justifica: `ssh -A bastion` y desde ahí `ssh db`; `ProxyJump`; `ssh-add -h bastion -h 'bastion>db'` con `-A`. |
| 8 | ¿Por qué `ssh-add -h` necesita tu `known_hosts`? ¿Qué ve root de `server` en `ssh-add -l` si cargaste la llave solo con `-h server`? |
| 9 | ¿Qué hace `ssh-add -c` y por qué falla sin `SSH_ASKPASS`? ¿Por qué esa variable se le da al agente y no a `ssh`? |
| 10 | ¿Qué contiene el archivo privado de una llave `ed25519-sk`? ¿Qué gana un atacante que lo copia? ¿Qué cambian `verify-required` y `no-touch-required`? |

<details>
<summary><strong>Respuestas</strong></summary>

**1.** Guarda llaves privadas ya descifradas. `ssh` le envía los datos a firmar y la pública que quiere usar; el agente devuelve solo la firma. No existe ninguna operación del protocolo del agente que devuelva una privada.

**2.** `ssh-agent` imprime código de shell que define `SSH_AUTH_SOCK` y `SSH_AGENT_PID`; `eval` lo ejecuta en la shell actual. Una variable solo la heredan los procesos hijos: otra terminal no la tiene y no encuentra el agente (salvo con un socket de ruta fija y la variable exportada en `~/.bashrc`).

**3.** 0: hay agente y tiene llaves. 1: hay agente, vacío. 2: no hay agente en `SSH_AUTH_SOCK` (o el socket está huérfano). Un script decide así si reutilizar el agente (0 o 1) o arrancar uno (2), sin leer mensajes.

**4.** Tu usuario y root de tu equipo. El socket está en 600 dentro de una carpeta 700. Nadie puede extraer la privada por el socket; el agente además impide que otros procesos de tu usuario lean su memoria (root sí podría).

**5.** `AddKeysToAgent 1h`: la primera vez que `ssh` descifra la llave, la carga en el agente durante una hora. `ssh-agent -t 1h`: toda llave que entre en ese agente caduca en una hora como máximo. Una llave olvidada en un agente sigue firmando para cualquiera que llegue al socket; la caducidad acota ese tiempo.

**6.** `sshd` crea un socket en el servidor y define `SSH_AUTH_SOCK`; lo que llega a ese socket viaja por la conexión hasta tu agente. Root del servidor (o un proceso con tu usuario allí) puede pedir firmas y entrar como tú en cualquier servidor que acepte tu llave mientras dure la conexión. No puede llevarse la privada ni usarla después de que cierres.

**7.** De más a menos segura: `ProxyJump` (la firma se hace en tu equipo, `bastion` solo reenvía bytes cifrados y no recibe socket); `-h` con `-A` (`bastion` recibe socket, pero solo sirve para ir a `db`); `-A` sin restricciones (root de `bastion` puede usar tu agente para ir a cualquier sitio).

**8.** El agente compara la host key de cada salto, que le informa `ssh` (`bound agent to hostkey`), con las de tu `known_hosts`; sin ellas no sabe qué es "server" (`No host keys found for destination`). Con solo `-h server`, desde `server` la llave no tiene destino permitido y `ssh-add -l` allí dice `The agent has no identities.`

**9.** Pide confirmación antes de cada firma ejecutando el programa de `SSH_ASKPASS`; si no hay programa o sale con un código distinto de 0, el agente se niega (`agent refused operation`). Quien pregunta es el agente, no `ssh`, y el agente solo ve las variables que tenía al arrancar.

**10.** Un identificador (*key handle*) que el dispositivo usa para encontrar su privada, que nunca sale de él. Copiado, no sirve para firmar sin el dispositivo físico. `verify-required` exige además el PIN en cada firma; `no-touch-required` (al crear la llave y en `authorized_keys`) permite firmar sin tocar, solo para automatización y con la línea restringida.

</details>

---

## 💪 Desempeño (40%)

Siete labs, 10 puntos cada uno, escalados a 40.

| Lab | Criterio | Puntos |
|---|---|:--:|
| [01 — Arrancar el agente](2-practicas/lab-01-arrancar-el-agente/README.md) | `eval` explicado; socket 600 en carpeta 700; códigos 0/1/2 de `ssh-add -l`; llave marcada `agent` en `-v` | 10 |
| [02 — La frase una sola vez](2-practicas/lab-02-la-frase-una-sola-vez/README.md) | `AddKeysToAgent 1h` en `config`; frase solo en la primera conexión; caducidad y bloqueo comprobados | 10 |
| [03 — Un agente para todas las terminales](2-practicas/lab-03-un-agente-para-todas-las-terminales/README.md) | Socket de ruta fija compartido; socket huérfano provocado; `agente-vivo.sh` con los tres códigos | 10 |
| [04 — Agent forwarding](2-practicas/lab-04-agent-forwarding/README.md) | Salto con `-A`; socket visto y desaparecido al cerrar; `ForwardAgent` solo para un host; `restrict` lo niega | 10 |
| [05 — Restringir destinos](2-practicas/lab-05-restringir-destinos/README.md) | Camino permitido funcionando; destino directo rechazado; agente vacío visto desde `server`; papel de `known_hosts` explicado | 10 |
| [06 — Confirmar cada uso](2-practicas/lab-06-confirmar-cada-uso/README.md) | Rechazo sin `SSH_ASKPASS` explicado; `confirmar.sh` completo; dos firmas de un salto en el registro | 10 |
| [07 — Llaves FIDO2](2-practicas/lab-07-llaves-fido2/README.md) | Llave `-sk` reconocida por tipo, huella y *application*; opciones de servidor explicadas; (con dispositivo) entrada con toque | 10 |

Dentro de cada lab: 10 puntos si se cumplen todos los criterios y explicas con tus palabras por qué funciona; 8 si se cumplen todos; 7 si falla uno; menos de 7 si fallan dos o más. En el lab 07, la parte B no es obligatoria: sin dispositivo, los 10 puntos salen de la parte A y de la explicación de la B.

---

## 📦 Producto (30%)

### Verificable por el autograding — 60 puntos

Lo ejecuta `./scripts/verificar-semana.sh 04`. Es binario: pasa o no pasa.

| Comprobación | Puntos |
|---|:--:|
| `config-parsea` — El config se lee sin errores | 1 |
| `config-hereda-semana-03` — Siguen las opciones de la semana 03 (IdentitiesOnly yes) | 1 |
| `config-addkeys` — La primera conexión deja la llave en el agente durante 1 h | 4 |
| `config-forwardagent` — ssh no reenvía el agente | 4 |
| `au-uso` — agent-up con argumentos sale con 2 | 1 |
| `au-arranca` — agent-up crea un socket de agente con permisos 600 | 2 |
| `au-dir-700` — El directorio nuevo del socket queda en 700 | 2 |
| `au-eval` — eval de su salida deja un agente vacío listo (ssh-add -l sale con 1) | 3 |
| `au-solo-export` — stdout es solo la línea export SSH_AUTH_SOCK | 3 |
| `au-reutiliza` — Una segunda llamada sale con 0 y no arranca otro agente | 3 |
| `au-reutiliza-llaves` — El agente reutilizado conserva sus llaves | 3 |
| `au-socket-muerto` — Con un socket sin agente detrás, arranca uno nuevo | 5 |
| `au-caducidad` — Las llaves caducan en el agente pasado AGENT_LIFETIME | 4 |
| `kn-uso` — key-new sin argumentos sale con 2 | 1 |
| `kn-tipo-defecto` — Sin KEY_TYPE, la llave es Ed25519 | 2 |
| `kn-tipo-invalido` — key-new rechaza KEY_TYPE=rsa (sale con 2) | 4 |
| `kn-tipo-invalido-limpio` — Con un tipo no admitido no crea ningún archivo | 2 |
| `kn-sk-sin-dispositivo` — Con ed25519-sk y sin llave FIDO2, sale con 1 | 3 |
| `kn-sk-pista` — Sin llave FIDO2, el error lo dice | 2 |
| `ag-sshd-addkeys` — Con el config, la primera conexión a un sshd real deja la llave en el agente | 6 |
| `kit-sigue-funcionando` — ak-line y kh-add de semanas anteriores siguen en el kit | 1 |
| `bin-completo-y-limpio` — Sin TODO y shellcheck sin avisos en bin/ | 3 |
| **Total** | **60** |

### Calidad — 40 puntos

| Criterio | Excelente | Suficiente | Puntos |
|---|---|---|:--:|
| **README del kit** | Fila de `agent-up` con variables, códigos y ejemplo; `KEY_TYPE` en la de `key-new`; bitácora de la semana 04; sección para escribir la frase una vez por sesión y saltar sin `ForwardAgent` | Filas sin ejemplo o sin códigos | 8 |
| **Mensajes** | `agent-up` escribe en stdout solo el `export` y todo lo demás en stderr; los errores dicen qué hacer ("¿está conectada la llave FIDO2?") | Mensajes genéricos | 8 |
| **Comentarios del porqué** | `config` con Qué / Para qué / Impacto en `AddKeysToAgent` y `ForwardAgent`; `agent-up` explica la caducidad y cuándo es seguro borrar el socket | Comentarios que repiten el código | 8 |
| **Seguridad** | Caducidad por defecto en el agente; nunca borra el socket de un agente vivo; `ForwardAgent no` explicado con su riesgo y su alternativa | Agente sin caducidad o forwarding activado en `Host *` | 8 |
| **Git** | Commit nuevo en `~/ssh-infra-kit` con mensaje descriptivo y sin llaves ni sockets en el historial | Sin commit de la semana | 8 |
| **Total** | | | **40** |

### Penalizaciones

| Situación | Deducción |
|---|:--:|
| Una llave privada en el repositorio del kit o en su historial de git | −20 pts |
| `ForwardAgent yes` en `Host *` | −10 pts |
| `StrictHostKeyChecking no`, `accept-new` o `UserKnownHostsFile /dev/null` en cualquier archivo del kit | −10 pts |
| Contraseñas o frases de paso escritas en un archivo del kit | −10 pts |

---

## 📋 Checklist de entrega

- [ ] Los 7 labs con sus criterios de éxito comprobados
- [ ] Las 10 preguntas de Conocimiento respondidas por escrito
- [ ] `3-proyecto/starter/` sin ningún `TODO`
- [ ] `./scripts/verificar-semana.sh 04` con las 22 comprobaciones en verde
- [ ] `ssh-infra-kit` con un commit nuevo y sin llaves

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Proyecto — ssh-infra-kit: agente y llaves `-sk`](3-proyecto/README.md) | [Recursos — ebooks](4-recursos/ebooks-free/README.md) → |

[↑ Semana 04](README.md)
