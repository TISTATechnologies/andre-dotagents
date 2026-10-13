---
name: strip-ai-tells
description: "Rewrites AI-sounding prose until it reads as human-written. Use this skill when a draft reads like AI wrote it: em dashes, colon splices, negative parallelism, empty intensifiers, slogan rhythm, and the same point restated across sections."
user-invocable: true
---
# Strip AI Tells

## When to Use

The user wants prose that reads as human-written.
Typical phrasings are "strip the AI tells", "de-AI this", "make this sound less like AI", "remove the em dashes", "this reads like ChatGPT wrote it", "humanize this draft", and "reads like an AI note to self".

This is not a proofread: spelling, grammar, and ordinary punctuation stay out of scope.
Change word choice, sentence shape, and the patterns in the inventory.

## Scope

Work on the whole document by default.
Restrict the pass to a section when the user has selected one or named one, and say which range you worked on.

Leave quoted or copied material alone, such as a passage taken from another document or a section written by someone else, unless the user asked for a full sweep.
Say which sections you skipped and why.

## Make the Edits Reviewable

Turn on the editor's change tracking or revision mode before the first edit, when the environment has one, so the user can see and reject every rewrite.
Say in one line that you turned it on.
Never turn it off during the rewrite.

Make the edits silently only when the user asks for that.
A plain file under version control needs no extra step, because the diff already serves that purpose.
Read [Word and Office JS Mechanics](references/word-office-js.md) when the document is open in Word, or when you are writing the file directly, for the calls this step and the checks below need.

## Inventory Before Editing

Count each pattern in scope before changing anything.
The document text is usually already in context, so do not re-read it just to count.

### Punctuation and Glyphs

- **Em dashes**: every one, doc-wide.
- **En dashes used as separators**, such as a title and a subtitle joined by one.
  Date ranges and number ranges stay.
- **Colon splices**: a colon joining two independent clauses.
  A list lead-in, a bullet label, a title and subtitle, and a labeled caveat are legitimate colons.
  Two colons in one sentence is always a hit.
- **Symbol shorthand in prose**: arrows, double arrows, multiplication signs, inequality signs, check marks, and bullets standing in for words, such as "8x/day" or "source > destination".
- **Mixed apostrophes or quotes**: straight and curly forms in the same document.

### Word Choice

- **"Not X but Y" parallelism**: including "rather than", "instead of", "it's not just X, it's Y", and "not merely".
- **Empty intensifiers and consultant filler**: genuinely, actively, deliberately, organically, truly, simply, seamlessly, robustly, holistically, significant, substantial, comprehensive, leverage, foster, empower, streamline, and "best practices".
- **Triads and filler**: three-item lists where two carry the meaning, plus "at minimum", "from day one", "going forward", "alike", "that said", and "it's worth noting".

### Sentence Shape

- **Tidy payoff tails**: sentences that end on ", so" plus a payoff.
  A few are fine.
  A run of them is the tell.
- **Date-led openings**: a sentence that opens with a date or a season in a document that is not a timeline.
  Move the date inside the sentence.
- **Passive with a known actor**: the actor is already clear, and the sentence still hides them.
- **Counting lead-ins**: a sentence that announces how many things follow, such as "two factors held it back."
- **Moral tags**: an abstract lesson tacked onto a fact.
  Cut it, or move the point to the section that already draws that conclusion.
- **Notes to self**: an instruction sitting in a narrative section.
  Tell what happened when the source supports it.
  Otherwise move the instruction to the section that already holds it, or cut it when that section already makes the point.
- **Slogan runs**: short sentences with the same rhythm in a row.
  Make them a list, or merge them into one or two sentences with different shapes.

### Document Shape

- **Mid-sentence bold**: emphasis phrases bolded inside a sentence.

Also note these, and do not change them unless directed by the user:

- A broken cross-reference.
- A claim the document cannot support, such as an unmeasured duration or a result marked achieved with no measurement.
- Jargon repeated past usefulness.
- A metaphor that does not hold.
- The same finding restated in three or more places, such as a summary, the section body, and a later list.
- An inconsistency between parallel documents.
- An acronym used before it is defined.
- Attribution you are unsure about.

**Done when:** you have a per-pattern count to compare against later.

## Rewrite

Work section by section.
Make one edit per changed phrase, and batch related phrases into a single search-and-replace pass only when there are many.

