# UI critique

A visual and UX review based on all 18 screenshots in `docs/screenshots/`. The
first pass only covered 5 of them. This version replaces it, keeps the points
that still hold, and adds what the other screens show.

## What works

- **The palette stays calm and restrained.** One indigo accent, Material 3 tonal
  surfaces, and almost no decoration. It suits a study app.
- **Japanese text is the hero.** It is large and clear, and the soft underlines
  show which words you can tap without adding visual noise.
- **The reading tools are well thought out.** The highlighted active line while
  audio plays, the blurred listening mode and the inline "Didn't match / Heard:"
  shadowing verdict all give useful feedback without leaving the screen.
- **The import flow is honest.** Triage leads to the review queue and then to
  commit, and "Nothing is saved until you commit" builds trust. The
  "Approve all high-confidence" shortcut respects the user's time.
- **The bottom sheets are well structured.** Small-caps section labels
  (MEANING, NOTES, DICTIONARY FORM) give a clear hierarchy.

## Bugs that look like design problems

These are worth fixing before any polish work.

1. **The review card photo snippet shows the wrong area.** In *Review card with
   photo snippet*, "Compare with the worksheet" shows the edge of the desk, not
   the word. The crop coordinates look off, maybe because they don't account
   for the user's framing in *Photo crop*. Because of this, the card can't do
   its one job.
2. **Japanese line breaks leave orphans.** A lone `か?` or `。` wraps onto its
   own line (*Reading*, *Free conversation*). Keep trailing punctuation and
   short particles with the previous word (kinsoku rules), or let segments
   break inside a word when the width requires it.
3. **The speaker-name column is too narrow.** `たかはし` wraps to `たかは / し`
   (*Reading furigana off*). Widen the column, shrink the name, or put the name
   above the line.
4. **Content runs under the bottom controls.** The last line's replay icon is
   clipped by the hint text (*Shadowing hold row*). The FAB covers list rows in
   *Conversation list*. Add bottom padding the height of the bar or FAB, and
   give the bottom bar a solid surface.
5. **Review card actions sit below the fold.** The Skip/Approve buttons are cut
   off at the bottom of *Review card with photo snippet*. Pin them to a sticky
   bottom bar.
6. **Copy has grammar slips.** "1 slots" (*Bunko structures*) and "3 item(s)"
   (*Commit*). Use proper plurals.

## Top improvements

1. **Give Home a reason to open the app every day.** Four buttons of different
   widths and styles (filled, tonal, narrower tonal, outlined) float in a blank
   page. Use equal full-width cards with an icon and a one-line subtitle, and
   fill the top with something daily: words due, a streak, or the last
   conversation to continue. *mainichi* means "every day", so the home screen
   should say so.
2. **Make Free conversation look like a chat.** Right now the user's reply is a
   small, indented "You:" line that reads like a footnote, and there is a big
   gap between each speaker label and its text. Show the partner's turns on the
   left and the user's on the right in tinted bubbles. The user's reply also
   contains kanji (私, 好き) without the tappable underline, so it should get
   the same word treatment. A gentle correction (バナナ**が**好きです) would be
   the most valuable addition here.
3. **Tidy up the Reading screen.**
   - Line up the speaker name with the first text baseline. Today it floats a
     few pixels off and varies from screen to screen.
   - Reduce the line height a little. Wrapped lines inside one turn are spaced
     almost as far apart as separate turns, so turns blur together.
   - Label or tooltip the two toolbar icons (shadowing, listening). They are
     not self-explanatory.
   - In shadowing mode the controls take three ragged rows with three button
     styles ("Check me" outlined, "Hear it again" text, "Next line" filled),
     and "Next line" competes with the main "Next". Put them in one compact
     row (🔁 · 🎤 Check me · Next line ›) and rename the bottom button to
     something like "Finish" while shadowing.
4. **Use one set of status colours with enough contrast.** The app currently
   uses peach/orange, pink, lavender, mint and grey tints for status, each
   ad hoc. Orange-on-peach text (*Review card duplicate*, *Triage*) has poor
   contrast. Define *success*, *warning* and *error* containers in the theme
   and use their `on*Container` colours for text. In the duplicate diff, show
   only the rows that differ, or emphasise the `≠` row and mute the `=` rows.
5. **Make word sheets and lists consistent.**
   - Hide the reading line when it equals the headword: the lookup sheet shows
     `かいました / かいました` and `かう かう`.
   - The lookup sheet and the Bunko detail sheet show the same kind of object
     with different layouts. Pick one, so the dictionary form, notes and
     examples always appear in the same place.
   - Don't show internal metadata ("Approved · inferred") to the user, or move
     it to a small footer.
   - In Bunko lists, drop the "Noun" label on every row when a filter is
     active, or make it a small coloured tag. Add a fade at the edge of the
     chip row so it's clear it scrolls.
6. **Render structure templates instead of showing raw placeholders.**
   `{noun} が たくさんいます。` and `{time_1}` look like template source. Show
   each slot as a small tinted chip (`[noun]`), drop the `_1/_2` suffixes, and
   use one style of punctuation (`？` vs `?` are mixed).
7. **Settle the button layouts.** "Not a match" wraps to two lines in
   *Review card duplicate*. Stack the three actions or give the main action
   full width with two secondary buttons below. The word cards there take only
   a third of the width. Placing them side by side (new → existing) would make
   the comparison clearer.

## Typography

The app-bar titles are large and thin compared with the body text, and every
screen centres its title differently: left-aligned in Reading, centred
elsewhere. Define a type scale once, using `titleLarge` for app bars and the
display sizes only for Japanese headwords, and use it everywhere. A Japanese
font with matching weights, such as Noto Sans JP, would also fix the slightly
mismatched Latin and kana weights on mixed lines like `You: 私は…`.

## Minor

- The import counts are hard to reconcile. Triage shows 26 high-confidence and
  3 to review, but Commit shows 24 approved and 3 skipped. If that's
  correct, a short explanation would help.
- The empty state "No example sentences." could offer an action, for example
  generating an example.
- Turn off the DEBUG banner (`debugShowCheckedModeBanner: false`) and retake
  the screenshots for the README.
