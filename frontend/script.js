const API_URL = 'http://localhost:8000';
const accessToken = sessionStorage.getItem('access_token');

if (!accessToken) {
  location.href = 'auth.html';
}

fetch(`${API_URL}/user/me`, {
  headers: { Authorization: `Bearer ${accessToken}` },
}).then((response) => {
  if (response.status === 401) {
    sessionStorage.clear();
    location.href = 'auth.html';
  }
}).catch(() => {});

const mapEl = document.getElementById('map');
const canvas = document.getElementById('fog');
const ctx = canvas.getContext('2d');

const player = { x: 0.5, y: 0.5 }; // позиція у частках 0..1, щоб не залежати від розміру екрана
const VIEW_RADIUS = 0.12;          // радіус видимості (частка від меншої сторони)

// Підганяємо розмір canvas під контейнер (з урахуванням retina-екранів)
function resize() {
  const dpr = window.devicePixelRatio || 1;
  const { width, height } = mapEl.getBoundingClientRect();
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  drawFog();
}

function drawFog() {
  const w = canvas.clientWidth;
  const h = canvas.clientHeight;
  ctx.clearRect(0, 0, w, h);

  // Туман
  ctx.fillStyle = 'rgba(0, 0, 0, 0.85)';
  ctx.fillRect(0, 0, w, h);

  // "Вирізаємо" видиму зону навколо гравця
  const r = Math.min(w, h) * VIEW_RADIUS;
  ctx.globalCompositeOperation = 'destination-out';
  ctx.beginPath();
  ctx.arc(player.x * w, player.y * h, r, 0, Math.PI * 2);
  ctx.fill();
  ctx.globalCompositeOperation = 'source-over';

  // Позначка гравця
  ctx.fillStyle = '#c8553d';
  ctx.beginPath();
  ctx.arc(player.x * w, player.y * h, 6, 0, Math.PI * 2);
  ctx.fill();
}

// Керування: стрілки або WASD (e.code не залежить від розкладки, тож працює й з українською)
const keys = new Set();
const MOVE_KEYS = {
  ArrowUp: 'up',    KeyW: 'up',
  ArrowDown: 'down', KeyS: 'down',
  ArrowLeft: 'left', KeyA: 'left',
  ArrowRight: 'right', KeyD: 'right',
};
const SPEED = 0.3; // частка від меншої сторони карти за секунду

window.addEventListener('keydown', (e) => {
  if (MOVE_KEYS[e.code]) {
    e.preventDefault(); // щоб стрілки не скролили сторінку
    keys.add(MOVE_KEYS[e.code]);
  }
});
window.addEventListener('keyup', (e) => {
  if (MOVE_KEYS[e.code]) keys.delete(MOVE_KEYS[e.code]);
});
window.addEventListener('blur', () => keys.clear()); // не "залипати" при втраті фокуса

// Ігровий цикл
let last = performance.now();
function loop(now) {
  const dt = Math.min((now - last) / 1000, 0.05); // секунди, з обмеженням на випадок лагів
  last = now;

  let dx = (keys.has('right') ? 1 : 0) - (keys.has('left') ? 1 : 0);
  let dy = (keys.has('down') ? 1 : 0) - (keys.has('up') ? 1 : 0);

  if (dx || dy) {
    const len = Math.hypot(dx, dy); // однакова швидкість по діагоналі
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    const step = SPEED * Math.min(w, h) * dt; // у пікселях
    player.x = Math.min(1, Math.max(0, player.x + (dx / len) * step / w));
    player.y = Math.min(1, Math.max(0, player.y + (dy / len) * step / h));
    drawFog();
  }
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);

window.addEventListener('resize', resize);
resize();