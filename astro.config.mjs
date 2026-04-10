import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://openleash.ai',
  base: '/',
  output: 'static',
  integrations: [
    sitemap({
      changefreq: 'weekly',
      priority: 0.7,
      lastmod: new Date(),
      serialize(item) {
        // Homepage gets highest priority
        if (item.url === 'https://openleash.ai/') {
          item.priority = 1.0;
          item.changefreq = 'weekly';
        }
        // Concept/educational pages — high value content
        if (item.url.includes('/concepts/')) {
          item.priority = 0.9;
          item.changefreq = 'monthly';
        }
        // Use cases and docs — core pages
        if (item.url.includes('/use-cases') || item.url.includes('/docs')) {
          item.priority = 0.8;
          item.changefreq = 'weekly';
        }
        // Pro, playground, openclaw
        if (item.url.includes('/pro') || item.url.includes('/playground') || item.url.includes('/openclaw')) {
          item.priority = 0.6;
          item.changefreq = 'monthly';
        }
        // Brand assets — low priority
        if (item.url.includes('/brand')) {
          item.priority = 0.3;
          item.changefreq = 'yearly';
        }
        return item;
      },
    }),
  ],
  build: {
    assets: 'assets',
  },
});
