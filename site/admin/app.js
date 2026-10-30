// Sanadi admin portal: sign in with Google (admins only), then overview,
// applications, people, lessons, reports, announcements, connecting a
// student and teacher, admins, and spreadsheet exports.
import { firebaseConfig, emulatorUser } from './config.js';
import * as data from './data.js';

const root = document.getElementById('root');
const DAY = 86400000;

// ---- Small DOM helpers (all text goes in as text, never as HTML) ----

function h(tag, attrs = {}, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v == null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
    else if (k === 'html') throw new Error('no raw html');
    else el.setAttribute(k, v === true ? '' : v);
  }
  for (const kid of kids.flat(Infinity)) {
    if (kid == null || kid === false) continue;
    el.append(kid instanceof Node ? kid : document.createTextNode(String(kid)));
  }
  return el;
}

/** Replaces an element's contents, flattening lists and skipping empties. */
function fill(el, ...kids) {
  el.replaceChildren(...kids.flat(Infinity).filter((k) => k != null && k !== false)
    .map((k) => (k instanceof Node ? k : document.createTextNode(String(k)))));
}

function toast(text) {
  const t = document.getElementById('toast');
  t.textContent = text;
  t.hidden = false;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => (t.hidden = true), 3200);
}

/** A dialog with OK and Cancel, optionally asking for a reason. */
function ask(title, body, okLabel, { danger = false, reason = null, reasonRequired = false } = {}) {
  return new Promise((resolve) => {
    const area = reason ? h('textarea', { id: 'dlg-reason', placeholder: reason, maxlength: 1000 }) : null;
    const dlg = h('dialog', {},
      h('form', { method: 'dialog' },
        h('h2', {}, title),
        body ? h('p', { class: 'muted' }, body) : null,
        area ? h('label', { class: 'f' }, reason, area) : null,
        h('div', { class: 'row', style: 'justify-content:flex-end' },
          h('button', { class: 'btn ghost', value: 'cancel', type: 'submit' }, 'Cancel'),
          h('button', { class: danger ? 'btn warn' : 'btn', value: 'ok', type: 'submit' }, okLabel))));
    dlg.addEventListener('close', () => {
      dlg.remove();
      resolve(dlg.returnValue === 'ok' ? { ok: true, reason: area ? area.value.trim() : '' } : { ok: false });
    });
    dlg.querySelector('form').addEventListener('submit', (e) => {
      if (e.submitter?.value === 'ok' && reasonRequired && area && !area.value.trim()) {
        e.preventDefault();
        area.focus();
      }
    });
    document.body.append(dlg);
    dlg.showModal();
  });
}

async function act(label, fn) {
  try {
    await fn();
    toast(label);
    return true;
  } catch (e) {
    console.error(e);
    toast(`Couldn't do that: ${e.code || e.message}`);
    return false;
  }
}

// ---- Formatting ----

const dateFmt = new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
const timeFmt = new Intl.DateTimeFormat('en-GB', { hour: '2-digit', minute: '2-digit' });
const regions = new Intl.DisplayNames(['en'], { type: 'region' });
const fmtDate = (d) => (d ? dateFmt.format(d) : '—');
const fmtDateTime = (d) => (d ? `${dateFmt.format(d)}, ${timeFmt.format(d)}` : '—');
const fmtNum = (n) => (n == null ? '—' : n.toLocaleString('en'));
function ago(d) {
  if (!d) return '—';
  const days = Math.floor((startOfDay(new Date()) - startOfDay(d)) / DAY);
  if (days <= 0) return 'Today';
  if (days === 1) return 'Yesterday';
  if (days < 30) return `${days} days ago`;
  return fmtDate(d);
}
const startOfDay = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
const country = (c) => {
  try { return c ? regions.of(c) : '—'; } catch { return c; }
};
const genderL = (g) => (g === 'female' ? 'Sister' : g === 'male' ? 'Brother' : '—');
const ratingL = ['Not good', 'OK', 'Good'];
function roleL(p) {
  if (p.role === 'student') return 'Student';
  if (p.role === 'teacher') {
    return { approved: 'Teacher', pending: 'Applicant', rejected: 'Not approved' }[p.appStatus] || 'Teacher (no application)';
  }
  return 'Signing up';
}
const isArabic = (s) => /[؀-ۿ]/.test(s || '');

function avatar(p, big = false) {
  const el = h('span', { class: big ? 'avatar big' : 'avatar' });
  const a = p.avatar || '';
  if (a && !a.startsWith('photo:')) el.append(h('img', { src: `avatars/${a}.svg`, alt: '' }));
  else el.textContent = (p.name || '?').trim().charAt(0).toUpperCase() || '?';
  return el;
}
const who = (p) => h('span', { class: 'who' }, avatar(p), h('span', { class: isArabic(p.name) ? 'ar' : '' }, p.name || '(no name)'));

// ---- Data cache (refreshed on demand) ----

const cache = {};
async function load(key, fn, fresh = false) {
  if (fresh || !(key in cache)) cache[key] = await fn();
  return cache[key];
}
const peopleNow = (fresh) => load('people', data.people, fresh);
const byUid = async () => new Map((await peopleNow()).map((p) => [p.uid, p]));
function forget(...keys) {
  for (const k of keys) delete cache[k];
}

// ---- Shell and routing ----

let me = null;
const pages = [
  ['overview', 'Overview'],
  ['applications', 'Applications'],
  ['people', 'People'],
  ['lessons', 'Lessons'],
  ['reports', 'Reports'],
  ['announcements', 'Announcements'],
  ['connect', 'Connect'],
  ['admins', 'Admins'],
  ['export', 'Export'],
];

function shell(active, badges, content) {
  return h('div', { class: 'app' },
    h('nav', { class: 'side', 'aria-label': 'Admin sections' },
      h('div', { class: 'logo' }, h('img', { src: 'sanadi-mark-cream.png', alt: '' }), 'Sanadi Admin'),
      pages.map(([id, label]) => h('a', { href: `#${id}`, class: id === active ? 'on' : null },
        label, badges[id] ? h('span', { class: 'badge' }, badges[id]) : null)),
      h('div', { class: 'foot' },
        h('span', {}, me.name || me.email || 'Admin'),
        h('button', { onclick: () => data.logOut() }, 'Sign out'))),
    h('main', {}, content));
}

let badges = {};
async function refreshBadges() {
  const c = await data.liveCounts();
  badges = { applications: c.pending || 0, reports: c.openReports || 0 };
  return c;
}

