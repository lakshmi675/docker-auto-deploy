const express = require('express');
const Item = require('../models/Item');

const router = express.Router();

// GET /api/data - list items
router.get('/', async (req, res) => {
  try {
    const items = await Item.find().sort({ createdAt: -1 }).limit(50);
    res.json({ items });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/data - create an item, body: { name }
router.post('/', async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({ error: 'name is required' });
    }
    const item = await Item.create({ name });
    res.status(201).json({ item });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
