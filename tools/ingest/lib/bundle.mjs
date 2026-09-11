// Reads / validates / merges the SurSaar v2 content bundle.

import { readFile, writeFile } from 'node:fs/promises';

const DIFFICULTIES = new Set(['beginner', 'intermediate', 'advanced']);

export function slugify(text) {
  return text
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/[\s-]+/g, '_')
    .slice(0, 60);
}

export async function readBundle(file) {
  const json = JSON.parse(await readFile(file, 'utf8'));
  json.lessons ||= [];
  json.songs ||= [];
  json.courses ||= [];
  json.chords ||= [];
  json.schemaVersion ||= 2;
  return json;
}

export async function writeBundle(file, bundle) {
  bundle.lastUpdated = new Date().toISOString().slice(0, 10);
  await writeFile(file, JSON.stringify(bundle, null, 2) + '\n', 'utf8');
}

export function validateBundle(bundle) {
  const errors = [];
  const ids = new Set();
  for (const song of bundle.songs) {
    const where = `song ${song.id || '?'}`;
    for (const f of ['id', 'title', 'artist', 'difficulty', 'strummingPattern', 'originalChords']) {
      if (song[f] === undefined || song[f] === null || song[f] === '') errors.push(`${where}: missing ${f}`);
    }
    if (ids.has(song.id)) errors.push(`${where}: duplicate id`);
    ids.add(song.id);
    if (song.difficulty && !DIFFICULTIES.has(song.difficulty)) errors.push(`${where}: bad difficulty ${song.difficulty}`);
    if (!Array.isArray(song.originalChords) || !song.originalChords.length) errors.push(`${where}: originalChords empty`);
    if (song.lyrics) errors.push(`${where}: lyrics must not be stored in the bundle`);
    for (const section of song.sections || []) {
      for (const line of section.lines || []) {
        if (line.lyric) errors.push(`${where}: section "${section.name}" contains lyric text`);
      }
    }
  }
  const lessonIds = new Set();
  for (const lesson of bundle.lessons) {
    const where = `lesson ${lesson.id || '?'}`;
    for (const f of ['id', 'title', 'description', 'difficulty', 'duration', 'topicsCount']) {
      if (lesson[f] === undefined) errors.push(`${where}: missing ${f}`);
    }
    if (lessonIds.has(lesson.id)) errors.push(`${where}: duplicate id`);
    lessonIds.add(lesson.id);
  }
  for (const course of bundle.courses) {
    for (const id of course.lessonIds || []) {
      if (!lessonIds.has(id)) errors.push(`course ${course.id}: unknown lesson ${id}`);
    }
  }
  return errors;
}

/** Inserts or replaces a song by id; keeps user-facing fields already curated. */
export function mergeSong(bundle, song) {
  const index = bundle.songs.findIndex((s) => s.id === song.id);
  if (index === -1) {
    bundle.songs.push(song);
    return 'added';
  }
  const existing = bundle.songs[index];
  bundle.songs[index] = {
    ...existing,
    ...song,
    tutorialUrl: existing.tutorialUrl || song.tutorialUrl,
    tags: Array.from(new Set([...(existing.tags || []), ...(song.tags || [])])),
    notes: existing.notes || song.notes,
  };
  return 'updated';
}
