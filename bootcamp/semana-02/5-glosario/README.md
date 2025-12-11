# 📖 Glosario - Semana 02: Autenticación con Llaves SSH

![Glosario](https://img.shields.io/badge/Glosario-40_términos-purple?style=for-the-badge)
![SSH](https://img.shields.io/badge/SSH-Llaves-red?style=for-the-badge)

## 📋 Términos Técnicos

Este glosario contiene los términos técnicos más importantes relacionados con la autenticación SSH mediante llaves.

---

## A

### AES (Advanced Encryption Standard)

Algoritmo de cifrado simétrico usado para proteger llaves privadas con passphrase.

```bash
# Las llaves con passphrase usan AES-256-CTR
ssh-keygen -t ed25519  # La passphrase cifra con AES
```

### Agent (SSH Agent)

Programa que mantiene las llaves privadas descifradas en memoria para evitar escribir la passphrase repetidamente.

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### Agent Forwarding

Técnica que permite usar las llaves del agente local en servidores remotos.

```bash
ssh -A usuario@servidor  # Habilita agent forwarding
```

### Algoritmo de Llave

Método criptográfico usado para generar el par de llaves. Ejemplos: Ed25519, RSA, ECDSA.

### Authorized Keys

Archivo en el servidor (`~/.ssh/authorized_keys`) que contiene las llaves públicas autorizadas para conectarse.

---

## B

### Base64

Codificación usada para representar la llave pública en texto legible.

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... (Base64)
```

### Bit Length

Longitud en bits de una llave. RSA usa 2048-4096 bits; Ed25519 usa 256 bits con seguridad equivalente.

### Brute Force

Ataque que prueba sistemáticamente todas las combinaciones posibles de contraseñas.

---

## C

### Challenge-Response

Mecanismo de autenticación donde el servidor envía un desafío que solo puede resolver quien posee la llave privada.

### Cipher

Algoritmo de cifrado. SSH soporta múltiples ciphers como chacha20-poly1305, aes256-gcm.

### Comentario (Key Comment)

Texto identificativo al final de la llave pública.

```bash
ssh-keygen -t ed25519 -C "usuario@laptop"  # -C define el comentario
```

### Criptografía Asimétrica

Sistema criptográfico que usa un par de llaves (pública y privada) matemáticamente relacionadas.

### Curva Elíptica

Base matemática de algoritmos modernos como Ed25519 y ECDSA.

---

## D

### DSA (Digital Signature Algorithm)

Algoritmo de firma digital obsoleto. **No usar** - deprecado por OpenSSH.

---

## E

### ECDSA (Elliptic Curve DSA)

Algoritmo de curva elíptica. Válido pero Ed25519 es preferido.

```bash
ssh-keygen -t ecdsa -b 521  # Genera llave ECDSA
```

### Ed25519

Algoritmo de curva elíptica moderno, recomendado para nuevas llaves.

```bash
ssh-keygen -t ed25519 -C "email@ejemplo.com"
```

### Entropía

Aleatoriedad usada para generar llaves criptográficas. Mayor entropía = llave más segura.

---

## F

### Fingerprint

Huella digital única de una llave, usada para verificar su autenticidad.

```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub
# 256 SHA256:ABC123... email@ejemplo.com (ED25519)
```

### Forward Agent

Ver [Agent Forwarding](#agent-forwarding).

---

## G

### Generación de Llaves

Proceso de crear un par de llaves usando `ssh-keygen`.

---

## H

### Hash

Función que convierte datos en un valor fijo. SHA256 se usa para fingerprints.

### Host Key

Llave del servidor que identifica al host. Se almacena en `known_hosts`.

---

## I

### IdentityFile

Opción en `~/.ssh/config` para especificar qué llave usar.

```bash
Host github.com
    IdentityFile ~/.ssh/id_github
```

### IdentitiesOnly

Opción para usar SOLO las llaves especificadas, ignorando las del agente.

```bash
Host servidor
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id_servidor
```

---

## K

### KDF (Key Derivation Function)

Función que deriva la clave de cifrado a partir de la passphrase.

```bash
ssh-keygen -t ed25519 -a 100  # -a aumenta rondas KDF
```

### Keychain

Herramienta para gestionar ssh-agent entre sesiones en Linux.

### Known Hosts

Archivo (`~/.ssh/known_hosts`) que almacena fingerprints de servidores conocidos.

---

## L

### Llave Privada

Archivo secreto que NUNCA debe compartirse. Usada para firmar y descifrar.

```
~/.ssh/id_ed25519  # Permisos: 600
```

### Llave Pública

Archivo que se comparte libremente y se coloca en servidores para autorizar acceso.

```
~/.ssh/id_ed25519.pub  # Permisos: 644
```

---

## M

### MAC (Message Authentication Code)

Código que verifica la integridad de los datos transmitidos.

### Multiplexing

Reutilización de una conexión SSH para múltiples sesiones.

```bash
Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
```

---

## O

### OpenSSH

Implementación open source más usada del protocolo SSH.

---

## P

### Passphrase

Contraseña que protege la llave privada. A diferencia de password, puede ser una frase larga.

### PEM (Privacy Enhanced Mail)

Formato de archivo para llaves y certificados (usado por llaves RSA antiguas).

### Permisos

Configuración de acceso a archivos SSH.

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519      # Privada: solo propietario
chmod 644 ~/.ssh/id_ed25519.pub  # Pública: lectura todos
```

### PKCS#8

Formato estándar para almacenar llaves privadas.

### ProxyJump

Opción para conectar a través de un servidor intermedio (bastion).

```bash
ssh -J bastion@jump.com usuario@destino.interno
```

### Public Key Authentication

Método de autenticación que usa criptografía asimétrica en lugar de contraseñas.

---

## R

### Randomart

Representación visual ASCII del fingerprint de una llave.

```
+--[ED25519 256]--+
|     .+B=o.      |
|    . +oB..      |
+----[SHA256]-----+
```

### RSA (Rivest-Shamir-Adleman)

Algoritmo clásico de criptografía asimétrica. Usar mínimo 4096 bits.

```bash
ssh-keygen -t rsa -b 4096
```

### Rotación de Llaves

Práctica de reemplazar llaves periódicamente por seguridad.

---

## S

### SHA256

Algoritmo hash usado para generar fingerprints de llaves.

### ssh-add

Comando para añadir llaves al agente SSH.

```bash
ssh-add ~/.ssh/id_ed25519
ssh-add -l  # Listar llaves cargadas
```

### ssh-agent

Programa que almacena llaves descifradas en memoria.

### ssh-copy-id

Comando para copiar la llave pública a un servidor.

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@servidor
```

### ssh-keygen

Comando para generar, gestionar e inspeccionar llaves SSH.

```bash
ssh-keygen -t ed25519 -C "email"  # Generar
ssh-keygen -lf llave.pub          # Ver fingerprint
ssh-keygen -p -f llave            # Cambiar passphrase
```

### ssh-keyscan

Comando para obtener llaves públicas de hosts.

```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

### StrictHostKeyChecking

Opción que controla la verificación de llaves de host.

```bash
Host *
    StrictHostKeyChecking ask  # Preguntar para hosts nuevos
```

---

## T

### Two-Factor Authentication (2FA)

Autenticación que requiere dos factores: algo que tienes (llave) + algo que sabes (passphrase).

---

## V

### Verificación de Host

Proceso de confirmar que el servidor es quien dice ser usando su fingerprint.

---

## 🔤 Resumen por Categoría

### Algoritmos

Ed25519, RSA, ECDSA, DSA, AES, SHA256

### Archivos

id_ed25519, id_ed25519.pub, authorized_keys, known_hosts, config

### Comandos

ssh-keygen, ssh-add, ssh-agent, ssh-copy-id, ssh-keyscan

### Conceptos

Challenge-Response, Fingerprint, Passphrase, Public Key Authentication, Agent Forwarding

---

## 🔗 Navegación

| ← Anterior                            | Actual         | Siguiente →                            |
| ------------------------------------- | -------------- | -------------------------------------- |
| [4-Recursos](../4-recursos/README.md) | **5-Glosario** | [Semana 03](../../semana-03/README.md) |

---

<div align="center">

[🏠 Volver al inicio de Semana 02](../README.md)

</div>
