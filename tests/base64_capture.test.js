const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const {decode,qtModel}=require('./qt_base64_model.cjs');
// Decode models cover codec edges; actual Qt 6.12 compatibility is separately
// proven by the recorded 15-case old/new engine comparison.
const proposal={old:'JSON.parse(Qt.atob(payloadB64 || ""))',
 strict:'JSON.parse(Qt.atob((payloadB64 || "").split("")).toString())',
 legacyCompatible:'JSON.parse(Qt.atob((payloadB64 || "").replace(/[^A-Za-z0-9+/]/g, "").split("")).toString())'};
const service=fs.readFileSync(path.join(__dirname,'..','Service.qml'),'utf8');
const signature='function beginCapture(payloadB64: string): string';
const start=service.indexOf(signature);assert.ok(start>=0);
let current;
for(let end=service.indexOf('}',start);end!==-1;end=service.indexOf('}',end+1)){
 const source=service.slice(start,end+1).replace(signature,'function beginCapture(payloadB64)');
 try{new vm.Script('('+source+')');current=source;break;}catch(error){if(!(error instanceof SyntaxError))throw error;}
}
assert.ok(current,'actual capture handler must parse as JavaScript after type removal');
assert.ok(current.includes(proposal.legacyCompatible),'capture handler must use the nondeprecated legacy-compatible decode');
const original=current.replace(proposal.legacyCompatible,proposal.old);
const owner='owner_fixture_1234567890abcdef';
function run(variant,encoded,otherOwner=''){
 const Qt=qtModel(), root={activeSessions:[],settings:{},capturePreviewActive:!!otherOwner,capturePreviewOwner:otherOwner};
 const expression=variant==='old'?proposal.old:proposal[variant];const source=original.replace(proposal.old,expression).replace('function beginCapture(payloadB64: string): string','function beginCapture(payloadB64)');
 const callback=new vm.Script('('+source+')').runInNewContext({Qt,root,Date:{now:()=>1000},Model:{sanitizeCaptureSessions:s=>s,sanitizeSettings:s=>s}});
 return {result:callback(encoded),root,deprecations:Qt.deprecated};
}
function payload(settings={label:'fixture'}){return {owner,settings,history:[],sessions:[]};}
function encode(value){return Buffer.from(JSON.stringify(value),'utf8').toString('base64');}
for(const label of ['ASCII fixture','café','汉字','Ελληνικά','snow ☃ and emoji 🦊','mixed e\u0301 / 𐐷'])test('valid UTF8JSON preserved: '+label,()=>{
 const value=payload({label,nested:{label}}),encoded=encode(value);
 for(const variant of ['old','strict','legacyCompatible']){const actual=run(variant,encoded);assert.equal(actual.result,'ok');assert.equal(actual.root.capturePreviewSettings.label,label);assert.equal(actual.root.capturePreviewOwner,owner);assert.equal(actual.deprecations,variant==='old'?1:0);}
});
test('malformed JSON, empty and undecodable junk stay invalid',()=>{
 for(const encoded of ['', '@@@', 'e30=',Buffer.from('{bad json','utf8').toString('base64')])for(const variant of ['old','strict','legacyCompatible'])assert.equal(run(variant,encoded).result,'invalid');
});
test('token validation and existing other-owner busy outcome unchanged',()=>{
 for(const variant of ['old','strict','legacyCompatible']){
  assert.equal(run(variant,encode({...payload(),owner:'bad'})).result,'invalid');
  assert.equal(run(variant,encode(payload()),'different_fixture_owner_1234').result,'busy');
 }
});
test('strict malformed-base64 change is EXPLICIT, not falsely called equivalent',()=>{
 const valid=encode(payload());for(const encoded of ['@'+valid,valid+'\n',valid+'====','é'+valid,'雪'+valid]){
  assert.equal(run('old',encoded).result,'ok');assert.equal(run('strict',encoded).result,'invalid');assert.equal(run('legacyCompatible',encoded).result,'ok');
 }
});
test('compatibility filter preserves actual Qt ignored-character algorithm for deterministic perturbations',()=>{
 const valid=encode(payload({label:'🦊 café 汉字'})),junk=['@','\n',' ','=','雪','é','?'];let compared=0;
 for(let index=0;index<=valid.length;index++)for(const insertion of junk){const encoded=valid.slice(0,index)+insertion+valid.slice(index),filtered=encoded.replace(/[^A-Za-z0-9+/]/g,'').split('');assert.deepEqual(decode(encoded,false),decode(filtered,true));compared++;}
 assert.ok(compared>1000);
});
test('source body changes only the decoding expression',()=>{
 for(const variant of ['strict','legacyCompatible']){const changed=original.replace(proposal.old,proposal[variant]);assert.equal(changed.replace(proposal[variant],proposal.old),original);}
});
test('padding, nonzero tail bits, mod4=1 and truncated inputs follow exact source loop',()=>{
 for(const [encoded,hex] of [['Zg==Yg==','660620'],['Zh==','66'],['Z',''],['Zm8','666f'],['Zm9vY','666f6f'],['Zg===','66'],['Zg=YQ','660610']]){
  assert.equal(decode(encoded,false).toString('hex'),hex,encoded);
  assert.equal(decode(encoded.replace(/[^A-Za-z0-9+/]/g,'').split(''),true).toString('hex'),hex,encoded);
 }
 for(const encoded of ['Zg==Yg==','Zg===','Zg=YQ'])assert.throws(()=>decode(encoded.split(''),true));
});
