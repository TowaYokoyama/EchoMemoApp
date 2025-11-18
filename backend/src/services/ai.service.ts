import OpenAI from 'openai';
import { getDatabase } from '../config/database';
import { ObjectId } from 'mongodb';
import { cache } from '../utils/cache';

// OpenAIクライアントの初期化（遅延評価）
let openaiClient: OpenAI | null = null;
let isInitialized = false;

const getOpenAIClient = (): OpenAI | null => {
  if (!isInitialized) {
    isInitialized = true;
    const apiKey = process.env.OPENAI_API_KEY;
    
    if (apiKey && apiKey.length > 0) {
      openaiClient = new OpenAI({
        apiKey,
        timeout: 30000, // 30秒のタイムアウト
        maxRetries: 2,
      });
      console.log('✅ OpenAI API configured successfully');
      console.log(`   API Key length: ${apiKey.length} characters`);
    } else {
      console.warn('⚠️  OPENAI_API_KEY is not set. AI features will use mock implementations.');
    }
  }
  
  return openaiClient;
};

const isOpenAIConfigured = (): boolean => {
  return getOpenAIClient() !== null;
};

// 音声文字起こし (Whisper API)
export const transcribeAudioService = async (
  audioBuffer: Buffer,
  filename: string,
  mimetype: string
): Promise<string> => {
  console.log('🎤 Starting transcription service');
  console.log(`📁 File: ${filename}, size: ${audioBuffer.length} bytes`);
  
  const client = getOpenAIClient();
  
  if (!client) {
    console.log('⚠️  Using mock transcription (no OpenAI API key)');
    return 'これはサンプルの文字起こしテキストです。実際の文字起こしにはOPENAI_API_KEYが必要です。';
  }
  
  try {
    console.log('🚀 Calling Whisper API...');
    
    // OpenAI SDKを使用してファイルをアップロード
    const file = new File([audioBuffer], filename, { type: mimetype });
    
    const transcription = await client.audio.transcriptions.create({
      file,
      model: 'whisper-1',
      language: 'ja',
    });
    
    console.log('✅ Transcription successful:', transcription.text.substring(0, 50) + '...');
    return transcription.text;
  } catch (error: any) {
    console.error('❌ Whisper API error:', error);
    throw new Error(`Whisper API error: ${error.message}`);
  }
};

// タイトル生成（キャッシュ対応）
export const generateTitleService = async (content: string): Promise<string> => {
  // キャッシュチェック
  const cacheKey = cache.generateKey('title', content);
  const cachedTitle = cache.get<string>(cacheKey);
  
  if (cachedTitle) {
    console.log('✨ Cache hit: title generation');
    return cachedTitle;
  }
  
  const client = getOpenAIClient();
  
  if (!client) {
    // フォールバック: 簡易的な実装
    const firstSentence = content.split(/[。.!！?？\n]/)[0];
    const title = firstSentence.substring(0, 30) + (firstSentence.length > 30 ? '...' : '');
    return title || 'タイトルなし';
  }
  
  try {
    const completion = await client.chat.completions.create({
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
    });
    
    const title = completion.choices[0]?.message?.content?.trim() || 'タイトルなし';
    
    // キャッシュに保存（1時間）
    cache.set(cacheKey, title, 3600);
    
    return title;
  } catch (error: any) {
    console.error('Generate title error:', error);
    throw new Error(`Title generation failed: ${error.message}`);
  }
};

// タグ抽出（キャッシュ対応）
export const extractTagsService = async (content: string): Promise<string[]> => {
  // キャッシュチェック
  const cacheKey = cache.generateKey('tags', content);
  const cachedTags = cache.get<string[]>(cacheKey);
  
  if (cachedTags) {
    console.log('✨ Cache hit: tag extraction');
    return cachedTags;
  }
  
  const client = getOpenAIClient();
  
  if (!client) {
    // フォールバック: 簡易的な実装（頻出単語ベース）
    const words = content
      .replace(/[。、.!！?？\n]/g, ' ')
      .split(' ')
      .filter(word => word.length > 2 && word.length < 10);
    
    const tags = Array.from(new Set(words)).slice(0, 5);
    return tags.length > 0 ? tags : ['一般'];
  }
  
  try {
    const completion = await client.chat.completions.create({
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
    });
    
    const tagsText = completion.choices[0]?.message?.content?.trim() || '一般';
    const tags = tagsText.split(/[,、]/).map(tag => tag.trim()).filter(tag => tag.length > 0);
    const result = tags.length > 0 ? tags.slice(0, 5) : ['一般'];
    
    // キャッシュに保存（1時間）
    cache.set(cacheKey, result, 3600);
    
    return result;
  } catch (error: any) {
    console.error('Extract tags error:', error);
    throw new Error(`Tag extraction failed: ${error.message}`);
  }
};

