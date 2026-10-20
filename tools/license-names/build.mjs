import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'../..');
const records=JSON.parse(fs.readFileSync(path.join(import.meta.dirname,'microsoft-products.json'),'utf8')).products;
const encodedNames=JSON.stringify(records).replace(/[\u007f-\uffff]/g,c=>'\\u'+c.charCodeAt(0).toString(16).padStart(4,'0'));
const resolver=fs.readFileSync(path.join(import.meta.dirname,'resolver.ps1.txt'),'utf8').replace('__LICENSE_NAMES__',encodedNames);
for(const file of ['INVOKE-ASSIGN-LICENSES.ps1','INVOKE-REMOVE-LICENSES.ps1']){
 const target=path.join(root,'published-source/identity',file);
 let source=fs.readFileSync(target,'utf8').replace('.VERSION 1.0.1','.VERSION 1.0.2');
 if(source.includes('function Get-LicenseProductName {'))source=source.replace(/function Get-LicenseProductName \{[\s\S]*?\n\}/,()=>resolver.trimEnd());
 else source=source.replace(/^\$ErrorActionPreference\s*=\s*['"]Stop['"]\r?$/m,match=>match+'\n\n'+resolver);
 if(!source.includes('function Get-LicenseProductName {'))throw Error('Could not embed resolver: '+file);
 fs.writeFileSync(target,source);
}