async function route() {
  if (!me) return;
  const [page, arg] = (location.hash.slice(1) || 'overview').split('/');
  const view = views[page] || views.overview;
  // Keep the side bar's counts current (four cheap counts on the server).
  await refreshBadges().catch(() => {});
  const main = h('div', { class: 'grid' }, h('p', { class: 'loading' }, 'Loading…'));
  fill(root, shell(page === 'person' ? 'people' : page, badges, main));
  try {
    const content = await view(arg);
    fill(main, ...[content].flat());
  } catch (e) {
    console.error(e);
    fill(main, h('div', { class: 'card' }, h('h2', {}, 'Something went wrong'),
      h('p', { class: 'muted' }, String(e.code || e.message || e))));
  }
}
window.addEventListener('hashchange', route);

const header = (title, ...right) => h('div', { class: 'head' }, h('h1', {}, title), h('div', { class: 'row' }, right));
const refreshBtn = (keys) => h('button', { class: 'btn ghost', onclick: async () => { forget(...keys); await refreshBadges(); route(); } }, 'Refresh');

// ---- Charts ----

const charts = [];
function chart(title, config) {
  const canvas = h('canvas', { role: 'img', 'aria-label': title });
  const card = h('div', { class: 'card' }, h('h3', {}, title), canvas);
  requestAnimationFrame(() => {
    if (!window.Chart) return;
    const css = getComputedStyle(document.documentElement);
    const ink = css.getPropertyValue('--muted').trim();
    const line = css.getPropertyValue('--line').trim();
    charts.push(new window.Chart(canvas, {
      ...config,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
        plugins: { legend: { labels: { color: ink, boxWidth: 12 } } },
        scales: Object.fromEntries(Object.entries(config.scales || { x: {}, y: {} }).map(([k, v]) => [k, {
          ...v, ticks: { color: ink, precision: 0, ...(v.ticks || {}) }, grid: { color: line, ...(v.grid || {}) },
        }])),
      },
    }));
  });
  return card;
}
const C = { green: '#026c3b', sage: '#8fae9e', gold: '#b88a2e', warn: '#a04a0a', deep: '#0d4a3c' };

function lastDays(n) {
  const out = [];
  const today = startOfDay(new Date());
  for (let i = n - 1; i >= 0; i--) out.push(new Date(today - i * DAY));
  return out;
}
function perDay(days, items, at, pick = () => 1) {
  const idx = new Map(days.map((d, i) => [d.getTime(), i]));
  const out = days.map(() => 0);
  for (const it of items) {
    const d = at(it);
    if (!d) continue;
    const i = idx.get(startOfDay(d).getTime());
    if (i != null) out[i] += pick(it);
  }
  return out;
}
const dayLabel = (d) => d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' });

function barsCard(title, rows) {
  const max = Math.max(1, ...rows.map((r) => r[1]));
  return h('div', { class: 'card grid' }, h('h3', {}, title),
    rows.length ? h('div', { class: 'bars' }, rows.map(([label, n]) => h('div', { class: 'bar' },
      h('span', {}, label), h('span', { class: 'track' }, h('span', { class: 'fill', style: `width:${(n / max) * 100}%` })),
      h('span', { class: 'n' }, fmtNum(n))))) : h('p', { class: 'muted' }, 'Nothing yet.'));
}
function tally(items, key, label = (k) => k) {
  const m = new Map();
  for (const it of items) {
    const k = key(it);
    if (k == null || k === '') continue;
    m.set(k, (m.get(k) || 0) + 1);
  }
  return [...m.entries()].sort((a, b) => b[1] - a[1]).map(([k, n]) => [label(k), n]);
}
const tile = (label, value, sub, alert) =>
  h('div', { class: alert ? 'tile alert' : 'tile' }, h('span', { class: 'l' }, label), h('span', { class: 'v' }, fmtNum(value)), sub ? h('span', { class: 's' }, sub) : null);

// ---- Views ----

const views = {};

