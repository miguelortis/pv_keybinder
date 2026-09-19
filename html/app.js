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
let binds=[],maxBinds=50,editingId=null,selectedKey='',pendingDeleteId=null,capturing=false,noticeTimer=null,lang='es';

const I18N={
    es:{eyebrow:'PV DEVELOPMENT',title:'Keybinder',subtitle:'Administra tus teclas y comandos locales.',search:'Buscar tecla o comando...',add:'＋ Agregar bind',close:'Cerrar',hint:'ESC para cerrar',emptyTitle:'No tienes binds configurados',emptyText:'Agrega tu primera tecla personalizada.',noResults:'No se encontraron binds',tryAgain:'Prueba otra búsqueda.',config:'CONFIGURACIÓN',newBind:'Nuevo bind',editBind:'Editar bind',key:'Tecla',pressKey:'Presiona una tecla',pressKeyNow:'Presiona una tecla...',keyHelp:'La tecla debe estar permitida por el servidor.',command:'Comando',example:'Ejemplo: e dance o inventory. No necesitas escribir la barra /.',cancel:'Cancelar',save:'Guardar',deleteTitle:'Eliminar bind',deleteQuestion:'¿Quieres eliminar este bind?',delete:'Eliminar',edit:'Editar',remove:'Eliminar',bind:'Bind',selectKey:'Selecciona una tecla.',writeCommand:'Escribe el comando que quieres ejecutar.',keyAssigned:'La tecla {key} ya está asignada.',keyUnknown:'No se pudo identificar esa tecla.',commError:'No se pudo comunicar con pv_keybinder.',max:'Has alcanzado el máximo de {max} binds.'},
    en:{eyebrow:'PV DEVELOPMENT',title:'Keybinder',subtitle:'Manage your local keys and commands.',search:'Search key or command...',add:'＋ Add bind',close:'Close',hint:'ESC to close',emptyTitle:'You have no configured binds',emptyText:'Add your first custom key.',noResults:'No binds found',tryAgain:'Try another search.',config:'CONFIGURATION',newBind:'New bind',editBind:'Edit bind',key:'Key',pressKey:'Press a key',pressKeyNow:'Press a key...',keyHelp:'The key must be allowed by the server.',command:'Command',example:'Example: e dance or inventory. You do not need to type /.',cancel:'Cancel',save:'Save',deleteTitle:'Delete bind',deleteQuestion:'Do you want to delete this bind?',delete:'Delete',edit:'Edit',remove:'Delete',bind:'Bind',selectKey:'Select a key.',writeCommand:'Enter the command you want to execute.',keyAssigned:'The key {key} is already assigned.',keyUnknown:'That key could not be identified.',commError:'Could not communicate with pv_keybinder.',max:'You have reached the maximum of {max} binds.'},
    pt:{eyebrow:'PV DEVELOPMENT',title:'Keybinder',subtitle:'Gerencie suas teclas e comandos locais.',search:'Buscar tecla ou comando...',add:'＋ Adicionar bind',close:'Fechar',hint:'ESC para fechar',emptyTitle:'Você não possui binds configurados',emptyText:'Adicione sua primeira tecla personalizada.',noResults:'Nenhum bind encontrado',tryAgain:'Tente outra busca.',config:'CONFIGURAÇÃO',newBind:'Novo bind',editBind:'Editar bind',key:'Tecla',pressKey:'Pressione uma tecla',pressKeyNow:'Pressione uma tecla...',keyHelp:'A tecla precisa ser permitida pelo servidor.',command:'Comando',example:'Exemplo: e dance ou inventory. Não é necessário digitar /.',cancel:'Cancelar',save:'Salvar',deleteTitle:'Excluir bind',deleteQuestion:'Deseja excluir este bind?',delete:'Excluir',edit:'Editar',remove:'Excluir',bind:'Bind',selectKey:'Selecione uma tecla.',writeCommand:'Digite o comando que deseja executar.',keyAssigned:'A tecla {key} já está atribuída.',keyUnknown:'Não foi possível identificar essa tecla.',commError:'Não foi possível comunicar com pv_keybinder.',max:'Você atingiu o limite de {max} binds.'}
};
function t(key,vars={}){let s=(I18N[lang]||I18N.es)[key]||I18N.es[key]||key;return s.replace(/\{(\w+)\}/g,(_,k)=>vars[k]??'')}
function applyLanguage(){
    const x=I18N[lang]||I18N.es;
    document.documentElement.lang=lang;
    document.querySelector('.eyebrow').textContent=x.eyebrow;
    document.querySelector('h1').textContent=x.title;
    document.querySelector('.topbar p').textContent=x.subtitle;
    search.placeholder=x.search;
    document.getElementById('addBtn').textContent=x.add;
    document.getElementById('closeBtn').setAttribute('aria-label',x.close);
    document.querySelector('.hint').textContent=x.hint;
    document.querySelector('#editor .eyebrow').textContent=x.config;
    document.querySelector('#editor .field label').textContent=x.key;
    document.getElementById('keyHelp').textContent=x.keyHelp;
    document.querySelectorAll('.field label')[1].textContent=x.command;
    document.querySelector('.field>small').textContent=x.example;
    document.getElementById('cancelBtn').textContent=x.cancel;
    document.getElementById('saveBtn').textContent=x.save;
    document.querySelector('#confirm h2').textContent=x.deleteTitle;
    document.getElementById('confirmCancel').textContent=x.cancel;
    document.getElementById('confirmDelete').textContent=x.delete;
    document.getElementById('languageSelect').value=lang;
    if(!selectedKey) keyValue.textContent=t('pressKey');
    render();
}

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
function escapeHtml(v){return String(v).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'","&#039;")}
function render(){
    const term=search.value.trim().toLowerCase();
    const filtered=binds.filter(b=>!term||b.key.toLowerCase().includes(term)||b.command.toLowerCase().includes(term));
    count.textContent=binds.length+' / '+maxBinds;
    bindList.innerHTML='';
    filtered.forEach(bind=>{
        const row=document.createElement('div');row.className='bind-row';
        row.innerHTML='<div><span class="bind-key">'+escapeHtml(prettyKey(bind.key))+'</span></div>'+
            '<div class="bind-command"><strong>/'+escapeHtml(bind.command)+'</strong><small>'+t('bind')+' #'+bind.id+'</small></div>'+
            '<div class="row-actions"><button class="small-btn edit" data-id="'+bind.id+'">'+t('edit')+'</button><button class="small-btn delete" data-id="'+bind.id+'">'+t('remove')+'</button></div>';
        bindList.appendChild(row);
    });
    const noResults=filtered.length===0;
    empty.classList.toggle('hidden',!noResults);bindList.classList.toggle('hidden',noResults);
    if(noResults&&term){empty.querySelector('h2').textContent=t('noResults');empty.querySelector('p').textContent=t('tryAgain')}
    else if(noResults){empty.querySelector('h2').textContent=t('emptyTitle');empty.querySelector('p').textContent=t('emptyText')}
}
function openEditor(bind){
    editingId=bind?bind.id:null;selectedKey=bind?bind.key:'';
    editorTitle.textContent=bind?t('editBind'):t('newBind');
    keyValue.textContent=selectedKey?prettyKey(selectedKey):t('pressKey');
    commandInput.value=bind?bind.command:'';
    showEditorError('');
    editor.classList.remove('hidden');
}
function closeEditor(){capturing=false;keyCapture.classList.remove('capturing');editor.classList.add('hidden');showEditorError('')}
function startCapture(){capturing=true;keyCapture.classList.add('capturing');keyValue.textContent=t('pressKeyNow');showEditorError('')}
function finishCapture(key){if(!key){showEditorError(t('keyUnknown'));return}selectedKey=key;keyValue.textContent=prettyKey(key);capturing=false;keyCapture.classList.remove('capturing')}
function saveEditor(){
    if(!selectedKey){showEditorError(t('selectKey'));return}
    const command=commandInput.value.trim();
    if(!command){showEditorError(t('writeCommand'));commandInput.focus();return}
    const duplicate=binds.find(b=>b.key===selectedKey&&b.id!==editingId);
    if(duplicate){showEditorError(t('keyAssigned',{key:prettyKey(selectedKey)}));return}
    const callback=editingId?'editBind':'createBind';
    const payload=editingId?{id:editingId,key:selectedKey,command:command}:{key:selectedKey,command:command};
    post(callback,payload).then(result=>{
        if(!result.ok){showEditorError(result.error||t('commError'));return}
        binds=result.binds||[];maxBinds=result.maxBinds||maxBinds;closeEditor();render();
    }).catch(()=>showEditorError(t('commError')));
}
function requestDelete(id){const bind=binds.find(b=>b.id===id);if(!bind)return;pendingDeleteId=id;confirmText.textContent=t('deleteQuestion').replace('bind',prettyKey(bind.key)+' → /'+bind.command);confirmModal.classList.remove('hidden')}
function closeConfirm(){pendingDeleteId=null;confirmModal.classList.add('hidden')}
function deletePending(){if(!pendingDeleteId)return;post('deleteBind',{id:pendingDeleteId}).then(result=>{if(!result.ok){showNotice(result.error||t('commError'));return}binds=result.binds||[];maxBinds=result.maxBinds||maxBinds;closeConfirm();render()}).catch(()=>showNotice(t('commError')))}

function closeMenu(){post('close').catch(()=>{})}

document.getElementById('languageSelect').addEventListener('change',event=>{
    const requested=event.target.value;
    post('setLanguage',{language:requested}).then(result=>{
        if(result.ok){lang=result.language||requested;applyLanguage()}
    }).catch(()=>showNotice(t('commError')));
});
document.getElementById('closeBtn').addEventListener('click',closeMenu);
document.getElementById('editorClose').addEventListener('click',closeEditor);
document.getElementById('cancelBtn').addEventListener('click',closeEditor);
document.getElementById('addBtn').addEventListener('click',()=>{if(binds.length>=maxBinds){showNotice(t('max',{max:maxBinds}));return}openEditor()});
document.getElementById('saveBtn').addEventListener('click',saveEditor);
document.getElementById('confirmCancel').addEventListener('click',closeConfirm);
document.getElementById('confirmDelete').addEventListener('click',deletePending);
keyCapture.addEventListener('click',startCapture);
search.addEventListener('input',render);
bindList.addEventListener('click',event=>{const button=event.target.closest('button');if(!button)return;const id=Number(button.dataset.id);const bind=binds.find(b=>b.id===id);if(!bind)return;if(button.classList.contains('edit'))openEditor(bind);if(button.classList.contains('delete'))requestDelete(id)});
document.addEventListener('keydown',event=>{
    if(app.classList.contains('hidden'))return;
    if(capturing){event.preventDefault();event.stopPropagation();if(event.code==='Escape'){capturing=false;keyCapture.classList.remove('capturing');keyValue.textContent=selectedKey?prettyKey(selectedKey):t('pressKey');return}finishCapture(keyFromEvent(event));return}
    if(event.key==='Escape'){if(!editor.classList.contains('hidden')){closeEditor();return}if(!confirmModal.classList.contains('hidden')){closeConfirm();return}closeMenu()}
});
window.addEventListener('message',event=>{
    const data=event.data||{};
    if(data.action==='open'){binds=data.binds||[];maxBinds=data.maxBinds||50;lang=data.language||lang;app.classList.remove('hidden');applyLanguage()}
    if(data.action==='refresh'){binds=data.binds||[];maxBinds=data.maxBinds||maxBinds;lang=data.language||lang;applyLanguage()}
    if(data.action==='close'){app.classList.add('hidden');editor.classList.add('hidden');confirmModal.classList.add('hidden');capturing=false}
    if(data.action==='notify')showNotice(data.message||'')
});
