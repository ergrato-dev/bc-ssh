# Semana 04 — `ssh-agent`, agent forwarding y llaves FIDO2

## Descripción

Tu llave tiene frase de paso, y ahora la escribes en cada conexión. `ssh-agent` la descifra una vez y firma por ti sin entregar nunca la privada. Verás quién puede pedirle firmas a tu agente y por qué eso importa cuando lo **reenvías** a un servidor con `ssh -A`: mientras estás conectado, root de ese servidor puede usarlo para entrar como tú en otros. Aprenderás a limitar ese riesgo (no reenviar por defecto, restringir destinos con `ssh-add -h`, confirmar cada firma con `ssh-add -c`, caducidad) y conocerás las llaves FIDO2, cuya privada vive en un dispositivo físico que hay que tocar para cada firma. Tu kit pasa a pedir la frase una vez por sesión, reutiliza un solo agente y no reenvía nada.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Explicar cómo `ssh` usa el agente por `SSH_AUTH_SOCK` y por qué la privada no sale de él
- Arrancar, cargar, listar, bloquear y detener un agente, con caducidad por llave
- Compartir un solo agente entre terminales y recuperarte de un socket huérfano
- Explicar qué hace el agent forwarding y qué puede hacer con él root del servidor
- Restringir una llave a un camino con `ssh-add -h` y pedir confirmación por firma con `ssh-add -c`
- Reconocer una llave FIDO2 (`ed25519-sk`) y las opciones de toque y PIN en cliente y servidor
- Añadir a tu `ssh-infra-kit` `AddKeysToAgent`, `ForwardAgent no`, `bin/agent-up` y llaves `-sk` en `bin/key-new`

## Prerrequisitos

- [Semana 03](../week-03-autenticacion_con_llaves_ssh/README.md) completa: llaves con frase de paso, `authorized_keys` y `restrict`
- El laboratorio levantado: `docker compose up -d`
- Opcional, para la parte B del lab 07: una llave de seguridad FIDO2

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-ssh-agent.md](1-teoria/01-ssh-agent.md) · [02-agent-forwarding-y-riesgos.md](1-teoria/02-agent-forwarding-y-riesgos.md) · [03-llaves-fido2-sk.md](1-teoria/03-llaves-fido2-sk.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-arrancar-el-agente](2-practicas/lab-01-arrancar-el-agente/) | 60 min |
| 2 | Lab | [lab-02-la-frase-una-sola-vez](2-practicas/lab-02-la-frase-una-sola-vez/) | 60 min |
| 3 | Lab | [lab-03-un-agente-para-todas-las-terminales](2-practicas/lab-03-un-agente-para-todas-las-terminales/) | 60 min |
| 4 | Lab | [lab-04-agent-forwarding](2-practicas/lab-04-agent-forwarding/) | 60 min |
| 5 | Lab | [lab-05-restringir-destinos](2-practicas/lab-05-restringir-destinos/) | 60 min |
| 6 | Lab | [lab-06-confirmar-cada-uso](2-practicas/lab-06-confirmar-cada-uso/) | 60 min |
| 7 | Lab | [lab-07-llaves-fido2](2-practicas/lab-07-llaves-fido2/) | 60 min |
| — | Proyecto | [ssh-infra-kit: agente y llaves `-sk`](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (agente, forwarding y riesgos, llaves FIDO2)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — eval "$(ssh-agent)", ssh-add y el socket
[60 min] lab-02 — AddKeysToAgent, caducidad, bloqueo e IdentityAgent=none
[60 min] lab-03 — Socket de ruta fija, socket huérfano y agente-vivo.sh
[60 min] lab-04 — ssh -A, el socket en el servidor, ForwardAgent y restrict
[60 min] lab-05 — ssh-add -h: una llave para un solo camino
[60 min] lab-06 — ssh-add -c con un SSH_ASKPASS que registra cada firma
[60 min] lab-07 — Llaves ed25519-sk: formato, opciones y dispositivo real
[3 h]    Proyecto: AddKeysToAgent, ForwardAgent no, bin/agent-up y KEY_TYPE
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 04
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 22 requisitos verificables de la semana; uno de ellos arranca un `sshd` real dentro del cliente para comprobar que la primera conexión carga tu llave en el agente. Al terminar deben pasar todos, y esto debe pedir la frase de tu llave **una sola vez** dentro del cliente:

```bash
cd bootcamp/week-04-ssh_agent_y_llaves_fido2/3-proyecto/starter
eval "$(bin/agent-up)"
ssh -F config lab-server hostname
ssh -F config lab-server hostname
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 03 — Autenticación con llaves](../week-03-autenticacion_con_llaves_ssh/README.md) | **Semana 04 — `ssh-agent`, agent forwarding y llaves FIDO2** | [Semana 05 — 🔧 Semana 03: Configuración Avanzada del Cliente SSH →](../week-05-configuracion_avanzada_cliente_ssh/README.md) |

[← Volver al índice del bootcamp](../README.md)
