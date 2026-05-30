-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "vector";

-- CreateEnum
CREATE TYPE "Provider" AS ENUM ('google', 'apple', 'kakao', 'email');

-- CreateEnum
CREATE TYPE "Role" AS ENUM ('user', 'admin', 'editor');

-- CreateEnum
CREATE TYPE "Part" AS ENUM ('P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7');

-- CreateEnum
CREATE TYPE "Locale" AS ENUM ('en_US', 'en_GB', 'en_AU');

-- CreateEnum
CREATE TYPE "TtsProvider" AS ENUM ('azure', 'polly', 'google', 'piper');

-- CreateEnum
CREATE TYPE "SrsState" AS ENUM ('new', 'learning', 'review', 'mastered');

-- CreateEnum
CREATE TYPE "JobKind" AS ENUM ('tts_batch', 'image_gen', 'seed_import', 'license_report');

-- CreateEnum
CREATE TYPE "JobStatus" AS ENUM ('queued', 'running', 'succeeded', 'failed');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "emailVerified" TIMESTAMP(3),
    "name" TEXT,
    "avatarUrl" TEXT,
    "role" "Role" NOT NULL DEFAULT 'user',
    "passwordHash" TEXT,
    "locale" TEXT NOT NULL DEFAULT 'ko',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuthIdentity" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "provider" "Provider" NOT NULL,
    "providerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuthIdentity_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "refreshToken" TEXT NOT NULL,
    "userAgent" TEXT,
    "ip" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Word" (
    "id" TEXT NOT NULL,
    "part" "Part" NOT NULL,
    "word" TEXT NOT NULL,
    "pos" TEXT,
    "meaningKo" TEXT NOT NULL,
    "ipa" TEXT,
    "pronKo" TEXT,
    "exampleEn" TEXT,
    "exampleKo" TEXT,
    "topic" TEXT[],
    "frequencyTier" INTEGER NOT NULL DEFAULT 2,
    "imagePrompt" TEXT,
    "imageUrl" TEXT,
    "synonyms" TEXT[],
    "distractors" TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Word_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AudioAsset" (
    "id" TEXT NOT NULL,
    "wordId" TEXT NOT NULL,
    "locale" "Locale" NOT NULL,
    "provider" "TtsProvider" NOT NULL,
    "voiceId" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "durationMs" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AudioAsset_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Lesson" (
    "id" TEXT NOT NULL,
    "part" "Part" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "orderIndex" INTEGER NOT NULL DEFAULT 0,
    "publishedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Lesson_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LessonWord" (
    "lessonId" TEXT NOT NULL,
    "wordId" TEXT NOT NULL,
    "position" INTEGER NOT NULL,

    CONSTRAINT "LessonWord_pkey" PRIMARY KEY ("lessonId","wordId")
);

-- CreateTable
CREATE TABLE "Progress" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "wordId" TEXT NOT NULL,
    "lessonId" TEXT,
    "state" "SrsState" NOT NULL DEFAULT 'new',
    "easeFactor" DOUBLE PRECISION NOT NULL DEFAULT 2.5,
    "intervalDays" INTEGER NOT NULL DEFAULT 0,
    "repetitions" INTEGER NOT NULL DEFAULT 0,
    "lapses" INTEGER NOT NULL DEFAULT 0,
    "lastReview" TIMESTAMP(3),
    "dueAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "correctCount" INTEGER NOT NULL DEFAULT 0,
    "wrongCount" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Progress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Note" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "wordId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "tags" TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Note_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Bookmark" (
    "userId" TEXT NOT NULL,
    "wordId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Bookmark_pkey" PRIMARY KEY ("userId","wordId")
);

-- CreateTable
CREATE TABLE "Curriculum" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "examDate" TIMESTAMP(3),
    "dailyTarget" INTEGER NOT NULL DEFAULT 20,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Curriculum_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Job" (
    "id" TEXT NOT NULL,
    "kind" "JobKind" NOT NULL,
    "status" "JobStatus" NOT NULL DEFAULT 'queued',
    "payload" JSONB NOT NULL,
    "result" JSONB,
    "error" TEXT,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "startedAt" TIMESTAMP(3),
    "endedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Job_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_email_idx" ON "User"("email");

-- CreateIndex
CREATE INDEX "AuthIdentity_userId_idx" ON "AuthIdentity"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "AuthIdentity_provider_providerId_key" ON "AuthIdentity"("provider", "providerId");

-- CreateIndex
CREATE UNIQUE INDEX "Session_refreshToken_key" ON "Session"("refreshToken");

-- CreateIndex
CREATE INDEX "Session_userId_idx" ON "Session"("userId");

-- CreateIndex
CREATE INDEX "Word_part_idx" ON "Word"("part");

-- CreateIndex
CREATE INDEX "Word_frequencyTier_idx" ON "Word"("frequencyTier");

-- CreateIndex
CREATE UNIQUE INDEX "Word_part_word_key" ON "Word"("part", "word");

-- CreateIndex
CREATE INDEX "AudioAsset_wordId_idx" ON "AudioAsset"("wordId");

-- CreateIndex
CREATE UNIQUE INDEX "AudioAsset_wordId_locale_provider_key" ON "AudioAsset"("wordId", "locale", "provider");

-- CreateIndex
CREATE INDEX "Lesson_part_orderIndex_idx" ON "Lesson"("part", "orderIndex");

-- CreateIndex
CREATE INDEX "LessonWord_lessonId_position_idx" ON "LessonWord"("lessonId", "position");

-- CreateIndex
CREATE INDEX "Progress_userId_dueAt_idx" ON "Progress"("userId", "dueAt");

-- CreateIndex
CREATE INDEX "Progress_userId_state_idx" ON "Progress"("userId", "state");

-- CreateIndex
CREATE UNIQUE INDEX "Progress_userId_wordId_key" ON "Progress"("userId", "wordId");

-- CreateIndex
CREATE INDEX "Note_userId_wordId_idx" ON "Note"("userId", "wordId");

-- CreateIndex
CREATE INDEX "Curriculum_userId_idx" ON "Curriculum"("userId");

-- CreateIndex
CREATE INDEX "Job_kind_status_idx" ON "Job"("kind", "status");

-- CreateIndex
CREATE INDEX "Job_createdAt_idx" ON "Job"("createdAt");

-- AddForeignKey
ALTER TABLE "AuthIdentity" ADD CONSTRAINT "AuthIdentity_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AudioAsset" ADD CONSTRAINT "AudioAsset_wordId_fkey" FOREIGN KEY ("wordId") REFERENCES "Word"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LessonWord" ADD CONSTRAINT "LessonWord_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "Lesson"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LessonWord" ADD CONSTRAINT "LessonWord_wordId_fkey" FOREIGN KEY ("wordId") REFERENCES "Word"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Progress" ADD CONSTRAINT "Progress_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Progress" ADD CONSTRAINT "Progress_wordId_fkey" FOREIGN KEY ("wordId") REFERENCES "Word"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Progress" ADD CONSTRAINT "Progress_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "Lesson"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Note" ADD CONSTRAINT "Note_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Note" ADD CONSTRAINT "Note_wordId_fkey" FOREIGN KEY ("wordId") REFERENCES "Word"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Bookmark" ADD CONSTRAINT "Bookmark_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Bookmark" ADD CONSTRAINT "Bookmark_wordId_fkey" FOREIGN KEY ("wordId") REFERENCES "Word"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Curriculum" ADD CONSTRAINT "Curriculum_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
