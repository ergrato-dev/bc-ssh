# Semana 02 — Protocolo por dentro: KEX, host keys y known_hosts

## Descripción

Abres la caja negra de la semana 01. Verás con `tcpdump` qué viaja en claro y qué cifrado, seguirás mensaje a mensaje las tres capas del protocolo, aplicarás a mano la regla con la que cliente y servidor eligen algoritmos y entenderás dónde exactamente queda demostrada la identidad del servidor. La segunda mitad trata de `known_hosts`, la pieza de la que depende toda esa seguridad: su formato, sus nombres hasheados y qué hace `ssh` con llaves nuevas, cambiadas o revocadas. Tu kit deja de aceptar llaves a ciegas.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Explicar las tres capas de SSH y asignar cada mensaje de `ssh -vvv` a su capa
- Comprobar con `tcpdump` qué partes de una conexión ve un observador
- Predecir qué algoritmos se negocian y modificar las listas con `+`, `-` y `^`
- Explicar por qué la firma del hash de intercambio solo protege con una host key verificada
- Conectarte a un servidor con algoritmos antiguos sin rebajar la seguridad del resto
- Leer, buscar, hashear y limpiar `known_hosts`, y calcular un nombre hasheado a mano
- Elegir el valor de `StrictHostKeyChecking` adecuado a cada situación
- Añadir a tu `ssh-infra-kit` un `known_hosts` verificado con `bin/kh-add`

## Prerrequisitos

- [Semana 01](../week-01-fundamentos_ssh_y_primera_conexion/README.md) completa: laboratorio, `ssh -v`, `known_hosts` básico y tu `ssh-infra-kit`
- La imagen del laboratorio actualizada: `docker compose up -d --build` (esta semana incluye `tcpdump`)

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-capas-del-protocolo.md](1-teoria/01-capas-del-protocolo.md) · [02-intercambio-de-llaves.md](1-teoria/02-intercambio-de-llaves.md) · [03-host-keys-y-known_hosts.md](1-teoria/03-host-keys-y-known_hosts.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-lo-que-ve-un-espia](2-practicas/lab-01-lo-que-ve-un-espia/) | 60 min |
| 2 | Lab | [lab-02-mensajes-y-capas](2-practicas/lab-02-mensajes-y-capas/) | 60 min |
| 3 | Lab | [lab-03-negociacion-de-algoritmos](2-practicas/lab-03-negociacion-de-algoritmos/) | 60 min |
| 4 | Lab | [lab-04-servidor-antiguo](2-practicas/lab-04-servidor-antiguo/) | 60 min |
| 5 | Lab | [lab-05-host-keys-y-huellas](2-practicas/lab-05-host-keys-y-huellas/) | 60 min |
| 6 | Lab | [lab-06-known-hosts-por-dentro](2-practicas/lab-06-known-hosts-por-dentro/) | 60 min |
| 7 | Lab | [lab-07-politicas-de-verificacion](2-practicas/lab-07-politicas-de-verificacion/) | 60 min |
| — | Proyecto | [ssh-infra-kit: known_hosts verificado](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (capas, negociación e intercambio de llaves, host keys y known_hosts)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — Qué ve un espía: tcpdump sobre texto plano y sobre SSH
[60 min] lab-02 — Mensajes de ssh -vvv por capas y renegociación de llaves
[60 min] lab-03 — La regla de negociación a mano; +, - y ^
[60 min] lab-04 — Un servidor con algoritmos SHA-1, solo para su Host
[60 min] lab-05 — Host keys, huellas y el tipo de llave que pide el cliente
[60 min] lab-06 — known_hosts por dentro y HMAC a mano
[60 min] lab-07 — StrictHostKeyChecking, @revoked y known_hosts global
[3 h]    Proyecto: StrictHostKeyChecking yes y bin/kh-add
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 02
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 19 requisitos verificables de la semana. Al terminar deben pasar todos, y esto debe funcionar dentro del cliente, con la huella que obtengas por `docker compose exec server ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`:

```bash
cd bootcamp/week-02-protocolo_kex_y_known_hosts/3-proyecto/starter
bin/kh-add server SHA256:...
ssh -F config lab-server hostname
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 01 — Fundamentos de SSH y primera conexión](../week-01-fundamentos_ssh_y_primera_conexion/README.md) | **Semana 02 — Protocolo por dentro: KEX, host keys y known_hosts** | [Semana 03 — Autenticación con llaves →](../week-03-autenticacion_con_llaves_ssh/README.md) |

[← Volver al índice del bootcamp](../README.md)
