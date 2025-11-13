import { Router } from 'express';
import {
  createMemo,
  getRecentMemos,
  getMemoById,
  searchMemosByEmbedding,
  deleteMemo,
  updateMemo,
  getRelatedMemos,
} from '../controllers/memoController';
import { authenticate } from '../middleware/auth';

const router = Router();

// すべてのメモエンドポイントに認証を適用
router.use(authenticate);

// POST /api/memos - Create a new memo
router.post('/', createMemo);

// GET /api/memos - Get recent memos
router.get('/', getRecentMemos);

// GET /api/memos/search - Search memos by query string (text-based search)
router.get('/search', async (req, res, next) => {
  try {
    const query = req.query.q as string;
    if (!query) {
      res.status(400).json({ error: 'Query parameter "q" is required' });
      return;
    }
    
    const db = (await import('../config/database')).getDatabase();
    const collection = db.collection('memos');
    const userId = new (await import('mongodb')).ObjectId((req as any).user.userId);
    
    // テキストベース検索（transcription と summary を対象）
    const memos = await collection
      .find({
        user_id: userId,
        deleted_at: { $exists: false },
        $or: [
          { transcription: { $regex: query, $options: 'i' } },
          { summary: { $regex: query, $options: 'i' } },
          { tags: { $regex: query, $options: 'i' } }
        ]
      })
      .sort({ created_at: -1 })
      .limit(50)
      .toArray();
    
    const response = memos.map((memo: any) => ({
      id: memo._id.toString(),
      title: memo.summary || '',
      content: memo.transcription || '',
      tags: memo.tags || [],
      audioUrl: memo.audio_url,
      createdAt: memo.created_at,
      updatedAt: memo.updated_at
    }));
    
    res.status(200).json(response);
  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({ error: 'Search failed' });
  }
});

// POST /api/memos/search - Search memos by embedding (must be before /:id)
router.post('/search', searchMemosByEmbedding);

// GET /api/memos/:id - Get a specific memo by ID
router.get('/:id', getMemoById);

// GET /api/memos/:id/related - Get related memos
router.get('/:id/related', getRelatedMemos);

// PATCH /api/memos/:id - Update a memo
router.patch('/:id', updateMemo);

// DELETE /api/memos/:id - Delete a memo
router.delete('/:id', deleteMemo);

export default router;
