import { Request, Response } from 'express';
import { z } from 'zod';
import multer from 'multer';
import { asyncHandler, AppError } from '../middleware/errorHandler';
import {
  transcribeAudioService,
  generateTitleService,
  extractTagsService,
  extractDateTimeService,
  generateSuggestionsService,
} from '../services/ai.service';

// Multer設定: メモリにファイルを保存
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 25 * 1024 * 1024, // 25MB (Whisper API limit)
  },
});

// フロントエンドは 'file' フィールド名で送信
export const audioUploadMiddleware = upload.single('file');

// バリデーションスキーマ
const GenerateTitleSchema = z.object({
  content: z.string().min(1),
});

const ExtractTagsSchema = z.object({
  content: z.string().min(1),
});

const ExtractDateTimeSchema = z.object({
  content: z.string().min(1),
});

const GenerateSuggestionsSchema = z.object({
  memoIds: z.array(z.string()),
});

// 音声文字起こし (Whisper API)
export const transcribeAudio = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  // ファイルがアップロードされているか確認
  if (!req.file) {
    throw new AppError(400, 'Audio file is required');
  }
  
  const text = await transcribeAudioService(
    req.file.buffer,
    req.file.originalname,
    req.file.mimetype
  );
  
  res.json({ text });
});

// タイトル生成
export const generateTitle = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const validatedData = GenerateTitleSchema.parse(req.body);
  const title = await generateTitleService(validatedData.content);
  res.json({ title });
});

// タグ抽出
export const extractTags = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const validatedData = ExtractTagsSchema.parse(req.body);
  const tags = await extractTagsService(validatedData.content);
  res.json({ tags });
});

// 日時抽出
export const extractDateTime = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const validatedData = ExtractDateTimeSchema.parse(req.body);
  const dateTimeInfo = await extractDateTimeService(validatedData.content);
  res.json(dateTimeInfo);
});

// Echo提案生成
export const generateSuggestions = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const validatedData = GenerateSuggestionsSchema.parse(req.body);
  const suggestions = await generateSuggestionsService(validatedData.memoIds);
  res.json(suggestions);
});
