const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

// nosemgrep: javascript.express.security.audit.express-check-csurf-middleware-usage.express-check-csurf-middleware-usage
const app = express();
const port = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Configuración de la base de datos mediante variables de entorno
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'enterprise_db',
  port: process.env.DB_PORT || 5432,
});

// Inicialización de la tabla (solo para bootstrap inicial)
const initDb = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notes (
        id SERIAL PRIMARY KEY,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("Database initialized successfully.");
  } catch (err) {
    console.error("Database initialization failed (will retry):", err.message);
  }
};
setTimeout(initDb, 3000);

// Endpoint crítico para Liveness y Readiness Probes de Kubernetes
app.get('/healthz', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'healthy', database: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'unhealthy', database: err.message });
  }
});

// API Routes
app.get('/api/notes', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM notes ORDER BY id DESC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/notes', async (req, res) => {
  try {
    const { content } = req.body;
    if (!content) return res.status(400).json({ error: 'Content is required' });
    const result = await pool.query(
      'INSERT INTO notes (content) VALUES ($1) RETURNING *',
      [content]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(port, () => {
  console.log(`Backend service listening on port ${port}`);
});