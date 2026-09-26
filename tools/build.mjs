import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const escape = s => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
let id = 0;
function item(className, name, body = '', properties = '') {
  return `<Item class="${className}" referent="RT${++id}"><Properties><string name="Name">${escape(name)}</string>${properties}</Properties>${body}</Item>`;
}
function sourceFolder(folder, name) {
  const files = fs.readdirSync(path.join(root, folder)).filter(f => f.endsWith('.luau')).sort();
  return item('Folder', name, files.map(file => {
    const className = file.endsWith('.server.luau') ? 'Script' : file.endsWith('.client.luau') ? 'LocalScript' : 'ModuleScript';
    const scriptName = file.replace(/\.(server|client)\.luau$/, '').replace(/\.luau$/, '');
    const source = fs.readFileSync(path.join(root, folder, file), 'utf8');
    return item(className, scriptName, '', `<ProtectedString name="Source">${escape(source)}</ProtectedString>`);
  }).join(''));
}
const xml = `<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="4">
<External>null</External><External>nil</External>
${item('Workspace', 'Workspace')}
${item('ReplicatedStorage', 'ReplicatedStorage', sourceFolder('src/shared', 'RotationTalk'))}
${item('ServerScriptService', 'ServerScriptService', sourceFolder('src/server', 'RotationTalk'))}
${item('StarterPlayer', 'StarterPlayer', item('StarterPlayerScripts', 'StarterPlayerScripts', sourceFolder('src/client', 'RotationTalk')))}
${item('TextChatService', 'TextChatService', '', '<token name="ChatVersion">1</token><bool name="CreateDefaultTextChannels">true</bool><bool name="CreateDefaultCommands">true</bool>')}
</roblox>`;
const output = path.resolve(root, process.argv[2] || 'build/RotationTalk.rbxlx');
fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, xml, 'utf8');
console.log(`Built ${path.basename(output)} (${Buffer.byteLength(xml)} bytes, ${id} instances). Studio playtest is still required.`);
