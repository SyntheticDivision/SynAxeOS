const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { execSync } = require('child_process');

const src = path.join(__dirname, 'synaxe-www');
const dest = path.join(__dirname, 'dist', 'axe-os');
fs.rmSync(dest, { recursive: true, force: true });
fs.mkdirSync(dest, { recursive: true });

for (const file of fs.readdirSync(src)) {
  const buf = fs.readFileSync(path.join(src, file));
  fs.writeFileSync(path.join(dest, file + '.gz'), zlib.gzipSync(buf, { level: 9 }));
  console.log('packed', file);
}

let version = 'synaxe';
try {
  version = execSync('git describe --tags --always --dirty', { cwd: path.resolve(__dirname, '../../..') }).toString().trim();
} catch (err) {
  console.warn('git describe failed', err.message);
}
fs.writeFileSync(path.join(dest, 'version.txt'), version);
console.log('SynAxe OS web UI', version);
