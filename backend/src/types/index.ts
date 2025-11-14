import { ObjectId } from 'mongodb';

export interface MemoDocument {
  _id?: ObjectId;
  user_id: ObjectId;
  audio_url: string;
  transcription: string;
  summary: string;
  tags: string[];
  embedding?: number[];
  created_at: Date;
  updated_at?: Date;
  deleted_at?: Date;
  share_id?: string;
  related_memo_ids?: string[];
}

export interface MemoResponse {
  id: string;
  audio_url: string;
  transcription: string;
  summary: string;
  tags: string[];
  embedding?: number[];
  created_at: string;
  related_memo_ids?: string[];
}

export function documentToResponse(doc: MemoDocument): MemoResponse {
  return {
    id: doc._id!.toString(),
    audio_url: doc.audio_url,
    transcription: doc.transcription,
    summary: doc.summary,
    tags: doc.tags,
    embedding: doc.embedding,
    created_at: doc.created_at.toISOString(),
    related_memo_ids: doc.related_memo_ids,
  };
}
