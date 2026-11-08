# CLAUDE.md — bc-ssh

Instrucciones de proyecto para Claude Code. Este archivo se carga automáticamente en cada sesión.

---

## Identidad del proyecto

- **Nombre:** bc-ssh
- **Tipo:** Bootcamp técnico Zero to Advanced, orientado a la práctica
- **Duración:** 14 semanas × 12 horas = 168 horas totales
- **Herramienta central:** OpenSSH **≥ 9.6** (Ubuntu 24.04 LTS). Features más nuevas se marcan "OpenSSH 9.9+" con alternativa para 9.6
- **Sistema mínimo del estudiante:** Docker + Docker Compose (Linux, macOS o Windows con WSL2). Todo lab corre en el laboratorio de `compose.yaml`
- **Repositorio de referencia de estructura:** ergrato-dev/bc-tmux

## Audiencia objetivo

Personas que nunca usaron SSH, o que solo lo usan para entrar con contraseña. Se asume terminal básica (nivel de bc-linux-commandline: navegar, editar un archivo, permisos). **No se asume nada de SSH, criptografía, redes ni Docker**: cada comando nuevo se explica la primera vez que aparece.

## Reglas obligatorias de contenido

- **Idioma:** documentación en español, **siempre tuteo, nunca voseo** (`ejecuta`, `revisa`, nunca `ejecutá`, `revisá`, `vos`). Nomenclatura técnica en inglés (nombres de archivos de código, variables, opciones, comandos).
- **Herramientas:** Python siempre con **uv** (`uv tool install`, `uv run`, FastAPI con `uv`), nunca pip. JavaScript siempre con **pnpm**, nunca npm/npx/yarn. Bases de datos siempre **PostgreSQL**, nunca MySQL/MariaDB. **Docker** siempre que haga falta un servidor, una red o un servicio.
- **Paso a paso:** ejemplos claros y detallados, numerados, con el comando exacto y la salida esperada. Nunca "configura X" sin decir cómo. Los ejercicios no dan nada por sabido.
- **Qué / Para qué / Impacto:** documenta así cada configuración, opción o decisión relevante (en prosa o en comentarios). No repitas el mismo comentario en varios sitios: explica una vez y enlaza.
- **Seguridad:** el laboratorio usa contraseñas débiles a propósito; cada vez que aparezca, se avisa que es solo para el laboratorio. Nunca se suben llaves privadas a git.

## Distribución de tiempo por semana (12 h)

| Sección | Tiempo | Descripción |
|---|---|---|
| 1-teoria | 1.5 h | Contexto, conceptos y referencia (2–4 archivos) |
| Conocimiento | 0.5 h | 10 preguntas de la rúbrica, respondidas por escrito |
| 2-practicas | 7 h | 6–7 labs progresivos (~60 min c/u) |
| 3-proyecto | 3 h | Incremento semanal de `ssh-infra-kit` |

## Proyecto hilo conductor: `ssh-infra-kit`

El estudiante construye a lo largo del bootcamp **su kit de acceso e infraestructura SSH**: configuración de cliente modular, scripts, hardening de servidor, CA de certificados y automatización. Cada `3-proyecto/starter/` parte de la `solucion/` de la semana anterior; la semana 14 entrega el kit completo. Detalle en `docs/proyecto-hilo-conductor.md`.

## Estructura de carpetas por semana

```
week-NN-nombre_del_tema/
├── README.md                  # Descripción, objetivos, contenidos, navegación entre semanas
├── rubrica-evaluacion.md      # Conocimiento 30 / Desempeño 40 / Producto 30
├── checks.json                # Autograding (docs/autograding.md)
├── 0-assets/                  # Solo SVG, cada uno enlazado desde 1-teoria
├── 1-teoria/                  # 01-tema.md ... (2–4 archivos)
├── 2-practicas/
│   ├── README.md              # Índice de labs con duración
│   └── lab-NN-nombre/
│       ├── README.md          # Objetivo, pasos numerados, salida esperada, criterios de éxito
│       ├── starter/           # Archivos con TODOs (si el lab los necesita)
│       └── solucion/          # Solución de referencia
├── 3-proyecto/
│   ├── README.md              # Paso a paso + "✅ Requisitos verificables" (copia de checks.json)
│   ├── starter/               # ssh-infra-kit de la semana anterior + TODOs
│   └── solucion/              # ssh-infra-kit al terminar la semana
├── 4-recursos/
│   ├── ebooks-free/README.md
│   ├── videografia/README.md
│   └── webgrafia/README.md
└── 5-glosario/README.md
```

Nombres: `week-NN-slug_con_guiones_bajos`, `lab-NN-slug-con-guiones`.

## Diagramas SVG (0-assets/)

- Solo los que la teoría necesite: que no sobre ninguno ni falte ninguno.
- Tema dark: fondo `#0d1117`, cajas `#161b22`, bordes `#30363d`, texto `#c9d1d9`; acentos `#58a6ff`, `#3fb950`, `#f85149`, `#d29922`.
- **Sin degradados** (`linearGradient`/`radialGradient` prohibidos). Fuente `sans-serif`; `monospace` solo para comandos o código.
- Cada SVG enlazado desde al menos un `.md` (lo comprueba `scripts/verificar-enlaces.sh`).

## Navegación

Cada documento de la semana termina con la tabla `| Anterior | Siguiente |` generada por `scripts/generar-navegacion.sh NN` (orden: teoría → labs → proyecto → rúbrica → recursos → glosario). El README de cada semana lleva su propia tabla entre semanas. No se escribe a mano.

## Laboratorio

`compose.yaml`: `client` (shell del estudiante, monta el repo en `/bc-ssh`), `server` y `bastion` en la red `publica`, `interno` solo en la red `privada` (alcanzable únicamente vía `bastion`). Usuario `alumno`, contraseña `alumno` (solo laboratorio). Host keys generadas al arrancar cada contenedor.

## Antes de dar una semana por terminada

1. `ENTREGA=solucion ./scripts/verificar-semana.sh NN` pasa y `./scripts/verificar-semana.sh NN` (starter) falla.
2. `./scripts/generar-navegacion.sh NN` y `./scripts/verificar-enlaces.sh` sin errores.
3. Marcar la semana con ✅ en `bootcamp/README.md`.