views.overview = async () => {
  charts.splice(0).forEach((c) => c.destroy());
  const [people, live, totals, recent, calls] = await Promise.all([
    peopleNow(true), refreshBadges(), data.lessonTotals(), load('lessons30', () => data.lessons(30), true),
    load('calls30', () => data.calls(30), true),
  ]);
  // The badges may have changed: redraw the side bar's counts.
  document.querySelectorAll('.side a').forEach((a) => {
    const id = a.getAttribute('href').slice(1);
    a.querySelector('.badge')?.remove();
    if (badges[id]) a.append(h('span', { class: 'badge' }, badges[id]));
  });
  const now = Date.now();
  const within = (d, days) => d && now - d.getTime() <= days * DAY;
  const students = people.filter((p) => p.role === 'student');
  const teachers = people.filter((p) => p.role === 'teacher' && p.appStatus === 'approved');
  const week = recent.filter((l) => within(l.at, 7));
  const mins = (ls) => ls.reduce((m, l) => m + l.minutes, 0);
  const asked = calls.filter((c) => c.direction !== 'toStudent');
  const connected = asked.filter((c) => c.status === 'active' || c.status === 'ended');
  const noTeacher = asked.filter((c) => c.status === 'unmatched');
  const rated = recent.filter((l) => l.rating != null);
  const days = lastDays(30);

  return [
    header('Overview', h('span', { class: 'muted small' }, `Updated ${timeFmt.format(new Date())}`), refreshBtn([])),
    h('p', { class: 'section-title' }, 'Needs attention'),
    h('div', { class: 'tiles' },
      tile('Applications waiting', live.pending, null, live.pending > 0),
      tile('Open reports', live.openReports, null, live.openReports > 0),
      tile('Paused accounts', people.filter((p) => p.paused).length),
      tile('Students who found no teacher', noTeacher.length, 'last 30 days', noTeacher.length > 0)),
    h('p', { class: 'section-title' }, 'Right now'),
    h('div', { class: 'tiles' },
      tile('Teachers available', live.teachersOn),
      tile('Students waiting for a teacher', live.waiting)),
    h('p', { class: 'section-title' }, 'People'),
    h('div', { class: 'tiles' },
      tile('Everyone', people.length),
      tile('Students', students.length),
      tile('Approved teachers', teachers.length),
      tile('New this week', people.filter((p) => within(p.joined, 7)).length),
      tile('Active this week', people.filter((p) => within(p.lastActive, 7)).length),
      tile('Active today', people.filter((p) => within(p.lastActive, 1) && startOfDay(p.lastActive).getTime() === startOfDay(new Date()).getTime()).length)),
    h('p', { class: 'section-title' }, 'Teaching'),
    h('div', { class: 'tiles' },
      tile('Lessons, all time', totals.lessons),
      tile('Minutes taught, all time', totals.minutes),
      tile('Lessons this week', week.length, `${fmtNum(mins(week))} minutes`),
      tile('Lessons, last 30 days', recent.length, `${fmtNum(mins(recent))} minutes`),
      tile('Average lesson', recent.length ? Math.round(mins(recent) / recent.length) : null, 'minutes, last 30 days'),
      tile('Calls answered', asked.length ? Math.round((connected.length / asked.length) * 100) : null,
        `% of ${fmtNum(asked.length)} requests, last 30 days`)),
    h('div', { class: 'charts' },
      chart('New people per day (30 days)', {
        type: 'bar',
        data: {
          labels: days.map(dayLabel),
          datasets: [
            { label: 'Students', data: perDay(days, students, (p) => p.joined), backgroundColor: C.green },
            { label: 'Teachers & applicants', data: perDay(days, people.filter((p) => p.role === 'teacher'), (p) => p.joined), backgroundColor: C.gold },
          ],
        },
        scales: { x: { stacked: true, grid: { display: false } }, y: { stacked: true, beginAtZero: true } },
      }),
      chart('Lessons and minutes per day (30 days)', {
        type: 'bar',
        data: {
          labels: days.map(dayLabel),
          datasets: [
            { label: 'Lessons', data: perDay(days, recent, (l) => l.at), backgroundColor: C.green, yAxisID: 'y' },
            { label: 'Minutes', type: 'line', data: perDay(days, recent, (l) => l.at, (l) => l.minutes), borderColor: C.gold, backgroundColor: C.gold, yAxisID: 'y1', tension: 0.3, pointRadius: 2 },
          ],
        },
        scales: { x: { grid: { display: false } }, y: { beginAtZero: true }, y1: { beginAtZero: true, position: 'right', grid: { display: false } } },
      }),
      chart('Calls per day: answered and no teacher found (30 days)', {
        type: 'bar',
        data: {
          labels: days.map(dayLabel),
          datasets: [
            { label: 'Answered', data: perDay(days, connected, (c) => c.at), backgroundColor: C.green },
            { label: 'No teacher found', data: perDay(days, noTeacher, (c) => c.at), backgroundColor: C.warn },
          ],
        },
        scales: { x: { stacked: true, grid: { display: false } }, y: { stacked: true, beginAtZero: true } },
      }),
      chart('Busiest hours for lessons (30 days, your time)', {
        type: 'bar',
        data: {
          labels: [...Array(24).keys()].map((hr) => `${String(hr).padStart(2, '0')}:00`),
          datasets: [{ label: 'Lessons', data: [...Array(24).keys()].map((hr) => recent.filter((l) => l.at?.getHours() === hr).length), backgroundColor: C.deep }],
        },
        scales: { x: { grid: { display: false } }, y: { beginAtZero: true } },
      })),
    h('div', { class: 'cols' },
      barsCard('Brothers and sisters', tally(people, (p) => p.gender, genderL)),
      barsCard('Countries (top 8)', tally(people, (p) => p.nationality, country).slice(0, 8)),
      barsCard('Age groups', tally(people, (p) => p.ageGroup).sort((a, b) => a[0].localeCompare(b[0]))),
      barsCard('App language', tally(people, (p) => p.locale, (l) => (l === 'ar' ? 'Arabic' : 'English'))),
      barsCard('Lesson ratings by students (30 days)', [2, 1, 0].map((r) => [ratingL[r], rated.filter((l) => l.rating === r).length])),
      barsCard('WhatsApp community', [['Asked to join', people.filter((p) => p.whatsapp).length], ['Not interested', people.filter((p) => !p.whatsapp).length]])),
    h('p', { class: 'muted small' },
      'Joined dates and "last active" are recorded from app version 0.17.0 on. People who signed up earlier show their first visit after updating.'),
  ];
};

// ---- Applications ----

views.applications = async () => {
  let tab = sessionStorage.getItem('appsTab') || 'pending';
  const [apps, people] = await Promise.all([load('apps', data.applications, true), byUid()]);
  const box = h('div', { class: 'grid' });
  const tabs = h('div', { class: 'tabs', role: 'tablist' });
  const counts = { pending: 0, approved: 0, rejected: 0 };
  apps.forEach((a) => (counts[a.status] = (counts[a.status] || 0) + 1));

  function card(a) {
    const p = people.get(a.id) || { uid: a.id, name: a.name, gender: a.gender };
    const player = h('div', {});
    const playBtn = h('button', { class: 'btn out', onclick: async () => {
      playBtn.disabled = true;
      const url = await data.sample(a.id);
      fill(player, url ? h('audio', { controls: true, src: url, autoplay: true }) : h('span', { class: 'muted' }, 'No recording found.'));
    } }, `▶ Play recitation sample${a.sampleSec ? ` (${Math.floor(a.sampleSec / 60)}:${String(a.sampleSec % 60).padStart(2, '0')})` : ''}`);
    const decideBtns = a.status === 'pending' || a.status === 'rejected'
      ? h('div', { class: 'row' },
          h('button', { class: 'btn', onclick: async () => {
            const r = await ask(`Approve ${a.name}?`, `${a.name} will be able to switch on "available" and take calls from ${a.gender === 'female' ? 'sisters' : 'brothers'}.`, 'Approve');
            if (r.ok && await act('Approved', () => data.decide(a.id, true))) { forget('apps', 'people'); route(); }
          } }, 'Approve'),
          a.status === 'pending' ? h('button', { class: 'btn warn', onclick: async () => {
            const r = await ask(`Don't approve ${a.name}?`, 'They will see your reason in the app and can apply again.', 'Not approved',
              { danger: true, reason: 'Reason (the applicant will see it)', reasonRequired: true });
            if (r.ok && await act('Marked as not approved', () => data.decide(a.id, false, r.reason))) { forget('apps', 'people'); route(); }
          } }, 'Not approved') : null)
      : null;
    return h('div', { class: 'card app-card' },
      h('div', { class: 'head' },
        h('a', { href: `#person/${a.id}`, style: 'text-decoration:none' }, who(p)),
        h('div', { class: 'row' },
          h('span', { class: 'chip' }, genderL(a.gender)),
          h('span', { class: a.status === 'pending' ? 'chip gold' : a.status === 'approved' ? 'chip green' : 'chip warn' },
            { pending: 'Waiting', approved: 'Approved', rejected: 'Not approved' }[a.status] || a.status),
          h('span', { class: 'muted small' }, `Sent ${fmtDateTime(a.submitted)}`))),
      h('dl', { class: 'answers' }, a.answers.map(([k, v]) => h('div', {}, h('dt', {}, k), h('dd', { class: isArabic(v) ? 'ar' : '' }, v)))),
      a.reason ? h('p', { class: 'muted' }, `Reason given: ${a.reason}`) : null,
      a.decided ? h('p', { class: 'muted small' }, `Decided ${fmtDateTime(a.decided)}`) : null,
      h('div', { class: 'row' }, playBtn, decideBtns), player);
  }
  function draw() {
    sessionStorage.setItem('appsTab', tab);
    fill(tabs, ...[['pending', 'Waiting'], ['approved', 'Approved'], ['rejected', 'Not approved'], ['all', 'All']].map(([id, label]) =>
      h('button', { class: tab === id ? 'on' : null, role: 'tab', 'aria-selected': String(tab === id), onclick: () => { tab = id; draw(); } },
        `${label} (${id === 'all' ? apps.length : counts[id] || 0})`)));
    const list = apps.filter((a) => tab === 'all' || a.status === tab)
      .sort((x, y) => (tab === 'pending' ? (x.submitted || 0) - (y.submitted || 0) : (y.submitted || 0) - (x.submitted || 0)));
    fill(box, ...(list.length ? list.map(card) : [h('div', { class: 'card empty' }, 'No applications here.')]));
  }
  draw();
  return [header('Teacher applications', refreshBtn(['apps'])), tabs, box];
};

