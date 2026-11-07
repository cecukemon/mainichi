# UI critique

A quick visual and UX review based on the screenshots in `docs/screenshots/`.
It covers 5 of the 18 screenshots: Home, Reading (furigana on), Review card
with photo snippet, Bunko words tab (filter chips), and Free conversation.

## What works

- The indigo Material 3 palette is calm and consistent, with one main accent colour.
- The Japanese text is large and easy to read, and the soft underlines make it
  clear which words you can tap.
- The Bunko list reads well: bold kanji, with the reading and meaning in a
  lighter line below.
- The review flow is easy to follow thanks to the progress bar, the status chip
  and the warning box.

## Top improvements

1. **The Home screen feels empty.** Four buttons of different widths float in
   the middle of a blank page. Replace them with equal full-width cards, each
   with an icon and a one-line subtitle, and add a greeting, streak or
   "due today" count at the top.
2. **The conversation doesn't look like a chat.** Show your lines as
   right-aligned tinted bubbles and the partner's as cards on the left, with
   less space between them.
3. **The Reading screen layout is loose.** Line up the speaker names and replay
   icons with the first line of text, reduce the line spacing a little, and
   separate the turns. The "Tap any word" hint is too close to the Next button.
4. **Type and colour aren't consistent.** The app-bar titles look thin and large
   next to the body text, so set up one consistent type scale. The pink warning
   box clashes with the beige chip, so pick one warning colour (amber) and one
   error colour from the theme.
5. **The Bunko list repeats itself.** Hide the "Noun" label when the Noun filter
   is on, or make it a small coloured tag. Lighten the dividers, and hint that
   the chip row scrolls.

## Minor

- The screenshots show the DEBUG banner. Set `debugShowCheckedModeBanner: false`
  before retaking them.
