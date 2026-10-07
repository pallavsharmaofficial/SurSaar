#!/usr/bin/env python3
"""Builds the tutor library from the researched shelves in content/catalog/.

    python3 tools/catalog/build_catalog.py          # merge into both bundles
    python3 tools/catalog/build_catalog.py --check  # validate only

Inputs (one JSON array per shelf, see docs/TUTOR.md):
    content/catalog/bollywood.json, global.json, band.json, instrumental.json

Outputs: the songs are merged (by id) into content/sursaar_content.json and
assets/data/local_bundle.json. Only facts are stored: chord names and order,
section names, key, capo, tempo, strumming, plus single-note tabs for
public-domain melodies (converted from sargam) and scale warm-ups written for
this app. No lyrics, and no transcription of a copyrighted melody.
"""

import json
import re
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "content" / "catalog"
BUNDLES = [ROOT / "content" / "sursaar_content.json", ROOT / "assets" / "data" / "local_bundle.json"]
SHELVES = ["bollywood", "global", "band", "instrumental"]

SHARPS = {"Db": "C#", "Eb": "D#", "Gb": "F#", "Ab": "G#", "Bb": "A#"}
CHORD_RE = re.compile(r"^[A-G]#?(m|maj7|m7|7|sus2|sus4|7sus4|add9|madd9|dim|aug|6|m6|9|5)?(/[A-G]#?)?$")
STRUM_RE = re.compile(r"^[DUXM\- ]+$")

# --------------------------------------------------------------- tablature

OPEN_MIDI = [40, 45, 50, 55, 59, 64]  # low E .. high e
STRING_NAMES = ["E", "A", "D", "G", "B", "e"]
SARGAM = {"S": 0, "r": 1, "R": 2, "g": 3, "G": 4, "m": 5, "M": 6, "P": 7, "d": 8, "D": 9, "n": 10, "N": 11}
NOTE_INDEX = {n: i for i, n in enumerate(["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"])}


def place(midi, previous):
    """Picks a string/fret for midi, favouring the first position on the top
    strings and small hand movements (one finger per fret)."""
    best = None
    for string, open_midi in enumerate(OPEN_MIDI):
        fret = midi - open_midi
        if fret < 0 or fret > 15:
            continue
        cost = max(0, fret - 4) * 3 + (5 - string) * 0.4
        if previous is not None:
            cost += abs(fret - previous[1]) * 0.25 + abs(string - previous[0]) * 0.15
        if best is None or cost < best[0]:
            best = (cost, string, fret)
    if best is None:
        raise ValueError(f"MIDI {midi} is outside the guitar range")
    return best[1], best[2]


def sargam_notes(phrase, sa_midi):
    """'S:1 R:1 .N:2 - S\\':1' -> [(midi or None for rest, beats)]."""
    out = []
    for token in phrase.replace("|", " ").split():
        name, _, beats = token.partition(":")
        beats = float(beats) if beats else 1.0
        if name == "-":
            out.append((None, beats))
            continue
        octave = 0
        while name.startswith("."):
            octave -= 1
            name = name[1:]
        while name.endswith("'"):
            octave += 1
            name = name[:-1]
        if name not in SARGAM:
            raise ValueError(f"unknown swara {token!r}")
        out.append((sa_midi + SARGAM[name] + 12 * octave, beats))
    return out


def tab_from_notes(sections):
    """[(section, [(midi|None, beats)])] -> ASCII tab, four columns per beat,
    in the format lib/teacher/melody/tab_parser.dart reads back."""
    blocks = []
    previous = None
    for name, notes in sections:
        # rests extend the previous note
        merged = []
        for midi, beats in notes:
            if midi is None and merged:
                merged[-1] = (merged[-1][0], merged[-1][1] + beats)
            elif midi is not None:
                merged.append((midi, beats))
        rows = ["-" for _ in range(6)]
        for midi, beats in merged:
            string, fret = place(midi, previous)
            previous = (string, fret)
            width = max(2, min(16, round(beats * 4)))
            for s in range(6):
                rows[s] += (str(fret) if s == string else "").ljust(width, "-")
        lines = [f"[{name}]"] + [f"{STRING_NAMES[s]}|{rows[s]}|" for s in range(5, -1, -1)]
        blocks.append("\n".join(lines))
    return "\n\n".join(blocks)


