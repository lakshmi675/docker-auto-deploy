import { useEffect, useState } from 'react';
import './App.css';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000';

function App() {
  const [health, setHealth] = useState(null);
  const [items, setItems] = useState([]);
  const [error, setError] = useState(null);

  const loadData = async () => {
    try {
      const [healthRes, itemsRes] = await Promise.all([
        fetch(`${API_URL}/api/health`),
        fetch(`${API_URL}/api/data`)
      ]);
      setHealth(await healthRes.json());
      setItems((await itemsRes.json()).items || []);
      setError(null);
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 5000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="app">
      <header className="app-header">
        <h1>🚀 Docker Auto Deploy Demo</h1>
        <p className="tagline">v1.0.4 - edited directly on GitHub🚀</p>
      </header>

      <section className="card">
        <h2>Backend Health</h2>
        {error && <p className="status status-down">⚠️ Cannot reach backend: {error}</p>}
        {!error && !health && <p>Loading…</p>}
        {!error && health && (
          <p className={`status ${health.status === 'ok' ? 'status-up' : 'status-down'}`}>
            {health.status === 'ok' ? '✅ Healthy' : '❌ Unhealthy'} — DB: {health.database} — uptime: {Math.round(health.uptime)}s
          </p>
        )}
      </section>

      <section className="card">
        <h2>Items from MongoDB</h2>
        {items.length === 0 && <p>No items yet.</p>}
        <ul>
          {items.map((item) => (
            <li key={item._id}>{item.name}</li>
          ))}
        </ul>
      </section>
    </div>
  );
}

export default App;
