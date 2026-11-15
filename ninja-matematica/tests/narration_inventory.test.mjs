import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const entries = JSON.parse(fs.readFileSync(path.join(root, 'content/menu_narration_request.json'), 'utf8'));
const keys = new Set();
for (const entry of entries) {
  assert.match(entry.key, /^game:ninja-matematica:[a-z0-9][a-z0-9:-]*$/);
  assert(!keys.has(entry.key), `Duplicate key: ${entry.key}`);
  keys.add(entry.key);
  for (const field of ['text', 'context']) assert.equal(typeof entry[field], 'string');
  assert(entry.text.trim() && entry.context.trim());
  assert(['required', 'optional'].includes(entry.priority));
  assert(!/[{}]|Bearer\s|eyJ[A-Za-z0-9_-]{20}/u.test(entry.text), `Template/private token in text: ${entry.key}`);
}
for (const name of fs.readdirSync(path.join(root, 'scenes')).filter(name => name.endsWith('.tscn'))) {
  const source = fs.readFileSync(path.join(root, 'scenes', name), 'utf8');
  assert(!source.includes('narration_key'), `Runtime narration metadata remains in ${name}`);
}
for (const name of fs.readdirSync(path.join(root, 'scripts')).filter(name => name.endsWith('.gd'))) {
  const source = fs.readFileSync(path.join(root, 'scripts', name), 'utf8');
  assert(!/DisplayServer\.tts_|speech|speak|narration|voice|faber|device_fallback/i.test(source), `Runtime narration remains in ${name}`);
}
assert(!/general\/text_to_speech=true/.test(fs.readFileSync(path.join(root, 'project.godot'), 'utf8')));
assert(!fs.readFileSync(path.join(root, 'export_presets.cfg'), 'utf8').includes('include_filter="content/menu_narration_request.json"'));
for (const suffix of ['game-over:score', 'game-over:correct', 'game-over:attempts', 'dynamic:question', 'dynamic:round-result']) {
  assert(entries.find(entry => entry.key.endsWith(':' + suffix)).context.startsWith('[modelo dinâmico]'));
}
console.log(`NARRATION_INVENTORY: PASS (${entries.length} external entries, unique keys, no runtime narration)`);
