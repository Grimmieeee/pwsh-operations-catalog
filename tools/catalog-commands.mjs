// Export the effective inline commands for static parsing; never execute them.
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadCatalog } from './site-test-harness.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const {api}=loadCatalog(root);
process.stdout.write(JSON.stringify(api.ITEMS.filter(item=>item.type==='Quick Command').map(item=>({name:item.name,code:item.code}))));
