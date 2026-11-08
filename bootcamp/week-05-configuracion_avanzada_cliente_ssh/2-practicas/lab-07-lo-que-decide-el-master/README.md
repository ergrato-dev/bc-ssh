# Lab 07 — Lo que decide el master

⏱ Duración estimada: ~60 min

## Objetivo

Comprobar que un master abierto ya no se entera de una revocación de llave, que decide si el agente se reenvía a todas las sesiones, y saltarlo cuando necesitas una conexión limpia.

## Contexto

- [Teoría 03, "Lo que el master decide" y "Riesgos"](../../1-teoria/03-multiplexing.md#lo-que-el-master-decide).
- Usa la configuración resuelta del lab 06: `../lab-06-multiplexing/solucion/config`.
- **La contraseña `alumno` es solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 01](../lab-01-el-primer-valor-gana/README.md), con `cd` a esta carpeta, y además:
   ```bash
   mkdir -m 700 ~/.ssh/cm
   C=../lab-06-multiplexing/solucion/config
   ```
   `C` guarda la ruta para escribir menos: `-F $C`.

### A. Una revocación que no corta

1. **Abre el master y mira tu `authorized_keys` en `server`:**
   ```bash
   ssh -F $C lab-server 'wc -l < ~/.ssh/authorized_keys'
   ```
   ```
   1
   ```

2. **Revoca tu llave**: vacía `authorized_keys` (`: >` deja el archivo a cero bytes):
   ```bash
   ssh -F $C lab-server ': > ~/.ssh/authorized_keys'
   ```

3. **Intenta entrar de nuevo:**
   ```bash
   ssh -F $C lab-server 'echo sigo dentro; wc -l < ~/.ssh/authorized_keys'
   ```
   ```
   sigo dentro
   0
   ```
   Ninguna llave autorizada, y entras: la sesión viajó por el master, que se autenticó en el paso 1.

4. **Sin el master**, la misma conexión se autentica y falla:
   ```bash
   ssh -F $C -o ControlMaster=no -o ControlPath=none -o BatchMode=yes lab-server true; echo "código: $?"
   ```
   ```
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   Con `ControlMaster=no` solo, `ssh` no crearía un master, pero **sí usaría** el que existe. Hace falta `ControlPath=none` para no buscarlo.

5. **Cierra el master: ahora sí se aplica la revocación.**
   ```bash
   ssh -F $C -O exit lab-server
   ssh -F $C -o BatchMode=yes lab-server true; echo "código: $?"
   ```
   ```
   Exit request sent.
   alumno@server: Permission denied (publickey,password).
   código: 255
   ```
   Cuando revoques una llave **tuya** (perdiste el portátil, la rotaste), cierra también tus masters: `ssh -O exit` por host, o `bin/mux stop` de tu kit para todos.

6. **Restaura la llave** con la contraseña, y cierra el master que acaba de abrir `ssh-copy-id`:
   ```bash
   sshpass -e ssh-copy-id -F $C -i ~/.ssh/lab.pub lab-server
   ssh -F $C -O exit lab-server
   ```

### B. El agente y el master

7. **Arranca un agente** con la llave:
   ```bash
   eval "$(ssh-agent)"
   ssh-add ~/.ssh/lab
   ```

8. **Master abierto sin `-A`:**
   ```bash
   ssh -F $C lab-server 'echo "sin -A: [$SSH_AUTH_SOCK]"'
   ssh -F $C -A lab-server 'echo "con -A: [$SSH_AUTH_SOCK]"'
   ssh -F $C -o ControlMaster=no -o ControlPath=none -A lab-server 'echo "sin master: [$SSH_AUTH_SOCK]"'
   ```
   ```
   sin -A: []
   con -A: []
   sin master: [/tmp/ssh-AKOX3EhJSH/agent.523]
   ```
   El segundo pidió `-A` y no lo obtuvo: el master se abrió sin reenvío.

9. **Master abierto con `-A`:**
   ```bash
   ssh -F $C -O exit lab-server
   ssh -F $C -A lab-server 'echo "master con -A: [$SSH_AUTH_SOCK]"'
   ssh -F $C lab-server 'echo "después, sin -A: [$SSH_AUTH_SOCK]"'
   ```
   ```
   Exit request sent.
   master con -A: [/tmp/ssh-K5fk2Yjkxv/agent.536]
   después, sin -A: [/tmp/ssh-K5fk2Yjkxv/agent.536]
   ```
   La segunda sesión **no** pidió el agente y lo tiene, en la misma ruta. Un `ssh -A` puntual deja el agente disponible en `server` mientras viva el master: con `ControlPersist 10m`, hasta diez minutos después de tu última sesión. Por eso tu kit mantiene `ForwardAgent no` y usa `ssh-add -h` ([semana 04](../../../week-04-ssh_agent_y_llaves_fido2/README.md)) para saltar.

   Cierra el master:
   ```bash
   ssh -F $C -O exit lab-server
   ```

### C. Quién llega al socket

10. **Permisos:**
    ```bash
    ssh -F $C lab-server true
    ls -ld ~/.ssh/cm | cut -c1-10
    ls -l ~/.ssh/cm | tail -1 | cut -c1-10
    ```
    ```
    drwx------
    srw-------
    ```
    Carpeta y socket son solo tuyos. Quien pudiera conectarse al socket abriría sesiones en `server` como tú, sin llave ni contraseña. Root en tu equipo puede: el multiplexing no protege de un equipo comprometido, igual que el agente (semana 04).

11. **Responde en tus notas:**
    - Rotaste tu llave y quitaste la vieja de `authorized_keys` en todos los servidores. ¿Qué más tienes que hacer en tu equipo, y por qué?
    - ¿Por qué un master con `ControlPersist 10m` hace más grave un `ssh -A` olvidado?
    - Escribe la orden que usarías para comprobar de verdad que una llave nueva funciona en un servidor.

## Criterios de éxito

- [ ] Entraste por el master con la llave ya revocada, y comprobaste que sin él se rechaza (pasos 3 a 5)
- [ ] Viste que el master decide el reenvío del agente en los dos sentidos (pasos 8 y 9)
- [ ] Respondiste las preguntas del paso 11

## Reto extra

Tu kit tendrá `ssh -P sinmux` en lugar de las dos `-o` del paso 4. Escribe ese perfil en un archivo de prueba (`Match tagged sinmux` con `ControlMaster no` y `ControlPath none`, antes de `Host *`) y repite el paso 4 con `-P sinmux`.

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Multiplexing](../lab-06-multiplexing/README.md) | [Proyecto — ssh-infra-kit: `conf.d/`, perfiles y multiplexing](../../3-proyecto/README.md) → |

[↑ Semana 05](../../README.md)
