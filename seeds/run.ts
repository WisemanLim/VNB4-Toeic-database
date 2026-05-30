/**
 * Seed runner. Loads per-part JSON files under seeds/parts/ and upserts Words.
 * Run: pnpm seed
 */
import { PrismaClient } from "@prisma/client";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

type AudioSeed = {
  locale: "en-US" | "en-GB" | "en-AU";
  provider: "azure" | "polly" | "google" | "piper";
  voice_id: string;
  url: string;
};

type WordSeed = {
  id: string;
  part: 1 | 2 | 3 | 4 | 5 | 6 | 7;
  word: string;
  pos?: string;
  meaning_ko: string;
  ipa?: string;
  pron_ko?: string;
  example_en?: string;
  example_ko?: string;
  topic?: string[];
  frequency_tier?: number;
  image_prompt?: string;
  image_url?: string;
  synonyms?: string[];
  distractors?: string[];
  audio?: AudioSeed[];
};

type SentenceSeed = {
  id: string;
  part: 1 | 2 | 3 | 4;
  day: number;
  order: number;
  prompt: string;
  answer: string;
  full_sentence: string;
  translation_ko: string;
  tokens: string[];
};

// Plain string maps — work for both SQLite (String fields) and PostgreSQL (enum fields)
const PART_MAP: Record<number, string> = {
  1: "P1", 2: "P2", 3: "P3", 4: "P4", 5: "P5", 6: "P6", 7: "P7",
};

// Normalize part-of-speech to a canonical set. The collected data mixes
// abbreviations ("prep", "adj", "adv", "conj", "det") and a few mis-tags
// ("place", "time" → noun). Keeps the words/admin view consistent.
const POS_CANON: Record<string, string> = {
  prep: "preposition",
  adj: "adjective",
  adv: "adverb",
  conj: "conjunction",
  det: "determiner",
  "wh-word": "pronoun",
  place: "noun",
  time: "noun",
  abbr: "abbreviation",
};
function normPos(pos?: string): string | undefined {
  if (!pos) return pos;
  const p = pos.trim().toLowerCase();
  return POS_CANON[p] ?? p;
}

const LOCALE_MAP: Record<string, string> = {
  "en-US": "en_US",
  "en-GB": "en_GB",
  "en-AU": "en_AU",
};

const PROVIDER_MAP: Record<string, string> = {
  azure: "azure",
  polly: "polly",
  google: "google",
  piper: "piper",
};

const prisma = new PrismaClient();

// SQLite stores String[] fields as JSON strings; PostgreSQL uses native arrays.
const isSqlite = (process.env.DATABASE_URL ?? "").startsWith("file:");
function toArr(a: string[] | undefined): any {
  return isSqlite ? JSON.stringify(a ?? []) : (a ?? []);
}

// Dev-only demo accounts so the admin console (users/TTS) is usable out of the box.
// NEVER seeded when NODE_ENV=production. Password for all: "admin1234".
// Hash precomputed with argon2 (the API's hasher) so this seed needs no argon2 dep.
const DEV_PW_HASH =
  "$argon2id$v=19$m=65536,t=3,p=4$AGqWwygO0fetNtCiFYbfyg$7v3gA/ZJwOgULOdQFBhk8h0WwpZ0RLTzwUQDHHYg2ZU";
const DEMO_USERS: { email: string; name: string; role: string }[] = [
  { email: "admin@vnb4.local", name: "관리자", role: "admin" },
  { email: "editor@vnb4.local", name: "편집자", role: "editor" },
  { email: "learner@vnb4.local", name: "학습자", role: "user" },
];

async function seedDemoUsers() {
  if (process.env.NODE_ENV === "production") {
    console.log("[seed] NODE_ENV=production — skipping demo users");
    return;
  }
  for (const u of DEMO_USERS) {
    await prisma.user.upsert({
      where: { email: u.email },
      update: { name: u.name, role: u.role as any },
      create: { email: u.email, name: u.name, role: u.role as any, passwordHash: DEV_PW_HASH, emailVerified: new Date() },
    });
  }
  console.log(`[seed] demo users upserted: ${DEMO_USERS.length} (login: admin@vnb4.local / admin1234)`);
}

