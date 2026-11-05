---
name: cite-references
description: How to cite sources for the Book of the Dead game, both in a level's registry.json (the references dictionary and each entry's reference field) and in the Totenbuch Scene Atlas artifact (the References list and each scene's links). Use whenever a description, caption or translation is added or changed from a source, or a new source is read.
---

# Citing references

Sources are cited in two places, which must agree:

1. **The level's registry**, `godot/assets/<level>/registry.json`.
2. **The Totenbuch Scene Atlas** artifact, https://claude.ai/artifact/QystRPRnxHBNa3VKjQfEro.

The first level done this way is the Field of Offerings (`godot/assets/field/registry.json`, spell 110). Use it as the model.

## Abbreviations

Every source has one abbreviation, used the same way everywhere: the registry dictionary, the entry fields, and the artifact.

- Write it as `Author year`, e.g. `Allen 1960` or `Lucarelli 2010`.
- With two authors, join them: `Renouf & Naville 1904`.
- An undated work gets `n.d.`. Add a letter when one author has several: `Zaytseva n.d.a`, `Zaytseva n.d.b`.
- An online database or a web page with no fixed date gets a short tag, e.g. `Backes TBP` (the Totenbuch-Projekt) or `Wikipedia GDU`.
- Before you coin a new abbreviation, check the artifact's References list. If the source is already there, reuse its abbreviation exactly.

## Full citations

Give author, title, series and number, place, year, then a URL if the source is online. For a web database, add the accession date.

```
Allen, T. G. The Egyptian Book of the Dead: Documents in the Oriental Institute Museum at the University of Chicago. OIP 82. Chicago: University of Chicago Press, 1960. https://isac-assets.s3.amazonaws.com/isac-publications/oip82.pdf
```

Cite only sources you have actually viewed. If you read only part of a source (the abstract, the opening, a truncated page), say so in brackets at the end of the citation, e.g. `(Abstract only.)`.

## In the registry JSON

At the top of the file, before `entries`, put a `references` dictionary that maps each abbreviation to its full citation:

```json
{
 "references": {
  "Allen 1960": "Allen, T. G. The Egyptian Book of the Dead: ...",
  "Backes TBP": "Backes, B. (trans.). German translations of P. Turin 1791 ..."
 },
 "entries": { ... }
}
```

- List only the sources that this file's entries cite. Remove a source when no entry cites it any more. The full list of everything read belongs in the artifact.
- Give every entry a `reference` string. The game never reads this field: `scripts/descriptions.gd` reads only `entries[id].name`, `descriptions`, `speech`, `speaker` and `journal`.

```json
"caption_mid_hapi": {
 "name": "Hapi",
 "descriptions": { "default": "\"Hapi, father of the gods.\" ..." },
 "journal": false,
 "reference": "Backes TBP; Allen 1960 \"the Inundation, father of the gods\"; the archived level.json calls him Hetep"
}
```

The rules for the `reference` string:

- Cite one source per entry, two at most. Use the second only when it adds something the first lacks: a different reading, or confirmation of an uncertain one.
- If an entry truly needs more than two, ask the user directly before adding them. Say which sources, and what each adds that the others don't. Don't stay quietly at two to avoid asking, and don't add a third without asking. A source that only repeats another is redundant: leave it out.
- When choosing between sources, prefer recent scholarship to old (e.g. Backes or Allen over Budge or Renouf & Naville), and published books and articles to web pages or Wikipedia. Web sources are still fine to use when they are the best or only source.
- Put the abbreviations first, separated by `; `. List the source of the wording first, then any parallel sources.
- Leave out page numbers.
- Where it helps, add a very short, informal note: a different reading in another source, an uncertain word, or "placement is my reading" when you decided which part of the plate a text belongs to.
- When you don't know where something came from, write `"reference": ""` and add an unchecked item for it to that level's section of `godot/TODO.md`. Never guess a source. Put placement or reading questions in the TODO too, as items to verify.
- Check that the file is still valid JSON after editing, e.g. `python3 -c "import json; json.load(open('godot/assets/<level>/registry.json'))"`.

## In the Scene Atlas artifact

The artifact is shared with other sessions. Before you edit it:

1. Read the live version with the Artifact tool's `read` action on its URL.
2. Copy the saved HTML file into the scratchpad.
3. Strip the publish skeleton: everything before `<title>`, and the closing `</body></html>`.
4. Edit, then publish to the same `url`.

### The References list (top of the page)

It is a collapsible `<details class="refs" id="refs">`, folded by default ("Show all" / "Show less"). It lists **every** source viewed for the game, each as an abbreviation and a full citation, and nothing more. Notes on what a source was used for belong in the registry, not here.

```html
<li id="ref-allen-1960"><span class="ab">Allen 1960</span><span>Allen, T. G. <i>The Egyptian Book of the Dead: Documents in the Oriental Institute Museum at the University of Chicago.</i> OIP 82. Chicago, 1960. <a href="https://isac-assets.s3.amazonaws.com/isac-publications/oip82.pdf" target="_blank" rel="noopener">PDF</a></span></li>
```

- Put titles in `<i>`, and make the URL a link with `target="_blank" rel="noopener"`.
- Add new sources at the end of the list.
- The `id` is `ref-` plus the abbreviation in lower case, with `&` as `and` and every run of other characters as `-` (`Renouf & Naville 1904` becomes `ref-renouf-and-naville-1904`). It must match the page's `refId()` function, or scene links won't find their entry.

### References in a scene

Each scene in the `SCENES` array takes an optional `refs` array of abbreviations. `card()` turns it into a "References:" line of links to the list, and clicking a link unfolds the list.

```js
{ act: "act4", id: "s110", ..., refs: ["Backes TBP", "Allen 1960"] },
```

- A scene's `refs` are the sources cited in that level's registry, so they match its `references` dictionary.
- Every abbreviation in `refs` must have an `<li>` in the References list.
- After editing, extract the inline `<script>` and run `node --check` on it. Then publish once.

## Checklist when adding a source

1. Read it, and note how much of it you read.
2. Choose its abbreviation, reusing an existing one if the source is already listed.
3. Add it to the artifact's References list if it isn't there yet.
4. If a registry entry uses it, add it to that registry's `references` dictionary, cite it in the entry's `reference` field, and add it to the matching scene's `refs` in the artifact.
5. Put any blank sources and open placement questions in `godot/TODO.md`.
