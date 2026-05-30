#!/usr/bin/env node
// One-off: merge extracted-vocab.json into seeds/parts/part{1..7}.json,
// skipping duplicate (part, lower(word)) — matches seeds/run.ts dedupe key.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const PARTS_DIR = join(HERE, "..", "parts");
const POS_OK = new Set(["noun", "verb", "adjective", "adverb", "preposition", "conjunction", "phrase"]);

const extracted = JSON.parse(readFileSync(join(HERE, "extracted-vocab.json"), "utf8"));

const slug = (w) =>
  w.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");

let added = 0, skipped = 0;
const perPart = {};

for (let part = 1; part <= 7; part++) {
  const file = join(PARTS_DIR, `part${part}.json`);
  const arr = JSON.parse(readFileSync(file, "utf8"));
  // existing keys + id set
  const seen = new Set(arr.map((r) => `${r.part}|${String(r.word).toLowerCase()}`));
  const ids = new Set(arr.map((r) => r.id));
  let partAdded = 0;

  for (const e of extracted.filter((x) => x.part === part)) {
    const key = `${part}|${String(e.word).toLowerCase()}`;
    if (seen.has(key)) { skipped++; continue; }
    seen.add(key);
    // unique id
    let base = `toeic-p${part}-${slug(e.word)}`;
    let id = base, n = 2;
    while (ids.has(id)) id = `${base}-${n++}`;
    ids.add(id);

    const rec = { id, part, word: e.word, meaning_ko: e.meaning_ko };
    if (e.pos && POS_OK.has(e.pos)) rec.pos = e.pos;
    rec.frequency_tier = 2;
    rec.source = "hackers800-voca";
    arr.push(rec);
    added++; partAdded++;
  }
  writeFileSync(file, JSON.stringify(arr, null, 2) + "\n");
  perPart[part] = { total: arr.length, added: partAdded };
}

console.log(`merged: +${added} new, ${skipped} dup skipped`);
for (let p = 1; p <= 7; p++) console.log(`  part${p}: ${perPart[p].total} total (+${perPart[p].added})`);
