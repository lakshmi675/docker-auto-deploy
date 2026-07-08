const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://mongo:27017/appdb';

async function connectDB() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('MongoDB connected:', MONGO_URI);
  } catch (err) {
    console.error('MongoDB connection error:', err.message);
    // Retry after a short delay instead of crashing immediately,
    // useful while the mongo container is still starting up.
    setTimeout(connectDB, 3000);
  }
}

module.exports = connectDB;
