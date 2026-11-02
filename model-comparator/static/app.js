const $ = (id) => document.getElementById(id);

const els = {
  status: $('status'),
  models: $('models'),
  drop: $('drop'),
  file: $('file'),
  preview: $('preview'),
  dropHint: $('dropHint'),
  fileInfo: $('fileInfo'),
  analyze: $('analyze'),
  reset: $('reset'),
  placeholder: $('placeholder'),
  loading: $('loading'),
  error: $('error'),
  result: $('result'),
  topLabel: $('topLabel'),
  topProb: $('topProb'),
  bars: $('bars'),
  meta: $('meta'),
  cmpPlaceholder: $('cmpPlaceholder'),
  cmpLoading: $('cmpLoading'),
  cmpResult: $('cmpResult'),
  cmpSummary: $('cmpSummary'),
  cmpHead: $('cmpHead'),
  cmpBody: $('cmpBody'),
};

let selected = null;
let models = [];
let modelId = null;
let results = null; // Map: id model -> hasil prediksi, untuk gambar yang sedang dipilih

const pct = (p) => (p * 100).toFixed(1) + '%';
const shortLabel = (label) => label.split(' · ')[0];

function showPanel(name) {
  els.placeholder.hidden = name !== 'placeholder';
  els.loading.hidden = name !== 'loading';
  els.result.hidden = name !== 'result';
  els.error.hidden = name !== 'error';
}

function showCompare(name) {
  els.cmpPlaceholder.hidden = name !== 'placeholder';
  els.cmpLoading.hidden = name !== 'loading';
  els.cmpResult.hidden = name !== 'result';
}

function clearResults() {
  results = null;
  showPanel('placeholder');
  showCompare('placeholder');
}

function setFile(file) {
  if (!file || !file.type.startsWith('image/')) {
    showPanel('error');
    els.error.textContent = 'File harus berupa gambar.';
    return;
  }
  selected = file;
  if (els.preview.src) URL.revokeObjectURL(els.preview.src);
  els.preview.src = URL.createObjectURL(file);
  els.preview.hidden = false;
  els.dropHint.hidden = true;
  els.fileInfo.hidden = false;
  els.fileInfo.textContent = `${file.name} · ${(file.size / 1024).toFixed(0)} KB`;
  els.analyze.disabled = false;
  els.reset.disabled = false;
  clearResults();
}

function reset() {
  selected = null;
  els.file.value = '';
  if (els.preview.src) URL.revokeObjectURL(els.preview.src);
  els.preview.removeAttribute('src');
  els.preview.hidden = true;
  els.dropHint.hidden = false;
  els.fileInfo.hidden = true;
  els.analyze.disabled = true;
  els.reset.disabled = true;
  clearResults();
}

function renderResult(data) {
  els.topLabel.textContent = data.top.label;
  els.topProb.textContent = pct(data.top.probability);

  els.bars.replaceChildren(
    ...data.predictions.map((p) => {
      const row = document.createElement('li');
      row.className = 'bar-row' + (p.index === data.top.index ? ' top' : '');
      row.innerHTML = '<span class="name"></span><div class="bar-track"><div class="bar-fill"></div></div><span class="val"></span>';
      row.querySelector('.name').textContent = p.label;
      row.querySelector('.val').textContent = pct(p.probability);
      row.querySelector('.bar-fill').dataset.width = (p.probability * 100).toFixed(2);
      return row;
    })
  );
  els.meta.textContent = `Model: ${data.model.name} · waktu inferensi: ${data.inference_ms} ms`;
  showPanel('result');

  // Set width di frame berikutnya supaya transisi bar jalan.
  requestAnimationFrame(() => {
    els.bars.querySelectorAll('.bar-fill').forEach((el) => { el.style.width = el.dataset.width + '%'; });
  });
}

function renderSelected() {
  if (results && results.has(modelId)) renderResult(results.get(modelId));
  else showPanel('placeholder');
  els.cmpBody.querySelectorAll('tr').forEach((tr) => tr.classList.toggle('sel', tr.dataset.id === modelId));
}

