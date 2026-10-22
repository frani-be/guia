#!/bin/bash
# Genera una versión encriptada de guia-freelancer.html por cada usuario de usuarios.txt
# Salida: d/<slug>/index.html (solo blobs encriptados, el contenido no es legible)
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
OUT_DIR="d"
BASE_URL="https://guia.frani.be"
STCRYPT="npx -y staticrypt@3.5.4"

[ -f "$FUENTE" ] || { echo "Falta $FUENTE"; exit 1; }
[ -f usuarios.txt ] || { echo "Falta usuarios.txt"; exit 1; }
if [ -z "${BASE_PASSWORD:-}" ] || [ "$BASE_PASSWORD" = "tu_base_aqui" ]; then
  echo "Define BASE_PASSWORD en .env"; exit 1
fi
if [ -z "${LOG_URL:-}" ]; then
  echo "Aviso: LOG_URL vacío, no se registrarán accesos"
fi

rm -rf "$OUT_DIR"
: > links.txt

while IFS= read -r raw || [ -n "$raw" ]; do
  case "$raw" in ''|\#*) continue;; esac
  user=$(printf '%s' "$raw" | tr -d ' \r' | sed 's/^@//' | tr 'A-Z' 'a-z')
  [ -z "$user" ] && continue

  slug=$(printf '%s' "$user" | shasum -a 256 | cut -c1-10)
  tmp="$(mktemp -d)"

  # Variante por usuario: guía + beacon que anota el acceso en la planilla
  cat "$FUENTE" > "$tmp/index.html"
  cat >> "$tmp/index.html" <<EOF
<script>(function(){try{if(localStorage.getItem('guia_log'))return;localStorage.setItem('guia_log','1')}catch(e){};(new Image()).src='${LOG_URL}?u=${user}&ua='+encodeURIComponent(navigator.userAgent)})();</script>
EOF

  $STCRYPT "$tmp/index.html" \
    -p "${BASE_PASSWORD}${user}" \
    -d "$OUT_DIR/$slug" \
    --remember false \
    --short \
    --template-title "Guía Freelancer · frani.be" \
    --template-instructions "Ingresa tu clave personal: la base que te envié + tu usuario de Instagram, todo junto, en minúscula y sin @." \
    --template-placeholder "tu clave" \
    --template-button "Ver la guía" \
    --template-error "Clave incorrecta, revísala e inténtalo de nuevo." \
    --template-color-primary "#8b2db3" \
    --template-color-secondary "#eedffc" \
    >/dev/null

  printf '@%s\t%s/d/%s/\t%s%s\n' "$user" "$BASE_URL" "$slug" "$BASE_PASSWORD" "$user" >> links.txt
  rm -rf "$tmp"
  echo "ok  $user -> $OUT_DIR/$slug/"
done < usuarios.txt

echo ""
echo "Listo: $(wc -l < links.txt | tr -d ' ') links en links.txt (usuario | url | clave)"
