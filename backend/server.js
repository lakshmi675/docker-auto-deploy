require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./src/db');
const healthRouter = require('./src/routes/health');
const dataRouter = require('./src/routes/data');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

app.use('/api/health', healthRouter);
app.use('/api/data', dataRouter);

app.get('/', (req, res) => {
  res.json({ message: 'Docker Auto Deploy backend is running' });
});

async function start() {
  await connectDB();
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Backend listening on port ${PORT}`);
  });
}

start();

module.exports = app;
