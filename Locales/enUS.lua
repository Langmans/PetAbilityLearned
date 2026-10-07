local _, ns = ...

-- The fallback locale: every other locale falls back to these strings (see Locale.lua). This file
-- loads first, so it also creates the table the other locale files add themselves to.
-- Slash commands stay English in every locale; the game's own texts (spell names, the "learned"
-- chat line, the rank word) come from the client and need nothing here.
ns.Locales = {}
ns.Locales.enUS = {
    strings = {
        CHAT_PREFIX = "Pet Ability Learned:",

        -- The splash.
        SPLASH_TITLE = "New Pet Ability Learned!",
        -- The pet's name, then the ability's name.
        SPLASH_FROM_PET = "%s has taught you %s.",
        SPLASH_TEACH = "Teach it to your pet from the Beast Training window.",

        -- The pet's name, its free training points.
        SPLASH_POINTS = "%s has %d training points free.",

        -- Said in chat when a pet is summoned or tamed. The pet's name, then a list like
        -- "Claw (Rank 3), Dash (Rank 1)".
        HINT_TEACHES = "%s can teach you: %s.",
        HINT_OPEN_TRAINING = "Open Beast Training once so the addon knows your ranks.",

        -- /pal. STATUS: duration in seconds, scale, sound (a SOUND_NAME_* or STATUS_OFF), then
        -- screenshot, pet hints and debug on/off, the command list.
        STATUS = "Splash for %d s at scale %.2f, sound %s, screenshot %s, pet hints %s, debug %s. Commands: %s",
        STATUS_ON = "on",
        STATUS_OFF = "off",
        SOUND_NAME_FAMILY = "pet family",
        SOUND_NAME_LEVELUP = "level-up",
        NOT_HUNTER = "Only hunters learn pet abilities; nothing is watched on this character.",
        -- Used by /pal test and /pal sim when the client cannot name Claw rank 2 itself.
        TEST_SPELL = "Claw",
        TEST_RANK = "Rank 2",
        NO_LEARN_MESSAGE = "This client has no learn message to imitate.",
        -- %s is the chat line being imitated.
        SIMULATING = "Simulating: %s",
        -- %s is a spell name.
        NOT_WILD = "%s is not a pet ability learned in the wild; no splash.",
        DURATION_SET = "Splash duration: %d seconds.",
        SCALE_SET = "Splash scale: %.2f.",
        SOUND_FAMILY = "Sound: the call of your pet's family (the level-up sound when it has none).",
        SOUND_LEVELUP = "Sound: the level-up sound.",
        SOUND_OFF = "Sound off.",
        POSITION_RESET = "Splash position reset.",
        SCREENSHOT_ON = "A screenshot is taken of each splash.",
        SCREENSHOT_OFF = "No screenshots.",
        HINTS_ON = "Summoning or taming a pet says what it can still teach you.",
        HINTS_OFF = "No hints about new pets.",
        -- /pal history.
        HISTORY_EMPTY = "This character has not learned a pet ability since the addon was installed.",
        -- How many are listed, how many there are.
        HISTORY_TITLE = "Pet abilities learned on this character (last %d of %d):",
        -- The pet's name.
        HISTORY_FROM = "from %s",
        DEBUG_ON = "Debug on.",
        DEBUG_OFF = "Debug off.",
        OPTIONS_AFTER_COMBAT = "In combat: the options open when combat ends.",

        -- The options panel (Options.lua).
        OPTIONS_TITLE = "Pet Ability Learned",
        -- Version, author and license from the .toc.
        OPTION_ABOUT = "Version %s by %s, %s license.",
        OPTION_WEBSITE = "Website (Ctrl+C to copy):",
        OPTION_DESCRIPTION = "When your hunter learns a pet ability from a tamed beast (Claw rank 2 from a "
            .. "Nightstalker, say), a large splash shows it in the middle of the screen. Abilities bought "
            .. "from a pet trainer do not count.\n\n"
            .. "Drag the splash to move it, right-click to close it, hover to keep it up. "
            .. "Type /pal for the settings.",
        OPTION_DEBUG = "Debug trace",
        OPTION_DEBUG_NOTE = "Print in chat every learn the addon sees and what it decided. Same as /pal debug.",
        OPTION_TEST = "Show the splash",
        OPTION_SIM = "Simulate a learn",
    },
}
