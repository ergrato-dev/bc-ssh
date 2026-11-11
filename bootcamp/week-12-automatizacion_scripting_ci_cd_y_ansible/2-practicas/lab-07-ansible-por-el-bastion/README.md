# Lab 07 — Ansible a través del bastion, y rápido

⏱ Duración estimada: ~60 min

## Objetivo

Llegar con Ansible a `interno`, que solo es alcanzable a través de `bastion`, de las dos formas posibles (una variable del inventario o tu configuración SSH), y medir cuánto pesan el multiplexing y el *pipelining* en el tiempo de un playbook.

## Contexto

- Cómo usa SSH Ansible y qué lo hace rápido: [teoría 03](../../1-teoria/03-ansible.md#cómo-usa-ssh).
- `ProxyJump` y la red privada: [semana 09](../../../week-09-bastion_hosts_y_arquitecturas_segmentadas/README.md).
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-ssh-en-scripts/README.md) y los pasos 1 y 2 del [lab 05](../lab-05-ansible-ad-hoc/README.md). Además, la host key de `interno` (leída desde `bastion`, que sí llega) y tu llave en `interno`:
   ```bash
   cd ~/w/ansible
   ssh bastion ssh-keyscan -t ed25519 interno 2>/dev/null >> ~/.ssh/known_hosts
   sshpass -e ssh-copy-id -f -o ProxyJump=bastion interno 2>&1 | grep "Number of"
   ```
   ```
   Number of key(s) added: 1
   ```
   Leer la host key a través de `bastion` está bien aquí porque es el laboratorio; con un servidor de verdad, compara su huella con la que te da quien lo administra ([semana 09](../../../week-09-bastion_hosts_y_arquitecturas_segmentadas/README.md)).

1. **Por el inventario.**
   ```bash
   printf '[lab]\nserver\nbastion\n\n[privada]\ninterno ansible_ssh_common_args="-J bastion"\n' > hosts.ini
   ansible all -m command -a hostname
   ansible interno -m ping -vvv 2>&1 | grep -m1 "SSH: EXEC" | grep -o -- "-J bastion"
   ```
   ```
   bastion | CHANGED | rc=0 >>
   bastion
   server | CHANGED | rc=0 >>
   server
   interno | CHANGED | rc=0 >>
   interno
   -J bastion
   ```
   `ansible_ssh_common_args` se añade a cada `ssh` de ese servidor. Funciona, pero el salto queda escrito en Ansible: tu `ssh interno` en la terminal no lo sabe.

2. **Por tu configuración SSH.** Mejor: que el salto viva en un solo sitio y lo usen los dos.
   ```bash
   printf "Host interno\n    ProxyJump bastion\n" >> ~/.ssh/config
   printf "[lab]\nserver\nbastion\n\n[privada]\ninterno\n" > hosts.ini
   ansible interno -m command -a "hostname -I"
   ssh interno hostname
   ```
   ```
   interno | CHANGED | rc=0 >>
   172.19.0.2
   interno
   ```
   Ansible lanza `ssh interno`, y `ssh` lee `~/.ssh/config`. Es lo que hace el kit: `ssh_args = -F ../config` en su `ansible.cfg`, y el salto, los alias y las llaves salen de `conf.d/`.

3. **Diez tareas pequeñas.**
   ```bash
   cat > diez.yml <<'FIN'
   - name: Diez tareas pequeñas
     hosts: server
     gather_facts: false
     tasks:
       - ansible.builtin.command: "true"
         loop: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
   FIN
   ```

4. **Sin multiplexing.** `ANSIBLE_SSH_ARGS` sustituye los argumentos de `ssh` de Ansible (los de `-vvv` del lab 05):
   ```bash
   TIMEFORMAT="%R s"
   time ANSIBLE_SSH_ARGS="-o ControlMaster=no" ansible-playbook diez.yml >/dev/null
   ```
   ```
   13.715 s
   ```
   Cada paso de cada tarea abre una conexión nueva: intercambio de llaves, autenticación, y varias conexiones por tarea (crear carpeta temporal, copiar el módulo, ejecutarlo, borrar).

5. **Con multiplexing (lo de serie).**
   ```bash
   time ansible-playbook diez.yml >/dev/null
   ```
   ```
   3.256 s
   ```
   Una conexión y muchos canales dentro de ella.

6. **Y con *pipelining*.**
   ```bash
   time ANSIBLE_PIPELINING=True ansible-playbook diez.yml >/dev/null
   ```
   ```
   2.238 s
   ```
   El módulo viaja por la entrada de `ssh` y se ejecuta sin escribirlo antes en un archivo del servidor: un paso por tarea en lugar de varios. El kit lo activa en `ansible.cfg`. Tus tiempos serán otros; la proporción, parecida. Con 50 servidores y 30 tareas, la diferencia son minutos.

7. **Cuando el master estorba.** Con multiplexing, una conexión ya abierta no vuelve a autenticarse ([semana 05](../../../week-05-configuracion_avanzada_cliente_ssh/README.md)): si un playbook cambia `sshd` y te deja fuera, las tareas siguientes **siguen funcionando** por el master viejo, y no te enteras hasta mañana. Escribe en `~/w/notas.md` cómo lo resuelve el final del playbook del proyecto (`flush_handlers`, `reset_connection` y `ping`) y por qué el kit pone `ControlPersist` en su `ssh_args`.

8. **Limpia** la línea de `interno` de `~/.ssh/config` si no la quieres para el resto de la semana.

## Criterios de éxito

- [ ] Llegas a `interno` con `ansible_ssh_common_args` (paso 1)
- [ ] Llegas a `interno` con `ProxyJump` en `~/.ssh/config` y explicas por qué es mejor (paso 2)
- [ ] Mides el playbook sin multiplexing, con multiplexing y con *pipelining*, y explicas de dónde sale cada diferencia (pasos 4 a 6)
- [ ] Explicas el riesgo del master abierto al cambiar `sshd` y cómo se comprueba con una conexión nueva (paso 7)

## Reto extra

Añade `forks = 1` a `ansible.cfg` y mide `ansible all -m command -a "sleep 2"` con 1 y con 5 *forks*. ¿Qué es un *fork* y en qué se parece a `xargs -P` del [lab 02](../lab-02-muchos-servidores/README.md)?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — El primer playbook](../lab-06-primer-playbook/README.md) | [Proyecto — ssh-infra-kit: Ansible y despliegue desde CI](../../3-proyecto/README.md) → |

[↑ Semana 12](../../README.md)
