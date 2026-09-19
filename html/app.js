const app=document.getElementById('app');
const bindList=document.getElementById('bindList');
const empty=document.getElementById('empty');
const count=document.getElementById('count');
const search=document.getElementById('search');
const notice=document.getElementById('notice');
const editor=document.getElementById('editor');
const editorTitle=document.getElementById('editorTitle');
const keyCapture=document.getElementById('keyCapture');
const keyValue=document.getElementById('keyValue');
const commandInput=document.getElementById('commandInput');
const editorError=document.getElementById('editorError');
const confirmModal=document.getElementById('confirm');
const confirmText=document.getElementById('confirmText');
let binds=[],maxBinds=50,editingId=null,selectedKey='',pendingDeleteId=null,capturing=false,noticeTimer=null;

const KEY_MAP={Escape:'ESCAPE',Enter:'RETURN',Backspace:'BACK',Tab:'TAB',Space:'SPACE',ArrowUp:'UP',ArrowDown:'DOWN',ArrowLeft:'LEFT',ArrowRight:'RIGHT',Home:'HOME',End:'END',PageUp:'PAGEUP',PageDown:'PAGEDOWN',Insert:'INSERT',Delete:'DELETE',Pause:'PAUSE',CapsLock:'CAPITAL',NumLock:'NUMLOCK',ScrollLock:'SCROLL',ShiftLeft:'LSHIFT',ShiftRight:'RSHIFT',ControlLeft:'LCONTROL',ControlRight:'RCONTROL',AltLeft:'LMENU',AltRight:'RMENU',MetaLeft:'LWIN',MetaRight:'RWIN',ContextMenu:'APPS',NumpadMultiply:'MULTIPLY',NumpadAdd:'ADD',NumpadSubtract:'SUBTRACT',NumpadDecimal:'DECIMAL',NumpadDivide:'DIVIDE',NumpadEnter:'NUMPADENTER'};

