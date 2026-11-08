# Labs — Semana 02: Protocolo por dentro: KEX, host keys y known_hosts

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-lo-que-ve-un-espia](lab-01-lo-que-ve-un-espia/) | Capturar una conexión con `tcpdump` y comprobar qué viaja en claro y qué cifrado | ~60 min |
| 2 | [lab-02-mensajes-y-capas](lab-02-mensajes-y-capas/) | Traducir los mensajes de `ssh -vvv` a sus capas y provocar una renegociación de llaves | ~60 min |
| 3 | [lab-03-negociacion-de-algoritmos](lab-03-negociacion-de-algoritmos/) | Aplicar a mano la regla de negociación y cambiar las listas con `+`, `-` y `^` | ~60 min |
| 4 | [lab-04-servidor-antiguo](lab-04-servidor-antiguo/) | Conectarte a un servidor con algoritmos antiguos sin rebajar la seguridad del resto | ~60 min |
| 5 | [lab-05-host-keys-y-huellas](lab-05-host-keys-y-huellas/) | Ver las host keys de un servidor, sus huellas y cómo elige el cliente cuál pedir | ~60 min |
| 6 | [lab-06-known-hosts-por-dentro](lab-06-known-hosts-por-dentro/) | Leer, buscar, hashear y limpiar `known_hosts`, y calcular un nombre hasheado a mano | ~60 min |
| 7 | [lab-07-politicas-de-verificacion](lab-07-politicas-de-verificacion/) | Comparar los valores de `StrictHostKeyChecking`, `UpdateHostKeys` y `@revoked` ante llaves nuevas, cambiadas y revocadas | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- Igual que en la semana 01: **paso 0** con `docker compose up -d` y `docker compose run --rm client` **en tu equipo**, y `cd` a la carpeta del lab **en el cliente**. Si cambiaste de semana, ejecuta antes `docker compose up -d --build`: esta semana la imagen incluye `tcpdump`.
- El cliente es un contenedor nuevo cada vez: `~/.ssh` empieza vacío. Varios labs lo aprovechan para empezar con un `known_hosts` limpio.
- Usuario `alumno`, contraseña `alumno`. **Es una contraseña débil a propósito y solo existe en el laboratorio.** Los labs usan `sshpass` para no teclearla cien veces; fuera del laboratorio, nunca.
- Los labs 01, 04 y 05 piden las dos terminales: **En tu equipo** y **En el cliente**.
- Si un lab tiene `starter/`, trabaja ahí. `solucion/` es la referencia.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Host keys y `known_hosts`](../1-teoria/03-host-keys-y-known_hosts.md) | [Lab 01 — Lo que ve un espía](lab-01-lo-que-ve-un-espia/README.md) → |

[↑ Semana 02](../README.md)
