# Lab 07 — Proteger la CA y saber qué firmó

⏱ Duración estimada: ~60 min

## Objetivo

Tratar la llave de la CA como lo que es, la llave de todos tus servidores: con frase, firmando desde el agente sin tener el archivo a mano, y con un registro de cada certificado que permita encontrarlo en los logs y revocarlo.

## Contexto

- Dónde vive la CA y cómo se protege: [teoría 03](../../1-teoria/03-revocacion-y-rotacion.md#proteger-la-ca).
- **La contraseña `alumno` y la frase `frase de la CA` son solo del laboratorio.**

## Instrucciones

0. **Preparación**: el paso 0 del [lab 02](../lab-02-principals/README.md).

1. **Una frase para la CA.** `ssh-keygen -p` cambia la frase de una llave sin cambiar la llave:
   ```bash
   ssh-keygen -p -f ~/ca/user_ca -P '' -N 'frase de la CA'
   ssh-keygen -s ~/ca/user_ca -I alumno@client -n alumno -V +8h -z 10 ~/.ssh/trabajo.pub
   ```
   ```
   Key has comment 'CA de usuarios del laboratorio'
   Your identification has been saved with the new passphrase.
   Enter passphrase:
   Signed user key /home/alumno/.ssh/trabajo-cert.pub: id "alumno@client" serial 10 for alumno valid from 2026-11-09T03:55:00 to 2026-11-09T11:56:47
   ```
   - `-P ''`: la frase de ahora (ninguna); `-N`: la nueva. En una CA real, escríbela cuando te la pida, no en la orden: quedaría en el historial de la shell. **Esta frase es solo del laboratorio.**
   - Escribe `frase de la CA` cuando te la pida. Ahora, quien copie `~/ca/user_ca` necesita también la frase.

2. **Firmar desde el agente.** Con muchas firmas al día, escribir la frase cada vez cansa, y tener el archivo siempre en el disco es lo que querías evitar. Carga la CA en un agente durante 15 minutos y **quita el archivo**:
   ```bash
   eval $(ssh-agent) >/dev/null
   ssh-add -t 15m ~/ca/user_ca
   mkdir -p -m 700 ~/w/usb; mv ~/ca/user_ca ~/w/usb/; ls ~/ca
   ```
   ```
   Enter passphrase for /home/alumno/ca/user_ca:
   Identity added: /home/alumno/ca/user_ca (CA de usuarios del laboratorio)
   Lifetime set to 900 seconds
   user_ca.pub
   ```
   `~/w/usb` hace de memoria USB: en la vida real, la CA vive en un disco cifrado que solo conectas para cargarla, o en una llave FIDO2 (semana 04) o un HSM, de donde nunca sale. Ahora firma con la llave **pública** y `-U`:
   ```bash
   ssh-keygen -Us ~/ca/user_ca.pub -I alumno@client -n alumno -V +8h -z 11 ~/.ssh/trabajo.pub
   ssh server-cert hostname
   ```
   ```
   Signed user key /home/alumno/.ssh/trabajo-cert.pub: id "alumno@client" serial 11 for alumno valid from 2026-11-09T03:55:00 to 2026-11-09T11:56:47
   server
   ```
   - `-U`: la llave de `-s` está en el agente; `ssh-keygen` le pide la firma, como `ssh` cuando entras (semana 04).
   - `-t 15m`: pasados 15 minutos, el agente la olvida. Sin agente, o sin la llave en él, no se firma:
   ```bash
   ssh-add -d ~/ca/user_ca.pub
   ssh-keygen -Us ~/ca/user_ca.pub -I x -n alumno -V +8h -z 12 ~/.ssh/trabajo.pub; echo "código: $?"
   ```
   ```
   Identity removed: /home/alumno/ca/user_ca.pub ED25519 (CA de usuarios del laboratorio)
   Retrieve agent key list: agent contains no identities
   código: 255
   ```
   **Nunca reenvíes un agente con la CA dentro** (`ssh -A`, semana 09): `root` en el otro lado firmaría lo que quisiera.

3. **Lo que `ssh-keygen` no lleva: el registro.** `ssh-keygen` no recuerda qué ha firmado. Sin un registro no sabrás qué número de serie revocar, ni de quién es el certificado que ves en un log. Lo mínimo, una línea por certificado:
   ```bash
   echo "$(date -u +%FT%TZ) serie=11 id=alumno@client principals=alumno validez=+8h huella=$(ssh-keygen -lf ~/.ssh/trabajo.pub | cut -d' ' -f2)" >> ~/ca/emitidos.log
   cat ~/ca/emitidos.log
   ```
   ```
   2026-11-09T03:56:47Z serie=11 id=alumno@client principals=alumno validez=+8h huella=SHA256:JugPMYdwljmXp5CjfsHJFOpPAYDs60uCqWntTimtcRA
   ```
   Y el siguiente número sale de un contador, nunca de memoria: dos certificados con el mismo número se revocan juntos (lab 05). El `ca-sign` de tu kit hace las dos cosas.

4. **Del log del servidor al registro.** En **otra terminal de tu equipo**:
   ```bash
   docker compose logs --no-log-prefix server | grep 'Accepted publickey' | tail -1
   ```
   ```
   Accepted publickey for alumno from 172.20.0.6 port 55784 ssh2: ED25519-CERT SHA256:JugPMYdwljmXp5CjfsHJFOpPAYDs60uCqWntTimtcRA ID alumno@client (serial 11) CA ED25519 SHA256:67MHehUbDS0/eH0MNfbjPXIOj4ekq85Ln0/INPGejsc
   ```
   En el cliente, ¿de qué CA y qué certificado?
   ```bash
   ssh-keygen -lf ~/ca/user_ca.pub
   grep 'serie=11 ' ~/ca/emitidos.log | cut -d' ' -f1-3
   ```
   ```
   256 SHA256:67MHehUbDS0/eH0MNfbjPXIOj4ekq85Ln0/INPGejsc CA de usuarios del laboratorio (ED25519)
   2026-11-09T03:56:47Z serie=11 id=alumno@client
   ```
   Huella de la CA, número de serie, identidad y huella de la llave: los cuatro coinciden. Si fuera un certificado que no está en tu registro, alguien más tiene tu CA.

5. **El certificado, dentro de la sesión.** `ExposeAuthInfo yes` deja en un archivo cómo se autenticó cada sesión. Sirve, por ejemplo, para que un script del servidor anote quién lo ejecutó:
   ```bash
   ssh server 'echo "ExposeAuthInfo yes" | sudo tee -a /etc/ssh/sshd_config.d/50-ca.conf; sudo kill -HUP $(cat /run/sshd.pid); sleep 1'
   ssh server-cert 'echo $SSH_USER_AUTH; cut -c1-60 $SSH_USER_AUTH'
   ssh server-cert 'cut -d" " -f2- $SSH_USER_AUTH | ssh-keygen -Lf - | grep -E "Key ID|Serial"'
   ```
   ```
   ExposeAuthInfo yes
   /tmp/sshauth.trIj28N8PNilVLY
   publickey ssh-ed25519-cert-v01@openssh.com AAAAIHNzaC1lZDI1N
   Key ID: "alumno@client"
   Serial: 11
   ```
   `SSH_USER_AUTH` es la ruta del archivo: el método y el certificado completo. `ssh-keygen -Lf -` lo lee de la entrada estándar.

6. **La mejor revocación: caducar pronto.** Compara dos políticas:

   | | Certificados de 1 año | Certificados de 8 horas |
   |---|---|---|
   | Si roban una llave | Revocas y subes la KRL a **todos** los servidores, hoy | Esperas, como mucho, hasta esta noche (o revocas, si no puedes esperar) |
   | Si alguien deja la empresa | Igual: KRL | No le firmas mañana |
   | La KRL | Crece y tiene que estar en todos | Casi vacía |
   | Lo que necesitas | Poco: firmas una vez al año | Firmar cada día, sin esfuerzo: `ca-sign`, el agente, o un servicio que firma tras un inicio de sesión con segundo factor |

   Con 8 horas, pon también `ssh-add -t 8h`: que el agente olvide la llave cuando caduca el certificado.

7. **Limpia.** Cierra el agente y devuelve la CA a su sitio:
   ```bash
   kill $SSH_AGENT_PID
   mv ~/w/usb/user_ca ~/ca/
   ```

## Criterios de éxito

- [ ] Pones frase a la CA y explicas por qué no se escribe en la orden (paso 1)
- [ ] Firmas con la CA en el agente y sin el archivo en el disco, y explicas por qué no se reenvía ese agente (paso 2)
- [ ] Llevas un registro con número de serie, identidad, principals, validez y huella (paso 3)
- [ ] Relacionas una línea del log del servidor con tu registro y con tu CA (paso 4)
- [ ] Lees el certificado de la sesión con `ExposeAuthInfo` (paso 5)
- [ ] Comparas certificados largos con revocación frente a certificados cortos (paso 6)

## Reto extra

`ssh-keygen -s` también puede firmar con una CA guardada en una llave FIDO2 (`-t ed25519-sk`, semana 04): cada firma te pide tocarla. ¿Qué ganas frente al agente? ¿Y qué pierdes si firmas cientos de certificados al día?

<!-- nav -->
---

## 🔗 Navegación

| Anterior | Siguiente |
|---|---|
| ← [Lab 06 — Rotar la CA sin dejar a nadie fuera](../lab-06-rotacion-de-la-ca/README.md) | [Proyecto — ssh-infra-kit: tu autoridad de certificados](../../3-proyecto/README.md) → |

[↑ Semana 10](../../README.md)
