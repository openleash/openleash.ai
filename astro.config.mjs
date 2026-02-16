import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://openleash.ai',
  base: '/',
  output: 'static',
  integrations: [sitemap()],
  build: {
    assets: 'assets',
  },
});
