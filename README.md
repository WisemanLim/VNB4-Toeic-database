# VNB4-Toeic-database

> 🌐 **언어 / Language**: **한국어** · [English](README.en.md)

PostgreSQL schema + SQLite local schema + Prisma + part별 seed data.

## Stack
- SQLite (local dev, Docker 불필요) / PostgreSQL 16 + pgvector (prod)
- Prisma 5 (Apache-2.0)

## 환경 분기

| 환경 | DB | Schema | Env file |
|---|---|---|---|
| local | SQLite (`prisma/dev.db`) | `prisma/schema.local.prisma` | `.env.local` |
| prod | PostgreSQL 16 + pgvector | `prisma/schema.prisma` | `.env` |

SQLite 제약: 배열 필드(`topic`, `synonyms`, `distractors`, `tags`)를 JSON 문자열로 저장. enum → String.

## PRD 매핑
- §2.2 Word 스키마 → `prisma/schema.prisma` (prod) / `prisma/schema.local.prisma` (local)
- §2.1 파트별 단어 시드 → `seeds/parts/part{1..7}.json` (Hackers 800 병합 후 **고유 3,686단어**)
- 문장쓰기·쉐도잉 → `SentenceItem` 모델 + `seeds/sentences/part{1..4}.json` (**198문항**: P1:20/P2:36/P3:69/P4:73)
- 레슨 → `Lesson`/`LessonWord`, `seeds/run.ts` 가 파트별 starter 레슨 7개 생성(`lesson-p1..7`, 각 첫 20단어)
- 데모/기본 사용자 → `seeds/run.ts` 가 데모 3계정 upsert(admin/editor/learner, `NODE_ENV=production` 시 skip). 운영 기본 관리자는 backend 부트스트랩(ops/env `SEED_ADMIN_*`)
- §4.3 환경분기 → `.env.local` (SQLite) / `.env` (PostgreSQL)

## Commands — Local (SQLite, Docker 없음)

```bash
pnpm install
pnpm migrate:local       # .env.local 자동생성 + prisma db push (SQLite)
pnpm seed                # seeds/parts/*.json → SQLite upsert
pnpm studio              # Prisma Studio (SQLite)
pnpm seed:reset          # DB 초기화 후 재seed
```

## Commands — Prod (PostgreSQL)

```bash
pnpm migrate:dev         # prisma migrate dev — 터미널 직접 실행 (TTY 필요)
pnpm migrate:prod        # prisma migrate deploy (CI/운영)
pnpm seed:prod           # seeds/parts/*.json → PostgreSQL upsert
pnpm studio:prod         # Prisma Studio (PostgreSQL)
```

> **Tip:** prod 스크립트는 `.env` 를 읽습니다. `pnpm env:init:prod` 로 `.env.example` 에서 복사.

## Seed (M1 — 완료, part별 200+단어)
`seeds/parts/partN.json` 배열이 단어 레코드(§2.2 PRD 스키마). 추가 시 동일 형식으로 append.
대량 임포트는 backend worker `seed_import` 작업 큐로도 가능.

> **pos 정규화**: 수집 데이터의 품사 표기가 혼재(`prep`/`adj`/`adv`/`conj`/`det`/`place`/`time`/`abbr`/`wh-word`).
> `seeds/run.ts` 의 `normPos()` 가 정규형으로 변환(prep→preposition, adj→adjective, adv→adverb, conj→conjunction,
> det→determiner, wh-word→pronoun, place·time→noun, abbr→abbreviation) 후 upsert. 앱 번들도 `gen-seed.mjs` 가 동일 정규화.
> (앱 클라이언트는 `pos` 를 자유 문자열로 관용 처리 — 미지정/비표준 값에도 파싱 안전.)

> **Dedupe**: `Word` 는 `@@unique([part, word])`. `seeds/run.ts` 가 (part, word) 중복을
> 건너뜁니다(첫 항목 유지) → **고유 3,686단어** upsert(중복 24 skip). `SentenceItem` 은
> 합성 id 만 unique 라 run.ts 가 id 중복도 skip(`sSeen` Set, 단어와 대칭) → 198 upsert.
> (id-upsert만 하던 초기엔 중복 id 가 조용히 덮어써졌음 — 수정 완료.)

### 모바일 앱 오프라인 번들 (소비처)
이 시드는 **앱의 오프라인/목(mock) 빌드에 그대로 번들**됩니다. 앱 레포의
`scripts/gen-seed.mjs` 가 `seeds/parts/*.json` 을 읽어 앱 `Word` 형태로 변환 →
`assets/seed/words.json` 생성(커밋). 백엔드 없이도 전 파트 단어가 앱에 포함됨.

```bash
# 시드 변경 후 앱 번들 갱신 (앱 레포에서)
VNB4_SEED_DIR=/path/to/VNB4-Toeic-database/seeds/parts pnpm gen:seed
```

## License files
- Prisma: Apache-2.0 → `node_modules/@prisma/client/LICENSE`
- PostgreSQL/pgvector: 운영 컨테이너 license 동봉 (ops/THIRD_PARTY_NOTICES.md 자동 생성)
