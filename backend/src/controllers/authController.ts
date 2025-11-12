import { Request, Response } from 'express';
import { ObjectId } from 'mongodb';
import { getDatabase } from '../config/database';
import {
  CreateUserSchema,
  LoginSchema,
  hashPassword,
  verifyPassword,
  documentToResponse,
  UserDocument,
} from '../models/user';
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
} from '../middleware/auth';

// ユーザー登録
export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    // バリデーション
    const validatedData = CreateUserSchema.parse(req.body);

    const db = getDatabase();
    const usersCollection = db.collection<UserDocument>('users');

    // メールアドレスの重複チェック
    const existingUser = await usersCollection.findOne({ email: validatedData.email });
    if (existingUser) {
      res.status(400).json({ error: 'Email already exists' });
      return;
    }

    // パスワードハッシュ化
    const hashedPassword = await hashPassword(validatedData.password);

    // ユーザー作成
    const newUser: UserDocument = {
      email: validatedData.email,
      password: hashedPassword,
      oauth_provider: validatedData.oauth_provider,
      oauth_id: validatedData.oauth_id,
      settings: {
        biometric_enabled: false,
        auto_backup: false,
        theme: 'dark',
      },
      created_at: new Date(),
      updated_at: new Date(),
    };

    const result = await usersCollection.insertOne(newUser);
    newUser._id = result.insertedId;

    // トークン生成
    const accessToken = generateAccessToken(result.insertedId.toString(), newUser.email);
    const refreshToken = generateRefreshToken(result.insertedId.toString());

    res.status(201).json({
      token: accessToken, // Frontend expects 'token'
      accessToken,
      refreshToken,
      user: documentToResponse(newUser),
    });
  } catch (error: any) {
    console.error('Registration error:', error);
    if (error.name === 'ZodError') {
      res.status(400).json({ error: 'Invalid input', details: error.errors });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ログイン
export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    console.log('Login attempt:', { email: req.body.email });
    
    // バリデーション
    const validatedData = LoginSchema.parse(req.body);

    const db = getDatabase();
    const usersCollection = db.collection<UserDocument>('users');

    // ユーザー検索
    const user = await usersCollection.findOne({ email: validatedData.email });
    if (!user) {
      console.log('User not found:', validatedData.email);
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

    // パスワード検証
    const isValidPassword = await verifyPassword(validatedData.password, user.password);
    if (!isValidPassword) {
      console.log('Invalid password for user:', validatedData.email);
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

    // トークン生成
    const accessToken = generateAccessToken(user._id.toString(), user.email);
    const refreshToken = generateRefreshToken(user._id.toString());

    const responseData = {
      token: accessToken, // Frontend expects 'token'
      accessToken,
      refreshToken,
      user: documentToResponse(user),
    };
    
    console.log('Login successful:', { 
      email: user.email, 
      userId: user._id.toString(),
      responseUser: responseData.user 
    });

    res.json(responseData);
  } catch (error: any) {
    console.error('Login error:', error);
    if (error.name === 'ZodError') {
      res.status(400).json({ error: 'Invalid input', details: error.errors });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
};

// トークンリフレッシュ
export const refreshAccessToken = async (req: Request, res: Response): Promise<void> => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      res.status(400).json({ error: 'Refresh token required' });
      return;
    }

    // リフレッシュトークン検証
    const decoded = verifyRefreshToken(refreshToken);
    if (!decoded) {
      res.status(401).json({ error: 'Invalid refresh token' });
      return;
    }

    const db = getDatabase();
    const usersCollection = db.collection<UserDocument>('users');

    // ユーザー取得
    const user = await usersCollection.findOne({ _id: new ObjectId(decoded.userId) });
    if (!user) {
      res.status(401).json({ error: 'User not found' });
      return;
    }

    // 新しいアクセストークン生成
    const accessToken = generateAccessToken(user._id.toString(), user.email);

    res.json({ accessToken });
  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// 現在のユーザー情報取得
export const getCurrentUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = (req as any).userId; // authenticate middleware sets this

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const db = getDatabase();
    const usersCollection = db.collection<UserDocument>('users');

    const user = await usersCollection.findOne({ _id: new ObjectId(userId) });
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    res.json(documentToResponse(user));
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
