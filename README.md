# PetAbilityLearned

Hunter addon. Tame a beast that knows an ability you don't (say a Nightstalker
with Claw rank 2 while you only have rank 1), keep using that ability, and the
moment your hunter learns it a large splash appears in the middle of the screen:
the ability's icon in a gold ring, its name and rank, and which pet it came from.
No more watching the chat for "You have learned a new ability".

The look follows GnomeLevelUp: a black panel that fades out at the edges, a
round icon, glowing text, a short fade-in and fade-out.

## How it detects a learn

- `CHAT_MSG_SYSTEM` matched against the client's own `ERR_LEARN_ABILITY_S` and
  `ERR_LEARN_SPELL_S` strings, so it works in any client language. A spell link
  inside the line is unwrapped and its spell ID used.
- `LEARNED_SPELL_IN_TAB` / `LEARNED_SPELL_IN_SKILL_LINE`, in case the client
  fires them for Beast Training. Beast Training abilities live in their own
  window rather than the spellbook, so the chat line is the dependable signal.
- Both are merged for 0.3 s, so one learn gives one splash with whatever rank
  and icon either source supplied.
- Only abilities learned from beasts in the wild count: Bite, Charge, Claw,
  Cower, Dash, Demoralizing Screech, Dive, Furious Howl, Lightning Breath,
  Prowl, Scorpid Poison, Shell Shield, Thunderstomp, and Forever's family
  abilities (Dismember, Dust Cloud, Mine!, Pinch, Savage Rend, Sonic Blast,
  Swipe, Tendon Rip, Web). Trainer abilities (Growl, Great Stamina, Natural
  Armor, resistances) are skipped. The list is spell IDs in `Detect.lua`; their
  names are looked up in the client, so no English text is compared anywhere
  and it works in every locale.
- Missing rank and icon come from the active pet's spellbook.
- The rank is read from a trailing `(...)` in the learned name, whatever the
  language calls it.
- Ignored: the first 5 s after login (spells are replayed then), anything while
  a trainer window is open (buying Growl ranks at a pet trainer), non-hunters.

## Commands

| Command | Effect |
| --- | --- |
| `/pal` | status line (current settings) with the list of commands; also for anything unknown |
| `/pal config` (or `options`) | open the about panel (Esc > Options > AddOns) |
| `/pal test [name]` | show the splash only, for Claw or `name` |
| `/pal sim [name]` | feed a fake "You have learned a new ability: Claw (Rank 2)." line through the real detection, ignoring the login wait, trainer window and duplicate window; says so when the name is not a wild pet ability |
| `/pal duration <s>` | whole seconds before it fades, from 1 (default 6) |
| `/pal scale <n>` | size, 0.3 to 3 (default 1) |
| `/pal sound on\|off` | the level-up sound (default on) |
| `/pal reset` | default position |
| `/pal debug` | trace in chat every learn the detection sees and what it decided (also a checkbox in the panel) |

Drag the splash to move it, right-click to close it, hover to keep it up.

Settings are in `PetAbilityLearnedDB` (account-wide): `duration`, `scale`,
`sound`, `debug` and `pos` (the dragged spot). The file keeps only what differs
from the defaults in `Core.lua`; a missing value reads the default, a broken
one is dropped on load, and numbers are put back in range.

The about panel shows version, author and license from the `.toc`, a copy box
for `X-Website` once the `.toc` has one, what the addon does, the Debug trace
checkbox, and buttons for `/pal test` and `/pal sim`.

## Development

Same tooling as FeedPetEmotes, as Node dev dependencies:

```bash
npm install
```

```bash
npm run check
```

- `npm test` runs `tests/*.test.lua` in fengari against a simulated client
  (`tests/wow.lua`) and reports line coverage per file; the target is 100%.
- `npm run lint` runs StyLua and WoW Lua LS (from its VS Code extension).
- `npm run format` formats with StyLua.

## Install

Developed here and linked into the client with a directory junction:

```powershell
New-Item -ItemType Junction `
  -Path "C:\Games\Blizzard\World of Warcraft\_classic_beta_\Interface\AddOns\PetAbilityLearned" `
  -Target "C:\Users\ruben\Documents\My Games\WoW AddOns\PetAbilityLearned"
```

## Files

- `Core.lua`: settings, spell info and the pet spellbook across client APIs.
- `Splash.lua`: the splash frame and its animation.
- `Detect.lua`: event handling and deciding what is a pet ability.
- `Commands.lua`: `/pal`.
- `Options.lua`: the about panel.
