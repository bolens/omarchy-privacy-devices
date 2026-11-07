'use strict';
// Executes the actual proposed QML JavaScript functions in a synthetic QObject
// model. It is not a Qt parser, metadata, binding-engine, or runtime proof.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, 'qml/RuntimePaletteContractTest.qml'), 'utf8');
const inventory = JSON.parse(fs.readFileSync(path.join(__dirname, 'palette_inventory.json'), 'utf8'));
const functions = [...source.matchAll(/^    function (\w+)\([^]*?^    }/gm)].map(m => ({name:m[1], source:m[0]}));
assert.equal(functions.length, 14);
function color(value) { return {toString() {return value;}}; }
function fixture(seed, fault='') {
    const queue=[], marks=[];
    let quits=0;
    const Style={resolvedFontFamily:"Resolved family "+seed, fontBaseSize:seed, fontOverrides:{caption:seed+2}, spacingOverrides:{md:seed+4},
        barOverrides:{'size-horizontal':seed+7}, barScaleWithFont:seed%2===0};
    const collector={waitForEnd:true,text:Style.resolvedFontFamily};
    Style.fcMatchProc={stdout:collector,running:false};
    Object.defineProperty(Style,'fontScale',{get(){return Math.max(1/12,this.fontBaseSize/12);}});
    const Color={colorsFile:{loaded:true},shellFile:{loaded:true},userShellFile:{loaded:true},foreground:color('#203040'),shellValues:{'bar.text':'#102030','menu.text':'#998877'}};
    if(fault==='live-color-wrapper') {
        let backing='#203040';const wrapper={toString(){return backing;}};
        Object.defineProperty(Color,'foreground',{get(){return wrapper;},set(value){backing=String(value);}});
    }
    Color.pick=(key,fallback)=>Color.shellValues[key] || fallback;
    const groups={};
    for(const [name, fields] of Object.entries(inventory)) {
        const object={};
        for(const [field,kind] of Object.entries(fields)) object[field]=kind==='string'?'non-default':kind==='color'?color('#304050'):seed+1;
        groups[name]=object;
        const [ownerName,field]=name.split('.');
        const owner=ownerName==='Style'?Style:Color;
        Object.defineProperty(owner,field,{enumerable:true,get(){return groups[name];},set(value){if(fault==='writable-owner'){groups[name]=value;}else throw new TypeError('readonly');}});
    }
    for(const field of ['baseSize','caption','body']) Object.defineProperty(groups['Style.font'],field,{enumerable:true,configurable:true,get(){
        if(field==='baseSize') return Style.fontBaseSize;
        if(field==='caption' && fault==='stale-binding') return seed+2;
        return Style.fontOverrides[field] || Style.fontBaseSize;
    }});
    Object.defineProperty(groups['Style.font'],'resolvedFamily',{enumerable:true,get(){return Style.resolvedFontFamily;}});
    Object.defineProperty(groups['Style.spacing'],'md',{enumerable:true,get(){return Style.spacingOverrides.md;}});
    Object.defineProperty(groups['Style.bar'],'sizeHorizontal',{enumerable:true,get(){return Math.max(1,Math.round(Style.barOverrides['size-horizontal']*(Style.barScaleWithFont?Style.fontScale:1)));}});
    for(const name of ['bar','popups','tooltip','notifications','menu','polkit','lock','imagePicker']) {
        const key=(name==='imagePicker'?'image-picker':name)+'.text';
        let binding=()=>Color.pick(key,Color.foreground), value;
        Object.defineProperty(groups['Color.'+name],'text',{enumerable:true,get(){return color(String(binding?binding():value));},set(next){
            if(next && next.binding) {if(fault!=='broken-restore-binding') binding=next.binding;}
            else {binding=null;value=next;}
        }});
    }
    if(fault==='missing-field') delete groups['Color.menu'].scrim;
    if(fault==='extra-field') groups['Color.menu'].unexpected=color('#ffffff');
    if(fault==='wrong-type') groups['Style.font'].family=123;
    const test={inventory,originalObjects:{},originalFields:{},saved:null,desired:null,phase:0,finished:false,fontCollector:collector};
    const context=vm.createContext({test,Commons:{Style,Color},Qt:{callLater(fn){if(!queue.includes(fn))queue.push(fn);},binding(fn){return {binding:fn};},quit(){quits++;}},console:{log(message){marks.push(message);}}});
    for(const item of functions){vm.runInContext(item.source,context);test[item.name]=context[item.name];}
    return {test,Style,Color,groups,marks,get quits(){return quits;},run(){
        test.schedule();let steps=0;
        while(queue.length && steps++<30){const fn=queue.shift();fn();if(fault==='identity-change' && test.phase===1)groups['Color.bar']={...groups['Color.bar']};}
        assert(steps<30,'unbounded scheduling');
        return test.finished;
    }};
}
let passed=0;
function check(name,fn){fn();passed++;console.log('PASS '+name);}
for(const seed of [9,12,23]) check('actual functions complete and restore nondefault seed '+seed,()=>{
    const f=fixture(seed), refs={font:f.Style.fontOverrides,space:f.Style.spacingOverrides,bar:f.Style.barOverrides,colors:f.Color.shellValues};
    assert.equal(f.run(),true);assert.equal(f.quits,1);assert.deepEqual(f.marks,['PALETTE_QML_CONTRACT_OK']);
    assert.equal(f.Style.fontBaseSize,seed);assert.equal(f.Style.fontOverrides,refs.font);assert.equal(f.Style.spacingOverrides,refs.space);assert.equal(f.Style.barOverrides,refs.bar);assert.equal(f.Color.shellValues,refs.colors);
    // After successful restoration, the original fallback binding remains live.
    f.Color.shellValues={};f.Color.foreground=color('#112233');
    assert.equal(String(f.Color.bar.text),'#112233');
});
for(const fault of ['missing-field','extra-field','wrong-type','writable-owner','identity-change'])check('reject '+fault,()=>{const f=fixture(12,fault);assert.throws(()=>f.run());assert.equal(f.quits,0);assert.deepEqual(f.marks,[]);});
for(const fault of ['stale-binding','broken-restore-binding'])check('wait without success on '+fault,()=>{const f=fixture(12,fault);assert.equal(f.run(),false);assert.equal(f.quits,0);assert.deepEqual(f.marks,[]);});
check('all 98 individual type regressions reject',()=>{
 for(const [name,fields] of Object.entries(inventory)) for(const [field,kind] of Object.entries(fields)) {
  const f=fixture(12);const target=f.groups[name];
  f.groups[name]=new Proxy(target,{get(object,key){return key===field ? (kind==='string'?123:'wrong type') : Reflect.get(object,key);}});
  assert.throws(()=>f.run(),undefined,name+'.'+field);assert.equal(f.quits,0);
 }
});
for(const file of ['colorsFile','shellFile','userShellFile']) check('wait for actual '+file+' then snapshot late vendor state',()=>{
 const f=fixture(12);f.Color[file].loaded=false;
 const before=f.Style.fontOverrides;
 assert.equal(f.run(),false);assert.equal(f.test.phase,0);assert.equal(f.test.saved,null);
 assert.equal(f.Style.fontOverrides,before);assert.deepEqual(f.marks,[]);
 // Model the real asynchronous vendor merge while startup is still pending.
 f.Style.fontBaseSize=19;f.Style.fontOverrides={caption:29};f.Color.foreground=color('#aa1122');
 f.Color.shellValues={'bar.text':'#667788'};
 const loadedFont=f.Style.fontOverrides,loadedColors=f.Color.shellValues;
 f.Color[file].loaded=true;
 assert.equal(f.run(),true);assert.equal(f.test.saved.fontBaseSize,19);
 assert.equal(f.Style.fontOverrides,loadedFont);assert.equal(f.Color.shellValues,loadedColors);
 assert.equal(String(f.Color.foreground),'#aa1122');assert.equal(f.quits,1);
});
check('all three file loads required, partial event does not mutate',()=>{
 const f=fixture(12);f.Color.shellFile.loaded=false;f.Color.userShellFile.loaded=false;
 assert.equal(f.run(),false);f.Color.shellFile.loaded=true;
 assert.equal(f.run(),false);assert.equal(f.test.phase,0);assert.equal(f.test.saved,null);
 f.Color.userShellFile.loaded=true;assert.equal(f.run(),true);
});
check('empty font resolution waits for matching completed collector state',()=>{
 const f=fixture(12);f.Style.resolvedFontFamily='  ';f.test.fontCollector.text='  ';
 assert.equal(f.run(),false);assert.equal(f.test.saved,null);
 const resolved='Some other resolved family';
 f.test.fontCollector.text=resolved+'\n';f.Style.resolvedFontFamily=resolved;
 f.Style.fcMatchProc.running=false;
 assert.equal(f.run(),true);
 assert.equal(f.test.originalFields['Style.font'].resolvedFamily,resolved);
});
check('delayed actual font resolution waits before snapshot and completes one roundtrip',()=>{
 const f=fixture(12), collector=f.test.fontCollector;
 assert.equal(f.Style.fcMatchProc.stdout,collector);
 f.Style.resolvedFontFamily='monospace';collector.text='';f.Style.fcMatchProc.running=true;
 const refs={font:f.Style.fontOverrides,space:f.Style.spacingOverrides,bar:f.Style.barOverrides,colors:f.Color.shellValues};
 const before=f.test.fields();
 assert.equal(f.run(),false);assert.equal(f.test.phase,0);assert.equal(f.test.saved,null);assert.equal(f.test.desired,null);
 assert.deepEqual(f.test.fields(),before);assert.equal(Object.keys(f.test.originalObjects).length,0);
 assert.equal(f.quits,0);assert.deepEqual(f.marks,[]);
 const resolved='DejaVu Sans Mono';
 collector.text=resolved+'\n';f.Style.resolvedFontFamily=resolved;f.Style.fcMatchProc.running=false;
 assert.equal(f.run(),true);assert.equal(f.test.phase,3);
 assert.equal(f.test.originalFields['Style.font'].resolvedFamily,resolved);
 assert.equal(JSON.stringify(f.test.fields()),JSON.stringify(f.test.originalFields));
 assert.equal(f.Style.fontBaseSize,12);assert.equal(f.Style.fontOverrides,refs.font);
 assert.equal(f.Style.spacingOverrides,refs.space);assert.equal(f.Style.barOverrides,refs.bar);assert.equal(f.Color.shellValues,refs.colors);
 assert.equal(f.quits,1);assert.deepEqual(f.marks,['PALETTE_QML_CONTRACT_OK']);
 // A further event cannot repeat the completed transaction or its marker.
 assert.equal(f.run(),true);assert.equal(f.quits,1);assert.equal(f.marks.length,1);
});
for(const state of ['never-started-empty','in-flight-cached-text','mismatched-output','stream-not-final','null-collector']) check('font readiness rejects '+state,()=>{
 const f=fixture(12), collector=f.test.fontCollector;
 if(state==='never-started-empty')collector.text='';
 else if(state==='in-flight-cached-text')f.Style.fcMatchProc.running=true;
 else if(state==='mismatched-output')collector.text='Another resolved font';
 else if(state==='stream-not-final')collector.waitForEnd=false;
 else {f.test.fontCollector=null;f.Style.fcMatchProc.stdout=null;}
 const before=f.test.fields(), refs={font:f.Style.fontOverrides,colors:f.Color.shellValues};
 assert.equal(f.run(),false);assert.equal(f.test.phase,0);assert.equal(f.test.saved,null);assert.equal(f.test.desired,null);
 assert.deepEqual(f.test.fields(),before);assert.equal(f.Style.fontOverrides,refs.font);assert.equal(f.Color.shellValues,refs.colors);
 assert.equal(f.quits,0);assert.deepEqual(f.marks,[]);
 // Matching completed real output satisfies readiness after each rejected state.
 f.test.fontCollector=collector;f.Style.fcMatchProc.stdout=collector;
 collector.waitForEnd=true;collector.text=f.Style.resolvedFontFamily;f.Style.fcMatchProc.running=false;
 assert.equal(f.run(),true);assert.equal(f.quits,1);assert.deepEqual(f.marks,['PALETTE_QML_CONTRACT_OK']);
});
check('all readiness signal handlers schedule without polling or success on failure',()=>{
 for(const file of ['colorsFile','shellFile','userShellFile']) {
  const block=source.match(new RegExp('target: Commons\\.Color\\.'+file+'([^]*?)^    }','m'));
  assert(block);assert(block[1].includes('function onLoaded() { test.schedule() }'));
  assert(block[1].includes('function onLoadFailed() { test.schedule() }'));
 }
 assert(source.includes('function onResolvedFontFamilyChanged() { test.schedule() }'));
 assert(source.indexOf('if (!test.startupReady()) return')<source.indexOf('test.originalObjects = test.groups()'));
});
check('restore an immutable scalar when Qt exposes a live color-property wrapper',()=>{
 const f=fixture(12,'live-color-wrapper');
 assert.equal(f.run(),true);assert.equal(f.test.phase,3);assert.equal(f.quits,1);
 assert.equal(typeof f.test.saved.foreground,'string');
 assert.equal(f.test.saved.foreground,'#203040');assert.equal(String(f.Color.foreground),'#203040');
 assert.deepEqual(f.marks,['PALETTE_QML_CONTRACT_OK']);
});
check('single natural marker and failure-only deadline',()=>{
 assert.equal((source.match(/console\.log\("PALETTE_QML_CONTRACT_OK"\)/g)||[]).length,1);
 assert.equal((source.match(/Qt\.quit\(\)/g)||[]).length,1);
 assert(source.includes('interval: 4000\n        running: !test.finished'));
 assert(!/\bvar\b|FixtureMono|setTimeout|sleep|ignoreUnknownSignals/.test(source.replace('readonly property var inventory','').replace(/property var \w+/g,'')));
});
console.log(JSON.stringify({passed,kind:'synthetic actual-function contract; no Qt runtime claim'}));