// 日時抽出
export const extractDateTimeService = async (content: string): Promise<{
  hasDateTime: boolean;
  datetime: string | null;
  original: string | null;
}> => {
  const client = getOpenAIClient();
  
  if (!client) {
    // フォールバック: 簡易的な正規表現ベース
    return extractDateTimeSimple(content);
  }
  
  try {
    const completion = await client.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: `あなたは日本語テキストから日時情報を抽出する専門家です。
現在の日時: ${new Date().toISOString()}
テキストから日時に関する表現を見つけて、ISO8601形式の日時に変換してください。
「明日」「来週」「3日後」などの相対的な表現も正確に解釈してください。
日時情報が見つからない場合はnullを返してください。`,
        },
        {
          role: 'user',
          content: `以下のテキストから日時情報を抽出してJSON形式で返してください:\n\n${content}\n\n形式: {"datetime": "ISO8601形式またはnull", "original": "元のテキスト表現またはnull", "hasDateTime": true/false}`,
        },
      ],
      max_tokens: 100,
      temperature: 0.3,
    });
    
    const resultText = completion.choices[0]?.message?.content?.trim() || '{}';
    const jsonMatch = resultText.match(/\{[\s\S]*\}/);
    const result = jsonMatch ? JSON.parse(jsonMatch[0]) : { hasDateTime: false, datetime: null, original: null };
    
    return result;
  } catch (error: any) {
    console.error('Extract datetime error:', error);
    throw new Error(`DateTime extraction failed: ${error.message}`);
  }
};

// 簡易的な日時抽出（フォールバック用）
function extractDateTimeSimple(text: string) {
  const now = new Date();
  
  // 明日のパターン
  if (text.match(/明日.*?(\d{1,2})時/)) {
    const hour = parseInt(text.match(/明日.*?(\d{1,2})時/)![1]);
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(hour, 0, 0, 0);
    return {
      hasDateTime: true,
      datetime: tomorrow.toISOString(),
      original: text.match(/明日.*?(\d{1,2})時/)![0],
    };
  }
  
  // 今日のパターン
  if (text.match(/今日.*?(\d{1,2})時/) || text.match(/(\d{1,2})時/)) {
    const match = text.match(/(?:今日.*?)?(\d{1,2})時/);
    if (match) {
      const hour = parseInt(match[1]);
      const today = new Date(now);
      today.setHours(hour, 0, 0, 0);
      return {
        hasDateTime: true,
        datetime: today.toISOString(),
        original: match[0],
      };
    }
  }
  
  // 日付のパターン (MM月DD日)
  if (text.match(/(\d{1,2})月(\d{1,2})日/)) {
    const match = text.match(/(\d{1,2})月(\d{1,2})日/)!;
    const month = parseInt(match[1]) - 1;
    const day = parseInt(match[2]);
    const date = new Date(now.getFullYear(), month, day);
    return {
      hasDateTime: true,
      datetime: date.toISOString(),
      original: match[0],
    };
  }
  
  return {
    hasDateTime: false,
    datetime: null,
    original: null,
  };
}

