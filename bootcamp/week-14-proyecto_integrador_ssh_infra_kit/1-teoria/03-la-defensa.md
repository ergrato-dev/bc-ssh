# La defensa

## Qué es la defensa

La defensa cierra el bootcamp: presentas tu `ssh-infra-kit` a otra persona (tu evaluador, un compañero o tu equipo) y respondes a sus preguntas. Dura unos **30 minutos**:

| Parte | Tiempo | Qué demuestras |
|---|:--:|---|
| Demo | 15 min | El kit funciona entero, de punta a punta, en un laboratorio limpio |
| Avería en vivo | 10 min | Diagnosticas un fallo que no conoces con tu kit y tu runbook |
| Preguntas | 5 min o más | Sabes por qué cada decisión, y qué no cubre el kit |

No se evalúa que todo salga perfecto: se evalúa que **entiendes** lo que hiciste. Un fallo en la demo que diagnosticas con calma vale más que una demo ensayada que no sabes explicar.

## La demo: un guion, no una improvisación

Quince minutos se van rápido. Escribe un guion: una lista de comandos en orden, cada uno con lo que vas a decir y lo que debe salir. El lab 07 te da la estructura:

1. **El kit** (1 min): `bin/kit-check`, todo en `ok`. Las tres reglas del mapa (teoría 01): lo secreto fuera, los servidores desde el repositorio, `kit-check` antes de cada cambio.
2. **Un equipo nuevo** (3 min): `bin/kit-link`, `bin/kh-add` con la huella comprobada, `bin/doctor lab-server` con `(postcuántico)` y `entrada: publickey`.
3. **Un servidor desde el repositorio** (4 min): el playbook con `--check --diff`, aplicado, y otra vez con `changed=0`. `bin/audit lab-server`: `cumple`.
4. **Una persona entra y sale** (4 min): `ca/ca-sign` a Ana, Ana entra sin `authorized_keys`; `ca/ca-revoke`, ya no entra, y la línea del log del servidor que lo dice.
5. **Lo que no cubre** (1 min): dos frases sobre tu lista de "no protege contra".
6. **Margen** (2 min): algo saldrá más lento de lo previsto.

**Qué:** comandos escritos, con su salida esperada. **Para qué:** no perder tiempo pensando qué teclear, y que cada paso demuestre algo concreto. **Impacto:** el guion es también tu red: si te pierdes, vuelves a la línea siguiente.

Antes de la defensa, ensáyalo **en un laboratorio recién creado** (`docker compose up -d --force-recreate`, un cliente nuevo). Lo que funciona en tu laboratorio de hace tres semanas puede depender de algo que hiciste a mano y no recuerdas.

## La avería en vivo

Tu evaluador rompe `server` sin decirte cómo (el lab 07 trae `romper.sh` para practicarlo) y tú lo arreglas. Lo que se mira es el **método**, no la velocidad:

1. **Empieza por `bin/doctor`**, no por adivinar. Di en voz alta en qué capa falla.
2. **Sigue la pista.** Si es `Permission denied`, la razón está en el servidor: el log o `sshd -d` en otro puerto. Entra por la consola (`docker compose exec server`).
3. **Busca en el RUNBOOK** el procedimiento del síntoma, y síguelo.
4. **Comprueba** con lo que dice la comprobación del procedimiento, no con "parece que va".
5. **Di qué lo habría evitado**: `sshd -t` antes de recargar, el playbook en lugar de un cambio a mano, una alerta en el log...

Callarse mientras pruebas cosas es lo peor que puedes hacer: el evaluador no puede valorar un razonamiento que no oye. Piensa en voz alta, aunque te equivoques.

## Las preguntas

Las preguntas buscan los límites: lo que harías distinto, lo que no cubre el kit, lo que pasa si algo falla. Algunas que salen casi siempre:

- ¿Por qué certificados y no solo `authorized_keys`? ¿Qué te cuesta tenerlos?
- Si te roban el portátil esta noche, ¿qué haces, en qué orden y cuánto tardas?
- ¿Qué pasa si alguien consigue la llave de tu CA? ¿Y la del CI?
- ¿Por qué `StrictHostKeyChecking yes` y no `accept-new`?
- ¿Qué cambiarías para cien servidores en lugar de dos? ¿Y para diez personas?
- ¿Qué parte de tu kit no entiendes del todo?

La última no es una trampa. "No lo sé, lo comprobaría así: ..." es una respuesta buena. Inventar es la mala.

### Cómo responder

- **Corto y concreto**: la respuesta, y después la razón. "Revoco con `ca/ca-revoke` y despliego la KRL; los masters abiertos siguen vivos, así que además corto sus sesiones."
- **Con el kit delante**: si la respuesta está en un archivo, ábrelo. "Está en `10-acceso.conf`: Qué, Para qué, Impacto."
- **Con el coste**: toda decisión de seguridad cuesta algo. Decir qué cuesta demuestra que la entiendes.

## Prepararla

| Cuándo | Qué |
|---|---|
| Al terminar el proyecto | `ENTREGA` de la semana: `./scripts/verificar-semana.sh 14` en verde |
| Dos días antes | El guion escrito; un ensayo cronometrado en un laboratorio limpio |
| Un día antes | Dos rondas de `romper.sh` con un compañero; repasa el RUNBOOK |
| El día | Laboratorio recién creado, guion a la vista, otra terminal con `docker compose exec server bash` preparada |

## Lo que te llevas

- La defensa mide si entiendes tu kit, no si la demo es perfecta.
- Un guion con la salida esperada de cada paso, ensayado en un laboratorio limpio.
- Ante una avería: `bin/doctor`, la pista, el RUNBOOK, la comprobación. En voz alta.
- "No lo sé, lo comprobaría así" es una buena respuesta.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Documentar para operar](02-documentar-para-operar.md) | [Índice de labs](../2-practicas/README.md) → |

[↑ Semana 14](../README.md)
