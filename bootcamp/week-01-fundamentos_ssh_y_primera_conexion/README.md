# Semana 01 — Fundamentos de SSH y primera conexión

## Descripción

Te conectarás por SSH por primera vez y entenderás qué pasa por debajo: un cliente que verifica la identidad del servidor, acuerda una llave de sesión y solo entonces envía tu contraseña. Todo ocurre en un laboratorio Docker con servidores reales. Es la base del bootcamp: sin este modelo, cada error de conexión es un misterio; con él, sabes en qué capa buscar.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Explicar qué problema resuelve SSH frente a Telnet y qué cuatro garantías ofrece
- Levantar el laboratorio y distinguir `client`, `server`, `bastion` e `interno`
- Conectarte a un servidor verificando su huella por un canal independiente
- Ejecutar comandos remotos y entender sus códigos de salida, comillas, stdin y stdout
- Leer las fases de una conexión en `ssh -v`
- Diagnosticar los cinco errores de conexión más comunes por su mensaje
- Escribir alias en un `config` de cliente y comprobar con `ssh -G` qué valor gana
- Empezar tu `ssh-infra-kit` con `config` y `bin/lab-check`

## Prerrequisitos

- Soltura básica con la terminal: navegar, editar un archivo, permisos, pipes
- Docker con Docker Compose, y git: ver [docs/setup-entorno.md](../../docs/setup-entorno.md)
- No se asume nada de SSH, criptografía ni redes

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-que-es-ssh.md](1-teoria/01-que-es-ssh.md) · [02-cliente-servidor-y-laboratorio.md](1-teoria/02-cliente-servidor-y-laboratorio.md) · [03-criptografia-basica.md](1-teoria/03-criptografia-basica.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-laboratorio-docker](2-practicas/lab-01-laboratorio-docker/) | 60 min |
| 2 | Lab | [lab-02-primera-conexion](2-practicas/lab-02-primera-conexion/) | 60 min |
| 3 | Lab | [lab-03-comandos-remotos](2-practicas/lab-03-comandos-remotos/) | 60 min |
| 4 | Lab | [lab-04-sesion-interactiva-y-escapes](2-practicas/lab-04-sesion-interactiva-y-escapes/) | 60 min |
| 5 | Lab | [lab-05-modo-verbose](2-practicas/lab-05-modo-verbose/) | 60 min |
| 6 | Lab | [lab-06-errores-comunes](2-practicas/lab-06-errores-comunes/) | 60 min |
| 7 | Lab | [lab-07-config-y-precedencia](2-practicas/lab-07-config-y-precedencia/) | 60 min |
| — | Proyecto | [ssh-infra-kit: config y lab-check](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (qué es SSH, cliente-servidor y laboratorio, criptografía mínima)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — Levantar el laboratorio y leer un banner SSH con nc
[60 min] lab-02 — Primera conexión verificando la huella
[60 min] lab-03 — Comandos remotos, códigos de salida y comillas
[60 min] lab-04 — Procesos de sshd y secuencias de escape
[60 min] lab-05 — Las fases de una conexión en ssh -v
[60 min] lab-06 — Los cinco errores más comunes
[60 min] lab-07 — config, alias y precedencia con ssh -G
[3 h]    Proyecto: ssh-infra-kit con config y lab-check
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 01
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 16 requisitos verificables de la semana, dentro del laboratorio Docker. Al terminar deben pasar todos, y estos comandos deben funcionar dentro del cliente:

```bash
cd bootcamp/week-01-fundamentos_ssh_y_primera_conexion/3-proyecto/starter
ssh -G -F config lab-server | grep -E '^(hostname|user) '
bin/lab-check server bastion interno
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| — | **Semana 01 — Fundamentos de SSH y primera conexión** | [Semana 02 — Protocolo por dentro: KEX, host keys y known_hosts →](../week-02-protocolo_kex_y_known_hosts/README.md) |

[← Volver al índice del bootcamp](../README.md)