def scale_warmup(tonic, scale_notes):
    """A warm-up written for this app: the piece's scale up and down, then a
    pattern in threes. It teaches the notes the melody lives in without
    reproducing the (copyrighted) composition."""
    sa = 50 + (NOTE_INDEX[tonic] - NOTE_INDEX["D"]) % 12  # tonic in the D3..C#4 octave
    steps = sorted({(NOTE_INDEX[n] - NOTE_INDEX[tonic]) % 12 for n in scale_notes})
    up = [sa + s for s in steps] + [sa + 12]
    down = list(reversed(up))
    threes = []
    for i in range(len(up) - 2):
        threes += up[i : i + 3]
    return tab_from_notes(
        [
            ("Scale up", [(m, 1) for m in up[:-1]] + [(up[-1], 2)]),
            ("Scale down", [(m, 1) for m in down[:-1]] + [(down[-1], 2)]),
            ("Pattern in threes", [(m, 0.5) for m in threes] + [(up[-1], 2)]),
        ]
    )


# ------------------------------------------------------------------ songs


def clean_chord(chord):
    chord = chord.strip()
    root = chord[:2] if len(chord) > 1 and chord[1] in "b#" else chord[:1]
    chord = SHARPS.get(root, root) + chord[len(root):]
    if "/" in chord:
        upper, bass = chord.split("/", 1)
        chord = upper + "/" + SHARPS.get(bass, bass)
    return chord


def clean_strum(text):
    text = re.sub(r"\(.*?\)", "", text or "").strip()
    text = text.split(";")[0].strip()
    return text if text and STRUM_RE.match(text) else "D DU UDU"


def to_song(item):
    shelf = item["collection"]
    tags = list(dict.fromkeys([*item.get("tags", []), shelf]))
    confidence = item.get("confidence", "medium")
    if confidence == "high":
        tags.append("verified")
    notes = (item.get("notes") or "").strip()
    confidence_note = {
        "high": "Chart cross-checked against several sources.",
        "medium": "Community chart – sources differ in places; trust your ears.",
        "low": "Thinly sourced chart – check it against the recording.",
    }[confidence]
    song = {
        "id": item["id"].replace("-", "_"),
        "title": item["title"],
        "artist": item["artist"],
        "album": item.get("album"),
        "year": item.get("year"),
        "collection": shelf,
        "difficulty": item["difficulty"],
        "key": item.get("key"),
        "capo": int(item.get("capo") or 0),
        "bpm": item.get("bpm") or None,
        "duration": item.get("duration") or None,
        "strummingPattern": clean_strum(item.get("strummingPattern")),
        "originalChords": [clean_chord(c) for c in item.get("originalChords") or item.get("chordVamp") or []],
        "sections": [
            {
                "name": section["name"],
                "repeat": int(section.get("repeat", 1)),
                "lines": [{"lyric": "", "chords": [{"chord": clean_chord(c), "position": 0} for c in section["chords"]]}],
            }
            for section in item.get("sections", [])
            if section.get("chords")
        ],
        "techniqueFocus": item.get("techniqueFocus", []),
        "tags": tags,
        "language": item.get("language"),
        "tutorialUrl": item.get("tutorialUrl", ""),
        "sourceUrl": item.get("sourceUrl"),
        "notes": f"{notes} {confidence_note}".strip(),
    }
    if shelf == "instrumental":
        song.update(instrumental_extras(item))
    return {k: v for k, v in song.items() if v is not None}


