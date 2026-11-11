const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

const db = new sqlite3.Database('./tokens.db');

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS tokens (
    token TEXT PRIMARY KEY,
    google_email TEXT,
    wa_number TEXT,
    status TEXT DEFAULT 'inactive',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);
});

// Admin: List tokens
app.get('/api/admin/tokens', (req, res) => {
  db.all("SELECT * FROM tokens", [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// Admin: Add token
app.post('/api/admin/tokens', (req, res) => {
  const { token } = req.body;
  if (!token) return res.status(400).json({ error: "Token required" });
  db.run("INSERT OR IGNORE INTO tokens (token) VALUES (?)", [token], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true, token });
  });
});

// Admin: Delete token
app.delete('/api/admin/tokens/:token', (req, res) => {
  const { token } = req.params;
  db.run("DELETE FROM tokens WHERE token = ?", [token], function(err) {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ success: true, deleted: token });
  });
});

// User: Bind Token & Google Account (1 token = 1 google + 1 wa)
app.post('/api/user/bind', (req, res) => {
  const { token, google_email, wa_number } = req.body;
  if (!token || !google_email) return res.status(400).json({ error: "Token and Google email required" });

  db.get("SELECT * FROM tokens WHERE token = ?", [token], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!row) return res.status(404).json({ error: "Token invalid or not registered by admin" });

    if (row.google_email && row.google_email !== google_email) {
      return res.status(400).json({ error: "Token already bound to another Google account" });
    }

    db.run("UPDATE tokens SET google_email = ?, wa_number = ?, status = 'active' WHERE token = ?", 
      [google_email, wa_number || '', token], function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ success: true, message: "Token bound successfully. Node can start." });
    });
  });
});

// User: Check token status
app.get('/api/user/status/:token', (req, res) => {
  const { token } = req.params;
  db.get("SELECT * FROM tokens WHERE token = ?", [token], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!row) return res.status(404).json({ error: "Token not found" });
    res.json(row);
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
