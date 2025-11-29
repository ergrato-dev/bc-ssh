# 🔑 Práctica 01: Generación de Llaves SSH

![SSH](https://img.shields.io/badge/SSH-Llaves-red?style=for-the-badge&logo=openssh)
![Nivel](https://img.shields.io/badge/Nivel-⭐_Básico-green?style=for-the-badge)
![Duración](https://img.shields.io/badge/Duración-30_min-blue?style=for-the-badge)

## 📋 Descripción

En esta práctica aprenderás a **generar tu primer par de llaves SSH** usando el algoritmo Ed25519 (recomendado). También explorarás las opciones de `ssh-keygen` y entenderás cada componente del proceso de generación.

Al finalizar, tendrás un par de llaves SSH listo para usar en la siguiente práctica.

---

## 🎯 Objetivos de Aprendizaje

Al completar esta práctica serás capaz de:

- [ ] Generar un par de llaves Ed25519 con `ssh-keygen`
- [ ] Proteger tu llave privada con una passphrase segura
- [ ] Verificar la información de tus llaves generadas
- [ ] Entender el fingerprint y su utilidad
- [ ] Configurar permisos correctos en archivos SSH

---

## 📚 Requisitos Previos

| Requisito               | Verificación          |
| ----------------------- | --------------------- |
| OpenSSH instalado       | `ssh -V`              |
| Terminal disponible     | Bash, Zsh, PowerShell |
| Semana 01 completada    | Conceptos básicos SSH |
| Módulos teóricos leídos | Teoría Semana 02      |

---

## 🛠️ Paso 1: Verificar el Entorno

Antes de generar llaves, verifica tu entorno:

```bash
# Verificar versión de OpenSSH
ssh -V
# Esperado: OpenSSH_8.x o superior

# Verificar que ssh-keygen está disponible
which ssh-keygen
# Esperado: /usr/bin/ssh-keygen

# Verificar directorio ~/.ssh
ls -la ~/.ssh 2>/dev/null || echo "Directorio ~/.ssh no existe aún"
```

### Crear directorio ~/.ssh si no existe

```bash
# Crear directorio con permisos correctos
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Verificar permisos
ls -ld ~/.ssh
# Esperado: drwx------ (700)
```

---

## 🔐 Paso 2: Generar Par de Llaves Ed25519

### Comando Principal

```bash
# Generar llave Ed25519 con comentario identificativo
ssh-keygen -t ed25519 -C "tu-nombre@tu-email.com"
```

### Proceso Interactivo

Cuando ejecutes el comando, verás:

```
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/usuario/.ssh/id_ed25519):
```

**Opciones:**

- **Enter** → Acepta ubicación por defecto (recomendado para primera llave)
- **Ruta personalizada** → Ejemplo: `/home/usuario/.ssh/id_mi_servidor`

```
Enter passphrase (empty for no passphrase):
```

**⚠️ IMPORTANTE**: Siempre usa una passphrase para proteger tu llave privada.

```
Enter same passphrase again:
```

### Resultado Esperado

```
Your identification has been saved in /home/usuario/.ssh/id_ed25519
Your public key has been saved in /home/usuario/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:ABC123xyz789DEF456ghiJKL012mnoPQR345stu tu-nombre@tu-email.com
The key's randomart image is:
+--[ED25519 256]--+
|     .+B=o.      |
|    . +oB..      |
|     o.* +       |
|    . o.* .      |
|     ..oS=       |
|    .  =+=       |
|   . .o.o..      |
|    o..o.o       |
|   E+=+o+o       |
+----[SHA256]-----+
```

---

## 📝 Paso 3: Verificar las Llaves Generadas

### Listar archivos creados

```bash
# Ver archivos en ~/.ssh
ls -la ~/.ssh/

# Salida esperada:
# -rw-------  id_ed25519      (llave privada - 600)
# -rw-r--r--  id_ed25519.pub  (llave pública - 644)
```

### Ver contenido de la llave pública

```bash
# Mostrar la llave pública (seguro compartir)
cat ~/.ssh/id_ed25519.pub

# Formato esperado:
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... tu-nombre@tu-email.com
```

### Ver fingerprint de la llave

```bash
# Fingerprint de la llave pública
ssh-keygen -lf ~/.ssh/id_ed25519.pub

# Salida esperada:
# 256 SHA256:ABC123xyz789DEF456ghiJKL012mno tu-nombre@tu-email.com (ED25519)
```

### Inspeccionar la llave privada (solo estructura)

```bash
# Ver las primeras líneas de la llave privada (NO compartir nunca)
head -3 ~/.ssh/id_ed25519

# Salida esperada:
# -----BEGIN OPENSSH PRIVATE KEY-----
# b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAA...
# (contenido encriptado)
```

---

## 🔄 Paso 4: Generar Llave RSA (Alternativa)

Para compatibilidad con sistemas antiguos, genera también una llave RSA:

```bash
# Generar llave RSA de 4096 bits
ssh-keygen -t rsa -b 4096 -C "tu-nombre@tu-email.com" -f ~/.ssh/id_rsa_4096

# Verificar
ssh-keygen -lf ~/.ssh/id_rsa_4096.pub
# Salida: 4096 SHA256:... tu-nombre@tu-email.com (RSA)
```

### Comparación de tamaños

```bash
# Comparar tamaño de llaves públicas
wc -c ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa_4096.pub

# Ed25519: ~100 bytes
# RSA-4096: ~750 bytes
```

---

## 🛡️ Paso 5: Verificar Permisos

Los permisos incorrectos son la causa #1 de errores con llaves SSH:

```bash
# Script de verificación de permisos
echo "=== Verificación de permisos SSH ==="

# Directorio ~/.ssh
ls -ld ~/.ssh
# Esperado: drwx------ (700)

# Llave privada
ls -l ~/.ssh/id_ed25519
# Esperado: -rw------- (600)

# Llave pública
ls -l ~/.ssh/id_ed25519.pub
# Esperado: -rw-r--r-- (644)
```

### Corregir permisos si es necesario

```bash
# Corregir permisos del directorio
chmod 700 ~/.ssh

# Corregir permisos de llave privada
chmod 600 ~/.ssh/id_ed25519

# Corregir permisos de llave pública
chmod 644 ~/.ssh/id_ed25519.pub
```

---

## 🧪 Paso 6: Ejercicios de Verificación

### Ejercicio 1: Verificar que la llave tiene passphrase

```bash
# Intentar mostrar el fingerprint de la llave privada
ssh-keygen -yf ~/.ssh/id_ed25519

# Si tiene passphrase, te la pedirá
# Enter passphrase: _
```

### Ejercicio 2: Comparar fingerprints

```bash
# El fingerprint debe ser idéntico para ambas llaves del par
ssh-keygen -lf ~/.ssh/id_ed25519      # Llave privada
ssh-keygen -lf ~/.ssh/id_ed25519.pub  # Llave pública

# ¿Son iguales? ✅
```

### Ejercicio 3: Exportar llave pública desde privada

```bash
# Derivar la llave pública desde la privada
ssh-keygen -yf ~/.ssh/id_ed25519

# Debe coincidir con:
cat ~/.ssh/id_ed25519.pub
```

---

## 🔍 Paso 7: Explorar Opciones Avanzadas

### Generar llave con número de rondas KDF personalizado

```bash
# Más rondas = más resistente a ataques de fuerza bruta
# Pero más lento al desbloquear
ssh-keygen -t ed25519 -a 100 -C "alta-seguridad@email.com" -f ~/.ssh/id_ed25519_secure

# -a 100: 100 rondas KDF (default: 16)
```

### Generar llave sin passphrase (solo para automatización)

```bash
# ⚠️ CUIDADO: Solo usar para scripts automatizados en entornos seguros
ssh-keygen -t ed25519 -N "" -C "automation@server" -f ~/.ssh/id_automation

# -N "": Passphrase vacía
```

### Ver todos los algoritmos soportados

```bash
# Listar tipos de llave disponibles
ssh-keygen -t ?
# O consultar el manual
man ssh-keygen | grep -A5 "^     -t"
```

---

## ✅ Checklist de Verificación

Antes de pasar a la siguiente práctica, verifica:

- [ ] Llave Ed25519 generada en `~/.ssh/id_ed25519`
- [ ] Passphrase configurada y memorizada
- [ ] Permisos correctos (600 privada, 644 pública)
- [ ] Puedes ver el fingerprint de tu llave
- [ ] Entiendes la diferencia entre llave pública y privada

---

## 🐛 Troubleshooting

### Error: "Permissions are too open"

```bash
# Problema
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# Solución
chmod 600 ~/.ssh/id_ed25519
chmod 700 ~/.ssh
```

### Error: "No such file or directory"

```bash
# Problema: Directorio ~/.ssh no existe
mkdir -p ~/.ssh && chmod 700 ~/.ssh
```

### Error: "Overwrite existing key?"

```bash
# Si ya tienes una llave y no quieres sobrescribirla
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_nuevo -C "nuevo@email.com"
```

### Olvidé la passphrase

```bash
# No hay forma de recuperarla - debes generar una nueva llave
# Guarda tu passphrase en un gestor de contraseñas

# Generar nueva llave
ssh-keygen -t ed25519 -C "email@ejemplo.com"
# (sobrescribe la anterior si usas el mismo nombre)
```

---

## 📊 Resumen de Comandos

| Comando                     | Descripción                   |
| --------------------------- | ----------------------------- |
| `ssh-keygen -t ed25519`     | Generar llave Ed25519         |
| `ssh-keygen -t rsa -b 4096` | Generar llave RSA 4096 bits   |
| `ssh-keygen -lf archivo`    | Ver fingerprint               |
| `ssh-keygen -yf privada`    | Derivar pública desde privada |
| `ssh-keygen -p -f archivo`  | Cambiar passphrase            |
| `chmod 600 archivo`         | Permisos llave privada        |
| `chmod 644 archivo`         | Permisos llave pública        |

---

## 🔗 Navegación

| ← Anterior                    | Actual          | Siguiente →                                            |
| ----------------------------- | --------------- | ------------------------------------------------------ |
| [README Prácticas](README.md) | **Práctica 01** | [Práctica 02: ssh-copy-id](practica-02-ssh-copy-id.md) |

---

<div align="center">

**🎉 ¡Felicidades!** Has generado tu primer par de llaves SSH.

En la siguiente práctica aprenderás a desplegarlas en un servidor remoto.

[🏠 Volver al inicio de Semana 02](../README.md)

</div>
