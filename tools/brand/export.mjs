// Export PNGs for the logo set and render the brand sheet.
import { chromium } from 'playwright-core';
import { readFileSync, readdirSync, mkdirSync, writeFileSync } from 'fs';
import { join } from 'path';

const OUT = 'out';
const DEST = process.argv[2];
mkdirSync(join(DEST, 'png'), { recursive: true });
mkdirSync(join(DEST, 'svg'), { recursive: true });
mkdirSync(join(DEST, 'app-icon'), { recursive: true });

const browser = await chromium.launch({
  executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
});

async function render(svgText, output, width, height) {
  const m = svgText.match(/viewBox="([\d.\s-]+)"/);
  const [, , vw, vh] = m[1].split(/\s+/).map(Number);
  const w = width, h = height ?? Math.round(width * vh / vw);
  const page = await browser.newPage({ viewport: { width: w, height: h } });
  await page.setContent(`<html><body style="margin:0;background:transparent">${
    svgText.replace('<svg', `<svg width="${w}" height="${h}" preserveAspectRatio="xMidYMid meet"`)}</body></html>`);
  await page.screenshot({ path: output, omitBackground: true, clip: { x: 0, y: 0, width: w, height: h } });
  await page.close();
}

// 1) Logo SVGs and high-res transparent PNGs.
for (const f of readdirSync(OUT).filter(f => f.startsWith('sanadi-') && f.endsWith('.svg'))) {
  const svg = readFileSync(join(OUT, f), 'utf8');
  writeFileSync(join(DEST, 'svg', f), svg);
  const width = f.includes('-mark-') ? 2048 : f.includes('vertical') ? 2048 : 4096;
  await render(svg, join(DEST, 'png', f.replace('.svg', '.png')), width);
}

// 2) App icon: adaptive layers, Android launcher sizes, Play Store icon.
for (const f of readdirSync(OUT).filter(f => (f.startsWith('app-icon') || f.startsWith('play-store')) && f.endsWith('.svg'))) {
  writeFileSync(join(DEST, 'app-icon', f), readFileSync(join(OUT, f), 'utf8'));
}
const icon = readFileSync(join(OUT, 'app-icon.svg'), 'utf8');
await render(readFileSync(join(OUT, 'app-icon-foreground.svg'), 'utf8'), join(DEST, 'app-icon', 'app-icon-foreground-432.png'), 432);
await render(readFileSync(join(OUT, 'app-icon-background.svg'), 'utf8'), join(DEST, 'app-icon', 'app-icon-background-432.png'), 432);
await render(readFileSync(join(OUT, 'play-store-icon.svg'), 'utf8'), join(DEST, 'app-icon', 'play-store-icon-512.png'), 512);
await render(readFileSync(join(OUT, 'app-icon-light.svg'), 'utf8'), join(DEST, 'app-icon', 'app-icon-light-432.png'), 432);
// Legacy square launcher icons crop the central 72dp of the 108dp canvas.
const legacy = icon.replace(/viewBox="0 0 432 432"/, 'viewBox="72 72 288 288"');
for (const [dpi, px] of Object.entries({ mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 })) {
  await render(legacy, join(DEST, 'app-icon', `ic_launcher-${dpi}-${px}.png`), px);
}

// 3) Brand sheet.
const sheet = readFileSync('sheet.html', 'utf8');
const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
await page.goto('file://' + join(process.cwd(), 'sheet.html'));
await page.waitForTimeout(500);
await page.screenshot({ path: join(DEST, 'sanadi-brand-sheet.png'), fullPage: true });
await page.close();
await browser.close();
console.log('exported to', DEST);