// ---- People ----

const peopleColumns = [
  ['Name', (p) => p.name.toLowerCase(), (p) => who(p)],
  ['Role', roleL, roleL],
  ['', (p) => p.gender || '', (p) => genderL(p.gender)],
  ['Country', (p) => country(p.nationality), (p) => country(p.nationality)],
  ['Age', (p) => p.ageGroup || '', (p) => p.ageGroup || '—'],
  ['Joined', (p) => p.joined?.getTime() || 0, (p) => fmtDate(p.joined)],
  ['Last active', (p) => p.lastActive?.getTime() || 0, (p) => ago(p.lastActive)],
  ['Status', (p) => (p.paused ? 0 : 1), (p) => h('span', { class: 'row' },
    p.paused ? h('span', { class: 'chip warn' }, 'Paused') : null,
    p.admin ? h('span', { class: 'chip gold' }, 'Admin') : null,
    p.available ? h('span', { class: 'chip green' }, 'Available') : null,
    p.whatsapp ? h('span', { class: 'chip' }, 'WhatsApp') : null)],
];

views.people = async () => {
  const people = await peopleNow(true);
  const st = JSON.parse(sessionStorage.getItem('peopleFilter') || '{}');
  let sort = st.sort ?? 6;
  let desc = st.desc ?? true;
  const qIn = h('input', { type: 'search', id: 'people-q', placeholder: 'Search name or phone', value: st.q || '' });
  const sel = (id, label, opts, val) => h('select', { id, 'aria-label': label }, opts.map(([v, l]) => h('option', { value: v, selected: v === val ? true : null }, l)));
  const roleSel = sel('people-role', 'Role', [['', 'Everyone'], ['student', 'Students'], ['teacher', 'Teachers'], ['applicant', 'Applicants'], ['signup', 'Still signing up']], st.role || '');
  const genSel = sel('people-gender', 'Gender', [['', 'Brothers and sisters'], ['female', 'Sisters'], ['male', 'Brothers']], st.gender || '');
  const stSel = sel('people-status', 'Status', [['', 'Any status'], ['paused', 'Paused'], ['admin', 'Admins'], ['whatsapp', 'WhatsApp volunteers'], ['inactive', 'Not active for 30 days']], st.status || '');
  const count = h('span', { class: 'muted' });
  const tbody = h('tbody');
  const thead = h('thead');

  function rows() {
    const q = qIn.value.trim().toLowerCase();
    const r = roleSel.value;
    const list = people.filter((p) => {
      if (q && !p.name.toLowerCase().includes(q) && !(p.phone || '').includes(q.replace(/\s/g, ''))) return false;
      if (r === 'student' && p.role !== 'student') return false;
      if (r === 'teacher' && !(p.role === 'teacher' && p.appStatus === 'approved')) return false;
      if (r === 'applicant' && !(p.role === 'teacher' && p.appStatus !== 'approved')) return false;
      if (r === 'signup' && p.role) return false;
      if (genSel.value && p.gender !== genSel.value) return false;
      const s = stSel.value;
      if (s === 'paused' && !p.paused) return false;
      if (s === 'admin' && !p.admin) return false;
      if (s === 'whatsapp' && !p.whatsapp) return false;
      if (s === 'inactive' && p.lastActive && Date.now() - p.lastActive.getTime() < 30 * DAY) return false;
      return true;
    });
    const key = peopleColumns[sort][1];
    list.sort((a, b) => {
      const x = key(a), y = key(b);
      return (x < y ? -1 : x > y ? 1 : 0) * (desc ? -1 : 1);
    });
    return list;
  }
  function draw() {
    sessionStorage.setItem('peopleFilter', JSON.stringify({ q: qIn.value, role: roleSel.value, gender: genSel.value, status: stSel.value, sort, desc }));
    fill(thead, h('tr', {}, peopleColumns.map(([label], i) => h('th', {
      'aria-sort': i === sort ? (desc ? 'descending' : 'ascending') : null,
      onclick: () => { desc = i === sort ? !desc : i >= 5; sort = i; draw(); },
    }, label, i === sort ? (desc ? ' ↓' : ' ↑') : ''))));
    const list = rows();
    count.textContent = `${list.length} of ${people.length}`;
    fill(tbody, ...list.map((p) => h('tr', { class: 'link', tabindex: 0, onclick: () => (location.hash = `person/${p.uid}`),
      onkeydown: (e) => { if (e.key === 'Enter') location.hash = `person/${p.uid}`; } },
      peopleColumns.map(([, , cell]) => h('td', {}, cell(p))))));
  }
  [qIn, roleSel, genSel, stSel].forEach((el) => el.addEventListener('input', draw));
  draw();
  return [
    header('People', h('button', { class: 'btn out', onclick: () => exportPeople(rows()) }, 'Export this list'), refreshBtn(['people'])),
    h('div', { class: 'row' }, qIn, roleSel, genSel, stSel, count),
    h('div', { class: 'table-wrap' }, h('table', {}, thead, tbody)),
  ];
};

