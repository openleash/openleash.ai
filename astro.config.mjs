import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

const isGitHubPages = process.env.GITHUB_PAGES === 'true';
const repoName = process.env.REPO_NAME || 'openleash.ai';

export default defineConfig({
  site: 'https://openleash.ai',
  base: isGitHubPages ? `/${repoName}` : '/',
  output: 'static',
  integrations: [sitemap()],
  build: {
    assets: 'assets',
  },
});
