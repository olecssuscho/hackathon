const API_URL = location.hostname === "localhost"
    ? "http://localhost:8000"
    : "https://hackathon-j2q3.onrender.com";
const accessToken = sessionStorage.getItem('access_token');
const gameFrame = document.getElementById('game-frame');
const gameOrigin = new URL(`${API_URL}/game/`).origin;

window.addEventListener('message', (event) => {
  if (
    !accessToken ||
    event.source !== gameFrame.contentWindow ||
    event.origin !== gameOrigin ||
    event.data?.type !== 'GODOT_READY'
  ) return;

  gameFrame.contentWindow.postMessage(
    { type: 'AUTH_TOKEN', accessToken },
    gameOrigin
  );
});

if (!accessToken) {
  location.href = 'auth.html';
}

fetch(`${API_URL}/user/me`, {
  headers: { Authorization: `Bearer ${accessToken}` },
}).then((response) => {
  if (response.status === 401) {
    sessionStorage.clear();
    location.href = 'auth.html';
    return;
  }
  if (!response.ok) {
    throw new Error(`Перевірка авторизації завершилася помилкою: ${response.status}`);
  }
  gameFrame.src = `${API_URL}/game/`;
}).catch((error) => {
  console.error('Не вдалося підключитися до сервера гри:', error);
  document.getElementById('status').textContent = 'Не вдалося підключитися до сервера гри.';
});