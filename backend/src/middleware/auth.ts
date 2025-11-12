import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const REFRESH_SECRET = process.env.REFRESH_SECRET || 'your-refresh-secret-change-in-production';

export interface JWTPayload {
  userId: string;
  email: string;
}

export interface AuthRequest extends Request {
  user?: JWTPayload;
}

// アクセストークン生成（15分）
export const generateAccessToken = (userId: string, email: string): string => {
  return jwt.sign(
    { userId, email },
    JWT_SECRET,
    { expiresIn: '15m', algorithm: 'HS256' }
  );
};

// リフレッシュトークン生成（7日）
export const generateRefreshToken = (userId: string): string => {
  return jwt.sign(
    { userId, type: 'refresh' },
    REFRESH_SECRET,
    { expiresIn: '7d', algorithm: 'HS256' }
  );
};

// アクセストークン検証ミドルウェア
export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Unauthorized: No token provided' });
      return;
    }

    const token = authHeader.split(' ')[1];

    try {
      const decoded = jwt.verify(token, JWT_SECRET) as JWTPayload;
      req.user = decoded;
      next();
    } catch (error: any) {
      if (error.name === 'TokenExpiredError') {
        res.status(401).json({ error: 'Token expired' });
        return;
      }
      res.status(401).json({ error: 'Invalid token' });
      return;
    }
  } catch (error) {
    console.error('Authentication error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// リフレッシュトークン検証
export const verifyRefreshToken = (token: string): { userId: string } | null => {
  try {
    const decoded = jwt.verify(token, REFRESH_SECRET) as any;
    if (decoded.type !== 'refresh') {
      return null;
    }
    return { userId: decoded.userId };
  } catch (error) {
    return null;
  }
};
