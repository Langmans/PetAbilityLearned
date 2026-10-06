# Pet Ability Learned

Shows a large splash in the middle of the screen the moment your hunter learns
a pet ability from a tamed beast:

> **New Pet Ability Learned!**
> Claw — Rank 2
> Fluffy has taught you Claw.

Tame a beast that knows a higher rank than you do (a Nightstalker with Claw
rank 2 while you only have rank 1, say), fight with it, and you learn that
rank after a while. The game only tells you with one line in the chat, easy
to miss in a fight. This addon makes it impossible to miss, so you know when
you can abandon the beast and tame the next one.

The look follows GnomeLevelUp's level-up screen: a dark panel that fades out
at the edges, the ability's icon in a gold ring, glowing text.

## What it shows

- The ability's icon, name and rank, and which pet taught it to you: its
  portrait as a badge on the icon, and "Fluffy has taught you Claw." under
  it, with the name your pet has now.
- Only abilities you learn from beasts in the wild: Bite, Charge, Claw, Cower,
  Dash, Demoralizing Screech, Dive, Furious Howl, Lightning Breath, Prowl,
  Scorpid Poison, Shell Shield, Thunderstomp, and the family abilities new in
  WoW: Forever (Dismember, Dust Cloud, Mine!, Pinch, Savage Rend, Sonic Blast,
  Swipe, Tendon Rip, Web).
- Not what you buy at a pet trainer (Growl, Great Stamina, Natural Armor, the
  resistances), nor anything learned while a trainer window is open, nor
  your other spells and recipes.
- The splash stays for 6 seconds, then fades. Hover over it to keep it up,
  right-click to close it, drag it to move it; a level-up sound plays with it.
- It only watches on hunters. On other characters the addon stays loaded but
  idle; `/pal` and the panel still work there.

## Install

By hand:

1. Download the zip from
   [GitHub](https://github.com/Langmans/PetAbilityLearned) (Code > Download
   ZIP).
2. Unzip it into your WoW client's `Interface\AddOns` and rename the folder
   to `PetAbilityLearned`, so that you get
   `Interface\AddOns\PetAbilityLearned\PetAbilityLearned.toc`.
3. Restart the game, or `/reload` if it was running, and check that
   "PetAbilityLearned" is enabled in the AddOns list on the character screen.

Made for WoW: Forever (1.60).

## Settings

Open the panel with `/pal config`, or through Esc > Options > AddOns > Pet
Ability Learned. It shows the version and website, and has:

