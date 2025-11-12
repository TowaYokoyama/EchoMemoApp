import { Router } from 'express';
import { transcribeAudio, generateTitle, extractTags, generateSuggestions } from '../controllers/gptController';
import { authenticate } from '../middleware/auth';

const router = Router();

// すべてのエンドポイントに認証を適用
router.use(authenticate);

// POST /api/transcribe - 音声文字起こし
router.post('/transcribe', transcribeAudio);

// POST /api/gpt/generate-title - タイトル生成
router.post('/gpt/generate-title', generateTitle);

// POST /api/gpt/extract-tags - タグ抽出
router.post('/gpt/extract-tags', extractTags);

// POST /api/echo/suggestions - AI提案生成
router.post('/echo/suggestions', generateSuggestions);

export default router;
