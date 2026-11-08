# Semana 05 — Configuración avanzada del cliente

## Descripción

Tu `config` crece cada semana, y con él los errores difíciles de ver: un valor que no se aplica, un alias que deja de resolver, una opción que gana a otra sin que sepas por qué. Esta semana entiendes exactamente cómo lee `ssh` su configuración (de dónde, en qué orden y por qué gana el **primer** valor) y lo compruebas con `ssh -G` sin conectar. Partes la configuración en archivos con `Include`, aplicas opciones según condiciones con `Match`, eliges perfiles al conectar con `ssh -P`, y reutilizas una conexión autenticada para todas las siguientes con el **multiplexing**, sabiendo qué decide ese master y cuándo saltártelo. Tu kit pasa a tener los hosts en `conf.d/`, multiplexing, un perfil `sinmux` y dos scripts nuevos: `bin/kit-link` y `bin/mux`.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Explicar de qué archivos y en qué orden lee `ssh` su configuración, y qué cambia `-F`
- Aplicar la regla del primer valor y encontrar con `ssh -G` por qué una opción no se aplica
- Agrupar hosts con patrones (`*`, `?`, `!`) y usar tokens en `HostName`, `IdentityFile` y `ControlPath`
- Partir la configuración con `Include` y resolver las rutas relativas a `~/.ssh`
- Usar `Match` (`host`, `originalhost`, `user`, `exec`, `tagged`) y perfiles con `ssh -P`
- Activar el multiplexing, controlarlo con `ssh -O` y explicar qué decide un master abierto
- Añadir a tu `ssh-infra-kit` `conf.d/`, multiplexing, el perfil `sinmux`, `bin/kit-link` y `bin/mux`

## Prerrequisitos

- [Semana 04](../week-04-ssh_agent_y_llaves_fido2/README.md) completa: agente, `ForwardAgent no` y `ssh-add -h`
- El laboratorio levantado: `docker compose up -d`

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-como-lee-ssh-su-configuracion.md](1-teoria/01-como-lee-ssh-su-configuracion.md) · [02-include-match-y-perfiles.md](1-teoria/02-include-match-y-perfiles.md) · [03-multiplexing.md](1-teoria/03-multiplexing.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-el-primer-valor-gana](2-practicas/lab-01-el-primer-valor-gana/) | 60 min |
| 2 | Lab | [lab-02-patrones-y-tokens](2-practicas/lab-02-patrones-y-tokens/) | 60 min |
| 3 | Lab | [lab-03-include-y-conf-d](2-practicas/lab-03-include-y-conf-d/) | 60 min |
| 4 | Lab | [lab-04-match](2-practicas/lab-04-match/) | 60 min |
| 5 | Lab | [lab-05-perfiles-con-tag](2-practicas/lab-05-perfiles-con-tag/) | 60 min |
| 6 | Lab | [lab-06-multiplexing](2-practicas/lab-06-multiplexing/) | 60 min |
| 7 | Lab | [lab-07-lo-que-decide-el-master](2-practicas/lab-07-lo-que-decide-el-master/) | 60 min |
| — | Proyecto | [ssh-infra-kit: `conf.d/`, perfiles y multiplexing](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (orden de lectura, Include/Match/perfiles, multiplexing)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — Fuentes, -F, ssh -G y un Host * mal colocado
[60 min] lab-02 — Host lab-*, * !lab-bastion y tokens
[60 min] lab-03 — ~/.ssh/conf.d/, orden alfabético, Include vacío y -F
[60 min] lab-04 — Match host, originalhost, user y exec
[60 min] lab-05 — Perfiles con -P, Tag y Match tagged
[60 min] lab-06 — ControlMaster, ControlPath, ControlPersist y ssh -O
[60 min] lab-07 — Revocación, -A y permisos con un master abierto
[3 h]    Proyecto: conf.d/, multiplexing, sinmux, bin/kit-link y bin/mux
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 05
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 22 requisitos verificables de la semana; tres de ellos arrancan un `sshd` real dentro del cliente para comprobar el master. Al terminar deben pasar todos, y dentro del cliente, con la llave del paso 5 del proyecto instalada, esto debe decir `hostname server`, `server` y `Master running`:

```bash
cd bootcamp/week-05-configuracion_avanzada_cliente_ssh/3-proyecto/starter
bin/kit-link
ssh -G -F config lab-server | grep '^hostname '
ssh -F config lab-server hostname
ssh -F config -O check lab-server
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 04 — `ssh-agent`, agent forwarding y llaves FIDO2](../week-04-ssh_agent_y_llaves_fido2/README.md) | **Semana 05 — Configuración avanzada del cliente** | [Semana 06 — Transferencia de archivos →](../week-06-transferencia_archivos_scp_sftp_rsync/README.md) |

[← Volver al índice del bootcamp](../README.md)
