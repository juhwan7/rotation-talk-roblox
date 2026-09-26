import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const luau = process.argv[2] || 'luau';
const compiler = process.argv[3] || 'luau-compile';
let failed = false;
function run(exe, args, silent = false) {
  const r = spawnSync(exe, args, { cwd: root, encoding: 'utf8' });
  if (r.status !== 0) { failed = true; console.error(r.error?.message || r.stderr || r.stdout); }
  else if (!silent) process.stdout.write(r.stdout);
}
const modules = {};
for (const folder of ['shared', 'server', 'client']) {
  for (const file of fs.readdirSync(path.join(root, 'src', folder)).filter(f => f.endsWith('.luau'))) {
    const relative = `src/${folder}/${file}`;
    run(compiler, ['--null', relative], true);
    if (!file.endsWith('.server.luau') && !file.endsWith('.client.luau')) modules[file.replace('.luau','')] = fs.readFileSync(path.join(root, relative), 'utf8');
  }
}
if (!failed) console.log('PASS: every production Luau source compiles');
run(luau, ['tests/rules.spec.luau']);
// Load the actual production modules in a minimal deterministic Roblox service mock.
// This verifies transitions and trust boundaries, not engine physics or real DataStore.
let bundle = fs.readFileSync(path.join(root, 'tests/mock-header.luau'), 'utf8');
for (const [name, source] of Object.entries(modules)) {
  if (name === 'WorldService') continue;
  bundle += `\nloaders["${name}"] = function()\n${source}\nend\n`;
}
bundle += fs.readFileSync(path.join(root, 'tests/integration-body.luau'), 'utf8');
fs.mkdirSync(path.join(root, 'build'), { recursive: true });
fs.writeFileSync(path.join(root, 'build/integration.generated.luau'), bundle);
run(luau, ['build/integration.generated.luau']);
if (failed) process.exitCode = 1;
