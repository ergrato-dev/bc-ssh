# Autograding

`scripts/verificar-semana.sh` te dice qué te falta antes de entregar. No sabe nada de ninguna semana en concreto: lee `bootcamp/week-NN-*/checks.json` y ejecuta lo que ahí ponga.

## Uso

```bash
./scripts/verificar-semana.sh --doctor   # comprueba tu entorno
./scripts/verificar-semana.sh 03         # comprueba la Semana 03 dentro de client
./scripts/verificar-semana.sh --host 04  # comprueba la Semana 04 con el ssh de tu equipo
```

Desde tu equipo, el script se relanza dentro del contenedor `client` (`docker compose run --rm -T client`), que arranca `server`, `bastion` e `interno` si no lo están. Así todos obtienen el mismo resultado.

Salida:

```
Semana 01 — Fundamentos de SSH y primera conexión

  ✅ bin/lab-check sale con 0 si server responde
  ❌ bin/lab-check sale con 1 si el host no existe
     pista: 3-proyecto/README.md, paso 4

  1/2 comprobaciones superadas.
```

Sale con 0 si pasan todas y con 1 si falla alguna. Cada pista dice en qué archivo y en qué paso se arregla.

## Formato de `checks.json`

```json
{
  "semana": "01",
  "titulo": "Fundamentos de SSH y primera conexión",
  "checks": [
    {
      "id": "config-parsea",
      "descripcion": "config parsea sin errores",
      "cmd": "ssh -G -F {proyecto}/config server",
      "assert": "exit0",
      "pista": "3-proyecto/README.md, paso 2"
    }
  ]
}
```

| Campo | Qué es |
|---|---|
| `id` | Identificador estable en kebab-case. Nunca se renombra |
| `descripcion` | Qué se comprueba, en una línea. Se copia literal a `3-proyecto/README.md` |
| `cmd` | Comando bash, ejecutado desde la raíz del repositorio |
| `assert` | `exit0`, `exit!=0`, `exit=N`, `stdout~RE`, `stdout!~RE` (la salida incluye stderr) |
| `pista` | Archivo y paso donde se arregla |

| Marcador | Se sustituye por |
|---|---|
| `{raiz}` | Ruta absoluta del repositorio |
| `{semana}` | Carpeta de la semana |
| `{proyecto}` | `{semana}/3-proyecto/starter`; con `ENTREGA=solucion`, `{semana}/3-proyecto/solucion` |

> [!IMPORTANT]
> Las expresiones regulares no pueden llevar `\`: `jq @tsv` la escapa. Usa `.` o clases como `[.]`.

## Reglas de diseño

1. El `checks.json` se escribe antes que el contenido: define qué tienen que enseñar los labs.
2. Entre 6 y 18 comprobaciones por semana. Una comprobación, un hecho.
3. Comprueba comportamiento, no existencia: `ssh -G` sobre la config, no `test -f config`.
4. Los checks solo hablan con los hosts del laboratorio (`server`, `bastion`, `interno`) y nunca con Internet.
5. Toda conexión SSH en un check usa `-o BatchMode=yes` o `sshpass` y `-o StrictHostKeyChecking=accept-new` con `-o UserKnownHostsFile=` temporal: un check nunca se queda esperando una respuesta ni ensucia tu `known_hosts`.
6. Cero lógica de semana en `verificar-semana.sh`.

## Escribir una comprobación nueva

1. Ejecuta el comando a mano con un caso que pasa y otro que falla.
2. Añádelo al `checks.json` con su `pista` y copia la `descripcion` al `3-proyecto/README.md`.
3. `./scripts/verificar-semana.sh NN` tiene que fallar contra `starter/` y `ENTREGA=solucion ./scripts/verificar-semana.sh NN` pasar.
