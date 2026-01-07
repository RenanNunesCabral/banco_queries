
(function(){
  const el = sel => document.querySelector(sel);
  const els = sel => Array.from(document.querySelectorAll(sel));

  const state = { snippets: [], theme: localStorage.getItem('sqlrepo_theme') || 'dark' };
  const KEYS = { storage: 'sqlrepo_snippets' };

  function init(){ document.body.classList.toggle('light', state.theme==='light'); load(); bind(); render(); }

  function bind(){
    el('#toggleTheme').addEventListener('click', () => { state.theme = state.theme==='light' ? 'dark' : 'light'; document.body.classList.toggle('light', state.theme==='light'); localStorage.setItem('sqlrepo_theme', state.theme); });
    el('#snippetForm').addEventListener('submit', onSave);
    el('#resetForm').addEventListener('click', resetForm);
    el('#previewBtn').addEventListener('click', showPreview);

    el('#search').addEventListener('input', render);
    el('#filterCategory').addEventListener('input', render);
    el('#filterTag').addEventListener('input', render);
    el('#clearFilters').addEventListener('click', () => { el('#search').value=''; el('#filterCategory').value=''; el('#filterTag').value=''; render(); });

    el('#exportJson').addEventListener('click', exportJson);
    el('#importJson').addEventListener('change', importJson);
  }

  function load(){ try { const raw = localStorage.getItem(KEYS.storage); state.snippets = raw ? JSON.parse(raw) : []; } catch(e){ state.snippets = []; } }
  function persist(){ localStorage.setItem(KEYS.storage, JSON.stringify(state.snippets)); }

  function normalizeSql(s){ return (s||'').replace(/\s+$/gm,''); }

  function showPreview(){ const sql = el('#code').value || ''; el('#previewCode').innerHTML = highlightSQL(sql); el('#preview').classList.remove('hidden'); }

  function onSave(ev){ ev.preventDefault(); const id = el('#snippetId').value || null; const now = new Date().toISOString(); const snippet = { id: id || String(Date.now()), title: el('#title').value.trim(), category: el('#category').value.trim(), tags: el('#tags').value.split(',').map(t=>t.trim()).filter(Boolean), description: el('#description').value.trim(), code: normalizeSql(el('#code').value), createdAt: id? undefined : now, updatedAt: now };
    if(!snippet.title || !snippet.code){ alert('Preencha ao menos Título e Código SQL.'); return; }
    if(id){ const idx = state.snippets.findIndex(s=>s.id===id); if(idx>=0) state.snippets[idx] = { ...state.snippets[idx], ...snippet }; }
    else { state.snippets.unshift(snippet); }
    persist(); resetForm(); render(); }

  function resetForm(){ el('#snippetId').value=''; el('#title').value=''; el('#category').value=''; el('#tags').value=''; el('#description').value=''; el('#code').value=''; el('#preview').classList.add('hidden'); }

  function render(){
    const q = (el('#search').value||'').toLowerCase(); const fc = (el('#filterCategory').value||'').toLowerCase(); const ft = (el('#filterTag').value||'').toLowerCase();
    const filtered = state.snippets.filter(s => { const matchQ = !q || [s.title,s.description,s.code,(s.tags||[]).join(' ')].some(v => (v||'').toLowerCase().includes(q)); const matchC = !fc || (s.category||'').toLowerCase().includes(fc); const matchT = !ft || (s.tags||[]).some(t=>t.toLowerCase().includes(ft)); return matchQ && matchC && matchT; });
    const list = el('#snippetsList'); list.innerHTML = '';
    if(filtered.length===0){ list.innerHTML = '<li class="snippet-meta">Nenhum snippet encontrado.</li>'; return; }
    filtered.forEach(s => list.appendChild(renderItem(s)));
  }

  function renderItem(s){
    const li = document.createElement('li'); li.className = 'item';
    const details = document.createElement('details'); // HTML nativo leve
    const summary = document.createElement('summary');
    const left = document.createElement('div'); left.style.display='flex'; left.style.flexDirection='column';
    const title = document.createElement('span'); title.textContent = s.title;
    const meta = document.createElement('span'); meta.className='meta'; meta.textContent = [s.category,(s.tags||[]).join(', ')].filter(Boolean).join(' • ');
    left.append(title, meta);

    const actions = document.createElement('div');
    const btnCopy = mkBtn('Copiar', ()=> copyText(s.code));
    const btnEdit = mkBtn('Editar', ()=> fillForm(s));
    const btnDel  = mkBtn('Excluir', ()=> delSnippet(s.id), 'danger');
    const btnDown = mkBtn('Baixar .sql', ()=> downloadSql(s));
    actions.append(btnCopy, btnEdit, btnDel, btnDown);

    summary.append(left, actions);

    const body = document.createElement('div'); body.className = 'body';
    const desc = document.createElement('div'); desc.className = 'snippet-meta'; desc.textContent = s.description || '';
    const pre = document.createElement('pre'); pre.className = 'code-view';
    const code = document.createElement('code'); code.className = 'code sql'; code.innerHTML = highlightSQL(s.code);
    pre.appendChild(code);

    const tagsWrap = document.createElement('div'); tagsWrap.className = 'row'; (s.tags||[]).forEach(t=>{ const span=document.createElement('span'); span.className='tag'; span.textContent=t; tagsWrap.appendChild(span); });

    body.append(desc, pre, tagsWrap);
    details.append(summary, body);
    li.append(details);
    return li;
  }

  function mkBtn(text, fn, variant){ const b=document.createElement('button'); b.className='btn small'+(variant?' '+variant:''); b.textContent=text; b.addEventListener('click', (ev)=>{ev.preventDefault(); ev.stopPropagation(); fn();}); return b; }

  function fillForm(s){ el('#snippetId').value=s.id; el('#title').value=s.title; el('#category').value=s.category||''; el('#tags').value=(s.tags||[]).join(', '); el('#description').value=s.description||''; el('#code').value=s.code||''; window.scrollTo({top:0,behavior:'smooth'}); }
  function delSnippet(id){ if(!confirm('Excluir este snippet?')) return; state.snippets = state.snippets.filter(s=>s.id!==id); persist(); render(); }

  function copyText(text){ navigator.clipboard.writeText(text).then(()=> alert('Copiado.')).catch(()=>{ const ta=document.createElement('textarea'); ta.value=text; document.body.appendChild(ta); ta.select(); document.execCommand('copy'); document.body.removeChild(ta); alert('Copiado.'); }); }
  function downloadSql(s){ const blob = new Blob([s.code], { type:'text/sql' }); const url = URL.createObjectURL(blob); const a=document.createElement('a'); a.href=url; a.download=(slug(s.title)||'snippet')+'.sql'; a.click(); URL.revokeObjectURL(url); }
  function slug(str){ return (str||'').toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/(^-|-$)/g,''); }

  /* ===== Destaque simples ===== */
  function escapeHtml(str){ return (str||'').replace(/[&<>\"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }
  function highlightSQL(sql){ let s = escapeHtml(sql); s = s.replace(/\/\*[\s\S]*?\*\//g, m => '<span class="comment">'+m+'</span>'); s = s.replace(/(^|\n)\s*--.*?(?=\n|$)/g, m => '<span class="comment">'+m+'</span>'); s = s.replace(/'([^']|'')*'/g, m => '<span class="str">'+m+'</span>'); s = s.replace(/\b\d+(\.\d+)?\b/g, m => '<span class="num">'+m+'</span>'); const KW=['SELECT','FROM','WHERE','GROUP','BY','ORDER','JOIN','LEFT','RIGHT','INNER','OUTER','ON','AS','CASE','WHEN','THEN','ELSE','END','UNION','ALL','INSERT','INTO','VALUES','UPDATE','DELETE','CREATE','DROP','ALTER','WITH','HAVING','DISTINCT','AND','OR','NOT','NULL','NVL','COALESCE','DATE','BETWEEN','LIKE','IN','IS']; const reKw=new RegExp('\\b('+KW.join('|')+')\\b','g'); s = s.replace(reKw, m => '<span class="kw">'+m+'</span>'); return s; }

  /* Exportar/Importar */
  function exportJson(){ const blob = new Blob([JSON.stringify(state.snippets, null, 2)], { type:'application/json' }); const url = URL.createObjectURL(blob); const a=document.createElement('a'); a.href=url; a.download='sql-snippets.json'; a.click(); URL.revokeObjectURL(url); }
  function importJson(ev){ const file=ev.target.files[0]; if(!file) return; const reader=new FileReader(); reader.onload=()=>{ try{ const arr=JSON.parse(reader.result); if(Array.isArray(arr)){ const map=new Map(state.snippets.map(s=>[s.id,s])); arr.forEach(s=> map.set(s.id, s)); state.snippets = Array.from(map.values()).sort((a,b)=> (b.createdAt||'').localeCompare(a.createdAt||'')); persist(); render(); alert('Importação concluída.'); } else { alert('JSON inválido.'); } } catch(e){ alert('Falha ao importar JSON.'); } }; reader.readAsText(file); }

  init();
})();
