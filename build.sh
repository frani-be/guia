#!/bin/bash
# Genera index.html: la guía encriptada con BASE_PASSWORD.
# Cada persona entra con la clave BASE + su usuario de Instagram (sin lista previa).
# El sufijo (usuario) queda registrado en la planilla vía LOG_URL.
# Requiere: .env con BASE_PASSWORD y LOG_URL (ver .env.example)
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
if [ -z "${BASE_PASSWORD:-}" ] || [ "$BASE_PASSWORD" = "tu_base_aqui" ]; then
  echo "Define BASE_PASSWORD en .env"; exit 1
fi
if printf '%s' "$BASE_PASSWORD" | grep -q '[^a-z0-9._+-]'; then
  echo "BASE_PASSWORD debe ser minúsculas, sin espacios ni símbolos raros"; exit 1
fi
BASE_LEN=${#BASE_PASSWORD}
if [ "$BASE_LEN" -lt 6 ]; then
  echo "BASE_PASSWORD muy corta (mínimo 6 caracteres)"; exit 1
fi
if [ -z "${LOG_URL:-}" ]; then
  echo "Aviso: LOG_URL vacío, no se registrarán accesos"
fi
LOG_ESC=${LOG_URL//&/\\&}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Plantilla del prompt con BASE_LEN y LOG_URL inyectados
sed -e "s|__BASE_LEN__|$BASE_LEN|" -e "s|__LOG_URL__|$LOG_ESC|g" template_guia.html > "$tmp/template.html"

# Guía + registro de respaldo dentro de la página ya desencriptada
cat "$FUENTE" > "$tmp/index.html"
cat >> "$tmp/index.html" <<EOF
<script>(function(){var u;try{u=localStorage.getItem('guia_u')}catch(e){return}if(!u)return;var k='guia_logged_'+u,done=false;try{done=!!localStorage.getItem(k);if(!done)localStorage.setItem(k,'1')}catch(e){}if(!done){(new Image()).src='${LOG_URL}?u='+encodeURIComponent(u)+'&ua='+encodeURIComponent(navigator.userAgent)}})();</script>
EOF

npx -y staticrypt@3.5.4 "$tmp/index.html" \
  -p "$BASE_PASSWORD" \
  -d "$tmp/out" \
  -t "$tmp/template.html" \
  --remember false \
  --short \
  --template-title "Guía Freelancer · frani.be" \
  --template-instructions "Tu clave es la que te envié<br><small>(clave base + tu usuario de Instagram, todo junto, en minúscula y sin @)</small>" \
  --template-placeholder "pass+tu_usuario" \
  --template-button "Ver la guía" \
  --template-error "Clave incorrecta, revísala e inténtalo de nuevo." \
  --template-color-primary "#8b2db3" \
  --template-color-secondary "#eedffc"

mv "$tmp/out/index.html" ./index.html
echo "Listo: index.html encriptado. Clave de acceso = ${BASE_PASSWORD} + usuario_ig (base_len=${BASE_LEN})"
