# Labs — Semana 01: Fundamentos de SSH y primera conexión

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-laboratorio-docker](lab-01-laboratorio-docker/) | Levantar el laboratorio y comprobar qué hosts existen y tienen un servidor SSH escuchando | ~60 min |
| 2 | [lab-02-primera-conexion](lab-02-primera-conexion/) | Conectarte a `server` verificando su huella por un canal independiente | ~60 min |
| 3 | [lab-03-comandos-remotos](lab-03-comandos-remotos/) | Ejecutar comandos remotos y entender códigos de salida, comillas, stdin y stdout | ~60 min |
| 4 | [lab-04-sesion-interactiva-y-escapes](lab-04-sesion-interactiva-y-escapes/) | Ver los procesos de `sshd` por conexión y recuperar una sesión colgada con `~.` | ~60 min |
| 5 | [lab-05-modo-verbose](lab-05-modo-verbose/) | Seguir cada fase de una conexión en la salida de `ssh -v` | ~60 min |
| 6 | [lab-06-errores-comunes](lab-06-errores-comunes/) | Provocar y diagnosticar los cinco errores de conexión más frecuentes | ~60 min |
| 7 | [lab-07-config-y-precedencia](lab-07-config-y-precedencia/) | Escribir alias en un `config` y comprobar con `ssh -G` qué valor gana | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- Todo ocurre en el laboratorio Docker. Cada lab empieza con un **paso 0**: en tu equipo, desde la raíz del repositorio, `docker compose up -d` y `docker compose run --rm client`; dentro del cliente, `cd` a la carpeta del lab.
- Las instrucciones dicen dónde va cada comando: **En tu equipo** (tu terminal normal, en la raíz de `bc-ssh`) o **En el cliente** (el prompt `alumno@client`). Los labs 02, 04 y 06 piden las dos terminales a la vez.
- El cliente es un contenedor nuevo cada vez (`--rm`): `~/.ssh` empieza vacío y volverás a ver la pregunta de la huella. Lo que guardes en `/bc-ssh` (el repositorio) se conserva.
- Usuario `alumno`, contraseña `alumno` en todos los servidores. **Es una contraseña débil a propósito y solo existe en el laboratorio.**
- Si un lab tiene `starter/`, trabaja ahí. `solucion/` es la referencia: ábrela solo para comparar al terminar.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Criptografía mínima para entender SSH](../1-teoria/03-criptografia-basica.md) | [Lab 01 — El laboratorio Docker](lab-01-laboratorio-docker/README.md) → |

[↑ Semana 01](../README.md)
