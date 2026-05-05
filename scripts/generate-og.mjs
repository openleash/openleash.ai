/**
 * Generate per-page OG images as PNG files in public/og/
 * Uses satori (HTML-to-SVG) + @resvg/resvg-js (SVG-to-PNG)
 *
 * Run: node scripts/generate-og.mjs
 */

import satori from 'satori';
import { Resvg } from '@resvg/resvg-js';
import { readFileSync, mkdirSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const outDir = join(root, 'public', 'og');

mkdirSync(outDir, { recursive: true });

// Load Inter font for satori
const fontPath = join(root, 'node_modules', '@fontsource', 'inter', 'files', 'inter-latin-700-normal.woff');
let fontData;
if (existsSync(fontPath)) {
  fontData = readFileSync(fontPath);
} else {
  // Fetch Inter 700 from Google Fonts if not available locally
  const res = await fetch('https://fonts.gstatic.com/s/inter/v18/UcCO3FwrK3iLTeHuS_nVMrMxCp50SjIw2boKoduKmMEVuFuYMZhrib2Bg-4.ttf');
  fontData = Buffer.from(await res.arrayBuffer());
}

const fontDataRegular = await (async () => {
  const regularPath = join(root, 'node_modules', '@fontsource', 'inter', 'files', 'inter-latin-400-normal.woff');
  if (existsSync(regularPath)) return readFileSync(regularPath);
  const res = await fetch('https://fonts.gstatic.com/s/inter/v18/UcCO3FwrK3iLTeHuS_nVMrMxCp50SjIw2boKoduKmMEVuGKYMZhrib2Bg-4.ttf');
  return Buffer.from(await res.arrayBuffer());
})();

const pages = [
  { slug: 'index', title: 'OpenLeash', subtitle: 'Open-Source Authorization for AI Agents' },
  { slug: 'docs', title: 'Documentation', subtitle: 'Policy language, API reference, SDK guides, and CLI commands' },
  { slug: 'use-cases', title: 'Use Cases', subtitle: 'Spending controls, MCP authorization, human-in-the-loop, and more' },
  { slug: 'getting-started', title: 'Getting Started', subtitle: 'Set up AI agent authorization in 5 minutes' },
  { slug: 'playground', title: 'Policy Playground', subtitle: 'Test authorization policies against scenarios locally' },
  { slug: 'pro', title: 'OpenLeash Pro', subtitle: 'Hosted authorization with enterprise authentication' },
  { slug: 'openclaw', title: 'OpenClaw Integration', subtitle: 'MCP authorization sidecar for OpenClaw' },
  { slug: 'ai-agent-authorization', title: 'What is AI Agent Authorization?', subtitle: 'Policy-based governance for autonomous AI agents' },
  { slug: 'mcp-authorization', title: 'MCP Authorization', subtitle: 'Tool governance for Model Context Protocol servers' },
  { slug: 'ai-agent-guardrails', title: 'AI Agent Guardrails', subtitle: 'Spending limits, action controls, and approval workflows' },
  { slug: 'paseto-tokens', title: 'PASETO Proof Tokens', subtitle: 'Cryptographic proof of AI agent authorization' },
  { slug: 'human-in-the-loop-ai', title: 'Human-in-the-Loop AI', subtitle: 'Approval workflows and step-up authentication' },
  { slug: 'openleash-vs-api-keys', title: 'OpenLeash vs API Keys', subtitle: 'Why API keys aren\'t enough for AI agent authorization' },
  { slug: 'openleash-vs-oauth', title: 'OpenLeash vs OAuth', subtitle: 'How OpenLeash complements OAuth for AI agents' },
  { slug: 'openleash-vs-opa', title: 'OpenLeash vs OPA', subtitle: 'General-purpose policy engine versus AI agent authorization' },
  { slug: 'openleash-vs-cedar', title: 'OpenLeash vs Cedar', subtitle: 'AWS\'s embedded policy language versus an agent-specific sidecar' },
  { slug: 'openleash-vs-openfga', title: 'OpenLeash vs OpenFGA', subtitle: 'Relationship-based authorization versus AI agent governance' },
  { slug: 'blog', title: 'Blog', subtitle: 'News, tutorials, and insights on AI agent authorization' },
  { slug: 'sdk', title: 'SDKs', subtitle: 'TypeScript, Python, and Go SDKs for AI agent authorization' },
  { slug: 'sdk-typescript', title: 'TypeScript SDK', subtitle: 'AI agent authorization for Node.js and TypeScript' },
  { slug: 'sdk-python', title: 'Python SDK', subtitle: 'AI agent authorization for Python applications' },
  { slug: 'sdk-go', title: 'Go SDK', subtitle: 'AI agent authorization for Go applications' },
];

for (const page of pages) {
  const svg = await satori(
    {
      type: 'div',
      props: {
        style: {
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          padding: '60px 80px',
          background: 'linear-gradient(135deg, #050a0e 0%, #0a1118 50%, #111d28 100%)',
          fontFamily: 'Inter',
        },
        children: [
          {
            type: 'div',
            props: {
              style: {
                display: 'flex',
                alignItems: 'center',
                gap: '16px',
                marginBottom: '32px',
              },
              children: [
                {
                  type: 'div',
                  props: {
                    style: {
                      width: '48px',
                      height: '48px',
                      borderRadius: '12px',
                      background: 'linear-gradient(135deg, #34d399, #065f46)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '24px',
                      color: '#050a0e',
                      fontWeight: 700,
                    },
                    children: 'O',
                  },
                },
                {
                  type: 'div',
                  props: {
                    style: { color: '#8899aa', fontSize: '20px', fontWeight: 500 },
                    children: 'openleash.ai',
                  },
                },
              ],
            },
          },
          {
            type: 'div',
            props: {
              style: {
                fontSize: page.title.length > 30 ? '48px' : '56px',
                fontWeight: 700,
                color: '#e8f0f8',
                lineHeight: 1.2,
                marginBottom: '16px',
              },
              children: page.title,
            },
          },
          {
            type: 'div',
            props: {
              style: {
                fontSize: '24px',
                color: '#8899aa',
                lineHeight: 1.5,
                maxWidth: '900px',
              },
              children: page.subtitle,
            },
          },
          {
            type: 'div',
            props: {
              style: {
                position: 'absolute',
                bottom: '60px',
                left: '80px',
                display: 'flex',
                gap: '8px',
              },
              children: [
                { type: 'div', props: { style: { width: '40px', height: '4px', borderRadius: '2px', background: '#34d399' }, children: '' } },
                { type: 'div', props: { style: { width: '40px', height: '4px', borderRadius: '2px', background: '#10b981' }, children: '' } },
                { type: 'div', props: { style: { width: '40px', height: '4px', borderRadius: '2px', background: '#fbbf24' }, children: '' } },
              ],
            },
          },
        ],
      },
    },
    {
      width: 1200,
      height: 630,
      fonts: [
        { name: 'Inter', data: fontDataRegular, weight: 400, style: 'normal' },
        { name: 'Inter', data: fontData, weight: 700, style: 'normal' },
      ],
    },
  );

  const resvg = new Resvg(svg, { fitTo: { mode: 'width', value: 1200 } });
  const png = resvg.render().asPng();
  const outPath = join(outDir, `${page.slug}.png`);
  writeFileSync(outPath, png);
  console.log(`  Generated: og/${page.slug}.png`);
}

console.log(`\nDone — ${pages.length} OG images generated in public/og/`);
