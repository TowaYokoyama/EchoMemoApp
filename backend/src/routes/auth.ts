import { Router } from 'express';
import { register, login, refreshAccessToken, getCurrentUser, oauthLogin } from '../controllers/authController';
import { authenticate } from '../middleware/auth';

const router = Router();

// POST /api/auth/register - ユーザー登録
router.post('/register', register);

// POST /api/auth/login - ログイン
router.post('/login', login);

// POST /api/auth/oauth - OAuth ログイン/登録
router.post('/oauth', oauthLogin);

// POST /api/auth/refresh - トークンリフレッシュ
router.post('/refresh', refreshAccessToken);

// GET /api/auth/me - 現在のユーザー情報取得
router.get('/me', authenticate, getCurrentUser);

export default router;
