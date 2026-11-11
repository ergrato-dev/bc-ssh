# Semana 12 — Automatización: scripting, CI/CD y Ansible

## Descripción

Hasta ahora, delante de cada `ssh` había una persona. Esta semana la quitas. Primero, **SSH dentro de un script**: códigos de salida, `BatchMode`, timeouts, la entrada de un bucle, las comillas que se interpretan dos veces y muchos servidores en paralelo. Después, **despliegues desde un CI**: una llave solo para eso, limitada con comando forzado, `restrict` y `from=`; los secretos en variables que nunca tocan el log; y el `known_hosts` que casi todos los CI se saltan, y por qué no debes hacerlo. Por último, **Ansible**: el mismo bucle hecho bien, que usa tu `ssh` (configuración, llaves, `known_hosts`, `ProxyJump`) para dejar muchos servidores en el mismo estado, solo cambiando lo que haga falta. Tu kit gana `ansible/` con el playbook de los servidores, `bin/ci-deploy` y un workflow de GitHub Actions.

## Objetivos de aprendizaje

Al terminar esta semana, podrás:

- Usar `ssh` en scripts: distinguir el código 255, usar `BatchMode`, `ConnectTimeout` y `ssh -n`, y pasar argumentos con `printf %q` y `bash -s`
- Ejecutar un comando en muchos servidores, en serie con resumen y en paralelo con `xargs -P`, y medir el efecto del multiplexing
- Limitar la llave de un CI con comando forzado (`$SSH_ORIGINAL_COMMAND`), `restrict` y `from=`
- Desplegar desde un entorno vacío con los secretos en variables, una carpeta temporal que se borra sola y `known_hosts` comprobado
- Explicar por qué `StrictHostKeyChecking no` y `ssh-keyscan` en un CI permiten a un impostor recibir el despliegue
- Escribir un inventario, un `ansible.cfg` y un playbook idempotente con `validate`, handlers y `--check --diff`
- Llevar Ansible a través de un bastion y acelerarlo con multiplexing y *pipelining*
- Añadir a tu `ssh-infra-kit` `ansible/`, `bin/ci-deploy` y `ci/github-actions.yml`

## Prerrequisitos

- [Semana 11](../week-11-2fa_fail2ban_y_auditoria/README.md) completa: el kit con `server/` entero (`sshd_config.d`, PAM y jaula de fail2ban)
- Opciones de `authorized_keys` ([semana 03](../week-03-autenticacion_con_llaves_ssh/README.md)), multiplexing ([semana 05](../week-05-configuracion_avanzada_cliente_ssh/README.md)), `sshd-deploy` ([semana 07](../week-07-servidor_sshd_config_y_hardening/README.md)) y `ProxyJump` ([semana 09](../week-09-bastion_hosts_y_arquitecturas_segmentadas/README.md))
- El laboratorio **reconstruido**: esta semana la imagen trae `ansible-core` 2.21. En tu equipo, desde la raíz del repositorio:
  ```bash
  docker compose build
  docker compose up -d --force-recreate
  ```

## Contenido

| # | Tipo | Tema | Tiempo |
|---|------|------|--------|
| — | Teoría | [01-ssh-en-scripts.md](1-teoria/01-ssh-en-scripts.md) · [02-despliegue-desde-ci.md](1-teoria/02-despliegue-desde-ci.md) · [03-ansible.md](1-teoria/03-ansible.md) | 1.5 h |
| — | Conocimiento | [10 preguntas](rubrica-evaluacion.md#-conocimiento-30) | 30 min |
| 1 | Lab | [lab-01-ssh-en-scripts](2-practicas/lab-01-ssh-en-scripts/) | 60 min |
| 2 | Lab | [lab-02-muchos-servidores](2-practicas/lab-02-muchos-servidores/) | 60 min |
| 3 | Lab | [lab-03-llave-de-despliegue](2-practicas/lab-03-llave-de-despliegue/) | 60 min |
| 4 | Lab | [lab-04-un-ci-sin-nadie-delante](2-practicas/lab-04-un-ci-sin-nadie-delante/) | 60 min |
| 5 | Lab | [lab-05-ansible-ad-hoc](2-practicas/lab-05-ansible-ad-hoc/) | 60 min |
| 6 | Lab | [lab-06-primer-playbook](2-practicas/lab-06-primer-playbook/) | 60 min |
| 7 | Lab | [lab-07-ansible-por-el-bastion](2-practicas/lab-07-ansible-por-el-bastion/) | 60 min |
| — | Proyecto | [ssh-infra-kit: Ansible y despliegue desde CI](3-proyecto/) | 3 h |

**Total: 12 horas**

## Distribución del tiempo

```
[1.5 h]  Leer 1-teoria/ (ssh en scripts, despliegue desde CI, Ansible)
[30 min] Responder las 10 preguntas de Conocimiento
[60 min] lab-01 — Códigos de salida, BatchMode, timeouts, bucles y comillas
[60 min] lab-02 — Muchos servidores: en serie, en paralelo y con multiplexing
[60 min] lab-03 — Una llave de despliegue: comando forzado, restrict y from=
[60 min] lab-04 — Un CI sin nadie delante: secretos, known_hosts y un impostor
[60 min] lab-05 — Ansible sin playbook: inventario, ansible.cfg y become
[60 min] lab-06 — El primer playbook: validate, handlers e idempotencia
[60 min] lab-07 — Ansible a través del bastion, y rápido
[3 h]    Proyecto: ansible/, servidores.yml, bin/ci-deploy y el workflow
```

## Verificación de completitud

Desde la raíz del repositorio, en tu equipo:

```bash
./scripts/verificar-semana.sh 12
```

Comprueba tu proyecto (`3-proyecto/starter/`) contra los 12 requisitos verificables de la semana. Arrancan un `sshd` como root en `127.0.0.1` y ejecutan contra él tu playbook y tu `bin/ci-deploy` (este, desde un entorno vacío): solo funcionan dentro del laboratorio y tardan unos minutos. Al terminar deben pasar todos, y tu kit debe dejar los dos servidores sin nada que cambiar:

```bash
cd bootcamp/week-12-automatizacion_scripting_ci_cd_y_ansible/3-proyecto/starter/ansible
ansible-playbook servidores.yml --check
```

## 🔗 Navegación

| Anterior | Actual | Siguiente |
|---|---|---|
| [← Semana 11 — 2FA, fail2ban y auditoría con ssh-audit](../week-11-2fa_fail2ban_y_auditoria/README.md) | **Semana 12 — Automatización: scripting, CI/CD y Ansible** | [Semana 13 — Operación y troubleshooting: algoritmos post-cuánticos, rendimiento y migraciones →](../week-13-troubleshooting_post_cuantico_rendimiento_y_migraciones/README.md) |

[← Volver al índice del bootcamp](../README.md)
