# Webgrafía — Semana 12

| Recurso | Descripción |
|---------|-------------|
| [ssh_config(5)](https://man.openbsd.org/ssh_config) | `BatchMode`, `ConnectTimeout`, `ServerAliveInterval`, `StrictHostKeyChecking` y `UserKnownHostsFile`: lo que usa un script |
| [sshd(8): AUTHORIZED_KEYS FILE FORMAT](https://man.openbsd.org/sshd#AUTHORIZED_KEYS_FILE_FORMAT) | `restrict`, `command=`, `from=` y `SSH_ORIGINAL_COMMAND`. Lab 03 |
| [BashFAQ/089: ssh se come la entrada del bucle](https://mywiki.wooledge.org/BashFAQ/089) | El problema del paso 4 del lab 01, explicado, y sus soluciones |
| [Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions) | Cómo se guardan, en qué pasos están disponibles y cómo se tapan en el log |
| [Ansible: introduction to ad hoc commands](https://docs.ansible.com/ansible/latest/command_guide/intro_adhoc.html) | `ansible GRUPO -m MÓDULO -a ARGS`, `become` y paralelismo. Lab 05 |
| [Ansible: how to build your inventory](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html) | Grupos, variables por host (`ansible_ssh_common_args`) y formatos. Labs 05 y 07 |
| [Ansible: intro to playbooks](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html) | Plays, tareas, handlers, idempotencia y `--check`. Lab 06 |
| [Ansible: ssh connection plugin](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ssh_connection.html) | `ssh_args`, `ssh_common_args`, `pipelining` y `control_path`: lo que configura el `ansible.cfg` del kit |
| [uv: using tools](https://docs.astral.sh/uv/guides/tools/) | `uv tool install ansible-core`: cómo instalarlo en tu equipo y en el runner |

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Recursos — videos](../videografia/README.md) | [Glosario](../../5-glosario/README.md) → |

[↑ Semana 12](../../README.md)
