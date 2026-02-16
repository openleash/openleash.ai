# openleash.ai

Marketing site for [OpenLeash](https://github.com/openleash) — the local-first policy gate for AI agents.

Built with [Astro](https://astro.build), deployed to GitHub Pages.

## Local development

```bash
npm install
npm run dev
```

Open [http://localhost:4321](http://localhost:4321).

## Build

```bash
npm run build
npm run preview   # preview the built site locally
```

## Deployment

The site deploys automatically to GitHub Pages on push to `main` via the `.github/workflows/deploy.yml` workflow.

For custom domain setup, the `public/CNAME` file contains `openleash.ai`. Update this if using a different domain.

### GitHub Pages base path

The Astro config handles base path automatically:

- With a custom domain (`public/CNAME` exists): base is `/`
- Without a custom domain (`GITHUB_PAGES=true`): base is `/<repo-name>`

## Configurable links

GitHub organization and repo links are used throughout the site. To change them, search for:

- `https://github.com/openleash` — GitHub org
- `https://github.com/openleash/openleash` — main repo
- `https://openclaw.ai` — OpenClaw website
- `https://docs.openclaw.ai` — OpenClaw docs

## Brand assets

Logo files are in `public/brand/`:

- `openleash-mark.svg` — icon only
- `openleash-lockup.svg` — icon + wordmark
- `openleash-mark-mono.svg` — monochrome variant
- `favicon.svg` — browser favicon

To replace brand assets, swap the SVG files in `public/brand/` and update the favicon reference in `src/layouts/BaseLayout.astro`.

## Tech stack

- **Astro** — static site generator
- **TypeScript** — type checking
- **Custom CSS** — no frameworks, CSS custom properties for theming
- **GitHub Actions** — CI/CD to GitHub Pages
