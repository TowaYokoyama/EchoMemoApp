import { Router } from 'express';
import { transcribeAudio, generateTitle, extractTags, extractDateTime, generateSuggestions, audioUploadMiddleware } from '../controllers/gptController';
import { authenticate } from '../middleware/auth';

const router = Router();

// すべてのエンドポイントに認証を適用
router.use(authenticate);

// POST /api/transcribe - 音声文字起こし（multerミドルウェアを追加）
router.post('/transcribe', audioUploadMiddleware, transcribeAudio);

// POST /api/gpt/generate-title - タイトル生成
router.post('/gpt/generate-title', generateTitle);

// POST /api/gpt/extract-tags - タグ抽出
router.post('/gpt/extract-tags', extractTags);

// POST /api/gpt/extract-datetime - 日時抽出
router.post('/gpt/extract-datetime', extractDateTime);

// POST /api/echo/suggestions - AI提案生成
router.post('/echo/suggestions', generateSuggestions);

export default router;
