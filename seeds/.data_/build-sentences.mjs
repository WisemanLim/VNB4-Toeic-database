#!/usr/bin/env node
// Transform extracted-sentences.json → seeds/sentences/part{1..4}.json
// for the 문장쓰기(단어 고르기) + 쉐도잉 feature.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(HERE, "..", "sentences");
mkdirSync(OUT_DIR, { recursive: true });

const items = JSON.parse(readFileSync(join(HERE, "extracted-sentences.json"), "utf8"));

// word-pick tokens: split the answer into orderable tokens. Multi-fill answers
// use " / " as a separator (Part 2 Q/A, multi-blank lines) — flatten to words.
const tokenize = (answer) =>
  answer
    .replace(/\s*\/\s*/g, " ")
    .split(/\s+/)
    .map((t) => t.trim())
    .filter(Boolean);

const byPart = { 1: [], 2: [], 3: [], 4: [] };
for (const it of items) {
  const part = it.part;
  if (!byPart[part]) continue;
  byPart[part].push({
    id: `toeic-sw-p${part}-d${it.day}-${it.order}`,
    part,
    day: it.day,
    order: it.order,
    prompt: it.prompt,
    answer: it.answer,
    full_sentence: it.full_sentence,
    translation_ko: it.translation_ko,
    tokens: tokenize(it.answer),
  });
}

let total = 0;
for (const part of [1, 2, 3, 4]) {
  const arr = byPart[part];
  writeFileSync(join(OUT_DIR, `part${part}.json`), JSON.stringify(arr, null, 2) + "\n");
  total += arr.length;
  console.log(`  part${part}: ${arr.length} items`);
}
console.log(`✓ ${total} sentence items → seeds/sentences/`);