- **Debug trace**: print in chat what the addon sees and decides (see
  [Reporting a problem](#reporting-a-problem)).
- **Show the splash** and **Simulate a learn**: the same as `/pal test` and
  `/pal sim` below.

All settings are saved for the whole account. The rest are chat commands
(`/petabilitylearned` works too):

- `/pal` shows the current settings, plus the list of commands.
- `/pal config` (or `/pal options`) opens the panel.
- `/pal test [name]` shows the splash for Claw, or for the ability you name.
  Nothing else happens; it is only a look at the splash.
- `/pal sim [name]` pretends the game just said you learned Claw rank 2 (or
  the ability you name), and runs that through the real detection. It says
  so when the name is not an ability learned in the wild.
- `/pal duration <seconds>` sets how long the splash stays (default 6).
- `/pal scale <0.3-3>` sets its size (default 1).
- `/pal sound on` and `/pal sound off` switch the sound.
- `/pal reset` puts the splash back in its standard spot.
- `/pal debug` switches the debug trace on or off.

## Languages

The splash, the panel and the chat messages follow your game's language:
English, German, French, Spanish, Korean and Russian. Other languages get
English. Ability names and ranks always come from the game itself, so they
are right in every language. Commands and the debug trace are English.

## Reporting a problem

If the splash does not appear when you learn an ability, or appears when it
should not:

1. Type `/pal debug`.
2. Learn the ability again, or do what made the splash appear.
3. Copy the chat lines into an
   [issue on GitHub](https://github.com/Langmans/PetAbilityLearned/issues).

## Credits

The splash copies the look of
[GnomeLevelUp](https://welcometozombo.com/)'s level-up screen by Lessa. The
list of abilities learned in the wild comes from Wowhead's
[Forever hunter pet abilities](https://www.wowhead.com/forever/spells/pet-abilities/hunter).

## License

MIT, see [LICENSE](https://github.com/Langmans/PetAbilityLearned/blob/main/LICENSE).

---

## Technical documentation

The rest of this file is for people who want to change the addon.

### Files

In `.toc` order; all share the addon namespace `ns`.

- `Locales\*.lua` — one file per locale with its `strings`. `enUS.lua` loads
  first and creates `ns.Locales`.
- `Locale.lua` — picks the client's locale; `ns.L`, `ns.Format`.
- `Core.lua` — the saved settings (`ns.DEFAULTS`, `ns.db`,
  `ns.LoadSettings`, `ns.StripDefaults`), `ns.Print`, `ns.Debug`, and the
  lookups that differ between clients: `ns.SpellInfo` (name, rank, icon by
  spell ID) and `ns.PetSpells` (the active pet's spellbook).
- `Splash.lua` — the splash frame (`ns.ShowSplash`, `ns.HideSplash`): its
  background, the glowing texts, and the animation on one `OnUpdate` clock.
- `Detect.lua` — the event frame (one method per event) and the detection:
  which line or event means a learn, whether it is an ability learned in the
  wild, merging, and `ns.SimulateChat` for `/pal sim`.
- `Commands.lua` — `/pal`: one function per subcommand in a `Commands` table,
  looked up by the slash handler like the event frame looks up its event
  methods; anything unknown shows the status line.
- `Options.lua` — the panel in the game's settings (`ns.OpenOptions`):
  version, author, license and website from the .toc (`GetAddOnMetadata`),
  the debug checkbox, the test and sim buttons.

The settings are saved account-wide in `PetAbilityLearnedDB`: `duration`
(whole seconds, from 1), `scale` (0.3 to 3), `sound` and `debug` (booleans),
and `pos`, the dragged spot as `{ point, relativePoint, x, y }`. Only values
that differ from their default are kept: `ns.db` reads the rest from the
defaults through a metatable, a broken value is dropped on load so its
default shows through, numbers are put back in range, and `ns.StripDefaults`
removes values equal to their default on `PLAYER_LOGOUT`. A default changed
in a later version so reaches everyone who never changed it. Until
`ADDON_LOADED`, `ns.db` is the defaults table itself.

### How it works

- A learn is seen in two ways:
  - **chat**: `CHAT_MSG_SYSTEM` lines are matched against the client's own
    `ERR_LEARN_ABILITY_S` and `ERR_LEARN_SPELL_S` format strings, turned into
    Lua patterns, so it works in any client language. A spell link in the
    line is unwrapped, and its spell ID gives the rank and icon.
  - **spellbook**: `LEARNED_SPELL_IN_TAB` and `LEARNED_SPELL_IN_SKILL_LINE`,
    in case the client fires them for Beast Training. Those abilities live in
    their own window rather than the spellbook, so they may not; the chat
    line is the dependable signal.
- Both often report the same learn. The first starts a 0.3 s window; what
  arrives for the same name within it only fills in a missing rank or icon,
  so one learn gives one splash. A name shown less than 5 s ago is dropped.
- The rank is a trailing `(...)` in the learned name, whatever the language
  calls it ("Rank 2", "Rang 2"). Without one, the active pet's spellbook
  supplies it: you learn an ability from the pet you have out, so it has it.
- An ability learned in the wild is recognised by name. `PET_ABILITY_IDS` in
  `Detect.lua` holds the rank 1 spell ID of each; their names are looked up in
  the client (every rank carries the same name), so nothing compares English
  text. Names the client cannot read yet are looked up again on the next
  learn.
- Ignored: the first 5 s after `PLAYER_LOGIN` (the client replays known
  spells then), and anything between `TRAINER_SHOW` and `TRAINER_CLOSED`.
  `/pal sim` lifts both for the line it feeds in.
- On any class but hunter, `ADDON_LOADED` registers only `PLAYER_LOGOUT`; the
  addon list is account-wide, so disabling the addon there would disable it
  for the hunters too.

### Localization

One file per locale in `Locales\`: enUS, deDE, esES (also used for esMX),
frFR, koKR and ruRU, each with that locale's `strings`.

- `Locale.lua` loads after the locale files and picks the client's locale.
  `ns.L` falls back to enUS through a metatable, so a locale lists only what
  it translates; a key missing from enUS as well returns the key itself.
- Ability names, the learn chat line and the rank word come from the client
  and are not in the locale files.
- A test checks that every locale only uses enUS keys, with the same format
  directives (`%s`, `%d`, `%.2f`) in the same order.

To add a locale: copy `Locales\enUS.lua`, change the key in `ns.Locales`,
drop the strings that stay English and the `ns.Locales = {}` line, and list
the file in the `.toc` before `Locale.lua`.

### Development

Needs Node.js. `npm install` once, then:

- `npm test` — runs `tests/*.test.lua` against a simulated WoW client
  (`tests/wow.lua`) in fengari, a Lua VM in JavaScript, and prints line
  coverage per file; `coverage/lcov.info` is written for editor plugins.
  `npm test detect` runs only the files whose name contains `detect`.
- `npm run lint` — StyLua formatting check, then WoW Lua LS diagnostics
  (taken from its VS Code extension; skipped if that is not installed).
- `npm run format` — formats all Lua with StyLua.
- `npm run check` — lint, then tests.

To try a change in the game, link the repository into the client's AddOns
folder with a directory junction instead of copying it, e.g. in PowerShell:
`New-Item -ItemType Junction -Path "<WoW>\Interface\AddOns\PetAbilityLearned"
-Target "<repository>"`.

fengari is Lua 5.3 and WoW runs 5.1; the addon sticks to the shared subset and
WoW Lua LS flags WoW-incompatible API use. What the simulation cannot show —
the exact chat line a learn from a beast produces, and whether the
`LEARNED_SPELL_*` events fire for it — is what the debug trace is for.

Coverage counts the first line of each statement as found by luaparse, with
two adjustments for how Lua reports lines: a function counts on its closing
`end` (where the closure is created), and `local a, b` without values does not
count (it has no instruction of its own). Both line coverage and WoW Lua LS
type coverage are at 100%.

WoW Lua LS only prints a total for type coverage. To find what is
unresolved, `wowlua_ls dump-types --with-stubs .` lists every name with its
type (look for `any`, `?` and `<none>`), and `wowlua_ls evaluate --with-stubs
<file>` reports parameters without a type, such as an unannotated `_`. Two
things it gets wrong here: a field of `ns` gets its type only where it is
first declared (so `ns.db` and `ns.isHunter` are declared in `Core.lua`), and
writing `ns.db.x = …` directly widens the field's type, so settings are
written through a local `db`.
