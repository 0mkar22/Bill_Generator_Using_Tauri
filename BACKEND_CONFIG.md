# Example Backend Configuration for Docker

This file shows how to structure your Node.js Express backend to work seamlessly with Docker.

## backend/package.json

```json
{
  "name": "bill-generator-backend",
  "version": "1.0.0",
  "description": "Bill Generator Backend - Node.js Express with MongoDB",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^7.0.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3",
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "nodemon": "^2.0.20"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
```

## backend/index.js (or server.js)

```javascript
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Database Connection
const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/bill_generator';

mongoose.connect(mongoUri, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  retryWrites: true,
  w: 'majority'
})
.then(() => {
  console.log('✓ Connected to MongoDB');
})
.catch((err) => {
  console.error('✗ MongoDB connection error:', err);
  // Don't exit on connection error - try again
  setTimeout(() => {
    mongoose.connect(mongoUri);
  }, 5000);
});

// Health Check Endpoint (required for Docker health checks)
app.get('/health', (req, res) => {
  const dbConnected = mongoose.connection.readyState === 1;
  
  if (dbConnected) {
    res.status(200).json({
      status: 'OK',
      timestamp: new Date(),
      database: 'connected'
    });
  } else {
    res.status(503).json({
      status: 'UNHEALTHY',
      timestamp: new Date(),
      database: 'disconnected'
    });
  }
});

// API Routes
app.use('/api/bills', require('./routes/bills'));
app.use('/api/customers', require('./routes/customers'));

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.path
  });
});

// Error Handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error'
  });
});

// Start Server
const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ Backend server running on http://0.0.0.0:${PORT}`);
});

// Graceful Shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('Server closed');
    mongoose.connection.close(false, () => {
      console.log('MongoDB connection closed');
      process.exit(0);
    });
  });
});

module.exports = app;
```

## backend/.env (for local development)

```env
NODE_ENV=development
MONGODB_URI=mongodb://localhost:27017/bill_generator
PORT=5000
RUST_LOG=info
```

## Docker-specific Notes for Backend

1. **Use 0.0.0.0 instead of localhost** in `app.listen()` so container can accept external connections
2. **Environment variables** are passed via docker-compose.yml
3. **Health check** endpoint (`/health`) is critical for Docker health checks
4. **Graceful shutdown** handling ensures clean container stops
5. **Retry logic** for MongoDB connection helps with startup timing
6. **Mongoose retry options** (`retryWrites`) handle temporary disconnections

## Example Bills Route (backend/routes/bills.js)

```javascript
const express = require('express');
const router = express.Router();
const Bill = require('../models/Bill');

// GET all bills
router.get('/', async (req, res) => {
  try {
    const bills = await Bill.find();
    res.json(bills);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// CREATE new bill
router.post('/', async (req, res) => {
  const bill = new Bill(req.body);
  try {
    const savedBill = await bill.save();
    res.status(201).json(savedBill);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// GET single bill
router.get('/:id', async (req, res) => {
  try {
    const bill = await Bill.findById(req.params.id);
    if (!bill) {
      return res.status(404).json({ error: 'Bill not found' });
    }
    res.json(bill);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE bill
router.put('/:id', async (req, res) => {
  try {
    const bill = await Bill.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!bill) {
      return res.status(404).json({ error: 'Bill not found' });
    }
    res.json(bill);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// DELETE bill
router.delete('/:id', async (req, res) => {
  try {
    const bill = await Bill.findByIdAndDelete(req.params.id);
    if (!bill) {
      return res.status(404).json({ error: 'Bill not found' });
    }
    res.json({ message: 'Bill deleted', bill });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
```

## Example Bill Model (backend/models/Bill.js)

```javascript
const mongoose = require('mongoose');

const billSchema = new mongoose.Schema({
  billNumber: {
    type: String,
    required: true,
    unique: true
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Customer',
    required: true
  },
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  items: [{
    description: String,
    quantity: Number,
    price: Number,
    total: Number
  }],
  issueDate: {
    type: Date,
    default: Date.now
  },
  dueDate: Date,
  status: {
    type: String,
    enum: ['paid', 'pending', 'overdue'],
    default: 'pending'
  }
}, { timestamps: true });

module.exports = mongoose.model('Bill', billSchema);
```

## Debugging

To debug backend in Docker:

```bash
# View logs
docker-compose logs -f backend

# Execute commands
docker-compose exec backend npm list

# Connect to shell
docker-compose exec backend /bin/sh

# Test MongoDB connection from backend container
docker-compose exec backend npm install --save mongoose
```