- **Recast each em dash and each colon splice by what the join is doing.**
  Use a period when the halves stand alone, parentheses for a true aside, a comma for apposition, and "by" or "which" for a gerund tail.
  Leave a colon the inventory calls legitimate.
- **Vary the replacement.**
  If "rather than" or ", so" is carrying every contrast, half the sentences now share a rhythm.
  Rotate through plain subordination, two sentences, or dropping the contrast entirely.
  Replacing every join with the same mark is its own tell.
- **Keep the replaced span minimal.**
  Change the words that need changing plus enough neighbors to make the match unique.
  Editors cap the length of a search string, so a long paragraph needs a distinctive fragment, never the whole thing.
- **Preserve meaning.**
  Dropping "deliberately" is fine.
  Dropping the clause it modified is not.
- **Spell symbols out** as words that match the rest of the document, such as "eight times per day" or "at least 1,000".
  An arrow inside a file path can become `>`.
- **Never type list bullets or heading numbers into replacement text.**
  The document's list and heading formatting generates them, so typing them by hand produces a doubled marker.
- **Drop mid-sentence bold** on emphasis phrases.

**Done when:** every counted instance in the section is resolved or consciously kept.

## Deliverable Defaults

Apply these when the document is a deliverable and the user has not said otherwise.

- **Attribution**: credit actions to the group the document already uses, not to a named person.
  Leave a person named when naming people is already that document's practice.
  An identifier that contains a name, such as a repository path or a URL, stays as-is.
  Use the bare group name, not the group plus a role: "the platform team", not "the platform team point of contact".
- **Voice**: active, concise, and high information density.
  Keep rewrites light.

## Watch for Formatting Leaks

Replacing a span inherits the formatting at the start of the range and flattens whatever was inside it.
Check each batch against the following before moving on.

- **Bold bleed**: replacing text that starts inside a bold run, such as a bold list label, makes the whole insertion bold.
  Clear bold on the portion that should not carry it.
- **Lost code font**: inline monospace tokens inside a replaced span come back in the body font.
  Find each token, compare its font against a surviving instance, and restore it.
- **Apostrophe and quote style**: match the document's existing style.
  Search a known word with a straight apostrophe and again with a curly one; whichever matches is the house style.
  Use it in every insertion, including where a word is split across text runs.
- **Inserted paragraphs**: when you add a sentence or a paragraph, copy the font, size, color, alignment, and spacing from a sibling paragraph of the same role.
  For a new list item, copy the sibling item's paragraph style.
  Do not rely on the style default.
- **Table header colors**: when you touch a table, keep its header fill identical to the other tables in the document.

**Done when:** reading the batch back shows the same fonts, weights, and fills as before the edit.

## Re-Scan Until a Pass Finds Nothing

Re-run the inventory over the rewritten text, including phrases you introduced, especially ", so", "which", colons, and "by".
Fix what the pass turns up, then run it again.
Stop when a complete pass over scope produces zero findings, not after a fixed number of rounds.
Two passes is the usual minimum.

## Verify, and Verify the Verifier

Run whatever visual or rendered verification the environment offers.
A tool that inspects a rendered or extracted copy reports predictable false positives, so fix only what you can confirm against the document's real properties.

- A lost hyphen on a word that wraps across a line is an extraction artifact, and the hyphen is still in the document.
- A hard line break reported mid-paragraph is usually ordinary justified wrapping.
- For a font, color, size, or spacing complaint, read the property off the paragraph and off a sibling before changing anything.
  Matching values mean the finding is wrong.

Then, for a deliverable, check the file itself.

- No placeholder markers, such as "TBD", "TODO", "XXX", or lorem, outside a sentence that legitimately uses them.
- No Markdown leakage in a document that is not Markdown: doubled asterisks, backticks, heading marks, or a bracketed link.
- The document title is set, and the author metadata is what the user expects.
- The cover date, the filename date, and the footer agree.
- Tracked changes and comments are gone when the user wants a clean file rather than a review copy.
  In that case, turn change tracking off in the handed-back file so later typing is not auto-tracked.

## Report

Keep the report to two short parts.

- One line of counts: which patterns came out, how many of each, and how many passes it took.
- A flag list under a bold header.
  One line each, with its location, for every item you noted and did not change.
