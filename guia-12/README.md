# TP12 — Portfolio final

La carpeta `portfolio/` contiene el README de presentación, la matriz de proyectos, el README del perfil y su workflow de comprobación.

## Preparar

Desde `guia-12/`:

```bash
grep -R "TU_USUARIO" portfolio
bash scripts/verificar.sh
```

Reemplazá `TU_USUARIO` y `[Tu Nombre]` antes de publicar.

## Publicar como repositorio independiente

```bash
cd portfolio
git init
git add .
git commit -m "portfolio: README final con 12 TPs de Operaciones1"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/devops-portfolio.git
git push -u origin main
```

El workflow comprueba la estructura del README y la existencia de los repositorios anteriores. Fallará mientras falte alguno de ellos en GitHub.
