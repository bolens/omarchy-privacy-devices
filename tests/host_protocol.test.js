const assert = require('node:assert/strict')
const fs = require('node:fs')
const vm = require('node:vm')
const path = require('node:path')
const protocol = {Qt: {
  color(value) { if (value !== '#123456') throw Error('invalid color'); return {valid:true,r:0.1,g:0.2,b:0.3,a:1} },
  rgba(r,g,b,a) { return {valid:true,r,g,b,a} },
  isQtObject(value) { return value && value.qmlObject === true }
}}
vm.createContext(protocol)
vm.runInContext(fs.readFileSync(path.join(__dirname,'..','BarHostProtocol.js'),'utf8'), protocol)
for (const host of [null, undefined, {}, {vertical:'true',barSize:'42',run:42,switchPanelFrom:42,shell:{serviceFor:42,updateEntryInline:42}}]) {
  assert.equal(protocol.vertical(host),false)
  assert.equal(protocol.barSize(host,24),24)
  assert.equal(protocol.color(host,'foreground','fallback'),'fallback')
  assert.equal(protocol.run(host,'command'),false)
  assert.equal(protocol.switchPanel(host,{},1),false)
  assert.equal(protocol.serviceFor(host,'test'),null)
  assert.equal(protocol.updateEntry(host,'test',{}),false)
}
for (const bad of [-1, NaN, Infinity, 1.5, 2147483648]) assert.equal(protocol.barSize({barSize:bad},24),24)
for (const bad of [false,1,{}, {valid:true,r:NaN,g:0,b:0,a:1}, {valid:false,r:0,g:0,b:0,a:1}, 'nonsense'])
  assert.equal(protocol.color({foreground:bad},'foreground','fallback'),'fallback')
assert.equal(protocol.color({foreground:'#123456'},'notAllowed','fallback'),'fallback')
const events = [], service = {}, entry = {}, owner = {}
const shell = {serviceFor(id){assert.equal(this,shell);events.push(['service',id]);return service}, updateEntryInline(id, value){assert.equal(this,shell);events.push(['update',id,value])}}
const host = {vertical:true,barSize:42,foreground:'#123456',shell,
  run(command){assert.equal(this,host);events.push(['run',command])},
  switchPanelFrom(value, direction){assert.equal(this,host);events.push(['switch',value,direction]);return true}}
assert.equal(protocol.vertical(host),true)
assert.equal(protocol.barSize(host,24),42)
assert.equal(protocol.color(host,'foreground','fallback').g,0.2)
assert.equal(protocol.run(host,'owned-command'),true)
assert.equal(protocol.switchPanel(host,owner,1),true)
assert.equal(protocol.serviceFor(host,'plugin'),service)
assert.equal(protocol.updateEntry(host,'plugin',entry),true)
assert.deepEqual(events,[['run','owned-command'],['switch',owner,1],['service','plugin'],['update','plugin',entry]])
assert.equal(protocol.windowScreen(null),null)
assert.equal(protocol.windowScreen({screen:{}}),null)
const screen={qmlObject:true};assert.equal(protocol.windowScreen({screen}),screen)
console.log('Optional host protocol null/custom/malformed values and method receivers passed')
