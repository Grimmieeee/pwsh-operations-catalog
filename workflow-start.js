// Operator directions and an in-browser ZIP writer. No tenant actions run here.
(() => {
  const stages = {
    'ir-risk-assessment.ps1': {
      result:'Findings and checks that could not run for the selected account. Review the evidence before deciding whether the incident is resolved.',
      next:'If containment is needed and approved, continue with ir-contain-eradicate. Otherwise record the findings and follow your incident process.',
      blocked:'If a required check cannot run, resolve the missing access or data before deciding the account is clear.'
    },
    'ir-contain-eradicate.ps1': {
      result:'Completed, failed, and skipped actions, plus any remaining investigation or unwanted access to remove.',
      next:'Continue with ir-recover-validate before restoring access. Keep the account contained until cleanup is complete and recovery is approved.',
      blocked:'A failed or cancelled action is not completed. Review the action results and maintain containment until the incident owner approves the next step.'
    },
    'ir-recover-validate.ps1': {
      result:'Recovery checks and whether the account was enabled. A pending sync is not confirmed recovery.',
      next:'Verify the user can sign in with MFA, record the result, and monitor for new suspicious activity for 48 hours. Unresolved issues remain open.',
      blocked:'If readiness or restored access cannot be verified, stop and return to the incident owner. Do not repeatedly enable the account to bypass a failed check.'
    }
  };
  const preparation = [
    'Use the approved client Windows jumpbox and an authorized account. Synced-user changes also need local Active Directory permissions.',
    'Have the exact user sign-in name (UPN) and tenant domain or ID ready. Required modules: Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+.',
    'Extract all three scripts into one folder. Open Windows PowerShell 5.1 or PowerShell 7 on the jumpbox and keep that window open for the workflow.',
    'The first sign-in requests permissions for assessment, containment and recovery. The assessment itself makes no tenant changes; change actions still require approval.'
  ];
  function launch(file){
    if(!/^[a-z0-9._-]+\.ps1$/i.test(file))throw new Error('Invalid script filename.');
    return '$ScriptPath = (Read-Host "Paste the full path to '+file+'").Trim().Trim(\'"\')\n'+
      'if ((Split-Path -Leaf $ScriptPath) -ne \''+file+'\') { throw \'Select '+file+'.\' }\n'+
      '& $ScriptPath';
  }
  function guide(){
    return '# FIELD // KIT — IR workflow\n\nPREPARE\n'+preparation.map((text,i)=>(i+1)+'. '+text).join('\n')+
      '\n\nSTART\nRight-click ir-risk-assessment.ps1 in File Explorer and choose Copy as path. In the existing PowerShell window, paste the following launch block, then paste the file path when asked.\n\n```powershell\n'+launch('ir-risk-assessment.ps1')+'\n```\n\n'+
      Object.entries(stages).map(([file,step])=>'## '+file.replace(/\.ps1$/,'')+'\n\nExpected result: '+step.result+'\n\nNext: '+step.next+'\n\nIf blocked or cancelled: '+step.blocked).join('\n\n')+
      '\n\nIf PowerShell blocks execution, stop and use the approved signing/execution-policy process. Do not bypass a managed policy.\n';
  }
  function crc32(bytes){
    let value=0xffffffff;
    for(const byte of bytes){value^=byte;for(let bit=0;bit<8;bit++)value=(value>>>1)^((value&1)?0xedb88320:0);}
    return (value^0xffffffff)>>>0;
  }
  function zip(entries){
    if(!entries.length||entries.length>16)throw new Error('Invalid package size.');
    const encoder=new TextEncoder(), chunks=[], central=[];
    let offset=0,centralSize=0;
    const names=new Set();
    for(const entry of entries){
      if(!/^[a-z0-9._-]+$/i.test(entry.name)||names.has(entry.name))throw new Error('Invalid package filename.');
      names.add(entry.name);
      const name=encoder.encode(entry.name), bytes=encoder.encode(entry.text), crc=crc32(bytes);
      const local=new Uint8Array(30+name.length), h=new DataView(local.buffer);
      h.setUint32(0,0x04034b50,true);h.setUint16(4,20,true);h.setUint16(6,0x800,true);h.setUint16(12,33,true);
      h.setUint32(14,crc,true);h.setUint32(18,bytes.length,true);h.setUint32(22,bytes.length,true);h.setUint16(26,name.length,true);local.set(name,30);
      const directory=new Uint8Array(46+name.length), d=new DataView(directory.buffer);
      d.setUint32(0,0x02014b50,true);d.setUint16(4,20,true);d.setUint16(6,20,true);d.setUint16(8,0x800,true);d.setUint16(14,33,true);
      d.setUint32(16,crc,true);d.setUint32(20,bytes.length,true);d.setUint32(24,bytes.length,true);d.setUint16(28,name.length,true);d.setUint32(42,offset,true);directory.set(name,46);
      chunks.push(local,bytes);central.push(directory);offset+=local.length+bytes.length;centralSize+=directory.length;
    }
    const end=new Uint8Array(22), e=new DataView(end.buffer);
    e.setUint32(0,0x06054b50,true);e.setUint16(8,entries.length,true);e.setUint16(10,entries.length,true);e.setUint32(12,centralSize,true);e.setUint32(16,offset,true);
    return new Blob([...chunks,...central,end],{type:'application/zip'});
  }
  window.FIELD_KIT_START = Object.freeze({stages,preparation,launch,guide,zip});
})();
