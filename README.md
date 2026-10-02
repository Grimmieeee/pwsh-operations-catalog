# PWSH Operations Catalog

A static website built with plain HTML, CSS, and JavaScript.

## Files

- `index.html` — page structure
- `styles.css` — retro theme and responsive layout
- `catalog-data.js` — catalog data loaded by the browser
- `app.js` — search, filters, sorting, paging, and UI behavior
- `catalog-data.json` — plain JSON copy of the catalog data

## Run locally

You can open `index.html` directly.

For a more realistic local web-development workflow:

```powershell
python -m http.server 8000
```

Then browse to:

```text
http://localhost:8000
```

Stop the server with Ctrl+C.

## Publish with GitHub Pages

1. Create a repository such as `pwsh-operations-catalog`.
2. Put these files in the repository root.
3. Commit and push to `main`.
4. Open the repository on GitHub.
5. Go to `Settings > Pages`.
6. Under Build and deployment, choose `Deploy from a branch`.
7. Select `main` and `/ (root)`.
8. Save.

A project-site URL normally looks like:

```text
https://YOUR-GITHUB-USERNAME.github.io/pwsh-operations-catalog/
```

## Learn web development with this project

Good first exercises:

1. Change a heading in `index.html`.
2. Change spacing or a color in `styles.css`.
3. Add one catalog item in `catalog-data.js`.
4. Add a quick-search chip in `index.html`.
5. Follow the `render()` function in `app.js`.
6. Add a new filter.
7. Commit each small change so Git history becomes your change log.

## Publishing safety

Treat anything you publish to the site as public.

Do not publish passwords, tokens, secrets, private certificates/PFX material,
client-specific sensitive data, private incident evidence, or internal credentials.
