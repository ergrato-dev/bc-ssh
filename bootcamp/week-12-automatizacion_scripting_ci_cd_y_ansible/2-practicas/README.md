# Labs — Semana 12: Automatización

| # | Lab | Objetivo | Tiempo |
|---|-----|----------|--------|
| 1 | [lab-01-ssh-en-scripts](lab-01-ssh-en-scripts/) | Códigos de salida, `BatchMode`, `ConnectTimeout`, `ssh -n` en bucles y comillas | ~60 min |
| 2 | [lab-02-muchos-servidores](lab-02-muchos-servidores/) | Un comando en muchos servidores: en serie con resumen, en paralelo con `xargs -P` y con multiplexing | ~60 min |
| 3 | [lab-03-llave-de-despliegue](lab-03-llave-de-despliegue/) | La llave de un CI con comando forzado, `restrict` y `from=` | ~60 min |
| 4 | [lab-04-un-ci-sin-nadie-delante](lab-04-un-ci-sin-nadie-delante/) | Un runner simulado: secretos en variables, `known_hosts` comprobado, limpieza y un impostor | ~60 min |
| 5 | [lab-05-ansible-ad-hoc](lab-05-ansible-ad-hoc/) | Inventario, `ansible.cfg`, comandos sueltos, `become`, *facts* y el `ssh` de Ansible | ~60 min |
| 6 | [lab-06-primer-playbook](lab-06-primer-playbook/) | Un playbook para `sshd`: `copy`, `validate`, handler, idempotencia y `--check --diff` | ~60 min |
| 7 | [lab-07-ansible-por-el-bastion](lab-07-ansible-por-el-bastion/) | Ansible a través de `bastion` y el tiempo con multiplexing y *pipelining* | ~60 min |

**Total labs: 7 horas**

## Antes de cada lab

- **Paso 0** del [lab 01](lab-01-ssh-en-scripts/README.md): `docker compose up -d --force-recreate server bastion interno` y `docker compose run --rm client` **en tu equipo**; `known_hosts` y tu llave de administrar en `server` y `bastion` **en el cliente**.
- Si aún no lo hiciste, reconstruye antes el laboratorio (`docker compose build`): esta semana la imagen trae `ansible-core`.
- Ten **otra terminal en tu equipo** en la raíz del repositorio: si un playbook te deja fuera de `server`, entras por la consola con `docker compose exec server bash`.
- Las contraseñas y las llaves sin frase de estos labs son **solo para el laboratorio**.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Teoría — Ansible: muchos servidores, el mismo estado](../1-teoria/03-ansible.md) | [Lab 01 — SSH dentro de un script](lab-01-ssh-en-scripts/README.md) → |

[↑ Semana 12](../README.md)
