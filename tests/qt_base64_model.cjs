// Pure model of Qt 6.12 fromBase64_helper, not a Qt runtime proof.
// Sources: qt/qtbase v6.12.0 src/corelib/text/qbytearray.cpp (fromBase64_helper);
// qt/qtdeclarative v6.12.0 src/qml/qml/qqmlbuiltinfunctions.cpp (atob) and
// src/qml/jsruntime/qv4arraybuffer.cpp (ArrayBuffer.toString UTF-8 conversion).
// Actual old/normalized equivalence is separately verified in the pinned Qt image.
const alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
function decode(input, strict=false) {
  const values=Array.isArray(input)?input:String(input).split('');
  let buffer=0, bits=0; const output=[];
  for(let i=0;i<values.length;i++){
    const value=values[i];
    if(typeof value!=='string'||value.length!==1||(strict&&value.charCodeAt(0)>255))throw Error('Invalid character');
    const char=value.charCodeAt(0)>255?'?':value;
    const digit=alphabet.indexOf(char);
    if(digit<0){
      if(strict){
        if(char!=='=')throw Error('Illegal character');
        if(values.length%4!==0)throw Error('Illegal input length');
        if(!(i===values.length-1||(i===values.length-2&&values[++i]==='=')))throw Error('Illegal padding');
      }
      continue;
    }
    buffer=(buffer<<6)|digit;bits+=6;
    if(bits>=8){bits-=8;output.push((buffer>>bits)&255);buffer&=(1<<bits)-1;}
  }
  return Buffer.from(output);
}
function qtModel(){let deprecated=0;return {get deprecated(){return deprecated;},atob(input){
  if(typeof input==='string'){deprecated++;return decode(input,false).toString('utf8');}
  const bytes=decode(input,true);return {toString(){return bytes.toString('utf8');}};
}};}
module.exports={decode,qtModel};
