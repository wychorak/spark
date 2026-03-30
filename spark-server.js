const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 9091;
const ROOT = path.join(__dirname, 'spark', 'build', 'web');

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

http.createServer((req, res) => {
  let urlPath = decodeURIComponent(req.url.split('?')[0]);

  // Normalize: remove leading slash for path.join
  if (urlPath.startsWith('/')) urlPath = urlPath.substring(1);

  let filePath = path.resolve(ROOT, urlPath || 'index.html');

  console.log(`[REQ] ${req.url} -> ${filePath} (exists: ${fs.existsSync(filePath)})`);

  // Security: ensure we stay within ROOT
  if (!filePath.startsWith(ROOT)) {
    console.log(`[BLOCKED] ${filePath} not under ${ROOT}`);
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  // Check if file exists; if directory, try index.html inside it
  let exists = false;
  try {
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      filePath = path.join(filePath, 'index.html');
      exists = fs.existsSync(filePath);
    } else {
      exists = true;
    }
  } catch (e) {
    exists = false;
  }

  // SPA fallback: only for paths without file extensions (routes like /age-gate)
  if (!exists) {
    const hasExt = path.extname(filePath).length > 0;
    if (!hasExt) {
      filePath = path.join(ROOT, 'index.html');
    } else {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
  }

  const ext = path.extname(filePath);
  const contentType = mimeTypes[ext] || 'application/octet-stream';

  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
  res.setHeader('Access-Control-Allow-Origin', '*');

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}).listen(PORT, () => {
  console.log(`Spark server running at http://localhost:${PORT}`);
  console.log(`Serving from: ${ROOT}`);
});