views.person = async (uid) => {
  const people = await byUid();
  const p = people.get(uid);
  if (!p) return [header('Not found'), h('p', {}, 'No one with this account.'), h('a', { href: '#people' }, '← Back to people')];
  const [lessons, chats, reps, apps] = await Promise.all([data.lessonsOf(uid), data.chatsOf(uid), load('reports', data.reports, true), load('apps', data.applications)]);
  const app = apps.find((a) => a.id === uid);
  const nameOf = (id) => people.get(id)?.name || '(deleted account)';
  const asTeacher = lessons.filter((l) => l.teacherId === uid);
  const asStudent = lessons.filter((l) => l.studentId === uid);
  const minutes = lessons.reduce((m, l) => m + l.minutes, 0);
  const rated = (asTeacher.length ? asTeacher : asStudent).filter((l) => l.rating != null);
  const made = reps.filter((r) => r.reporterId === uid);
  const against = reps.filter((r) => r.reportedId === uid);
  const sent = chats.reduce((n, c) => n + c.sentByThem, 0);
  const pic = avatar(p, true);
  if ((p.avatar || '').startsWith('photo:')) data.photo(uid).then((url) => url && fill(pic, h('img', { src: url, alt: '' })));

  const actions = h('div', { class: 'row' },
    p.paused
      ? h('button', { class: 'btn', onclick: async () => {
          const r = await ask(`Restore ${p.name}'s account?`, 'They can message, call and teach again.', 'Restore');
          if (r.ok && await act('Account restored', () => data.setPaused(uid, false))) { forget('people'); route(); }
        } }, 'Restore account')
      : h('button', { class: 'btn warn', onclick: async () => {
          const r = await ask(`Pause ${p.name}'s account?`, "They won't be able to send messages, call or teach until you restore it. The Quran and athkar stay open for them.",
            'Pause', { danger: true, reason: 'Reason (for the admins)' });
          if (r.ok && await act('Account paused', () => data.setPaused(uid, true, r.reason))) { forget('people'); route(); }
        } }, 'Pause account'),
    (p.avatar || '').startsWith('photo:') ? h('button', { class: 'btn out', onclick: async () => {
      const r = await ask(`Remove ${p.name}'s picture?`, 'Use this for a picture that is not suitable. They can choose another.', 'Remove', { danger: true });
      if (r.ok && await act('Picture removed', () => data.removePhoto(uid))) route();
    } }, 'Remove picture') : null,
    p.admin
      ? (uid !== me.uid ? h('button', { class: 'btn out', onclick: async () => {
          const r = await ask(`Remove ${p.name} as an admin?`, 'They will no longer be able to open this portal.', 'Remove admin', { danger: true });
          if (r.ok && await act('No longer an admin', () => data.removeAdmin(uid))) { forget('people'); route(); }
        } }, 'Remove admin') : null)
      : h('button', { class: 'btn out', onclick: async () => {
          const r = await ask(`Make ${p.name} an admin?`, 'Admins can see everyone\'s details, approve teachers, pause accounts and add other admins.', 'Make admin');
          if (r.ok && await act(`${p.name} is now an admin`, () => data.addAdmin(uid, p.name))) { forget('people'); route(); }
        } }, 'Make admin'),
    p.role === 'student' ? h('a', { class: 'btn ghost', href: `#connect/${uid}` }, 'Connect with a teacher') : null);

  const kv = (k, v) => h('div', {}, h('span', { class: 'k' }, k), h('span', {}, v));
  const copyPhone = p.phone ? h('button', { class: 'btn ghost', style: 'padding:2px 8px;font-size:12px', onclick: () => navigator.clipboard?.writeText(p.phone).then(() => toast('Number copied'), () => {}) }, 'Copy') : null;
  return [
    h('a', { href: '#people', class: 'small' }, '← People'),
    h('div', { class: 'card' },
      h('div', { class: 'head' },
        h('div', { class: 'who' }, pic, h('div', { class: 'grid', style: 'gap:4px' },
          h('h1', { class: isArabic(p.name) ? 'ar' : '' }, p.name || '(no name)'),
          h('div', { class: 'row' }, h('span', { class: 'chip' }, roleL(p)), h('span', { class: 'chip' }, genderL(p.gender)),
            p.paused ? h('span', { class: 'chip warn' }, 'Paused') : null, p.admin ? h('span', { class: 'chip gold' }, 'Admin') : null,
            p.available ? h('span', { class: 'chip green' }, 'Available now') : null))),
        actions)),
    p.paused ? h('div', { class: 'card', style: 'border-color:var(--warn)' }, h('strong', {}, 'Paused '), `on ${fmtDateTime(p.paused.at)}`,
      p.paused.by ? ` by ${nameOf(p.paused.by)}` : '', p.paused.reason ? `. Reason: ${p.paused.reason}` : '') : null,
    h('div', { class: 'card' }, h('dl', { class: 'kv' },
      kv('Phone', h('span', { class: 'row' }, p.phone || '—', copyPhone)),
      kv('WhatsApp community', p.whatsapp ? 'Asked to join' : 'No'),
      kv('Country', country(p.nationality)),
      kv('Age group', p.ageGroup || '—'),
      kv('App language', p.locale === 'ar' ? 'Arabic' : p.locale === 'en' ? 'English' : '—'),
      kv('Joined', fmtDate(p.joined)),
      kv('Last active', ago(p.lastActive)),
      app ? kv('Teacher application', `${{ pending: 'Waiting', approved: 'Approved', rejected: 'Not approved' }[app.status] || app.status} · sent ${fmtDate(app.submitted)}`) : null,
      kv('Account ID', h('span', { class: 'small muted' }, uid)))),
    h('div', { class: 'tiles' },
      tile(asTeacher.length ? 'Lessons taught' : 'Lessons', asTeacher.length || asStudent.length),
      tile('Minutes', minutes),
      tile(asTeacher.length ? 'Students taught' : 'Teachers', new Set(lessons.map((l) => (l.teacherId === uid ? l.studentId : l.teacherId))).size),
      tile('Rated "Good"', rated.length ? Math.round((rated.filter((l) => l.rating === 2).length / rated.length) * 100) : null, rated.length ? `% of ${rated.length} rated lessons` : 'no ratings yet'),
      tile('Chats', chats.length),
      tile('Messages sent', sent, 'counted from version 0.17.0'),
      tile('Reports about them', against.length, null, against.some((r) => r.status === 'open'))),
    h('h2', {}, 'Lessons'),
    lessons.length ? h('div', { class: 'table-wrap' }, h('table', {},
      h('thead', {}, h('tr', {}, ['When', 'With', 'As', 'Minutes', 'Student\'s rating', 'Notes'].map((t) => h('th', { class: 'nosort' }, t)))),
      h('tbody', {}, lessons.map((l) => {
        const other = l.teacherId === uid ? l.studentId : l.teacherId;
        return h('tr', {}, h('td', {}, fmtDateTime(l.at)),
          h('td', {}, h('a', { href: `#person/${other}` }, nameOf(other))),
          h('td', {}, l.teacherId === uid ? 'Teacher' : 'Student'),
          h('td', { class: 'num' }, l.minutes),
          h('td', {}, l.rating != null ? ratingL[l.rating] : '—'),
          h('td', {}, l.notes ? 'Yes' : '—'));
      })))) : h('p', { class: 'muted' }, 'No lessons yet.'),
    h('h2', {}, 'Chats'),
    h('p', { class: 'muted small' }, 'Only counts are shown. The messages themselves stay private, as the privacy policy promises.'),
    chats.length ? h('div', { class: 'table-wrap' }, h('table', {},
      h('thead', {}, h('tr', {}, ['With', 'Started', 'Last message', 'Sent by them', 'Sent by the other', ''].map((t) => h('th', { class: 'nosort' }, t)))),
      h('tbody', {}, chats.map((c) => h('tr', {},
        h('td', {}, h('a', { href: `#person/${c.other}` }, c.otherName || nameOf(c.other))),
        h('td', {}, fmtDate(c.started)), h('td', {}, ago(c.lastAt)),
        h('td', { class: 'num' }, c.sentByThem), h('td', { class: 'num' }, c.sentByOther),
        h('td', {}, c.blocked ? h('span', { class: 'chip warn' }, 'Blocked') : null)))))) : h('p', { class: 'muted' }, 'No chats yet.'),
    h('h2', {}, 'Reports'),
    made.length + against.length ? reportsTable([...against, ...made], people) : h('p', { class: 'muted' }, 'No reports made by or about them.'),
  ];
};

