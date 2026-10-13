# Word and Office JS Mechanics

Read this when the document being rewritten is open in Word through an Office JS bridge, or when the session is editing the `.docx` directly.
It carries the calls the `strip-ai-tells` steps depend on in that environment, and it is kept out of `SKILL.md` so that a session working on a plain file does not pay for it.

## Turning on Track Changes

Set `context.document.changeTrackingMode = "TrackAll"` through `execute_office_js`, unless `<doc_state>.changeTrackingMode` already reports it on.
Never turn it off again while the rewrite is in progress.
When the session edits the file XML instead, mark each change with `w:ins` and `w:del` and a named author.

## Writing the File Directly

Confirm the document is closed in Word before writing.
Write the result to the user's folder, then confirm the on-disk hash matches what was written.
A stale copy still open in Word can overwrite the edit on its next save.

## Making the Edits

Use one `edit_doc_text` call per changed phrase.
Fall back to a single `execute_office_js` search-and-replace loop only when a section has many related phrases to change at once.

Word's `search()` accepts at most 255 characters, so a long paragraph has to be matched on a distinctive fragment.
Auto-generated list bullets and heading numbers do not appear in `paragraph.text`, which is why replacement text must never include them.

## Reading Formatting Back

Check these properties after each batch, comparing the edited range against a sibling that was not touched.

- `font.bold`, set to `false` on the portion of an insertion that should not inherit a bold run.
- `font.name`, compared against a surviving instance of the same inline code token.
- `font.size`, `font.color`, `alignment`, `spaceAfter`, and `lineSpacing`, all copied from a sibling paragraph of the same role whenever a paragraph is inserted.
  For a new list item, copy the sibling item's paragraph style as well.
- The header fill of any table you touched, kept identical to the other tables in the document.
- Apostrophes and quotes split across text runs, normalized to the form the rest of the document already uses.

## Reading the Visual Verifier

`verify_doc_visual` renders the document through PDF extraction, so its findings describe the extraction as much as the document.
Confirm every finding by reading the underlying property before acting on it.
A lost hyphen on a wrapped word, and a hard line break reported mid-paragraph, are the usual extraction artifacts.

## Handing Back a Clean File

Do this only after the rewrite, and only when the user wants a clean file rather than a review copy.

- No tracked changes or comments remain.
- The `comments*.xml` and `people.xml` parts are gone once the comments are.
- `w:trackRevisions` is absent from `settings.xml`, so the next editor's typing is not auto-tracked.
