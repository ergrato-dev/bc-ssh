# Glosario — Semana 14

| Término | Definición |
|---|---|
| **Integración** | Usar las piezas de un sistema juntas. Un **fallo de integración** aparece entre dos piezas que funcionan bien por separado |
| **Prueba de punta a punta** | Recorrer un caso real completo (un equipo nuevo, una baja), desde cero y solo con el kit |
| **`bin/kit-check`** | Script del kit que lo comprueba sin conectar a nada: secretos, permisos, documentación, `TODO`, `ssh -G`, `sshd -t` y `shellcheck` |
| **`shellcheck`** | Analizador estático de scripts de shell: encuentra comillas que faltan, variables sin definir y errores comunes |
| **Idempotente** | Que aplicarlo dos veces deja lo mismo que una. Un playbook idempotente da `changed=0` la segunda vez |
| **Deriva de configuración** | Diferencia entre lo que dice el repositorio y lo que hay en un servidor, casi siempre por cambios a mano. `--check --diff` la muestra |
| **Runbook** | Procedimiento escrito para un incidente concreto: síntoma, pasos con su comando y comprobación |
| **Síntoma** | Lo que ve quien tiene el problema, con el texto exacto del error |
| **Comprobación** | La prueba de que un procedimiento terminó, no de que "parece que va" |
| **Prueba del extraño** | Que otra persona siga un procedimiento sin ayuda; cada duda es un paso que falta |
| **Modelo de amenazas** | Lista de contra qué protege un sistema, con qué control y dónde, y contra qué no |
| **Consola del proveedor** | Acceso al servidor que no pasa por SSH (`docker compose exec` en el laboratorio): la puerta cuando SSH te deja fuera |
| **Master autenticado** | Conexión de multiplexing ya abierta: las siguientes entran por ella sin volver a autenticar, aunque la llave cambie o se revoque |
| **`BatchMode`** | Opción de `ssh` que no pregunta nada (ni frase, ni contraseña, ni host key). La usan `bin/doctor`, Ansible y el CI |
| **`@cert-authority`** | Marca de una línea de `known_hosts` con la llave de una CA de hosts, no de un servidor |
| **Defensa** | Presentación del kit ante otra persona: demo, avería en vivo y preguntas |
| **Guion** | Lista de comandos de la demo, con la salida esperada y lo que demuestra cada uno |
| **`git tag`** | Nombre fijo para un commit (`v1.0`): la versión del kit que defiendes |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — web](../4-recursos/webgrafia/README.md) | — |

[↑ Semana 14](../README.md)
