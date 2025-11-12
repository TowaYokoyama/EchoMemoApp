import { z } from 'zod';

export const CreateMemoSchema = z.object({
  audio_url: z.string().url(),
  transcription: z.string().min(1),
  summary: z.string().min(1),
  tags: z.array(z.string()).min(1).max(10),
  embedding: z.array(z.number()).length(1536).optional(),
});

export const SearchMemoSchema = z.object({
  embedding: z.array(z.number()).length(1536),
  limit: z.number().int().min(1).max(50).optional(),
});

export type CreateMemoInput = z.infer<typeof CreateMemoSchema>;
export type SearchMemoInput = z.infer<typeof SearchMemoSchema>;
