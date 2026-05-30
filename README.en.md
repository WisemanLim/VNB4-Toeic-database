# VNB4-Toeic-database

> 🌐 **Language / 언어**: **English** · [한국어](README.md)

PostgreSQL schema + SQLite local schema + Prisma + per-part seed data.

## Stack
- SQLite (local dev, no Docker required) / PostgreSQL 16 + pgvector (prod)
- Prisma 5 (Apache-2.0)

## Environment Branching

| Environment | DB | Schema | Env file |
|---|---|---|---|
| local | SQLite (`prisma/dev.db`) | `prisma/schema.local.prisma` | `.env.local` |
| prod | PostgreSQL 16 + pgvector | `prisma/schema.prisma` | `.env` |

SQLite constraints: array fields (`topic`, `synonyms`, `distractors`, `tags`) are stored as JSON strings. enum → String.

## PRD Mapping
- §2.2 Word schema → `prisma/schema.prisma` (prod) / `prisma/schema.local.prisma` (local)
- §2.1 per-part word seeds → `seeds/parts/part{1..7}.json` (after merging Hackers 800, **3,686 unique words**)
- 문장쓰기 (sentence writing) · 쉐도잉 (shadowing) → `SentenceItem` model + `seeds/sentences/part{1..4}.json` (**198 items**: P1:20/P2:36/P3:69/P4:73)
- Lessons → `Lesson`/`LessonWord`; `seeds/run.ts` creates 7 per-part starter lessons (`lesson-p1..7`, each with the first 20 words)
- Demo / default users → `seeds/run.ts` upserts 3 demo accounts (admin/editor/learner, skipped when `NODE_ENV=production`). The production default admin is bootstrapped by the backend (ops/env `SEED_ADMIN_*`)
- §4.3 environment branching → `.env.local` (SQLite) / `.env` (PostgreSQL)

## Commands — Local (SQLite, no Docker)

```bash
pnpm install
pnpm migrate:local       # auto-generate .env.local + prisma db push (SQLite)
pnpm seed                # seeds/parts/*.json → SQLite upsert
pnpm studio              # Prisma Studio (SQLite)
pnpm seed:reset          # reset DB then re-seed
```

## Commands — Prod (PostgreSQL)

```bash
pnpm migrate:dev         # prisma migrate dev — run directly in terminal (requires TTY)
pnpm migrate:prod        # prisma migrate deploy (CI/operations)
pnpm seed:prod           # seeds/parts/*.json → PostgreSQL upsert
pnpm studio:prod         # Prisma Studio (PostgreSQL)
```

> **Tip:** prod scripts read `.env`. Use `pnpm env:init:prod` to copy from `.env.example`.

## Seed (M1 — complete, 200+ words per part)
The `seeds/parts/partN.json` arrays are word records (§2.2 PRD schema). Append in the same format when adding more.
Bulk imports can also be done via the backend worker `seed_import` job queue.

> **pos normalization**: the collected data has mixed part-of-speech notation (`prep`/`adj`/`adv`/`conj`/`det`/`place`/`time`/`abbr`/`wh-word`).
> `normPos()` in `seeds/run.ts` converts to the canonical form (prep→preposition, adj→adjective, adv→adverb, conj→conjunction,
> det→determiner, wh-word→pronoun, place·time→noun, abbr→abbreviation) before upsert. The app bundle applies the same normalization via `gen-seed.mjs`.
> (The app client tolerantly treats `pos` as a free-form string — parsing stays safe even for unspecified/non-standard values.)

> **Dedupe**: `Word` has `@@unique([part, word])`. `seeds/run.ts` skips (part, word) duplicates
> (keeping the first entry) → **3,686 unique words** upserted (24 duplicates skipped). `SentenceItem`
> only has a unique synthetic id, so run.ts also skips duplicate ids (`sSeen` Set, symmetric with words) → 198 upserted.
> (In the early version that only did id-upsert, duplicate ids were silently overwritten — now fixed.)

### Mobile App Offline Bundle (consumer)
This seed is **bundled as-is into the app's offline/mock build**. The app repo's
`scripts/gen-seed.mjs` reads `seeds/parts/*.json` and converts it to the app `Word` shape →
generating `assets/seed/words.json` (committed). All per-part words are included in the app even without a backend.

```bash
# refresh the app bundle after seed changes (run in the app repo)
VNB4_SEED_DIR=/path/to/VNB4-Toeic-database/seeds/parts pnpm gen:seed
```

## License files
- Prisma: Apache-2.0 → `node_modules/@prisma/client/LICENSE`
- PostgreSQL/pgvector: license bundled with the operations container (auto-generated in ops/THIRD_PARTY_NOTICES.md)
