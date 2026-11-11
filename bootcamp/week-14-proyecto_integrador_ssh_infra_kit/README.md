# Semana 14 — Proyecto integrador `ssh-infra-kit`

## Descripción

Trece semanas, trece piezas, cada una probada sola. Esta semana usas el kit **entero**, como lo usaría otra persona: un portátil vacío, dos servidores recién instalados, una persona que entra con certificado, una llave que se pierde, un ataque a tu propio servidor y un servidor reinstalado que hay que recuperar siguiendo la documentación. Por el camino aparecen fallos que ninguna semana podía ver, porque están **entre** las piezas: un master con contraseña que esconde una llave que no funciona, `bin/doctor` ciego ante los certificados de host, `bin/kh-add` que confunde la CA con el servidor. Los arreglas, añades `bin/kit-check` para que el kit se compruebe a sí mismo (también en el CI), escribes el `RUNBOOK.md` de los siete incidentes y el README que lo une todo, con lo que el kit protege y lo que no. Y cierras con la **defensa**: una demo, una avería en vivo y preguntas.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Explicar dónde vive cada pieza del kit, qué da por hecho de las demás y por qué lo secreto nunca entra en el repositorio
- Instalar el kit en un equipo nuevo y llevar un servidor nuevo a la configuración del repositorio, hasta `changed=0`
- Dar de alta a una persona con certificado y darla de baja, cortando también lo que tenía abierto
- Comprobar el modelo de amenazas atacando tu propio servidor, y escribir lo que el kit no cubre
- Encontrar y arreglar fallos de integración con pruebas de punta a punta
- Escribir procedimientos de incidente (síntoma, pasos, comprobación) y someterlos a la prueba del extraño
- Añadir a tu `ssh-infra-kit` `bin/kit-check`, `RUNBOOK.md` y un README como punto de entrada
- Defender tu kit: demo con guion, diagnóstico en vivo con método y respuestas con el coste de cada decisión

## Prerrequisitos

- [Semana 13](../week-13-troubleshooting_post_cuantico_rendimiento_y_migraciones/README.md) completa: el kit con `bin/doctor`, `bin/key-audit` y `conf.d/90-legado.conf`
- Todo el bootcamp: esta semana usa a la vez `known_hosts` (02), llaves y agente (03-04), multiplexing (05), el servidor endurecido (07), la CA (10), fail2ban y `ssh-audit` (11), Ansible y el CI (12) y el diagnóstico (13)
- El laboratorio de la semana 12 (con `ansible-core`); no hace falta reconstruirlo

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-el-kit-como-sistema.md](1-teoria/01-el-kit-como-sistema.md) · [02-documentar-para-operar.md](1-teoria/02-documentar-para-operar.md) · [03-la-defensa.md](1-teoria/03-la-defensa.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-un-equipo-nuevo](2-practicas/lab-01-un-equipo-nuevo/) | 60 min |
| 2 | Lab | [lab-02-un-servidor-nuevo](2-practicas/lab-02-un-servidor-nuevo/) | 60 min |
| 3 | Lab | [lab-03-alta-con-certificado](2-practicas/lab-03-alta-con-certificado/) | 60 min |
| 4 | Lab | [lab-04-una-llave-perdida](2-practicas/lab-04-una-llave-perdida/) | 60 min |
| 5 | Lab | [lab-05-atacar-tu-servidor](2-practicas/lab-05-atacar-tu-servidor/) | 60 min |
| 6 | Lab | [lab-06-reconstruir-un-servidor](2-practicas/lab-06-reconstruir-un-servidor/) | 60 min |
| 7 | Lab | [lab-07-la-defensa](2-practicas/lab-07-la-defensa/) | 60 min |
| — | Proyecto | [ssh-infra-kit: integración, documentación y defensa](3-proyecto/) | 3 h |

**Total: 12 horas** (más los ~30 min de la defensa)

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (el kit como sistema, documentar para operar, la defensa)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — Un equipo nuevo: el kit en un portátil vacío
[60 min] lab-02 — Un servidor nuevo: del playbook a changed=0
[60 min] lab-03 — Alta con certificado: Ana entra sin authorized_keys
[60 min] lab-04 — Una llave perdida: revocar y cortar lo abierto
[60 min] lab-05 — Atacar tu servidor: el modelo de amenazas en la práctica
[60 min] lab-06 — Reconstruir un servidor siguiendo el RUNBOOK
[3 h]    Proyecto: bin/kit-check, arreglos de integración, RUNBOOK.md, README y CI
[60 min] lab-07 — La defensa: guion y averías al azar (con el proyecto terminado)
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 14
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 15 requisitos verificables de la semana. Los de `bin/kit-check` lo ejecutan sobre copias de tu kit con una sola cosa rota; los de `bin/doctor` y `bin/kh-add` arrancan un `sshd` sin root con certificado de host en `127.0.0.1`: solo funcionan dentro del laboratorio. Al terminar deben pasar todos, y tu kit debe dar siete `ok`:

```bash
cd bootcamp/week-14-proyecto_integrador_ssh_infra_kit/3-proyecto/starter
bin/kit-check
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 13 — Operación y troubleshooting: algoritmos post-cuánticos, rendimiento y migraciones](../week-13-troubleshooting_post_cuantico_rendimiento_y_migraciones/README.md) | **Semana 14 — Proyecto integrador `ssh-infra-kit`** | Fin del bootcamp |

[← Volver al índice del bootcamp](../README.md)