// ---- Lessons ----

views.lessons = async () => {
  let range = Number(sessionStorage.getItem('lessonRange') || 30);
  const people = await byUid();
  const nameOf = (id) => people.get(id)?.name || '(deleted account)';
  const box = h('div', { class: 'grid' });
  const rangeSel = h('select', { id: 'lesson-range', 'aria-label': 'Period' },
    [[7, 'Last 7 days'], [30, 'Last 30 days'], [90, 'Last 90 days'], [0, 'All time']].map(([v, l]) => h('option', { value: v, selected: v === range ? true : null }, l)));
  const qIn = h('input', { type: 'search', id: 'lesson-q', placeholder: 'Search a name' });
  let list = [];
  async function drawAll() {
    sessionStorage.setItem('lessonRange', range);
    fill(box, h('p', { class: 'loading' }, 'Loading…'));
    const all = await load(`lessons${range}`, () => data.lessons(range || null), true);
    const q = qIn.value.trim().toLowerCase();
    list = all.filter((l) => !q || nameOf(l.studentId).toLowerCase().includes(q) || nameOf(l.teacherId).toLowerCase().includes(q));
    const mins = list.reduce((m, l) => m + l.minutes, 0);
    fill(box,
      h('p', { class: 'muted' }, `${fmtNum(list.length)} lessons · ${fmtNum(mins)} minutes`),
      list.length ? h('div', { class: 'table-wrap' }, h('table', {},
        h('thead', {}, h('tr', {}, ['When', 'Student', 'Teacher', '', 'Minutes', 'Rating', 'Recited', 'Notes'].map((t) => h('th', { class: 'nosort' }, t)))),
        h('tbody', {}, list.slice(0, 500).map((l) => h('tr', {},
          h('td', {}, fmtDateTime(l.at)),
          h('td', {}, h('a', { href: `#person/${l.studentId}` }, nameOf(l.studentId))),
          h('td', {}, h('a', { href: `#person/${l.teacherId}` }, nameOf(l.teacherId))),
          h('td', {}, genderL(l.gender)),
          h('td', { class: 'num' }, l.minutes),
          h('td', {}, l.rating != null ? ratingL[l.rating] : '—'),
          h('td', {}, l.notes?.recited ? `Surah ${l.notes.recited.sura}, ${l.notes.recited.from}–${l.notes.recited.to}` : '—'),
          h('td', {}, l.notes ? 'Yes' : '—')))))) : h('div', { class: 'card empty' }, 'No lessons in this period.'),
      list.length > 500 ? h('p', { class: 'muted small' }, 'Showing the newest 500. Export for the full list.') : null);
  }
  rangeSel.addEventListener('change', () => { range = Number(rangeSel.value); drawAll(); });
  qIn.addEventListener('input', drawAll);
  drawAll();
  return [header('Lessons', h('button', { class: 'btn out', onclick: () => exportLessons(list, nameOf) }, 'Export this list')), h('div', { class: 'row' }, rangeSel, qIn), box];
};

// ---- Reports ----

const reasonL = { words: 'Inappropriate words', respect: 'Not respectful', personal: 'Asked for personal details', other: 'Something else' };

function reportsTable(list, people) {
  const nameOf = (id, fallback) => people.get(id)?.name || fallback || '(deleted account)';
  return h('div', { class: 'table-wrap' }, h('table', {},
    h('thead', {}, h('tr', {}, ['When', 'Reported', 'By', 'Reason', 'Details', 'Status', ''].map((t) => h('th', { class: 'nosort' }, t)))),
    h('tbody', {}, list.map((r) => h('tr', {},
      h('td', {}, fmtDateTime(r.at)),
      h('td', {}, h('a', { href: `#person/${r.reportedId}` }, nameOf(r.reportedId, r.reportedName))),
      h('td', {}, h('a', { href: `#person/${r.reporterId}` }, nameOf(r.reporterId, r.reporterName))),
      h('td', {}, reasonL[r.reason] || r.reason),
      h('td', { class: 'wrap' }, r.details || '—'),
      h('td', {}, r.status === 'open' ? h('span', { class: 'chip gold' }, 'Open') : h('span', { class: 'chip' }, 'Dealt with')),
      h('td', {}, h('button', { class: 'btn ghost', onclick: async () => {
        if (await act(r.status === 'open' ? 'Marked as dealt with' : 'Reopened', () => data.resolveReport(r.id, r.status === 'open'))) { forget('reports'); await refreshBadges(); route(); }
      } }, r.status === 'open' ? 'Mark as dealt with' : 'Reopen')))))));
}

views.reports = async () => {
  let tab = 'open';
  const [list, people] = await Promise.all([load('reports', data.reports, true), byUid()]);
  const box = h('div');
  const tabs = h('div', { class: 'tabs' });
  function draw() {
    fill(tabs, ...[['open', 'Open'], ['resolved', 'Dealt with'], ['all', 'All']].map(([id, l]) =>
      h('button', { class: tab === id ? 'on' : null, onclick: () => { tab = id; draw(); } }, `${l} (${list.filter((r) => id === 'all' || r.status === id).length})`)));
    const shown = list.filter((r) => tab === 'all' || r.status === tab);
    fill(box, shown.length ? reportsTable(shown, people) : h('div', { class: 'card empty' }, tab === 'open' ? 'No open reports. Alhamdulillah.' : 'Nothing here.'));
  }
  draw();
  return [header('Reports', refreshBtn(['reports'])),
    h('p', { class: 'muted' }, 'To act on a report, open the reported person and pause their account if needed. Open the chat details there to see who they talk to.'),
    tabs, box];
};

