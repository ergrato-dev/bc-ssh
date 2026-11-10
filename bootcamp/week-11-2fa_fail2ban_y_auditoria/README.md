# Semana 11 — 2FA, fail2ban y auditoría con ssh-audit

## Descripción

Tu servidor ya solo acepta llaves (o certificados), sin root y con grupos. Esta semana lo miras como lo mira un atacante y le añades tres defensas. Primero lo **auditas** con `ssh-audit`: qué algoritmos anuncia, cuáles están rotos o son débiles, y una política que tu kit comprueba en cada servidor. Después le pides a cada persona **dos factores**: su llave y un código TOTP de su móvil, a través de PAM, solo para quien esté en el grupo `dosfa`. Por último, **fail2ban** lee el log de `sshd` y bloquea en el cortafuegos las IP que prueban usuarios y contraseñas. Y aprendes a leer ese log: quién entró, con qué llave y desde dónde. Tu kit gana `bin/audit`, `15-algoritmos.conf`, `60-2fa.conf`, el PAM de `sshd` y la jaula de fail2ban, y `sshd-deploy` los instala y los deshace juntos.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Leer un informe de `ssh-audit`: niveles `fail`, `warn` e `info`, recomendaciones y avisos de Terrapin y DHEat
- Quitar algoritmos débiles con listas `-` en `sshd_config` y comprobar qué clientes dejan de conectar
- Escribir una política de `ssh-audit` y comprobar varios servidores contra ella
- Explicar cómo se calcula un código TOTP y qué guarda `~/.google_authenticator`
- Exigir llave **y** código con `AuthenticationMethods`, PAM y `Match Group`, sin dejar fuera al resto
- Configurar una jaula de fail2ban, comprobar su filtro con `fail2ban-regex`, y ver y deshacer un bloqueo
- Responder con el log de `sshd` quién entró, con qué llave, quién falló y desde dónde
- Añadir a tu `ssh-infra-kit` `bin/audit`, `15-algoritmos.conf`, `60-2fa.conf`, `server/pam.d/sshd` y `server/fail2ban/`

## Prerrequisitos

- [Semana 10](../week-10-certificados_ssh_ca_principals_krl_y_rotacion/README.md) completa: el kit con `ca/` y `50-ca.conf`
- Negociación de algoritmos ([semana 02](../week-02-protocolo_kex_y_known_hosts/README.md)), `sshd_config`, `Match` y `sshd-deploy` ([semana 07](../week-07-servidor_sshd_config_y_hardening/README.md))
- El laboratorio **reconstruido**: esta semana la imagen trae `ssh-audit`, `fail2ban`, `nftables`, `libpam-google-authenticator` y `oathtool`, y los servidores pueden tocar su cortafuegos. En tu equipo, desde la raíz del repositorio:
  ```bash
  docker compose build
  docker compose up -d --force-recreate
  ```

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-auditar-algoritmos.md](1-teoria/01-auditar-algoritmos.md) · [02-segundo-factor.md](1-teoria/02-segundo-factor.md) · [03-fail2ban-y-registros.md](1-teoria/03-fail2ban-y-registros.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-leer-ssh-audit](2-practicas/lab-01-leer-ssh-audit/) | 60 min |
| 2 | Lab | [lab-02-quitar-algoritmos](2-practicas/lab-02-quitar-algoritmos/) | 60 min |
| 3 | Lab | [lab-03-politicas-ssh-audit](2-practicas/lab-03-politicas-ssh-audit/) | 60 min |
| 4 | Lab | [lab-04-totp-por-dentro](2-practicas/lab-04-totp-por-dentro/) | 60 min |
| 5 | Lab | [lab-05-llave-y-codigo](2-practicas/lab-05-llave-y-codigo/) | 60 min |
| 6 | Lab | [lab-06-fail2ban](2-practicas/lab-06-fail2ban/) | 60 min |
| 7 | Lab | [lab-07-leer-el-log](2-practicas/lab-07-leer-el-log/) | 60 min |
| — | Proyecto | [ssh-infra-kit: auditoría, segundo factor y fail2ban](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (auditar algoritmos, segundo factor, fail2ban y registros)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — Leer un informe de ssh-audit, en el servidor y en el cliente
[60 min] lab-02 — Quitar algoritmos con listas "-" y ver quién deja de conectar
[60 min] lab-03 — Políticas: generar, escribir y comprobar varios servidores
[60 min] lab-04 — TOTP por dentro: secreto, hora y código
[60 min] lab-05 — Llave y código: PAM, AuthenticationMethods y Match Group
[60 min] lab-06 — fail2ban: jaula, filtro, bloqueo y desbloqueo
[60 min] lab-07 — Leer el log: quién entró, con qué llave y quién falló
[3 h]    Proyecto: bin/audit, 15-algoritmos, 60-2fa, PAM, jaula y sshd-deploy
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 11
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 16 requisitos verificables de la semana. Arrancan `sshd` propios en `127.0.0.1` (con tus `15-algoritmos.conf`, `60-2fa.conf` y PAM), un fail2ban con tu jaula leyendo un log de prueba y un despliegue completo con `sshd-deploy`: solo funcionan dentro del laboratorio. Al terminar deben pasar todos, y tu kit debe auditar `server` sin fallos:

```bash
cd bootcamp/week-11-2fa_fail2ban_y_auditoria/3-proyecto/starter
bin/audit lab-server
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 10 — Certificados SSH: CA, principals, KRL y rotación](../week-10-certificados_ssh_ca_principals_krl_y_rotacion/README.md) | **Semana 11 — 2FA, fail2ban y auditoría con ssh-audit** | Semana 12 — Automatización: scripting, CI/CD y Ansible (próximamente) |

[← Volver al índice del bootcamp](../README.md)
