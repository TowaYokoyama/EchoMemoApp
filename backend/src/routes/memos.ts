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

// GET /api/memos/search - Search memos by query string (for frontend compatibility)
router.get('/search', async (req, res, next) => {
  try {
    const query = req.query.q as string;
    if (!query) {
      res.status(400).json({ error: 'Query parameter "q" is required' });
      return;
    }
    // リクエストボディを設定してPOSTハンドラーを呼び出す
    req.body = { query, limit: 20 };
    await searchMemosByEmbedding(req, res, next);
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