// ---- Announcements ----

views.announcements = async () => {
  const list = await load('ann', data.announcements, true);
  const en = h('textarea', { id: 'ann-en', maxlength: 500, placeholder: 'In English' });
  const ar = h('textarea', { id: 'ann-ar', maxlength: 500, dir: 'rtl', class: 'ar', placeholder: 'بالعربية' });
  const aud = h('select', { id: 'ann-aud' }, [['all', 'Everyone'], ['student', 'Students only'], ['teacher', 'Teachers only']].map(([v, l]) => h('option', { value: v }, l)));
  const until = h('input', { type: 'date', id: 'ann-until' });
  const audL = { all: 'Everyone', student: 'Students', teacher: 'Teachers' };
  const now = new Date();
  return [
    header('Announcements'),
    h('p', { class: 'muted' }, 'A short message shown at the top of the home screen in the app, until the person closes it. Write it in English, Arabic or both: each person sees their own language (or the other one if theirs is empty).'),
    h('form', { class: 'card grid', onsubmit: async (e) => {
      e.preventDefault();
      if (!en.value.trim() && !ar.value.trim()) return toast('Write the message in at least one language.');
      const end = until.value ? new Date(`${until.value}T23:59:59`) : null;
      const r = await ask('Publish this announcement?', `It will show to ${audL[aud.value].toLowerCase()} the next time they open Sanadi.`, 'Publish');
      if (r.ok && await act('Published', () => data.addAnnouncement({ textEn: en.value, textAr: ar.value, audience: aud.value, until: end }))) { forget('ann'); route(); }
    } },
      h('h2', {}, 'New announcement'),
      h('div', { class: 'cols' }, h('label', { class: 'f' }, 'English', en), h('label', { class: 'f' }, 'Arabic', ar)),
      h('div', { class: 'row' }, h('label', { class: 'f' }, 'Who sees it', aud), h('label', { class: 'f' }, 'Show until (optional)', until)),
      h('div', { class: 'row' }, h('button', { class: 'btn', type: 'submit' }, 'Publish'))),
    h('h2', {}, 'Published'),
    list.length ? h('div', { class: 'table-wrap' }, h('table', {},
      h('thead', {}, h('tr', {}, ['Message', 'For', 'Published', 'Until', 'Status', ''].map((t) => h('th', { class: 'nosort' }, t)))),
      h('tbody', {}, list.map((a) => h('tr', {},
        h('td', { class: 'wrap' }, a.textEn ? h('div', {}, a.textEn) : null, a.textAr ? h('div', { class: 'ar', dir: 'rtl' }, a.textAr) : null),
        h('td', {}, audL[a.audience] || a.audience),
        h('td', {}, fmtDate(a.at)), h('td', {}, a.until ? fmtDate(a.until) : 'Until removed'),
        h('td', {}, !a.until || a.until > now ? h('span', { class: 'chip green' }, 'Showing') : h('span', { class: 'chip' }, 'Ended')),
        h('td', {}, h('button', { class: 'btn ghost', onclick: async () => {
          const r = await ask('Remove this announcement?', 'It disappears from the app for everyone.', 'Remove', { danger: true });
          if (r.ok && await act('Removed', () => data.removeAnnouncement(a.id))) { forget('ann'); route(); }
        } }, 'Remove'))))))) : h('div', { class: 'card empty' }, 'No announcements yet.'),
  ];
};

// ---- Connect ----

views.connect = async (preset) => {
  const people = await peopleNow();
  const students = people.filter((p) => p.role === 'student' && !p.paused);
  const teachers = people.filter((p) => p.role === 'teacher' && p.appStatus === 'approved' && !p.paused);
  const sSel = h('select', { id: 'connect-student' }, h('option', { value: '' }, 'Choose a student'),
    students.map((p) => h('option', { value: p.uid, selected: p.uid === preset ? true : null }, `${p.name} (${genderL(p.gender)})`)));
  const tSel = h('select', { id: 'connect-teacher' });
  function teachersFor() {
    const s = people.find((p) => p.uid === sSel.value);
    const list = s ? teachers.filter((t) => t.gender === s.gender) : [];
    fill(tSel, h('option', { value: '' }, s ? (list.length ? 'Choose a teacher' : 'No approved teachers of the same gender yet') : 'Choose a student first'),
      list.map((t) => h('option', { value: t.uid }, t.name)));
  }
  sSel.addEventListener('change', teachersFor);
  teachersFor();
  return [
    header('Connect a student and teacher'),
    h('p', { class: 'muted' }, 'Opens a chat between them, so they can message and the teacher can call the student. Only a student and a teacher of the same gender.'),
    h('form', { class: 'card grid', onsubmit: async (e) => {
      e.preventDefault();
      const s = people.find((p) => p.uid === sSel.value);
      const t = people.find((p) => p.uid === tSel.value);
      if (!s || !t) return toast('Choose a student and a teacher.');
      try {
        const made = await data.connect(s, t);
        toast(made ? `Connected ${s.name} with ${t.name}` : 'They already have a chat.');
      } catch (err) {
        toast(`Couldn't connect: ${err.code || err.message}`);
      }
    } },
      h('div', { class: 'row' }, h('label', { class: 'f' }, 'Student', sSel), h('label', { class: 'f' }, 'Teacher', tSel)),
      h('div', {}, h('button', { class: 'btn', type: 'submit' }, 'Connect'))),
  ];
};

// ---- Admins ----

