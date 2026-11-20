const API_URL = location.hostname === "localhost"
    ? "http://localhost:8000"
    : "https://hackathon-j2q3.onrender.com";
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
    return;
  }
  if (!response.ok) {
    throw new Error(`Перевірка авторизації завершилася помилкою: ${response.status}`);
  }
  document.getElementById('game-frame').src = `${API_URL}/game/`;
}).catch((error) => {
  console.error('Не вдалося підключитися до сервера гри:', error);
  document.getElementById('status').textContent = 'Не вдалося підключитися до сервера гри.';
});