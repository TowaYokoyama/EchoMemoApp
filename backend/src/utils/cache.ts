import crypto from 'crypto';

// シンプルなメモリキャッシュ実装
// 本番環境ではRedisなどの外部キャッシュを推奨
interface CacheEntry<T> {
  value: T;
  expiresAt: number;
}

class MemoryCache {
  private cache: Map<string, CacheEntry<any>> = new Map();
  private cleanupInterval: NodeJS.Timeout;

  constructor() {
    // 5分ごとに期限切れのエントリーをクリーンアップ
    this.cleanupInterval = setInterval(() => {
      this.cleanup();
    }, 5 * 60 * 1000);
  }

  // キャッシュキーを生成（内容のハッシュ）
  generateKey(prefix: string, content: string): string {
    const hash = crypto.createHash('sha256').update(content).digest('hex');
    return `${prefix}:${hash}`;
  }

  // キャッシュから取得
  get<T>(key: string): T | null {
    const entry = this.cache.get(key);
    
    if (!entry) {
      return null;
    }
    
    // 期限切れチェック
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return null;
    }
    
    return entry.value as T;
  }

  // キャッシュに保存
  set<T>(key: string, value: T, ttlSeconds: number = 3600): void {
    const expiresAt = Date.now() + (ttlSeconds * 1000);
    this.cache.set(key, { value, expiresAt });
  }

  // 期限切れエントリーのクリーンアップ
  private cleanup(): void {
    const now = Date.now();
    let deletedCount = 0;
    
    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expiresAt) {
        this.cache.delete(key);
        deletedCount++;
      }
    }
    
    if (deletedCount > 0) {
      console.log(`🧹 Cache cleanup: removed ${deletedCount} expired entries`);
    }
  }

  // キャッシュをクリア
  clear(): void {
    this.cache.clear();
  }

  // キャッシュサイズを取得
  size(): number {
    return this.cache.size;
  }

  // クリーンアップタイマーを停止
  destroy(): void {
    clearInterval(this.cleanupInterval);
    this.cache.clear();
  }
}

// シングルトンインスタンス
export const cache = new MemoryCache();

// キャッシュ統計を取得
export const getCacheStats = () => {
  return {
    size: cache.size(),
    timestamp: new Date().toISOString(),
  };
};
