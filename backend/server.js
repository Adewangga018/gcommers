const express = require('express');
const sql = require('mssql');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

function parseHostAndInstance(hostStr) {
  if (!hostStr) return { server: undefined, instanceName: undefined };
  const parts = hostStr.split('\\');
  return {
    server: parts[0],
    instanceName: parts[1]
  };
}

const hostInfo = parseHostAndInstance(process.env.DB_HOST);

const config = {
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  server: hostInfo.server || process.env.DB_HOST,
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : undefined,
  database: process.env.DB_DATABASE,
  options: {
    encrypt: false,
    trustServerCertificate: true,
    instanceName: hostInfo.instanceName || undefined
  }
};

let pool;

app.get('/health', async (req, res) => {
  try {
    if (!pool) pool = await sql.connect(config);
    const result = await pool.request().query('SELECT 1 AS ok');
    res.json({ ok: result.recordset[0].ok === 1 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Lists tables in the current database (example endpoint)
app.get('/tables', async (req, res) => {
  try {
    if (!pool) pool = await sql.connect(config);
    const result = await pool.request().query("SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'");
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server started on port ${PORT}`);
});

process.on('SIGINT', async () => {
  try { if (pool) await pool.close(); } catch (e) {}
  process.exit();
});
