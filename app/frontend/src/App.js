import React, { useState, useEffect } from 'react';

const API_BASE = process.env.REACT_APP_API_URL || '';

export default function App() {
  const [notes, setNotes] = useState([]);
  const [input, setInput] = useState('');
  const [systemHealth, setSystemHealth] = useState('checking...');

  const fetchHealth = async () => {
    try {
      const res = await fetch(`${API_BASE}/healthz`);
      const data = await res.json();
      setSystemHealth(data.status === 'healthy' ? 'Healthy (Connected)' : 'Degraded');
    } catch {
      setSystemHealth('Offline / Error');
    }
  };

  const fetchNotes = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/notes`);
      if (res.ok) {
        const data = await res.json();
        setNotes(data);
      }
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchHealth();
    fetchNotes();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!input.trim()) return;
    try {
      const res = await fetch(`${API_BASE}/api/notes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content: input }),
      });
      if (res.ok) {
        setInput('');
        fetchNotes();
      }
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div style={{ fontFamily: 'sans-serif', maxWidth: '600px', margin: '40px auto', padding: '0 20px' }}>
      <h2>Cloud Operations Platform Status</h2>
      <p>
        <strong>Backend Health:</strong>{' '}
        <span style={{ color: systemHealth.includes('Healthy') ? 'green' : 'red' }}>
          {systemHealth}
        </span>
      </p>
      <hr />
      <h3>Production Notes Engine</h3>
      <form onSubmit={handleSubmit} style={{ display: 'flex', gap: '8px' }}>
        <input
          style={{ flexGrow: 1, padding: '8px' }}
          type="text"
          value={input}
          placeholder="New deployment note..."
          onChange={(e) => setInput(e.target.value)}
        />
        <button type="submit" style={{ padding: '8px 16px' }}>Save</button>
      </form>
      <ul style={{ marginTop: '20px', listStyle: 'none', padding: 0 }}>
        {notes.map((n) => (
          <li key={n.id} style={{ background: '#f4f4f4', padding: '10px', margin: '6px 0', borderRadius: '4px' }}>
            {n.content} <small style={{ color: '#888' }}>({new Date(n.created_at).toLocaleTimeString()})</small>
          </li>
        ))}
      </ul>
    </div>
  );
}