# Paper redline tools (LARAMAGANDA.docx)

These scripts build `LARAMAGANDA (aligned).docx` on the Desktop from the group's `LARAMAGANDA.docx`.
Wrong text is marked red with strikethrough and new text is green, so the group can edit by hand.
The group's file is never overwritten.

- `redline.py`: shared helpers (run splitting, red/green styling). `redline2.py` runs only its top part.
- `redline2.py <unpacked dir> <png dir>`: every edit, by paragraph index of the original file.
  It adds the Context Diagram, Level 1 DFD and the new architecture diagram from
  `docs/images/black-and-white/`, bookmarks every heading and caption, and writes
  `PAGEREF` fields into the TOC and lists. It also writes `clean.document.xml`
  (red text removed) for page counting.
- `pack.py <document.xml> <out.docx>`: zips the unpacked folder back into a docx.

Steps (run from a work folder holding these scripts and an `ed/` folder):

1. Unzip `LARAMAGANDA.docx` into `ed/`, run the docx skill's `merge_runs.py ed`, and copy
   `ed/word/document.xml` to `doc.merged.bak`.
2. `cp doc.merged.bak ed/word/document.xml && python redline2.py ed <repo>/docs/images/black-and-white`
3. `python pack.py clean.document.xml clean.docx`
4. In PowerShell, open `clean.docx` in Word (COM), set `Bookmarks.ShowHidden = $true`, and write
   `name=page` for every `_cp*` bookmark with `Range.Information(1)` into `pages.txt`.
5. Replace each `##_cpX##` in `ed/word/document.xml` with its page from `pages.txt`.
6. `python pack.py ed/word/document.xml out.docx`, then validate and copy it to the Desktop.

The page numbers are for the paper after the red text is deleted. After deleting it in Word,
press Ctrl+A, then F9 to refresh them.