function post(name,data){return fetch('https://'+GetParentResourceName()+'/'+name,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data||{})}).then(r=>r.json())}
function prettyKey(key){const n={LCONTROL:'L Ctrl',RCONTROL:'R Ctrl',LMENU:'L Alt',RMENU:'R Alt',LSHIFT:'L Shift',RSHIFT:'R Shift',RETURN:'Enter',CAPITAL:'Caps Lock',PAGEUP:'Page Up',PAGEDOWN:'Page Down',NUMPADENTER:'Num Enter'};return n[key]||key}
function keyFromEvent(e){
    if(KEY_MAP[e.code])return KEY_MAP[e.code];
    if(/^Key[A-Z]$/.test(e.code))return e.code.slice(3);
    if(/^Digit[0-9]$/.test(e.code))return e.code.slice(5);
    if(/^F([1-9]|1[0-9]|2[0-4])$/.test(e.code))return e.code;
    if(/^Numpad[0-9]$/.test(e.code))return e.code.toUpperCase();
    const p={Semicolon:'SEMICOLON',Equal:'EQUALS',Comma:'COMMA',Minus:'MINUS',Period:'PERIOD',Slash:'SLASH',Backquote:'GRAVE',BracketLeft:'LBRACKET',BracketRight:'RBRACKET',Backslash:'BACKSLASH',Quote:'APOSTROPHE'};
    return p[e.code]||'';
}
function showNotice(message){clearTimeout(noticeTimer);notice.textContent=message;notice.classList.remove('hidden');noticeTimer=setTimeout(()=>notice.classList.add('hidden'),3500)}
function showEditorError(message){editorError.textContent=message||'';editorError.classList.toggle('hidden',!message)}
function escapeHtml(v){return String(v).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#039;')}
function render(){
    const term=search.value.trim().toLowerCase();
    const filtered=binds.filter(b=>!term||b.key.toLowerCase().includes(term)||b.command.toLowerCase().includes(term));
    count.textContent=binds.length+' / '+maxBinds;
    bindList.innerHTML='';
    filtered.forEach(bind=>{
        const row=document.createElement('div');row.className='bind-row';
        row.innerHTML='<div><span class="bind-key">'+escapeHtml(prettyKey(bind.key))+'</span></div>'+
            '<div class="bind-command"><strong>/'+escapeHtml(bind.command)+'</strong><small>Bind #'+bind.id+'</small></div>'+
            '<div class="row-actions"><button class="small-btn edit" data-id="'+bind.id+'">Editar</button><button class="small-btn delete" data-id="'+bind.id+'">Eliminar</button></div>';
        bindList.appendChild(row);
    });
    const noResults=filtered.length===0;
    empty.classList.toggle('hidden',!noResults);bindList.classList.toggle('hidden',noResults);
    if(noResults&&term){empty.querySelector('h2').textContent='No se encontraron binds';empty.querySelector('p').textContent='Prueba otra búsqueda.'}
    else if(noResults){empty.querySelector('h2').textContent='No tienes binds configurados';empty.querySelector('p').textContent='Agrega tu primera tecla personalizada.'}
}
function openEditor(bind){
    editingId=bind?bind.id:null;selectedKey=bind?bind.key:'';
    editorTitle.textContent=bind?'Editar bind':'Nuevo bind';keyValue.textContent=selectedKey?prettyKey(selectedKey):'Presiona una tecla';commandInput.value=bind?bind.command:'';showEditorError('');editor.classList.remove('hidden');
}
function closeEditor(){capturing=false;keyCapture.classList.remove('capturing');editor.classList.add('hidden');showEditorError('')}
function startCapture(){capturing=true;keyCapture.classList.add('capturing');keyValue.textContent='Presiona una tecla...';showEditorError('')}
function finishCapture(key){if(!key){showEditorError('No se pudo identificar esa tecla.');return}selectedKey=key;keyValue.textContent=prettyKey(key);capturing=false;keyCapture.classList.remove('capturing')}
function saveEditor(){
    if(!selectedKey){showEditorError('Selecciona una tecla.');return}
    const command=commandInput.value.trim();
    if(!command){showEditorError('Escribe el comando que quieres ejecutar.');commandInput.focus();return}
    const duplicate=binds.find(b=>b.key===selectedKey&&b.id!==editingId);
    if(duplicate){showEditorError('La tecla '+prettyKey(selectedKey)+' ya está asignada.');return}
    const callback=editingId?'editBind':'createBind';
    const payload=editingId?{id:editingId,key:selectedKey,command:command}:{key:selectedKey,command:command};
    post(callback,payload).then(result=>{
        if(!result.ok){showEditorError(result.error||'No se pudo guardar el bind.');return}
        binds=result.binds||[];maxBinds=result.maxBinds||maxBinds;closeEditor();render();
    }).catch(()=>showEditorError('No se pudo comunicar con pv_keybinder.'));
}
function requestDelete(id){const bind=binds.find(b=>b.id===id);if(!bind)return;pendingDeleteId=id;confirmText.textContent='¿Quieres eliminar '+prettyKey(bind.key)+' → /'+bind.command+'?';confirmModal.classList.remove('hidden')}
function closeConfirm(){pendingDeleteId=null;confirmModal.classList.add('hidden')}
function deletePending(){if(!pendingDeleteId)return;post('deleteBind',{id:pendingDeleteId}).then(result=>{if(!result.ok){showNotice(result.error||'No se pudo eliminar el bind.');return}binds=result.binds||[];maxBinds=result.maxBinds||maxBinds;closeConfirm();render()}).catch(()=>showNotice('No se pudo comunicar con pv_keybinder.'))}
function closeMenu(){post('close').catch(()=>{})}

document.getElementById('closeBtn').addEventListener('click',closeMenu);
document.getElementById('editorClose').addEventListener('click',closeEditor);
document.getElementById('cancelBtn').addEventListener('click',closeEditor);
document.getElementById('addBtn').addEventListener('click',()=>{if(binds.length>=maxBinds){showNotice('Has alcanzado el máximo de '+maxBinds+' binds.');return}openEditor()});
document.getElementById('saveBtn').addEventListener('click',saveEditor);
document.getElementById('confirmCancel').addEventListener('click',closeConfirm);
document.getElementById('confirmDelete').addEventListener('click',deletePending);
keyCapture.addEventListener('click',startCapture);
search.addEventListener('input',render);
bindList.addEventListener('click',event=>{const button=event.target.closest('button');if(!button)return;const id=Number(button.dataset.id);const bind=binds.find(b=>b.id===id);if(!bind)return;if(button.classList.contains('edit'))openEditor(bind);if(button.classList.contains('delete'))requestDelete(id)});
document.addEventListener('keydown',event=>{
    if(app.classList.contains('hidden'))return;
    if(capturing){event.preventDefault();event.stopPropagation();if(event.code==='Escape'){capturing=false;keyCapture.classList.remove('capturing');keyValue.textContent=selectedKey?prettyKey(selectedKey):'Presiona una tecla';return}finishCapture(keyFromEvent(event));return}
    if(event.key==='Escape'){if(!editor.classList.contains('hidden')){closeEditor();return}if(!confirmModal.classList.contains('hidden')){closeConfirm();return}closeMenu()}
});
window.addEventListener('message',event=>{
    const data=event.data||{};
    if(data.action==='open'){binds=data.binds||[];maxBinds=data.maxBinds||50;app.classList.remove('hidden');render()}
    if(data.action==='refresh'){binds=data.binds||[];maxBinds=data.maxBinds||maxBinds;render()}
    if(data.action==='close'){app.classList.add('hidden');editor.classList.add('hidden');confirmModal.classList.add('hidden');capturing=false}
    if(data.action==='notify')showNotice(data.message||'')
});
