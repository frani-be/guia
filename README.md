# Guía Freelancer (acceso con clave base + usuario IG)

Guía en HTML encriptada con [StatiCrypt](https://github.com/robinmoisson/staticrypt), servida por GitHub Pages en `guia.frani.be`. Un solo link para todas las personas: cada quien entra con `BASE + su_usuario_IG` y cada apertura queda registrada en una planilla de Google.

## Cómo funciona

- `guia-freelancer.html` es la fuente (ignorada, nunca se sube).
- `build.sh` genera `index.html`: la guía encriptada con `BASE_PASSWORD`. Es lo único que ve quien entra a `guia.frani.be`.
- El prompt pide una sola clave. La página separa los primeros N caracteres (largo de la base) como contraseña real y el resto como usuario IG; valida que el usuario tenga formato `@usuario`, desencripta y anota el acceso (una vez por navegador por usuario).
- `template_guia.html` es la plantilla del prompt; `build.sh` le inyecta `BASE_LEN` y `LOG_URL`. La base nunca queda en el archivo publicado, solo su largo.
- `404.html` es la página de entrada para rutas inválidas.

## Setup (una sola vez)

### 1. Planilla de registro

1. Crea una planilla en sheets.google.com.
2. Extensiones > Apps Script: pega `apps_script.gs`.
3. Implementar > Nueva implementación > "Aplicación web", acceso "Cualquier persona".
4. Copia la URL `/exec`.

### 2. Secretos locales

```bash
cp .env.example .env   # define BASE_PASSWORD (minúsculas, min 6) y LOG_URL
```

### 3. GitHub Pages y DNS

En el repo: Settings > Pages > Source: Deploy from a branch > `main` / root. El `CNAME` ya apunta a `guia.frani.be`; agrega el registro CNAME `guia` -> `frani-be.github.io` en tu DNS.

## Uso habitual

```bash
./build.sh    # regenera index.html tras editar la guía o cambiar la base
git add index.html && git commit -m "Actualiza guía" && git push
```

Para compartir, envías el link `guia.frani.be` y le dices a cada persona: "tu clave es `BASE` seguida de tu usuario de Instagram". No necesitas registrar usuarios antes.

## Límites del seguimiento

- La planilla registra usuario + fecha + user-agent solo cuando alguien desbloquea la página.
- El usuario es auto-reportado: si alguien conoce la base puede escribir otro usuario. Para audiencia casual de Instagram es suficiente; no es verificación de identidad.
- El beacon confirma apertura, no lectura ni descarga. "Quiénes no entraron" = personas a quienes enviaste menos las que aparecen en la planilla.
