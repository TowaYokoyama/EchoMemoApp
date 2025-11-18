// Load environment variables FIRST
import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import cors from 'cors';
import compression from 'compression';
import { connectToDatabase, closeDatabaseConnection } from './config/database';
import memoRoutes from './routes/memos';
import authRoutes from './routes/auth';
import gptRoutes from './routes/gpt';
import { errorHandler } from './middleware/errorHandler';

const app = express();
const PORT = process.env.PORT || 3000;


app.use(cors({
  origin: '*',
  credentials: true
})); // Enable CORS for all origins (development)
app.use(compression()); // Gzip compression for responses
app.use(express.json({ limit: '10mb' })); // Parse JSON request bodies with size limit


app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});


app.use('/api/auth', authRoutes);
app.use('/api/memos', memoRoutes);
app.use('/api', gptRoutes);


app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Error handling middleware (must be last)
app.use(errorHandler);

async function startServer() {
  try {
    // Validate required environment variables
    if (!process.env.MONGODB_URI) {
      console.error('❌ MONGODB_URI environment variable is required');
      process.exit(1);
    }

   
    await connectToDatabase();

    // Start listening (0.0.0.0で全てのネットワークインターフェースでリッスン)
    const server = app.listen(Number(PORT), '0.0.0.0', () => {
      console.log(`🚀 Server running on:`);
      console.log(`   Local:   http://localhost:${PORT}`);
      console.log(`   Network: http://192.168.0.15:${PORT}`);
      console.log(`📝 API endpoints:`);
      console.log(`   POST   /api/auth/register`);
      console.log(`   POST   /api/auth/login`);
      console.log(`   GET    /api/auth/me`);
      console.log(`   POST   /api/memos`);
      console.log(`   GET    /api/memos`);
      console.log(`   GET    /api/memos/:id`);
      console.log(`   GET    /api/memos/search?q=query`);
      console.log(`   POST   /api/transcribe`);
      console.log(`   POST   /api/gpt/generate-title`);
      console.log(`   POST   /api/gpt/extract-tags`);
      console.log(`   POST   /api/echo/suggestions`);
    });

    // Graceful shutdown
    process.on('SIGTERM', async () => {
      console.log('SIGTERM signal received: closing HTTP server');
      server.close(async () => {
        console.log('HTTP server closed');
        await closeDatabaseConnection();
        process.exit(0);
      });
    });

    process.on('SIGINT', async () => {
      console.log('\nSIGINT signal received: closing HTTP server');
      server.close(async () => {
        console.log('HTTP server closed');
        await closeDatabaseConnection();
        process.exit(0);
      });
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
