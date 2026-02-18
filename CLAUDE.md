# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Marketing site for [OpenLeash](https://github.com/openleash) — a local-first policy gate and authorization sidecar for AI agents. Built with Astro 5, deployed to GitHub Pages at openleash.ai.

## Commands

```bash
npm run dev       # Dev server at http://localhost:4321
npm run build     # Static build to dist/
npm run preview   # Preview built site
npm run lint      # TypeScript checking (astro check)
```

No test runner is configured. There are no unit tests.

## Architecture

**Astro static site** — zero JavaScript frameworks, pure Astro components with scoped CSS. Output is static HTML.

- `src/pages/` — File-based routing. Each `.astro` file becomes a route (index, docs, playground, brand, openclaw).
- `src/components/` — Reusable Astro components. QuickStart.astro is the largest (~960 lines) with OS-detecting tabs and copy-to-clipboard.
- `src/layouts/BaseLayout.astro` — Shared HTML shell with SEO meta, OG tags, and AI agent discovery meta tags.
- `src/styles/global.css` — Design tokens as CSS custom properties, reset, and global styles.
- `public/` — Static assets served as-is: brand SVGs, install.sh, llms.txt, og.png, CNAME.

## Styling

Dark-first theme using CSS custom properties defined in `global.css`:
- **Primary (green/emerald)**: `--green-bright`, `--green-mid`, `--green-dark` — trust/authorization
- **Secondary (amber)**: `--amber-bright`, `--amber-mid`, `--amber-dark` — caution/policy gate
- **Backgrounds**: `--bg-deep`, `--bg-surface`, `--bg-elevated`

Components use scoped `<style>` blocks. No CSS framework — vanilla CSS with custom properties. Responsive breakpoints at 640px and 768px.

## Path Alias

TypeScript path alias `@/*` maps to `src/*` (configured in tsconfig.json).

## Deployment

Automatic via `.github/workflows/deploy.yml` on push to `main`. Uses Node 22, `npm ci`, builds, and deploys to GitHub Pages. The `public/CNAME` file sets the custom domain.

## Configurable Links

These URLs are hardcoded across components — search-and-replace when changing:
- `https://github.com/openleash` — GitHub org
- `https://github.com/openleash/openleash` — main repo
- `https://openclaw.ai` / `https://docs.openclaw.ai` — OpenClaw site and docs
