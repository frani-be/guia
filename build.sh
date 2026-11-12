#!/bin/bash
# Genera:
#   index.html              -> la guía encriptada con BASE_PASSWORD
#   calculadora/index.html  -> redirección a la planilla, encriptada igual
# Cada persona entra con la clave BASE + su usuario de Instagram (sin lista previa).
# El sufijo (usuario) queda registrado en la planilla vía LOG_URL.
# Requiere: .env con BASE_PASSWORD, LOG_URL y CALC_URL (ver .env.example)
set -euo pipefail
cd "$(dirname "$0")"

# Node 22 (el del sistema es v20)
export PATH="$HOME/.nvm/versions/node/v22.22.3/bin:$PATH"

if [ ! -f .env ]; then
  echo "Falta .env (copia .env.example y complétalo)"; exit 1
fi
set -a; . ./.env; set +a

FUENTE="guia-freelancer.html"
[ -f "$FUENTE" ] || { echo "Falta $FUENTE"; exit 1; }
[ -f calculadora_src.html ] || { echo "Falta calculadora_src.html"; exit 1; }
if [ -z "${BASE_PASSWORD:-}" ] || [ "$BASE_PASSWORD" = "tu_base_aqui" ]; then
  echo "Define BASE_PASSWORD en .env"; exit 1
fi
if printf '%s' "$BASE_PASSWORD" | grep -q '[^a-z0-9._+@-]'; then
  echo "BASE_PASSWORD debe ser minúsculas, sin espacios ni símbolos raros"; exit 1
fi
BASE_LEN=${#BASE_PASSWORD}
if [ "$BASE_LEN" -lt 6 ]; then
  echo "BASE_PASSWORD muy corta (mínimo 6 caracteres)"; exit 1
fi
if [ -z "${LOG_URL:-}" ]; then
  echo "Aviso: LOG_URL vacío, no se registrarán accesos"
fi
if [ -z "${CALC_URL:-}" ]; then
  echo "Define CALC_URL en .env (URL de la planilla de la calculadora)"; exit 1
fi
LOG_ESC=${LOG_URL//&/\\&}
CALC_ESC=${CALC_URL//&/\\&}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Beacon de respaldo dentro de la página ya desencriptada.
# $1 = LOG_URL ya etiquetada (puede traer ?p=...)
beacon() {
  cat <<EOF
<script>(function(){var u,l='$1';try{u=localStorage.getItem('guia_u')}catch(e){return}if(!u)return;var k='guia_logged_'+l+'_'+u,done=false;try{done=!!localStorage.getItem(k);if(!done)localStorage.setItem(k,'1')}catch(e){}if(!done){var s=l.indexOf('?')>=0?'&':'?';(new Image()).src=l+s+'u='+encodeURIComponent(u)+'&ua='+encodeURIComponent(navigator.userAgent)}})();</script>
EOF
}

# $1 = archivo de entrada (index.html), $2 = dir de salida, $3 = template, $4 = título
encrypt() {
  npx -y staticrypt@3.5.4 "$1" \
    -p "$BASE_PASSWORD" \
    -d "$2" \
    -t "$3" \
    --remember false \
    --short \
    --template-title "$4 · frani.be" \
    --template-instructions "Tu clave es la que te envié<br><small>(clave base + tu usuario de Instagram, todo junto, en minúscula y sin @)</small>" \
    --template-placeholder "pass+tu_usuario" \
    --template-button "Entrar" \
    --template-error "Clave incorrecta, revísala e inténtalo de nuevo." \
    --template-color-primary "#8b2db3" \
    --template-color-secondary "#eedffc" \
    >/dev/null
}

# --- Guía ---
sed -e "s|__BASE_LEN__|$BASE_LEN|" -e "s|__LOG_URL__|$LOG_ESC|g" template_guia.html > "$tmp/template.html"
cat "$FUENTE" > "$tmp/index.html"
beacon "$LOG_URL" >> "$tmp/index.html"
encrypt "$tmp/index.html" "$tmp/out_guia" "$tmp/template.html" "Guía Freelancer"
mv "$tmp/out_guia/index.html" ./index.html
echo "ok  index.html (guía)"

# --- Calculadora ---
if [ -n "${LOG_URL:-}" ]; then LOG_CALC="${LOG_URL}?p=calc"; else LOG_CALC=""; fi
LOG_CALC_ESC=${LOG_CALC//&/\\&}
sed -e "s|__BASE_LEN__|$BASE_LEN|" -e "s|__LOG_URL__|$LOG_CALC_ESC|g" template_guia.html > "$tmp/template_calc.html"
mkdir -p "$tmp/calc"
sed "s|__CALC_URL__|$CALC_ESC|g" calculadora_src.html > "$tmp/calc/index.html"
beacon "$LOG_CALC" >> "$tmp/calc/index.html"
encrypt "$tmp/calc/index.html" "$tmp/out_calc" "$tmp/template_calc.html" "Calculadora"
mkdir -p calculadora
mv "$tmp/out_calc/index.html" calculadora/index.html
echo "ok  calculadora/index.html (redirige a la planilla)"

echo ""
echo "Listo: clave de acceso = ${BASE_PASSWORD} + usuario_ig (base_len=${BASE_LEN})"
