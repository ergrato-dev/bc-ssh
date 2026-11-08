#!/usr/bin/env bash
#
# verificar-semana.sh — autograding declarativo del bootcamp.
#
# Uso:
#   ./scripts/verificar-semana.sh 03        comprueba la Semana 03
#   ./scripts/verificar-semana.sh --doctor  comprueba tu entorno
#   ENTREGA=solucion ./scripts/verificar-semana.sh 03
#                                           comprueba la solucion de referencia
#   ./scripts/verificar-semana.sh --host 04 usa el ssh de tu equipo
#
# Por defecto los checks corren dentro del contenedor client del laboratorio
# (compose.yaml, OpenSSH 9.6) contra server, bastion e interno, asi todos
# obtienen el mismo resultado. --host es para las semanas que dependen de tu
# equipo (por ejemplo, llaves FIDO2 en la semana 04).
#
# Este script no sabe nada de ninguna semana en concreto: lee las
# comprobaciones de bootcamp/week-NN-*/checks.json y las ejecuta. Si necesitas
# logica especifica de una semana, el sitio es el checks.json, nunca este
# archivo. El contrato completo esta en docs/autograding.md.

set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

rojo()  { printf '\033[0;31m%s\033[0m\n' "$*"; }
verde() { printf '\033[0;32m%s\033[0m\n' "$*"; }
gris()  { printf '\033[0;90m%s\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
# --doctor: comprueba las dependencias antes de culpar al material
# ---------------------------------------------------------------------------
doctor() {
  local fallos=0

  comprobar() {
    local etiqueta="$1" resultado="$2" detalle="${3:-}"
    if [[ "$resultado" == ok ]]; then
      printf '  \033[0;32m✅\033[0m %-14s %s\n' "$etiqueta" "$detalle"
    else
      printf '  \033[0;31m❌\033[0m %-14s %s\n' "$etiqueta" "$detalle"
      fallos=$(( fallos + 1 ))
    fi
  }

  opcional() {
    printf '  \033[0;33m➖\033[0m %-14s %s\n' "$1" "$2"
  }

  echo "Obligatorio:"

  # El doctor del host tambien exige Docker: ahi corre el autograding.
  if [[ -z "${BC_SSH_LAB:-}" ]]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      comprobar "docker" ok "$(docker compose version 2>/dev/null | head -1)"
    else
      comprobar "docker" no "no disponible — el autograding corre en el laboratorio (docs/setup-entorno.md)"
    fi
  fi

  local version
  if version=$(ssh -V 2>&1); then
    # OpenSSH 9.6 o superior (la de Ubuntu 24.04).
    if [[ "$version" =~ OpenSSH_([0-9]+)\.([0-9]+) ]] \
       && (( BASH_REMATCH[1] > 9 || (BASH_REMATCH[1] == 9 && BASH_REMATCH[2] >= 6) )); then
      comprobar "ssh" ok "$version"
    else
      comprobar "ssh" no "$version — se necesita OpenSSH >= 9.6 (docs/setup-entorno.md)"
    fi
  else
    comprobar "ssh" no "no instalado"
  fi

  if command -v bash >/dev/null 2>&1; then
    comprobar "bash" ok "$(bash --version | head -1 | awk '{print $4}')"
  else
    comprobar "bash" no "no instalado"
  fi

  if command -v jq >/dev/null 2>&1; then
    comprobar "jq" ok "$(jq --version)"
  else
    comprobar "jq" no "no instalado — es obligatorio para leer checks.json"
  fi

  if command -v git >/dev/null 2>&1; then
    comprobar "git" ok "$(git --version)"
  else
    comprobar "git" no "no instalado — ssh-infra-kit se versiona con git"
  fi

  if command -v shellcheck >/dev/null 2>&1; then
    comprobar "shellcheck" ok "$(shellcheck --version | awk '/^version:/{print $2}')"
  else
    comprobar "shellcheck" no "no instalado — los scripts de bin/ se revisan con shellcheck"
  fi

  echo
  echo "Para semanas concretas:"

  if command -v uv >/dev/null 2>&1; then
    comprobar "uv" ok "$(uv --version)"
  else
    opcional "uv" "no instalado (semanas 11 y 12: ssh-audit y Ansible; Python siempre con uv)"
  fi
  if command -v rsync >/dev/null 2>&1; then
    comprobar "rsync" ok "$(rsync --version | head -1)"
  else
    opcional "rsync" "no instalado (semana 06)"
  fi

  echo
  if (( fallos == 0 )); then
    verde "Todo listo."
    return 0
  fi
  rojo "$fallos comprobacion(es) del entorno fallaron."
  return 1
}

# ---------------------------------------------------------------------------
# Evaluacion de una asercion
#   exit0        el comando sale con 0
#   exit!=0      el comando sale distinto de 0
#   exit=N       el comando sale exactamente con N
#   stdout~RE    la salida casa con la expresion regular extendida RE
#   stdout!~RE   la salida NO casa con RE
# ---------------------------------------------------------------------------
evaluar() {
  local asercion="$1" codigo="$2" salida="$3"

  case "$asercion" in
    exit0)      [[ "$codigo" -eq 0 ]] ;;
    "exit!=0")  [[ "$codigo" -ne 0 ]] ;;
    exit=*)     [[ "$codigo" -eq "${asercion#exit=}" ]] ;;
    "stdout!~"*) ! grep -qE "${asercion#stdout!~}" <<<"$salida" ;;
    stdout~*)   grep -qE "${asercion#stdout~}" <<<"$salida" ;;
    *)
      rojo "ASERCION DESCONOCIDA: '$asercion'"
      gris "Validas: exit0, exit!=0, exit=N, stdout~RE, stdout!~RE"
      return 2
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Ejecucion de una semana
# ---------------------------------------------------------------------------
verificar_semana() {
  local semana="$1"

  if ! [[ "$semana" =~ ^[0-9]{2}$ ]]; then
    rojo "La semana se indica con dos digitos: 01, 02 ... 14"
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    rojo "Falta jq. Es obligatorio para leer checks.json."
    exit 1
  fi

  local dir
  dir=$(find "$RAIZ/bootcamp" -maxdepth 1 -type d -name "week-${semana}-*" | head -1)
  if [[ -z "$dir" ]]; then
    rojo "No existe la carpeta de la Semana $semana."
    exit 1
  fi

  local archivo="$dir/checks.json"
  if [[ ! -f "$archivo" ]]; then
    rojo "La Semana $semana todavia no tiene checks.json."
    gris "Se escribe antes que el contenido: ver docs/autograding.md"
    exit 1
  fi

  if ! jq -e . "$archivo" >/dev/null 2>&1; then
    rojo "checks.json invalido: $archivo"
    exit 1
  fi

  echo "Semana $semana — $(jq -r '.titulo' "$archivo")"
  echo

  local total=0 pasados=0
  local _id descripcion cmd asercion pista codigo salida

  while IFS=$'\t' read -r _id descripcion cmd asercion pista; do
    total=$(( total + 1 ))

    # Los marcadores dejan el checks.json independiente de rutas y plataforma.
    cmd=${cmd//\{semana\}/$dir}
    cmd=${cmd//\{raiz\}/$RAIZ}
    # El estudiante trabaja en starter/; el instructor valida solucion/.
    cmd=${cmd//\{proyecto\}/$dir/3-proyecto/${ENTREGA:-starter}}

    # `if` alrededor: con `set -e`, capturar el codigo de un comando que falla
    # a proposito requiere que la ejecucion este en un contexto condicional.
    # </dev/null: ssh lee stdin y se comería las líneas siguientes del bucle.
    if salida=$(bash -c "$cmd" 2>&1 </dev/null); then codigo=0; else codigo=$?; fi

    if evaluar "$asercion" "$codigo" "$salida"; then
      printf '  \033[0;32m✅\033[0m %s\n' "$descripcion"
      pasados=$(( pasados + 1 ))
    else
      printf '  \033[0;31m❌\033[0m %s\n' "$descripcion"
      printf '     \033[0;90mpista: %s\033[0m\n' "$pista"
    fi
  done < <(jq -r '.checks[] | [.id, .descripcion, .cmd, .assert, .pista] | @tsv' "$archivo")

  echo
  if (( pasados == total )); then
    verde "$pasados/$total comprobaciones superadas."
    return 0
  fi
  rojo "$pasados/$total comprobaciones superadas."
  gris "Cada pista dice en que lab y en que paso se arregla."
  return 1
}

# ---------------------------------------------------------------------------
# Fuera del laboratorio y sin --host, la semana se verifica dentro del
# contenedor. El --doctor siempre mira la maquina donde se ejecuta.
EN_HOST=""
if [[ "${1:-}" == "--host" ]]; then EN_HOST=1; shift; fi

if [[ -z "$EN_HOST" && -z "${BC_SSH_LAB:-}" && "${1:-}" =~ ^[0-9]{2}$ ]]; then
  exec docker compose run --rm -T -e ENTREGA="${ENTREGA:-starter}" client \
    ./scripts/verificar-semana.sh "$1"
fi

case "${1:-}" in
  --doctor)      doctor ;;
  -h|--help|"")  sed -n '3,19p' "${BASH_SOURCE[0]}" | sed 's|^# \?||' ;;
  *)             verificar_semana "$1" ;;
esac
