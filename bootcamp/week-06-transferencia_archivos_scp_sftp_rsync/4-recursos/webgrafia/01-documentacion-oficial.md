# 📚 Documentación Oficial

## SCP, SFTP y rsync

---

## SCP

### Manual Oficial

- **OpenSSH SCP Manual**
  - URL: https://man.openbsd.org/scp.1
  - Contenido: Referencia completa de opciones
  - Idioma: 🇬🇧 Inglés

### Páginas Man

```bash
# Ver manual en terminal
man scp

# Secciones importantes:
# - DESCRIPTION
# - OPTIONS
# - EXIT STATUS
```

---

## SFTP

### Manual Oficial

- **OpenSSH SFTP Manual (Cliente)**

  - URL: https://man.openbsd.org/sftp.1
  - Contenido: Comandos del cliente SFTP
  - Idioma: 🇬🇧 Inglés

- **OpenSSH SFTP-Server Manual**
  - URL: https://man.openbsd.org/sftp-server.8
  - Contenido: Configuración del servidor SFTP
  - Idioma: 🇬🇧 Inglés

### Páginas Man

```bash
# Cliente SFTP
man sftp

# Servidor SFTP
man sftp-server
```

### Referencia de Comandos SFTP

| Comando              | Descripción               |
| -------------------- | ------------------------- |
| `bye/quit/exit`      | Cerrar sesión             |
| `cd path`            | Cambiar directorio remoto |
| `lcd path`           | Cambiar directorio local  |
| `get remote [local]` | Descargar archivo         |
| `put local [remote]` | Subir archivo             |
| `ls [-la]`           | Listar remoto             |
| `lls`                | Listar local              |
| `mkdir path`         | Crear directorio          |
| `rm path`            | Eliminar archivo          |
| `rmdir path`         | Eliminar directorio       |
| `rename old new`     | Renombrar                 |
| `chmod mode path`    | Cambiar permisos          |
| `!command`           | Ejecutar comando local    |

---

## rsync

### Documentación Oficial

- **rsync Manual**

  - URL: https://rsync.samba.org/documentation.html
  - Contenido: Documentación completa
  - Idioma: 🇬🇧 Inglés

- **rsync Man Page**
  - URL: https://linux.die.net/man/1/rsync
  - Contenido: Referencia de opciones
  - Idioma: 🇬🇧 Inglés

### Páginas Man

```bash
# Manual completo de rsync
man rsync

# Ver solo ejemplos
man rsync | grep -A 5 "EXAMPLES"
```

### Opciones Esenciales de rsync

| Opción             | Descripción                         |
| ------------------ | ----------------------------------- |
| `-a`               | Archive mode (preserva todo)        |
| `-v`               | Verbose                             |
| `-z`               | Compresión durante transferencia    |
| `-h`               | Human-readable sizes                |
| `-n`               | Dry-run (simular)                   |
| `--delete`         | Eliminar archivos extras en destino |
| `--exclude`        | Excluir patrones                    |
| `--exclude-from`   | Archivo de exclusiones              |
| `--link-dest`      | Hard links para incrementales       |
| `--progress`       | Mostrar progreso                    |
| `--stats`          | Estadísticas al final               |
| `-e "ssh -p PORT"` | Especificar comando SSH             |
| `--bwlimit=KBPS`   | Limitar ancho de banda              |

---

## OpenSSH General

### Sitio Oficial

- **OpenSSH**
  - URL: https://www.openssh.com/
  - Manual: https://www.openssh.com/manual.html
  - Especificaciones: https://www.openssh.com/specs.html

### RFCs Relacionados

| RFC      | Título                       | Descripción          |
| -------- | ---------------------------- | -------------------- |
| RFC 4251 | SSH Protocol Architecture    | Arquitectura general |
| RFC 4252 | SSH Authentication Protocol  | Autenticación        |
| RFC 4253 | SSH Transport Layer Protocol | Capa de transporte   |
| RFC 4254 | SSH Connection Protocol      | Conexiones           |

---

## 📖 Libros Recomendados

### Gratuitos Online

- **Pro OpenSSH** (Apress)
  - Capítulos sobre SCP y SFTP
- **SSH, The Secure Shell: The Definitive Guide** (O'Reilly)
  - Referencia completa

### En Español

- **Administración de Sistemas Linux**
  - Incluye secciones de SSH y transferencia

---

<div align="center">

**📚 Documentación Oficial**

</div>