views.admins = async () => {
  const [list, people] = await Promise.all([data.admins(), byUid()]);
  const add = h('select', { id: 'admin-add' }, h('option', { value: '' }, 'Choose a person'),
    [...people.values()].filter((p) => !p.admin && p.name).map((p) => h('option', { value: p.uid }, `${p.name} · ${roleL(p)}`)));
  return [
    header('Admins'),
    h('p', { class: 'muted' }, 'Every admin can see everyone\'s details (including phone numbers), approve teachers, pause accounts, publish announcements and add or remove other admins. You can\'t remove yourself, so there is always at least one admin.'),
    h('div', { class: 'table-wrap' }, h('table', {},
      h('thead', {}, h('tr', {}, ['Admin', 'Added by', 'Added', ''].map((t) => h('th', { class: 'nosort' }, t)))),
      h('tbody', {}, list.map((a) => {
        const p = people.get(a.id) || { uid: a.id, name: a.name || a.id };
        return h('tr', {}, h('td', {}, h('a', { href: `#person/${a.id}`, style: 'text-decoration:none' }, who(p))),
          h('td', {}, a.by ? (people.get(a.by)?.name || a.by) : 'Set up in Firebase'),
          h('td', {}, fmtDate(a.at?.toDate ? a.at.toDate() : null)),
          h('td', {}, a.id === me.uid ? h('span', { class: 'muted small' }, 'You') : h('button', { class: 'btn ghost', onclick: async () => {
            const r = await ask(`Remove ${p.name} as an admin?`, 'They will no longer be able to open this portal.', 'Remove admin', { danger: true });
            if (r.ok && await act('No longer an admin', () => data.removeAdmin(a.id))) { forget('people'); route(); }
          } }, 'Remove')));
      })))),
    h('form', { class: 'card grid', onsubmit: async (e) => {
      e.preventDefault();
      const p = people.get(add.value);
      if (!p) return toast('Choose a person.');
      const r = await ask(`Make ${p.name} an admin?`, 'They need to have signed in to the app at least once (they have).', 'Make admin');
      if (r.ok && await act(`${p.name} is now an admin`, () => data.addAdmin(p.uid, p.name))) { forget('people'); route(); }
    } }, h('h2', {}, 'Add an admin'), h('p', { class: 'muted small' }, 'The person must have signed in to the Sanadi app first.'),
      h('div', { class: 'row' }, add, h('button', { class: 'btn', type: 'submit' }, 'Make admin'))),
  ];
};

// ---- Export ----

function download(name, rows) {
  const cell = (v) => {
    const s = v == null ? '' : String(v);
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  // A byte-order mark so Excel reads Arabic names correctly.
  const csv = '﻿' + rows.map((r) => r.map(cell).join(',')).join('\r\n');
  const a = h('a', { href: URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' })), download: name });
  document.body.append(a);
  a.click();
  a.remove();
}
const isoDate = (d) => (d ? d.toISOString().slice(0, 10) : '');
const stamp = () => new Date().toISOString().slice(0, 10);

function exportPeople(list, name = `sanadi-people-${stamp()}.csv`) {
  download(name, [
    ['Name', 'Role', 'Gender', 'Country', 'Age group', 'Phone', 'WhatsApp community', 'App language', 'Joined', 'Last active', 'Paused', 'Admin', 'Account ID'],
    ...list.map((p) => [p.name, roleL(p), genderL(p.gender), p.nationality ? country(p.nationality) : '', p.ageGroup, p.phone, p.whatsapp ? 'Yes' : 'No',
      p.locale, isoDate(p.joined), isoDate(p.lastActive), p.paused ? 'Yes' : 'No', p.admin ? 'Yes' : 'No', p.uid]),
  ]);
}
function exportLessons(list, nameOf) {
  download(`sanadi-lessons-${stamp()}.csv`, [
    ['Date', 'Time', 'Student', 'Teacher', 'Gender', 'Minutes', 'Student rating', 'Teacher notes'],
    ...list.map((l) => [isoDate(l.at), l.at ? timeFmt.format(l.at) : '', nameOf(l.studentId), nameOf(l.teacherId), genderL(l.gender), l.minutes,
      l.rating != null ? ratingL[l.rating] : '', l.notes ? 'Yes' : 'No']),
  ]);
}

views.export = async () => {
  const people = await peopleNow();
  const item = (title, text, fn) => h('div', { class: 'card grid' }, h('h3', {}, title), h('p', { class: 'muted' }, text), h('div', {}, h('button', { class: 'btn', onclick: fn }, 'Download CSV')));
  return [
    header('Export'),
    h('p', { class: 'muted' }, 'Spreadsheet files (CSV) that open in Excel or Google Sheets. They include phone numbers: keep them private and delete them when you are done.'),
    h('div', { class: 'cols' },
      item('Everyone', `${people.length} people with their details.`, () => exportPeople(people)),
      item('WhatsApp volunteers', `${people.filter((p) => p.whatsapp).length} people who asked to join the WhatsApp community.`,
        () => exportPeople(people.filter((p) => p.whatsapp), `sanadi-whatsapp-${stamp()}.csv`)),
      item('Teachers', `${people.filter((p) => p.role === 'teacher' && p.appStatus === 'approved').length} approved teachers.`,
        () => exportPeople(people.filter((p) => p.role === 'teacher' && p.appStatus === 'approved'), `sanadi-teachers-${stamp()}.csv`)),
      item('All lessons', 'Every lesson ever, with who taught whom, when and for how long.', async () => {
        const all = await load('lessons0', () => data.lessons(null), true);
        const m = await byUid();
        exportLessons(all, (id) => m.get(id)?.name || '(deleted account)');
      })),
  ];
};

// ---- Sign in ----

function signInScreen(message) {
  const btn = h('button', { class: 'btn', style: 'justify-content:center;padding:12px', onclick: async () => {
    btn.disabled = true;
    try {
      await data.signIn(emulatorUser);
    } catch (e) {
      btn.disabled = false;
      if (e.code !== 'auth/popup-closed-by-user') toast(`Sign-in failed: ${e.code || e.message}`);
    }
  } }, 'Sign in with Google');
  fill(root, h('div', { class: 'signin' }, h('div', { class: 'box' },
    h('img', { src: 'sanadi-horizontal-green.png', alt: 'Sanadi' }),
    h('h1', {}, 'Admin portal'),
    h('p', { class: 'muted' }, 'For Sanadi admins only. Sign in with the Google account you use in the Sanadi app.'),
    message ? h('div', { class: 'warn' }, message) : null,
    btn)));
}

if (!firebaseConfig || !firebaseConfig.apiKey) {
  fill(root, h('div', { class: 'signin' }, h('div', { class: 'box' }, h('h1', {}, 'Not set up yet'),
    h('p', { class: 'muted' }, 'This portal has no Firebase settings. They are added when the website is published from GitHub.'))));
} else {
  data.start(firebaseConfig);
  data.onUser(async (user) => {
    if (!user) {
      me = null;
      signInScreen();
      return;
    }
    if (!(await data.isAdmin(user.uid))) {
      me = null;
      signInScreen(h('span', {}, `${user.email || 'This account'} isn't a Sanadi admin. Ask an admin to add you (you need to have signed in to the app once), or sign in with another account. `,
        h('a', { href: '#', onclick: (e) => { e.preventDefault(); data.logOut(); } }, 'Sign out')));
      return;
    }
    me = { uid: user.uid, name: user.displayName, email: user.email };
    await refreshBadges().catch(() => {});
    route();
  });
}