async function main() {
  await seedDemoUsers();

  const partsDir = join(__dirname, "parts");
  const files = readdirSync(partsDir).filter((f) => f.endsWith(".json")).sort();
  let total = 0;
  let skipped = 0;
  // Word has @@unique([part, word]); skip duplicate (part, word) records so the
  // seed is resilient to dup entries in the JSON (keeps the first occurrence,
  // and its audio rows whose FK targets that word's id).
  const seen = new Set<string>();
  // Collect the first LESSON_SIZE word ids per part to build starter lessons.
  const LESSON_SIZE = 20;
  const lessonWordIds: Record<number, string[]> = {};

  for (const file of files) {
    const path = join(partsDir, file);
    const raw = readFileSync(path, "utf-8");
    const records: WordSeed[] = JSON.parse(raw);
    console.log(`[seed] ${file}: ${records.length} records`);

    for (const r of records) {
      const key = `${r.part}|${r.word.toLowerCase()}`;
      if (seen.has(key)) {
        skipped++;
        continue;
      }
      seen.add(key);

      (lessonWordIds[r.part] ??= []).length < LESSON_SIZE &&
        lessonWordIds[r.part].push(r.id);

      await prisma.word.upsert({
        where: { id: r.id },
        update: {
          part: PART_MAP[r.part],
          word: r.word,
          pos: normPos(r.pos),
          meaningKo: r.meaning_ko,
          ipa: r.ipa,
          pronKo: r.pron_ko,
          exampleEn: r.example_en,
          exampleKo: r.example_ko,
          topic: toArr(r.topic),
          frequencyTier: r.frequency_tier ?? 2,
          imagePrompt: r.image_prompt,
          imageUrl: r.image_url,
          synonyms: toArr(r.synonyms),
          distractors: toArr(r.distractors),
        },
        create: {
          id: r.id,
          part: PART_MAP[r.part],
          word: r.word,
          pos: normPos(r.pos),
          meaningKo: r.meaning_ko,
          ipa: r.ipa,
          pronKo: r.pron_ko,
          exampleEn: r.example_en,
          exampleKo: r.example_ko,
          topic: toArr(r.topic),
          frequencyTier: r.frequency_tier ?? 2,
          imagePrompt: r.image_prompt,
          imageUrl: r.image_url,
          synonyms: toArr(r.synonyms),
          distractors: toArr(r.distractors),
        },
      });

      if (r.audio?.length) {
        for (const a of r.audio) {
          await prisma.audioAsset.upsert({
            where: {
              wordId_locale_provider: {
                wordId: r.id,
                locale: LOCALE_MAP[a.locale],
                provider: PROVIDER_MAP[a.provider],
              },
            },
            update: { voiceId: a.voice_id, url: a.url },
            create: {
              wordId: r.id,
              locale: LOCALE_MAP[a.locale],
              provider: PROVIDER_MAP[a.provider],
              voiceId: a.voice_id,
              url: a.url,
            },
          });
        }
      }
      total++;
    }
  }

  console.log(`[seed] done. total words upserted: ${total}, skipped dup (part,word): ${skipped}`);

  // Starter lessons — one per part, each grouping the first LESSON_SIZE words.
  // Deterministic id (lesson-p<N>) keeps the seed idempotent; LessonWord rows
  // are upserted by their composite key so re-runs don't duplicate.
  const PART_TITLE: Record<number, string> = {
    1: "Part 1 사진묘사 핵심 어휘",
    2: "Part 2 질의응답 핵심 어휘",
    3: "Part 3 대화 핵심 어휘",
    4: "Part 4 담화 핵심 어휘",
    5: "Part 5 문장완성 핵심 어휘",
    6: "Part 6 지문완성 핵심 어휘",
    7: "Part 7 독해 핵심 어휘",
  };
  let lTotal = 0;
  for (const n of [1, 2, 3, 4, 5, 6, 7]) {
    const wordIds = lessonWordIds[n] ?? [];
    if (!wordIds.length) continue;
    const lessonId = `lesson-p${n}`;
    await prisma.lesson.upsert({
      where: { id: lessonId },
      update: { part: PART_MAP[n], title: PART_TITLE[n], orderIndex: n, publishedAt: new Date() },
      create: { id: lessonId, part: PART_MAP[n], title: PART_TITLE[n], orderIndex: n, publishedAt: new Date() },
    });
    for (let i = 0; i < wordIds.length; i++) {
      await prisma.lessonWord.upsert({
        where: { lessonId_wordId: { lessonId, wordId: wordIds[i] } },
        update: { position: i },
        create: { lessonId, wordId: wordIds[i], position: i },
      });
    }
    lTotal++;
  }
  console.log(`[seed] lessons upserted: ${lTotal}`);

  // 문장쓰기/쉐도잉 items (seeds/sentences/*.json) — optional, parts 1–4.
  const sentDir = join(__dirname, "sentences");
  if (existsSync(sentDir)) {
    let sTotal = 0;
    let sSkipped = 0;
    // SentenceItem's only unique constraint is the synthetic id. A duplicate id
    // (within or across files) would silently overwrite the earlier row, so skip
    // dups here — mirrors the (part, word) dedupe used for Words above.
    const sSeen = new Set<string>();
    const sFiles = readdirSync(sentDir).filter((f) => f.endsWith(".json")).sort();
    for (const file of sFiles) {
      const recs: SentenceSeed[] = JSON.parse(readFileSync(join(sentDir, file), "utf-8"));
      for (const r of recs) {
        if (sSeen.has(r.id)) {
          sSkipped++;
          continue;
        }
        sSeen.add(r.id);

        const data = {
          part: PART_MAP[r.part],
          day: r.day,
          orderIndex: r.order,
          prompt: r.prompt,
          answer: r.answer,
          fullSentence: r.full_sentence,
          translationKo: r.translation_ko,
          tokens: toArr(r.tokens),
        };
        await prisma.sentenceItem.upsert({ where: { id: r.id }, update: data, create: { id: r.id, ...data } });
        sTotal++;
      }
      console.log(`[seed] ${file}: ${recs.length} sentences`);
    }
    console.log(`[seed] sentence items upserted: ${sTotal}, skipped dup id: ${sSkipped}`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
