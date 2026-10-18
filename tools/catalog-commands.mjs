// Export the effective inline commands for static parsing; never execute them.
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadCatalog } from './site-test-harness.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const {api,window}=loadCatalog(root);
const commands=api.ITEMS.filter(item=>item.type==='Quick Command').map(item=>({name:item.name,code:item.code}));
for(const item of api.ITEMS.filter(item=>item.publishedPath?.endsWith('.ps1'))){
  commands.push({name:'Launch '+item.file,code:window.FIELD_KIT_START.launch(item.file)});
}
process.stdout.write(JSON.stringify(commands));
