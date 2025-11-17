import { z } from 'zod';
import bcrypt from 'bcrypt';
import { ObjectId } from 'mongodb';

// OAuth プロバイダーの型定義
export const OAuthProviders = ['google', 'apple', 'github', 'twitter'] as const;
export type OAuthProvider = typeof OAuthProviders[number];

// Zodスキーマ定義
export const CreateUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).optional(), // OAuth時はパスワード不要
  oauth_provider: z.enum(['google', 'apple', 'github', 'twitter']).optional(),
  oauth_id: z.string().optional(),
}).refine(
  (data) => {
    // OAuth使用時はパスワード不要、通常登録時はパスワード必須
    if (data.oauth_provider && data.oauth_id) {
      return true;
    }
    return !!data.password;
  },
  {
    message: 'Password is required for non-OAuth registration',
    path: ['password'],
  }
);

export const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

export const UserResponseSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  oauth_provider: z.enum(['google', 'apple', 'github', 'twitter']).optional(),
  created_at: z.string(),
  updated_at: z.string(),
});

// TypeScript型
export type CreateUserInput = z.infer<typeof CreateUserSchema>;
export type LoginInput = z.infer<typeof LoginSchema>;
export type UserResponse = z.infer<typeof UserResponseSchema>;

export interface UserDocument {
  _id?: ObjectId;
  email: string;
  password?: string; // OAuth時は不要
  oauth_provider?: OAuthProvider;
  oauth_id?: string;
  settings: {
    biometric_enabled: boolean;
    auto_backup: boolean;
    theme: 'dark' | 'light';
  };
  created_at: Date;
  updated_at: Date;
}

// パスワードハッシュ化
export const hashPassword = async (password: string): Promise<string> => {
  const saltRounds = 10;
  return await bcrypt.hash(password, saltRounds);
};

// パスワード検証
export const verifyPassword = async (
  password: string,
  hashedPassword: string
): Promise<boolean> => {
  return await bcrypt.compare(password, hashedPassword);
};

// UserDocumentをUserResponseに変換
export const documentToResponse = (doc: UserDocument): UserResponse => {
  return {
    id: doc._id.toString(),
    email: doc.email,
    oauth_provider: doc.oauth_provider,
    created_at: doc.created_at.toISOString(),
    updated_at: doc.updated_at.toISOString(),
  };
};
