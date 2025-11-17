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

    // パスワードハッシュ化（OAuth時は不要）
    let hashedPassword: string | undefined;
    if (validatedData.password) {
      hashedPassword = await hashPassword(validatedData.password);
    }

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

    try {
      const result = await usersCollection.insertOne(newUser);
      newUser._id = result.insertedId;

      // トークン生成
      const accessToken = generateAccessToken(result.insertedId.toString(), newUser.email);
      const refreshToken = generateRefreshToken(result.insertedId.toString());

      res.status(201).json({
        token: accessToken, 
        accessToken,
        refreshToken,
        user: documentToResponse(newUser),
      });
    } catch (dbError: unknown) {
      // MongoDB のユニークインデックス違反をキャッチ
      if (dbError && typeof dbError === 'object' && 'code' in dbError && dbError.code === 11000) {
        res.status(400).json({ error: 'Email already exists' });
        return;
      }
      throw dbError;
    }
  } catch (error: unknown) {
    if (error && typeof error === 'object' && 'name' in error && error.name === 'ZodError') {
      res.status(400).json({ error: 'Invalid input', details: (error as any).errors });
      return;
    }
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ログイン
export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    // バリデーション
    const validatedData = LoginSchema.parse(req.body);

    const db = getDatabase();
    const usersCollection = db.collection<UserDocument>('users');

    // ユーザー検索（必要なフィールドのみ取得）
    const user = await usersCollection.findOne(
      { email: validatedData.email },
      { 
        projection: { 
          _id: 1, 
          email: 1, 
          password: 1, 
          oauth_provider: 1,
          created_at: 1,
          updated_at: 1
        } 
      }
    );
    
    if (!user) {
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

    // パスワード検証
    if (!user.password) {
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }
    
    const isValidPassword = await verifyPassword(validatedData.password, user.password);
    if (!isValidPassword) {
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

    // トークン生成
    const accessToken = generateAccessToken(user._id!.toString(), user.email);
    const refreshToken = generateRefreshToken(user._id!.toString());

    const responseData = {
      token: accessToken,
      accessToken,
      refreshToken,
      user: documentToResponse(user),
    };
    
    console.log('Login successful:', { 
      email: user.email, 
      userId: user._id!.toString(),
      responseUser: responseData.user 
    });

    res.json(responseData);
  } catch (error: unknown) {
    if (error && typeof error === 'object' && 'name' in error && error.name === 'ZodError') {
      res.status(400).json({ error: 'Invalid input', details: (error as any).errors });
      return;
    }
    console.error('Login error:', error);
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

    // ユーザー取得（必要なフィールドのみ）
    const user = await usersCollection.findOne(
      { _id: new ObjectId(decoded.userId) },
      { projection: { _id: 1, email: 1 } }
    );
    
    if (!user) {
      res.status(401).json({ error: 'User not found' });
      return;
    }

    // 新しいアクセストークン生成
    const accessToken = generateAccessToken(user._id!.toString(), user.email);

    res.json({ accessToken });
  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// 現在のユーザー情報取得
export const getCurrentUser = async (req: Request, res: Response): Promise<void> => {
  try {
    // AuthRequest 型を使用して型安全に
    const user = (req as any).user;

    if (!user || !user.userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const db = getDatabase();
    const usersCollection = db.collection<UserDocument>('users');

    const userDoc = await usersCollection.findOne(
      { _id: new ObjectId(user.userId) },
      { projection: { password: 0 } } // パスワードは除外
    );
    
    if (!userDoc) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    res.json(documentToResponse(userDoc));
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// OAuth ログイン/登録
export const oauthLogin = async (req: Request, res: Response): Promise<void> => {
  try {
    const validatedData = CreateUserSchema.parse(req.body);

    if (!validatedData.oauth_provider || !validatedData.oauth_id) {
      res.status(400).json({ error: 'OAuth provider and ID are required' });
      return;
    }

    const db = getDatabase();
    const usersCollection = db.collection<UserDocument>('users');

    // OAuth プロバイダーとIDで既存ユーザーを検索
    let user = await usersCollection.findOne(
      { 
        oauth_provider: validatedData.oauth_provider,
        oauth_id: validatedData.oauth_id 
      },
      { projection: { password: 0 } }
    );

    // 既存ユーザーがいない場合は新規作成
    if (!user) {
      const newUser: UserDocument = {
        email: validatedData.email,
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

      try {
        const result = await usersCollection.insertOne(newUser);
        // 挿入後、再度取得して型を確実にする
        user = await usersCollection.findOne(
          { _id: result.insertedId },
          { projection: { password: 0 } }
        );
        
        if (!user) {
          throw new Error('Failed to create user');
        }
      } catch (dbError: unknown) {
        // ユニークインデックス違反（同じメールアドレスが既に存在）
        if (dbError && typeof dbError === 'object' && 'code' in dbError && dbError.code === 11000) {
          res.status(400).json({ error: 'Email already exists with different provider' });
          return;
        }
        throw dbError;
      }
    }

    // トークン生成
    const accessToken = generateAccessToken(user._id!.toString(), user.email);
    const refreshToken = generateRefreshToken(user._id!.toString());

    res.json({
      token: accessToken,
      accessToken,
      refreshToken,
      user: documentToResponse(user),
    });
  } catch (error: unknown) {
    if (error && typeof error === 'object' && 'name' in error && error.name === 'ZodError') {
      res.status(400).json({ error: 'Invalid input', details: (error as any).errors });
      return;
    }
    console.error('OAuth login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