// Echo提案生成
export const generateSuggestionsService = async (memoIds: string[]): Promise<any[]> => {
  if (memoIds.length === 0) {
    return [];
  }
  
  // メモの内容を取得
  const db = getDatabase();
  const collection = db.collection('memos');
  
  const memos = await collection
    .find({ 
      _id: { $in: memoIds.map(id => new ObjectId(id)) }
    })
    .limit(50) // パフォーマンス: 最大50件まで
    .toArray();
  
  if (memos.length < 2) {
    return [];
  }
  
  const suggestions: any[] = [];
  
  // 1. タグベースの関連性を分析（高速）
  const tagGroups = analyzeTagPatterns(memos);
  for (const group of tagGroups) {
    suggestions.push({
      id: `tag-${group.tag}`,
      type: 'connection',
      title: `「${group.tag}」に関するメモ`,
      description: `${group.count}件のメモが「${group.tag}」タグで関連しています`,
      relatedMemoIds: group.memoIds,
      priority: Math.min(group.count, 5),
      createdAt: new Date(),
      isActioned: false,
    });
  }
  
  // 2. Embeddingベースの類似度分析（中速）
  if (memos.some((m: any) => m.embedding)) {
    const similarityGroups = await analyzeSimilarityPatterns(memos);
    for (const group of similarityGroups) {
      suggestions.push({
        id: `similarity-${group.id}`,
        type: 'connection',
        title: '類似したテーマのメモ',
        description: `${group.count}件のメモに類似したテーマが見つかりました`,
        relatedMemoIds: group.memoIds,
        priority: 4,
        createdAt: new Date(),
        isActioned: false,
      });
    }
  }
  
  // 3. OpenAI GPTで洞察を生成（低速、オプション）
  if (isOpenAIConfigured() && memos.length >= 3 && memos.length <= 10) {
    try {
      const insights = await generateAIInsights(memos);
      if (insights) {
        suggestions.push({
          id: `insight-ai`,
          type: 'insight',
          title: insights.title,
          description: insights.description,
          relatedMemoIds: memoIds.slice(0, 5),
          priority: 5,
          createdAt: new Date(),
          isActioned: false,
        });
      }
    } catch (error) {
      console.error('AI insight generation failed:', error);
      // エラーが出てもスキップして続行
    }
  }
  
  // 優先度順にソートして上位5件まで返す
  suggestions.sort((a, b) => b.priority - a.priority);
  return suggestions.slice(0, 5);
};

// タグパターン分析（高速）
function analyzeTagPatterns(memos: any[]) {
  const tagCounts = new Map<string, string[]>();
  
  for (const memo of memos) {
    if (memo.tags && Array.isArray(memo.tags)) {
      for (const tag of memo.tags) {
        if (!tagCounts.has(tag)) {
          tagCounts.set(tag, []);
        }
        tagCounts.get(tag)!.push(memo._id.toString());
      }
    }
  }
  
  // 2件以上のメモがあるタグのみ返す
  const groups = [];
  for (const [tag, memoIds] of tagCounts.entries()) {
    if (memoIds.length >= 2) {
      groups.push({ tag, count: memoIds.length, memoIds });
    }
  }
  
  // 多い順にソート
  groups.sort((a, b) => b.count - a.count);
  return groups.slice(0, 3); // 上位3グループまで
}

// 類似度パターン分析（中速）
async function analyzeSimilarityPatterns(memos: any[]) {
  const { cosineSimilarity } = await import('../utils/similarity');
  const groups: any[] = [];
  const processed = new Set<string>();
  
  for (let i = 0; i < memos.length; i++) {
    const memo1 = memos[i];
    if (!memo1.embedding || processed.has(memo1._id.toString())) continue;
    
    const similarMemos = [memo1._id.toString()];
    
    for (let j = i + 1; j < memos.length; j++) {
      const memo2 = memos[j];
      if (!memo2.embedding || processed.has(memo2._id.toString())) continue;
      
      const similarity = cosineSimilarity(memo1.embedding, memo2.embedding);
      if (similarity > 0.75) { // 75%以上の類似度
        similarMemos.push(memo2._id.toString());
        processed.add(memo2._id.toString());
      }
    }
    
    if (similarMemos.length >= 2) {
      groups.push({
        id: memo1._id.toString(),
        count: similarMemos.length,
        memoIds: similarMemos,
      });
      processed.add(memo1._id.toString());
    }
    
    if (groups.length >= 2) break; // 最大2グループまで
  }
  
  return groups;
}

// AI洞察生成（低速）
async function generateAIInsights(memos: any[]) {
  const client = getOpenAIClient();
  if (!client) return null;
  
  // メモの要約を結合
  const summaries = memos
    .map(m => m.summary || m.transcription?.substring(0, 100))
    .filter(Boolean)
    .slice(0, 5);
  
  if (summaries.length < 3) return null;
  
  const prompt = `以下のメモから共通のテーマやパターンを見つけて、簡潔な洞察を提供してください。

メモ:
${summaries.map((s, i) => `${i + 1}. ${s}`).join('\n')}

以下の形式でJSONで回答してください:
{
  "title": "発見したパターンのタイトル（15文字以内）",
  "description": "洞察の説明（50文字以内）"
}`;

  try {
    const completion = await client.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: 'あなたはメモの分析専門家です。複数のメモから共通のパターンや洞察を見つけます。',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      max_tokens: 150,
      temperature: 0.7,
    });
    
    const content = completion.choices[0]?.message?.content?.trim();
    if (!content) return null;
    
    // JSONをパース
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
    
    return null;
  } catch (error) {
    console.error('AI insights error:', error);
    return null;
  }
}
