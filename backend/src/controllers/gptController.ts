import { Request, Response } from 'express';
import { z } from 'zod';

// OpenAI APIキーを環境変数から取得（遅延評価で取得）
const getOpenAIKey = () => process.env.OPENAI_API_KEY;
const OPENAI_API_URL = 'https://api.openai.com/v1';

// OpenAI APIが設定されているかチェック（関数として実装）
const isOpenAIConfigured = () => {
  const key = getOpenAIKey();
  return !!key && key.length > 0;
};

// 初期化フラグ（最初の呼び出し時のみログ出力）
let isInitialized = false;

// 初期化ログを出力（遅延実行）
const logInitialization = () => {
  if (!isInitialized) {
    isInitialized = true;
    if (isOpenAIConfigured()) {
      console.log('✅ OpenAI API configured successfully');
      console.log(`   API Key length: ${getOpenAIKey()?.length || 0} characters`);
    } else {
      console.warn('⚠️  OPENAI_API_KEY is not set. AI features will use mock implementations.');
    }
  }
};

// バリデーションスキーマ
const TranscribeSchema = z.object({
  audioData: z.string(), // Base64エンコードされた音声データ
});

const GenerateTitleSchema = z.object({
  content: z.string().min(1),
});

const ExtractTagsSchema = z.object({
  content: z.string().min(1),
});

const GenerateSuggestionsSchema = z.object({
  memoIds: z.array(z.string()),
});

// 音声文字起こし (Whisper API)
export const transcribeAudio = async (req: Request, res: Response): Promise<void> => {
  try {
    logInitialization();
    console.log('Transcribe audio endpoint called');
    
    if (!isOpenAIConfigured()) {
      // モック実装
      res.json({
        text: 'これはサンプルの文字起こしテキストです。実際のWhisper API統合にはOPENAI_API_KEYが必要です。',
      });
      return;
    }
    
    // TODO: 実際のファイルアップロード処理を実装
    // Multerなどを使用して音声ファイルを受け取る必要があります
    /*
    const formData = new FormData();
    formData.append('file', audioFile);
    formData.append('model', 'whisper-1');
    
    const response = await fetch(`${OPENAI_API_URL}/audio/transcriptions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${getOpenAIKey()}`,
      },
      body: formData,
    });
    
    const data = await response.json();
    res.json({ text: data.text });
    */
    
    res.json({
      text: 'Whisper API統合は未実装です。ファイルアップロード機能の追加が必要です。',
    });
  } catch (error) {
    console.error('Transcription error:', error);
    res.status(500).json({ error: 'Transcription failed' });
  }
};

// タイトル生成
export const generateTitle = async (req: Request, res: Response): Promise<void> => {
  try {
    const validatedData = GenerateTitleSchema.parse(req.body);
    const content = validatedData.content;
    
    if (!isOpenAIConfigured()) {
      // フォールバック: 簡易的な実装
      const firstSentence = content.split(/[。.!！?？\n]/)[0];
      const title = firstSentence.substring(0, 30) + (firstSentence.length > 30 ? '...' : '');
      
      res.json({
        title: title || 'タイトルなし',
      });
      return;
    }
    
    // OpenAI GPT APIの呼び出し
    const response = await fetch(`${OPENAI_API_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${getOpenAIKey()}`,
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: 'あなたはメモのタイトルを生成する専門家です。与えられたメモの内容から、簡潔で分かりやすい日本語のタイトルを1つ生成してください。タイトルは30文字以内にしてください。',
          },
          {
            role: 'user',
            content: `以下のメモの内容から適切なタイトルを生成してください:\n\n${content}`,
          },
        ],
        max_tokens: 50,
        temperature: 0.7,
      }),
    });
    
    const data = await response.json() as any;
    
    if (!response.ok) {
      throw new Error(`OpenAI API error: ${data.error?.message || 'Unknown error'}`);
    }
    
    const title = data.choices[0]?.message?.content?.trim() || 'タイトルなし';
    
    res.json({ title });
  } catch (error: any) {
    console.error('Generate title error:', error);
    if (error.name === 'ZodError') {
      res.status(400).json({ error: 'Invalid input', details: error.errors });
      return;
    }
    res.status(500).json({ error: 'Title generation failed' });
  }
};

// タグ抽出
export const extractTags = async (req: Request, res: Response): Promise<void> => {
  try {
    const validatedData = ExtractTagsSchema.parse(req.body);
    const content = validatedData.content;
    
    if (!isOpenAIConfigured()) {
      // フォールバック: 簡易的な実装（頻出単語ベース）
      const words = content
        .replace(/[。、.!！?？\n]/g, ' ')
        .split(' ')
        .filter(word => word.length > 2 && word.length < 10);
      
      const tags = Array.from(new Set(words)).slice(0, 5);
      
      res.json({
        tags: tags.length > 0 ? tags : ['一般'],
      });
      return;
    }
    
    // OpenAI GPT APIでより高度なタグ抽出
    const response = await fetch(`${OPENAI_API_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${getOpenAIKey()}`,
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: 'あなたはメモの内容を分析してタグを抽出する専門家です。与えられたメモの内容から、関連性の高いタグを3〜5個抽出してください。タグは日本語で、カテゴリーやトピックを表す単語にしてください。',
          },
          {
            role: 'user',
            content: `以下のメモの内容から適切なタグを抽出してください。タグはカンマ区切りで出力してください:\n\n${content}`,
          },
        ],
        max_tokens: 50,
        temperature: 0.5,
      }),
    });
    
    const data = await response.json() as any;
    
    if (!response.ok) {
      throw new Error(`OpenAI API error: ${data.error?.message || 'Unknown error'}`);
    }
    
    const tagsText = data.choices[0]?.message?.content?.trim() || '一般';
    const tags = tagsText.split(/[,、]/).map((tag: string) => tag.trim()).filter((tag: string) => tag.length > 0);
    
    res.json({
      tags: tags.length > 0 ? tags.slice(0, 5) : ['一般'],
    });
  } catch (error: any) {
    console.error('Extract tags error:', error);
    if (error.name === 'ZodError') {
      res.status(400).json({ error: 'Invalid input', details: error.errors });
      return;
    }
    res.status(500).json({ error: 'Tag extraction failed' });
  }
};

// Echo提案生成
export const generateSuggestions = async (req: Request, res: Response): Promise<void> => {
  try {
    const validatedData = GenerateSuggestionsSchema.parse(req.body);
    
    // フォールバック: ダミーデータを返す
    const suggestions = [
      {
        id: '1',
        type: 'connection',
        title: '関連するメモを発見',
        description: '複数のメモに共通のテーマが見つかりました',
        relatedMemoIds: validatedData.memoIds.slice(0, 2),
        priority: 5,
        createdAt: new Date(),
        isActioned: false,
      },
      {
        id: '2',
        type: 'insight',
        title: 'パターンの発見',
        description: '最近のメモから興味深いパターンが見つかりました',
        relatedMemoIds: validatedData.memoIds.slice(0, 3),
        priority: 4,
        createdAt: new Date(),
        isActioned: false,
      },
    ];
    
    // TODO: OpenAI APIを使用してメモの関連性を分析し、
    // より高度な提案を生成する
    // 1. メモの内容を取得
    // 2. Embeddingを生成
    // 3. 類似度を計算
    // 4. GPTで洞察を生成
    
    res.json(suggestions);
  } catch (error: any) {
    console.error('Generate suggestions error:', error);
    if (error.name === 'ZodError') {
      res.status(400).json({ error: 'Invalid input', details: error.errors });
      return;
    }
    res.status(500).json({ error: 'Suggestion generation failed' });
  }
};
