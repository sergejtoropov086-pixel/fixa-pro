let allDevices = [];
let userDevices = JSON.parse(localStorage.getItem('userDevices') || '[]');
let currentTab = 'main';
let isDarkTheme = false;
let currentLang = 'ru';

document.addEventListener('DOMContentLoaded', async () => {
  try {
    // Загрузка базы
    allDevices = window.PREMIUM_DATABASE || [];
    updateStats();
    renderContent();
  } catch (err) {
    console.error("База не загружена");
  }

  initEventListeners();
});

function initEventListeners() {
  document.getElementById('langBtn').addEventListener('click', toggleLanguage);
  document.getElementById('themeBtn').addEventListener('click', toggleTheme);
  document.querySelectorAll('.tab').forEach(btn => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
  });
  document.getElementById('search').addEventListener('input', renderContent);
  document.getElementById('addBtn').addEventListener('click', addDevice);
  document.getElementById('healthBtn').addEventListener('click', showHealth);
  document.getElementById('exportPdf').addEventListener('click', exportPDF);
  document.getElementById('exportJson').addEventListener('click', exportJSON);
  document.getElementById('importJson').addEventListener('click', () => document.getElementById('importInput').click());
  document.getElementById('printBtn').addEventListener('click', printPage);
  document.getElementById('scanQr').addEventListener('click', scanQR);
  document.getElementById('importInput').addEventListener('change', importData);
}

function switchTab(tab) {
  currentTab = tab;
  document.querySelectorAll('.tab').forEach(b => b.classList.remove('active'));
  document.querySelector(`[data-tab="${tab}"]`).classList.add('active');
  renderContent();
}

function renderContent() {
  const term = document.getElementById('search').value.toLowerCase();
  let items = [];

  if (currentTab === 'main') {
    items = [...allDevices, ...userDevices];
  } else if (currentTab === 'parts') {
    items = [...allDevices, ...userDevices].filter(i => i.partStatus !== '—');
  } else if (currentTab === 'health') {
    items = []; // Можно добавить здоровье позже
  }

  const filtered = items.filter(item =>
    item.name.toLowerCase().includes(term) ||
    item.brand.toLowerCase().includes(term) ||
    item.type.toLowerCase().includes(term)
  );

  const container = document.getElementById('content');
  if (filtered.length === 0) {
    container.innerHTML = '<p>Ничего не найдено</p>';
    return;
  }

  container.innerHTML = filtered.slice(0, 200).map(item => `
    <div class="item">
      <div class="name">${item.name}</div>
      <div class="meta">${item.brand} • ${item.type}</div>
      <div class="status">${item.partStatus}</div>
    </div>
  `).join('');

  if (filtered.length > 200) {
    container.innerHTML += `<p>Показано 200 из ${filtered.length}</p>`;
  }
}

function updateStats() {
  const techCount = allDevices.length + userDevices.length;
  const healthCount = 0; // Пока нет данных о здоровье
  document.getElementById('countTech').textContent = techCount;
  document.getElementById('countHealth').textContent = healthCount;
}

function addDevice() {
  const name = prompt("Модель:");
  if (!name) return;
  const brand = prompt("Бренд:") || "—";
  const type = prompt("Тип:") || "—";
  const status = prompt("Статус:\n1 — В наличии\n2 — Ожидается\n3 — Куплено") || "1";
  const map = {1: "В наличии", 2: "Ожидается", 3: "Куплено"};

  userDevices.push({
    id: Date.now(),
    name,
    brand,
    type,
    partStatus: map[status] || status,
    category: "Техника"
  });

  localStorage.setItem('userDevices', JSON.stringify(userDevices));
  updateStats();
  renderContent();
}

function showHealth() {
  alert("Функция 'Здоровье семьи' пока в разработке");
}

function exportPDF() {
  alert("Экспорт в PDF пока недоступен в PWA. Используйте печать.");
}

function exportJSON() {
  const blob = new Blob([JSON.stringify({user: userDevices}, null, 2)], {type: 'application/json'});
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'fixa-pro-backup.json';
  a.click();
}

function importData(e) {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    try {
      const data = JSON.parse(reader.result);
      if (Array.isArray(data.user)) {
        userDevices = data.user;
        localStorage.setItem('userDevices', JSON.stringify(userDevices));
        updateStats();
        renderContent();
        alert('✅ Импорт завершён!');
      }
    } catch (err) {
      alert('❌ Ошибка импорта');
    }
  };
  reader.readAsText(file);
  e.target.value = '';
}

function printPage() {
  window.print();
}

function scanQR() {
  alert("QR-сканирование доступно только в нативных приложениях. Используйте камеру телефона и введите данные вручную.");
}

function toggleLanguage() {
  currentLang = currentLang === 'ru' ? 'en' : 'ru';
  document.getElementById('langBtn').textContent = currentLang === 'ru' ? '🇷🇺' : '🇬🇧';
  // Можно добавить переводы позже
}

function toggleTheme() {
  isDarkTheme = !isDarkTheme;
  document.body.className = isDarkTheme ? 'dark' : '';
  document.getElementById('themeBtn').textContent = isDarkTheme ? '🌙' : '☀️';
}
