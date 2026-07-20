# nvim-presenter

A speaker-notes companion for oral presentations — not a slide deck
plugin. It renders a private, low-profile outline view in your system
browser (meant to sit in a small window near a webcam) while you
present on a video call. Nobody but you sees it.

Existing tools (presenting.nvim, vimdeck.nvim, presenterm.nvim) render
markdown as slides *for the audience*. This is the opposite.

## How it works

1. Write your notes as a plain outline in any buffer:

   ```
   # Introduction
   - State the issue in one sentence
   - Preview your two-part roadmap

   # Point One
   - Rule statement
   - Key case supporting the rule
   ```

   Lines starting with `#` are section headings; every other non-blank
   line is a talking point.

2. Run `:PresenterStart`. Neovim parses the buffer, writes it to
   `outline.json`, starts a small local Python server if one isn't
   already running, and opens your system default browser to it.

3. Keep presenting. Editing and saving the buffer (`BufWritePost`)
   re-parses it and rewrites `outline.json` — nothing else happens
   automatically. The browser page polls for changes on its own.

4. In the browser: `Space` / `↓` / `→` advance, `↑` / `←` / `Backspace`
   go back, `A−` / `A+` resize the current line, and the restart button
   jumps back to the top. All of this lives entirely in the page's own
   JS state — **Neovim's cursor position is never involved**. There is
   no bidirectional sync; the plugin only ever writes `outline.json`.

5. `:PresenterStop` stops the server.

Only one presenter session exists at a time. Running `:PresenterStart`
again on the same buffer just reopens the browser tab. Running it on a
*different* buffer moves the session there (the previous one is
stopped first).

## Requirements

- Neovim 0.10+ (`vim.system`, `vim.ui.open`)
- `python3` (or `python`) on `PATH` — only the standard library is
  used, no pip packages required

## Install (lazy.nvim)

```lua
{
  'yourname/nvim-presenter',
  cmd = { 'PresenterStart', 'PresenterStop' },
  opts = {
    -- port = 7777,
  },
}
```

## Configuration

```lua
require('nvim-presenter').setup({
  port = 7777,             -- first port tried
  port_search_range = 5,   -- how many ports to try (7777..7781) before giving up
})
```

## Commands

| Command          | Effect                                                          |
|------------------|------------------------------------------------------------------|
| `:PresenterStart` | Start a session for the current buffer, or reopen its browser tab |
| `:PresenterStop`  | Stop the server                                                  |

## Layout

```
lua/nvim-presenter/
  init.lua    -- commands' implementation, BufWritePost wiring
  parser.lua  -- buffer -> outline nodes
  server.lua  -- port selection, process lifecycle
  config.lua  -- defaults + setup()
plugin/
  presenter.lua -- :PresenterStart / :PresenterStop registration
server/
  server.py   -- stdlib-only static server (index.html + outline.json)
  index.html  -- the presenter page (ported from reference/presenter.html)
```