function selectModel(id) {
  modelId = id;
  const input = [...els.models.querySelectorAll('input')].find((i) => i.value === id);
  if (input) input.checked = true;
  renderSelected();
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function renderCompare() {
  const list = models.map((m) => results.get(m.id)).filter(Boolean);
  if (!list.length) return;

  // Header kolom pakai nama label bersama kalau semua model labelnya sama, kalau tidak pakai nomor kelas.
  const first = list[0].predictions;
  const sameLabels = list.every((r) =>
    r.predictions.length === first.length && r.predictions.every((p, i) => p.label === first[i].label)
  );
  const cols = sameLabels ? first.length : Math.max(...list.map((r) => r.predictions.length));
  const labelOf = (i) => (sameLabels ? first[i].label : `Kelas ${i}`);

  // Ringkasan: berapa model yang memilih kelas yang sama.
  const votes = new Map();
  list.forEach((r) => votes.set(r.top.index, (votes.get(r.top.index) || 0) + 1));
  const maxVotes = Math.max(...votes.values());
  const winners = [...votes].filter(([, n]) => n === maxVotes).map(([i]) => i);
  if (winners.length === 1 && maxVotes === list.length) {
    els.cmpSummary.textContent = `Semua ${list.length} model sepakat: ${labelOf(winners[0])}`;
  } else if (winners.length === 1) {
    els.cmpSummary.textContent = `${maxVotes} dari ${list.length} model memprediksi ${labelOf(winners[0])}`;
  } else {
    els.cmpSummary.textContent = `Pendapat model terbagi: ${winners.map(labelOf).join(' / ')} masing-masing ${maxVotes} dari ${list.length} model`;
  }

  const headRow = document.createElement('tr');
  headRow.append(el('th', '', 'Model'));
  for (let i = 0; i < cols; i++) {
    const th = el('th');
    const [code, ...rest] = labelOf(i).split(' · ');
    th.append(code);
    if (rest.length) th.append(el('small', '', rest.join(' · ')));
    headRow.append(th);
  }
  headRow.append(el('th', '', 'Prediksi'), el('th', '', 'Waktu'));
  els.cmpHead.replaceChildren(headRow);

  els.cmpBody.replaceChildren(
    ...list.map((r) => {
      const tr = el('tr');
      tr.dataset.id = r.model.id;
      tr.tabIndex = 0;
      tr.classList.toggle('sel', r.model.id === modelId);

      const th = el('th', '', r.model.name);
      th.scope = 'row';
      th.append(el('small', '', r.model.description));
      tr.append(th);

      for (let i = 0; i < cols; i++) {
        const p = r.predictions[i];
        const td = el('td', 'heat' + (p && p.index === r.top.index ? ' top' : ''), p ? pct(p.probability) : '–');
        td.style.setProperty('--p', p ? p.probability : 0);
        tr.append(td);
      }

      const pred = el('td', 'pred', shortLabel(r.top.label));
      pred.title = r.top.label;
      tr.append(pred, el('td', 'ms', `${r.inference_ms} ms`));

      tr.addEventListener('click', () => selectModel(r.model.id));
      tr.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); selectModel(r.model.id); }
      });
      return tr;
    })
  );
  showCompare('result');
}

async function analyze() {
  if (!selected) return;
  showPanel('loading');
  showCompare('loading');
  els.analyze.disabled = true;

  const body = new FormData();
  body.append('image', selected);

  try {
    const res = await fetch('/api/compare', { method: 'POST', body });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || `Server error (${res.status})`);
    results = new Map(data.results.map((r) => [r.model.id, r]));
    renderCompare();
    renderSelected();
  } catch (err) {
    results = null;
    showCompare('placeholder');
    showPanel('error');
    els.error.textContent = err.message || 'Gagal menghubungi server.';
  } finally {
    els.analyze.disabled = false;
  }
}

function renderModels(list, defaultId) {
  models = list;
  modelId = defaultId;
  els.models.replaceChildren(
    ...list.map((m) => {
      const label = document.createElement('label');
      label.className = 'model-opt';
      label.innerHTML = '<input type="radio" name="model"><span class="m-name"></span><span class="m-desc"></span>';
      const input = label.querySelector('input');
      input.value = m.id;
      input.checked = m.id === defaultId;
      label.querySelector('.m-name').textContent = m.name;
      label.querySelector('.m-desc').textContent = `${m.description} · ${m.input_size.join('×')} px`;
      input.addEventListener('change', () => selectModel(m.id));
      return label;
    })
  );
}

async function loadModels() {
  try {
    const res = await fetch('/api/models');
    const info = await res.json();
    renderModels(info.models, info.default);
    els.status.dataset.state = 'ready';
    els.status.textContent = `Server siap · ${info.models.length} model`;
  } catch {
    els.status.dataset.state = 'error';
    els.status.textContent = 'Server model tidak terjangkau';
  }
}

els.file.addEventListener('change', () => setFile(els.file.files[0]));
els.analyze.addEventListener('click', analyze);
els.reset.addEventListener('click', reset);

els.drop.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); els.file.click(); }
});
['dragenter', 'dragover'].forEach((ev) =>
  els.drop.addEventListener(ev, (e) => { e.preventDefault(); els.drop.classList.add('over'); })
);
['dragleave', 'drop'].forEach((ev) =>
  els.drop.addEventListener(ev, (e) => { e.preventDefault(); els.drop.classList.remove('over'); })
);
els.drop.addEventListener('drop', (e) => setFile(e.dataTransfer.files[0]));

document.addEventListener('paste', (e) => {
  const item = [...e.clipboardData.items].find((i) => i.type.startsWith('image/'));
  if (item) setFile(item.getAsFile());
});

loadModels();