def instrumental_extras(item):
    extras = {"language": "instrumental", "bpm": item.get("bpm") or 80}
    tonic = item.get("tonic")
    status = item["copyrightStatus"]
    structure = (item.get("structure") or "").strip()
    if status == "public_domain" and item.get("sargam"):
        sa = 60 + (NOTE_INDEX[tonic] - NOTE_INDEX["C"]) % 12 if tonic else 60
        sections = []
        for i, section in enumerate(item["sargam"], start=1):
            notes = []
            for phrase in section["phrases"]:
                notes += sargam_notes(phrase, sa)
            sections.append((f"Line {i}", notes))
        extras["tabs"] = tab_from_notes(sections)
        extras["notes"] = (
            f"Public domain ({item['copyrightReason']}) Melody converted from sargam with Sa = "
            f"{tonic or 'C'}; note lengths are approximate. {structure}"
        ).strip()
        if item["id"] == "jana-gana-mana":
            extras["notes"] += " Please practise the national anthem respectfully."
    elif tonic and item.get("scaleNotes"):
        extras["tabs"] = scale_warmup(tonic, item["scaleNotes"])
        extras["notes"] = (
            f"{structure} The tab here is a warm-up in the piece's scale "
            f"({', '.join(item['scaleNotes'])}), written for SurSaar – not the composition. "
            "Paste a tab of the melody to learn it note by note."
        ).strip()
    else:
        extras["notes"] = (
            f"{structure} Key and tempo aren't published yet, so there is no tab – "
            "paste one to learn it note by note."
        ).strip()
    return extras


# ------------------------------------------------------------- validation


def validate(songs, existing_ids):
    errors = []
    seen = set()
    for song in songs:
        sid = song["id"]
        if sid in seen:
            errors.append(f"duplicate id {sid}")
        seen.add(sid)
        if sid in existing_ids:
            errors.append(f"{sid} already exists in the bundle")
        chords = song["originalChords"] + [
            p["chord"] for s in song["sections"] for line in s["lines"] for p in line["chords"]
        ]
        for chord in chords:
            if not CHORD_RE.match(chord):
                errors.append(f"{sid}: odd chord {chord!r}")
        for section in song["sections"]:
            for line in section["lines"]:
                if line["lyric"]:
                    errors.append(f"{sid}: lyric text in {section['name']}")
        if not STRUM_RE.match(song["strummingPattern"]):
            errors.append(f"{sid}: strumming {song['strummingPattern']!r}")
        if song["collection"] != "instrumental" and not song["sections"]:
            errors.append(f"{sid}: no sections")
    return errors


def main():
    check_only = "--check" in sys.argv
    songs = []
    for shelf in SHELVES:
        items = json.loads((CATALOG / f"{shelf}.json").read_text())
        for item in items:
            item.setdefault("collection", shelf)
            songs.append(to_song(item))
    base = json.loads(BUNDLES[0].read_text())
    catalogue_ids = {s["id"] for s in songs}
    existing = {s["id"] for s in base["songs"] if s["id"] not in catalogue_ids}
    errors = validate(songs, existing)
    counts = {shelf: sum(1 for s in songs if s["collection"] == shelf) for shelf in SHELVES}
    print("songs per shelf:", counts, "total", len(songs))
    if errors:
        print("\n".join(errors))
        sys.exit(1)
    if check_only:
        return
    for path in BUNDLES:
        bundle = json.loads(path.read_text())
        kept = [s for s in bundle["songs"] if s["id"] not in catalogue_ids]
        for s in kept:
            # The original starter songs are Hindi film songs.
            if not s.get("addedByUser") and s.get("language") == "hi":
                s.setdefault("collection", "bollywood")
        bundle["songs"] = kept + songs
        bundle["version"] = "2.1.0"
        bundle["lastUpdated"] = date.today().isoformat()
        path.write_text(json.dumps(bundle, ensure_ascii=False, indent=2) + "\n")
        print("wrote", path.relative_to(ROOT), len(bundle["songs"]), "songs")


if __name__ == "__main__":
    main()
