#!/usr/bin/env node
// Audit the built public site with the Chrome bundled in the pinned CI image.
import { createServer } from 'node:http';
import { readFile, realpath, stat, mkdtemp, rm } from 'node:fs/promises';
import { extname, join, sep } from 'node:path';
import { tmpdir } from 'node:os';
import { createRequire } from 'node:module';
import { requireAccessibleReport } from './audit-site-result.mjs';

const root = await realpath('_site');
if (!(await stat(root)).isDirectory()) throw new Error('_site must be a built site directory');
const require = createRequire(import.meta.url);
const puppeteer = require('/home/pptruser/node_modules/puppeteer');
const { default: lighthouse } = await import('lighthouse');
const profile = await mkdtemp(join(tmpdir(), 'native-site-chrome-'));
const types = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript',
  '.json': 'application/json', '.svg': 'image/svg+xml', '.png': 'image/png',
  '.webp': 'image/webp', '.ico': 'image/x-icon', '.txt': 'text/plain' };
let browser;
const server = createServer(async (request, response) => {
  try {
    if (!['GET', 'HEAD'].includes(request.method)) {
      response.writeHead(405).end();
      return;
    }
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    const candidate = join(root, pathname.endsWith('/') ? `${pathname}index.html` : pathname);
    const file = await realpath(candidate);
    if (!file.startsWith(`${root}${sep}`) || !(await stat(file)).isFile()) {
      response.writeHead(404).end();
      return;
    }
    const data = await readFile(file);
    response.writeHead(200, { 'Content-Type': types[extname(file)] || 'application/octet-stream' });
    response.end(request.method === 'HEAD' ? undefined : data);
  } catch {
    response.writeHead(404).end();
  }
});
try {
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  browser = await puppeteer.launch({
    headless: true,
    userDataDir: profile,
    timeout: 30000,
    dumpio: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });
  const endpoint = new URL(browser.wsEndpoint());
  if (!['127.0.0.1', 'localhost', '[::1]'].includes(endpoint.hostname) || !endpoint.port)
    throw new Error('Chrome must expose an owned loopback DevTools endpoint');
  const version = await fetch(`http://127.0.0.1:${endpoint.port}/json/version`, {
    signal: AbortSignal.timeout(10000),
  });
  if (!version.ok || !(await version.json()).webSocketDebuggerUrl)
    throw new Error('Chrome DevTools readiness check failed');
  console.log(`Node ${process.version}; browser ${await browser.version()}`);
  const result = await lighthouse(`http://127.0.0.1:${server.address().port}/`, {
    port: Number(endpoint.port),
    onlyCategories: ['accessibility'],
    output: 'json',
    logLevel: 'info',
  });
  const score = requireAccessibleReport(result);
  console.log('accessibility score:', score);
} finally {
  try {
    if (browser) await browser.close();
  } finally {
    server.closeAllConnections();
    if (server.listening) await new Promise(resolve => server.close(resolve));
    await rm(profile, { recursive: true, force: true });
  }
}
