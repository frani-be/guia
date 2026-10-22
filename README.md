# Guía Freelancer (acceso con clave personal)

Guía en HTML encriptada con [StatiCrypt](https://github.com/robinmoisson/staticrypt), servida por GitHub Pages en `guia.frani.be`. Cada persona recibe un link propio y una clave `BASE + su_usuario_IG`. Cada apertura queda registrada en una planilla de Google.

## Cómo funciona

- `guia-freelancer.html` es la fuente (ignorada, nunca se sube).
- `usuarios.txt` lista los usernames de Instagram a quienes enviarás la guía (ignorado).
- `build.sh` genera `d/<slug>/index.html` por usuario: un blob encriptado que solo se abre con `BASE_PASSWORD + usuario`. El slug es un hash, así los usernames no se ven en el repo.
- Cada página desencriptada dispara un beacon a tu Google Sheet (una sola vez por navegador), anotando el usuario.
- `links.txt` (ignorado) queda con `usuario | url | clave` para copiar/pegar en los DMs.
- `index.html` / `404.html` son páginas de entrada sin contenido.

## Setup (una sola vez)

### 1. Planilla de registro

1. Crea una planilla en sheets.google.com.
2. Extensiones > Apps Script: pega `apps_script.gs`.
3. Implementar > Nueva implementación > "Aplicación web", acceso "Cualquier persona".
4. Copia la URL `/exec`.

### 2. Secretos locales

```bash
cp .env.example .env       # define BASE_PASSWORD (minúsculas) y LOG_URL
cp usuarios.txt.example usuarios.txt   # agrega los usernames reales
```

### 3. Repo en GitHub

```bash
git remote add origin git@github.com:frani-be/guia.git
git push -u origin main
```

En el repo: Settings > Pages > Source: Deploy from a branch > `main` / root. El `CNAME` ya apunta a `guia.frani.be`; agrega el registro CNAME `guia` -> `frani-be.github.io` en tu DNS.

## Uso habitual

```bash
./build.sh    # regenera d/ y links.txt tras editar la guía o usuarios.txt
git add d/ && git commit -m "Actualiza guía" && git push
```

Para agregar personas: añade su username a `usuarios.txt` y corre `build.sh` + push. Para revocar: borra su línea y vuelve a generar.

## Límites del seguimiento

El beacon confirma que alguien abrió la página con éxito desde ese navegador. No prueba que la leyó ni la descargó; para "quién no accedió" basta comparar la planilla contra `usuarios.txt`.
