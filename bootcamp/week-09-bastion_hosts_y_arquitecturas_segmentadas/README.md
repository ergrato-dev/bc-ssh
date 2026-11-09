# Semana 09 — Bastion hosts y arquitecturas segmentadas

## Descripción

`interno` está en una red a la que tu equipo no llega: la única puerta es `bastion`. Esta semana entras por ella bien. Primero, mal: dos sesiones encadenadas, con el bastion autenticando y viéndolo todo. Después, con `ProxyJump`: un `ssh` dentro de otro, los dos en tu equipo, cifrado de extremo a extremo. Ves qué puede hacer `root` en el bastion con tu agente reenviado, conviertes el bastion en una puerta que solo deja saltar a donde tú dices, y aprendes a saber quién saltó a dónde y a cortarle el paso. Tu kit gana `lab-interno`, que entra con una sola orden por una cuenta de salto sin shell, `kh-add -J` y la configuración del bastion.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Explicar qué gana una red segmentada, qué es un bastion y qué riesgos trae
- Entrar en un host interno con `ssh -J`, y decir quién se autentica, quién comprueba cada host key y qué ve el bastion
- Verificar la host key de un host al que solo llegas saltando
- Usar `ssh -W` y `ProxyCommand`, y saltar con `nc` o un proxy SOCKS
- Escribir saltos en `ssh_config`, desactivarlos y aplicarlos solo cuando hacen falta, con multiplexing
- Demostrar el riesgo del agente reenviado y limitarlo con `ssh-add -h` y `AllowAgentForwarding`
- Configurar cuentas que solo saltan: `ForceCommand`, `PermitTTY`, `AllowTcpForwarding local` y `PermitOpen`
- Registrar el destino de cada salto, cortar un acceso y cerrar las conexiones abiertas
- Añadir a tu `ssh-infra-kit` `conf.d/30-bastion.conf`, `kh-add -J` y `server/sshd_config.d/40-salto.conf`

## Prerrequisitos

- [Semana 08](../week-08-port_forwarding_socks_y_tuneles/README.md) completa: el kit con `bin/tunnel`, y los canales `direct-tcpip` de `-L`
- El agente y su reenvío ([semana 04](../week-04-ssh_agent_y_llaves_fido2/README.md)), `Match` y multiplexing ([semana 05](../week-05-configuracion_avanzada_cliente_ssh/README.md)), y `Match Group` y `sshd-deploy` ([semana 07](../week-07-servidor_sshd_config_y_hardening/README.md))
- El laboratorio levantado: `docker compose up -d` (esta semana usa `bastion` e `interno`, que ya estaban en `compose.yaml`)

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-redes-segmentadas-y-bastion.md](1-teoria/01-redes-segmentadas-y-bastion.md) · [02-proxyjump-y-proxycommand.md](1-teoria/02-proxyjump-y-proxycommand.md) · [03-endurecer-el-bastion.md](1-teoria/03-endurecer-el-bastion.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-red-segmentada](2-practicas/lab-01-red-segmentada/) | 60 min |
| 2 | Lab | [lab-02-proxyjump](2-practicas/lab-02-proxyjump/) | 60 min |
| 3 | Lab | [lab-03-proxycommand-y-w](2-practicas/lab-03-proxycommand-y-w/) | 60 min |
| 4 | Lab | [lab-04-saltos-en-config](2-practicas/lab-04-saltos-en-config/) | 60 min |
| 5 | Lab | [lab-05-agente-reenviado](2-practicas/lab-05-agente-reenviado/) | 60 min |
| 6 | Lab | [lab-06-bastion-endurecido](2-practicas/lab-06-bastion-endurecido/) | 60 min |
| 7 | Lab | [lab-07-auditoria-y-cortes](2-practicas/lab-07-auditoria-y-cortes/) | 60 min |
| — | Proyecto | [ssh-infra-kit: acceso a `interno` vía `bastion`](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (redes segmentadas, ProxyJump y ProxyCommand, endurecer el bastion)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — Quién alcanza a quién y dos sesiones encadenadas
[60 min] lab-02 — ssh -J, la host key de interno, qué ve el bastion y saltos encadenados
[60 min] lab-03 — ssh -W, ProxyCommand, nc y SOCKS, HostKeyAlias
[60 min] lab-04 — ProxyJump en ssh_config, -J none, Match exec y multiplexing
[60 min] lab-05 — El agente reenviado en manos de root, ssh-add -h
[60 min] lab-06 — Una cuenta que solo salta: nologin, ForceCommand, PermitOpen
[60 min] lab-07 — LogLevel DEBUG1, saltos activos, cortar un acceso y el bastion caído
[3 h]    Proyecto: conf.d/30-bastion.conf, kh-add -J y 40-salto.conf
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 09
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 16 requisitos verificables de la semana. Saltan de verdad con tu kit entre dos `sshd` propios dentro del contenedor `client`, y validan tu `40-salto.conf` con `sshd -T`: solo funcionan dentro del laboratorio. Al terminar deben pasar todos, y tu kit debe entrar en `interno`:

```bash
cd bootcamp/week-09-bastion_hosts_y_arquitecturas_segmentadas/3-proyecto/starter
bin/kit-link
ssh -F config lab-interno hostname
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 08 — Port forwarding, SOCKS y túneles](../week-08-port_forwarding_socks_y_tuneles/README.md) | **Semana 09 — Bastion hosts y arquitecturas segmentadas** | Semana 10 — Certificados SSH: CA, principals, KRL y rotación (próximamente) |

[← Volver al índice del bootcamp](../README.md)
