# Preparar el entorno

Todo el bootcamp corre en un laboratorio Docker. **Qué:** cuatro contenedores Ubuntu 24.04 con OpenSSH 9.6. **Para qué:** que tengas servidores reales a los que conectarte sin alquilar nada ni tocar tu equipo. **Impacto:** todos los estudiantes ven la misma salida y el autograding da el mismo resultado en cualquier máquina.

## 1. Instala Docker

| Sistema | Qué instalar |
|---|---|
| Linux | Docker Engine + plugin Compose: <https://docs.docker.com/engine/install/> |
| macOS | Docker Desktop: <https://docs.docker.com/desktop/setup/install/mac-install/> |
| Windows | WSL2 + Docker Desktop con integración WSL activada: <https://docs.docker.com/desktop/features/wsl/> |

Comprueba que funciona:

```bash
docker --version
docker compose version
docker run --rm hello-world
```

Salida esperada: dos líneas de versión y el mensaje `Hello from Docker!`. Si `docker run` dice `permission denied`, en Linux añade tu usuario al grupo `docker` (`sudo usermod -aG docker $USER`) y abre una sesión nueva.

## 2. Clona el repositorio

```bash
git clone https://github.com/ergrato-dev/bc-ssh.git
cd bc-ssh
```

## 3. Levanta el laboratorio

```bash
docker compose up -d --build
```

La primera vez tarda unos minutos (descarga Ubuntu e instala paquetes). Comprueba que los tres servidores están arriba:

```bash
docker compose ps
```

Debes ver `server`, `bastion` e `interno` con estado `running`.

## 4. Entra al cliente

```bash
docker compose run --rm client
```

Ahora estás dentro del contenedor `client`, como usuario `alumno`, en `/bc-ssh` (es tu copia del repositorio: lo que edites aquí se ve en tu equipo y al revés).

```
alumno@client:/bc-ssh$
```

Para salir: `exit`. El contenedor `client` se borra al salir (`--rm`); tus archivos en `/bc-ssh` se quedan. Lo que guardes en `/home/alumno` (por ejemplo `~/.ssh`) **se pierde**: cada semana explica dónde guardar lo que debe persistir.

## 5. Topología del laboratorio

```
client ── red publica ── server
                     └── bastion ── red privada ── interno
```

| Host | Redes | Para qué |
|---|---|---|
| `client` | publica | Tu terminal. Desde aquí ejecutas `ssh` |
| `server` | publica | Primer servidor al que te conectas |
| `bastion` | publica, privada | Servidor de salto (semana 09) |
| `interno` | privada | Solo alcanzable a través de `bastion` |

Usuario `alumno`, contraseña `alumno` en todos.

> [!WARNING]
> Esa contraseña es **solo para el laboratorio**. Un servidor real con contraseña débil y `PasswordAuthentication yes` es comprometido por bots en horas. En la semana 07 la desactivas.

## 6. Comprueba tu entorno

```bash
./scripts/verificar-semana.sh --doctor
```

Desde tu equipo comprueba Docker; dentro de `client` comprueba ssh, jq, git y shellcheck.

## Parar y limpiar

```bash
docker compose down        # para y borra los contenedores (las host keys cambian al volver a levantarlos)
docker compose down --rmi local   # además borra la imagen
```
