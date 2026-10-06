local _, ns = ...

-- /pal and its subcommands. Commands: one function per subcommand, named after it (lower case)
-- and called with what was typed after it; the slash handler only splits the message and looks
-- the subcommand up. Anything it does not know shows the status line with the list of commands.
-- Settings are read from ns.db, which exists once the addon has loaded (before anyone can type).

local L, Print = ns.L, ns.Print

local CLAW, CLAW_RANK_2 = 16827, 16828

local COMMAND_LIST = table.concat({
    "/pal test [name]",
    "/pal sim [name]",
    "/pal duration <seconds>",
    "/pal scale <0.3-3>",
    "/pal sound on|off",
    "/pal reset",
    "/pal config",
    "/pal debug",
}, ", ") .. "."

---The first word of what was typed after the subcommand, lower case.
---@param rest string
---@return string
local function firstWord(rest)
    local lowered = rest:lower()
    return lowered:match("^%S*") or ""
end

---"on" -> true, "off" -> false, anything else nil.
---@param rest string
---@return boolean?
local function onOff(rest)
    local word = firstWord(rest)
    if word == "on" then return true end
    if word == "off" then return false end
    return nil
end

---The current settings and the list of commands.
local function status()
    if not ns.isHunter then Print(L.NOT_HUNTER) end
    ---@type Settings
    local db = ns.db
    Print(
        ns.Format(
            "STATUS",
            db.duration,
            db.scale,
            db.sound and L.STATUS_ON or L.STATUS_OFF,
            db.debug and L.STATUS_ON or L.STATUS_OFF,
            COMMAND_LIST
        )
    )
end

---The ability a test uses, with the rank and icon the active pet has for it. Without a pet the
---rank is the client's own text for Claw rank 2, so the line reads right in any language.
---@param name string what was typed; empty for Claw
---@return string name
---@return string rank
---@return (number|string)? icon
local function testSpell(name)
    if name == "" then name = ns.SpellInfo(CLAW) or L.TEST_SPELL end
    local petSpell = ns.PetSpells()[name]
    local _, rank2, icon = ns.SpellInfo(CLAW_RANK_2)
    return name, (petSpell and petSpell.rank) or rank2 or L.TEST_RANK, (petSpell and petSpell.icon) or icon
end

---@type table<string, fun(rest: string)>
local Commands = {}

---/pal test [name]: the splash only, no detection. rest keeps the case it was typed in.
function Commands.test(rest)
    local spell, rank, icon = testSpell(rest)
    ns.ShowSplash({ name = spell, rank = rank, icon = icon })
end

---/pal sim [name]: a learn line as the game would print it, through the real detection.
function Commands.sim(rest)
    local format = ERR_LEARN_ABILITY_S or ERR_LEARN_SPELL_S
    if not format then return Print(L.NO_LEARN_MESSAGE) end
    local spell, rank = testSpell(rest)
    local msg = format:format(("%s (%s)"):format(spell, rank))
    Print(ns.Format("SIMULATING", msg))
    if not ns.SimulateChat(msg) then Print(ns.Format("NOT_WILD", spell)) end
end

---/pal duration <seconds>: how long the splash stays before it fades, whole seconds from 1.
function Commands.duration(rest)
    local seconds = tonumber(firstWord(rest))
    if not seconds then return status() end
    local db = ns.db
    db.duration = math.max(1, math.floor(seconds))
    Print(ns.Format("DURATION_SET", db.duration))
end

---/pal scale <0.3-3>
function Commands.scale(rest)
    local scale = tonumber(firstWord(rest))
    if not scale then return status() end
    local db = ns.db
    db.scale = math.min(3, math.max(0.3, scale))
    Print(ns.Format("SCALE_SET", db.scale))
end

---/pal sound on|off
function Commands.sound(rest)
    local on = onOff(rest)
    if on == nil then return status() end
    local db = ns.db
    db.sound = on
    Print(on and L.SOUND_ON or L.SOUND_OFF)
end

function Commands.reset()
    local db = ns.db
    db.pos = nil
    Print(L.POSITION_RESET)
end

function Commands.config()
    ns.OpenOptions()
end
Commands.options = Commands.config

function Commands.debug()
    local db = ns.db
    db.debug = not db.debug
    Print(db.debug and L.DEBUG_ON or L.DEBUG_OFF)
end

SLASH_PETABILITYLEARNED1 = "/pal"
SLASH_PETABILITYLEARNED2 = "/petabilitylearned"
---@param message string? what was typed after /pal
SlashCmdList.PETABILITYLEARNED = function(message)
    local typed = message or ""
    local name, rest = typed:match("^%s*(%S*)%s*(.-)%s*$")
    local key = name or ""
    local command = Commands[key:lower()]
    if command then
        command(rest or "")
    else
        status()
    end
end
