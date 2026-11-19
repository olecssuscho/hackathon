const API_URL = 'http://localhost:8000';

async function api(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, options);
  let data = null;
  try {
    data = await response.json();
  } catch {
    data = null;
  }
  if (!response.ok) {
    const detail = data?.detail;
    throw new Error(Array.isArray(detail) ? detail[0]?.msg || 'Помилка запиту' : detail || 'Помилка запиту');
  }
  return data;
}

function validate(email, password, fullname) {
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return 'Введіть коректний email';
  if (password.length < 6 || password.length > 100) return 'Пароль: від 6 до 100 символів';
  if (mode === 'register' && fullname.trim().length < 2) return 'Введіть повне ім’я';
  return null;
}

async function register(email, password, fullname) {
  const problem = validate(email, password, fullname);
  if (problem) return show(problem, 'error');
  await api('/user/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, fullname }),
  });
  form.reset();
  setMode('login');
  show('Реєстрація успішна. Тепер увійдіть.', 'ok');
}

async function login(email, password) {
  const body = new URLSearchParams({ username: email, password });
  const tokens = await api('/user/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  sessionStorage.setItem('access_token', tokens.access_token);
  sessionStorage.setItem('refresh_token', tokens.refresh_token);
  location.href = 'index.html';
}

// =====================================================================
//  Форма
// =====================================================================
const form = document.getElementById('auth-form');
const tabs = document.querySelectorAll('.tab');
const confirmBlock = document.getElementById('confirm-block');
const fullnameBlock = document.getElementById('fullname-block');
const message = document.getElementById('message');
const submit = document.getElementById('submit');
const passwordInput = document.getElementById('password');

let mode = 'login';

function show(text, type = '') {
  message.textContent = text;
  message.className = type;
}

function setMode(newMode) {
  mode = newMode;
  tabs.forEach((t) => t.classList.toggle('active', t.dataset.mode === mode));
  confirmBlock.hidden = mode !== 'register';
  fullnameBlock.hidden = mode !== 'register';
  submit.textContent = mode === 'register' ? 'Зареєструватися' : 'Увійти';
  passwordInput.autocomplete = mode === 'register' ? 'new-password' : 'current-password';
  show('');
}
tabs.forEach((t) => t.addEventListener('click', () => setMode(t.dataset.mode)));

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  const username = form.elements.username.value.trim();
  const password = form.elements.password.value;
  const fullname = form.elements.fullname.value.trim();

  if (!username || !password) return show('Заповніть усі поля', 'error');
  if (mode === 'register' && password !== form.elements.confirm.value) return show('Паролі не збігаються', 'error');

  submit.disabled = true;
  try {
    await (mode === 'register' ? register(username, password, fullname) : login(username, password));
  } catch (err) {
    console.error(err);
    show(`Помилка: ${err.name}: ${err.message}`, 'error');
  } finally {
    submit.disabled = false;
  }
});

