const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const admin = require('firebase-admin');
const dotenv = require('dotenv');
const groupRoutes = require('./routes/groupRoutes'); // Path to group routes
const errorHandler = require('./middleware/errorHandler');

dotenv.config();

const app = express();
const PORT = process.env.PORT;

// Middleware
app.use(cors());
app.use(express.json());

// Firebase Admin SDK Initialization
const serviceAccount = require('./config/firebaseServiceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Attach admin to request globally
app.use((req, res, next) => {
  req.admin = admin;
  next();
});

// MongoDB Connection
mongoose.connect(process.env.MONGO_URI).then(() => console.log('✅ MongoDB connected'))
  .catch(err => console.error('❌ MongoDB connection error:', err));

// Add request logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

// Routes (auth middleware is now inside groupRoutes, no need to duplicate here)
app.use('/groups', groupRoutes);

// Root route
app.get('/', (req, res) => {
  res.send('Splitwise Clone API Running');
});

// Error handling middleware (must be last)
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
