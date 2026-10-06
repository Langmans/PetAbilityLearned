local _, ns = ...

-- /pal and its subcommands. Commands: one function per subcommand, named after it (lower case)
-- and called with what was typed after it; the slash handler only splits the message and looks
-- the subcommand up. Anything it does not know shows the status line with the list of commands.
-- Settings are read from ns.db, which exists once the addon has loaded (before anyone can type).

local Print = ns.Print

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
    return rest:lower():match("^%S*") or ""
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

local function status()
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then Print("Only hunters learn pet abilities; nothing is watched on this character.") end
    local db = ns.db
    Print(
        ("Splash for %d s at scale %.2f, sound %s, debug %s. Commands: %s"):format(
            db.duration,
            db.scale,
            db.sound and "on" or "off",
            db.debug and "on" or "off",
            COMMAND_LIST
        )
    )
end

-- The ability a test uses, with the rank and icon the active pet has for it. Without a pet the
-- rank is the client's own text for Claw rank 2, so the line reads right in any language.
local function testSpell(name)
    if name == "" then name = ns.SpellInfo(CLAW) or "Claw" end
    local petSpell = ns.PetSpells()[name]
    local _, rank2, icon = ns.SpellInfo(CLAW_RANK_2)
    return name, (petSpell and petSpell.rank) or rank2 or "Rank 2", (petSpell and petSpell.icon) or icon
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
    if not format then return Print("This client has no learn message to imitate.") end
    local spell, rank = testSpell(rest)
    local msg = format:format(("%s (%s)"):format(spell, rank))
    Print("Simulating: " .. msg)
    if not ns.SimulateChat(msg) then Print(spell .. " is not a pet ability learned in the wild; no splash.") end
end

---/pal duration <seconds>: how long the splash stays before it fades, whole seconds from 1.
function Commands.duration(rest)
    local seconds = tonumber(firstWord(rest))
    if not seconds then return status() end
    ns.db.duration = math.max(1, math.floor(seconds))
    Print(("Splash duration: %d seconds."):format(ns.db.duration))
end

---/pal scale <0.3-3>
function Commands.scale(rest)
    local scale = tonumber(firstWord(rest))
    if not scale then return status() end
    ns.db.scale = math.min(3, math.max(0.3, scale))
    Print(("Splash scale: %.2f."):format(ns.db.scale))
end

---/pal sound on|off
function Commands.sound(rest)
    local on = onOff(rest)
    if on == nil then return status() end
    ns.db.sound = on
    Print("Sound " .. (on and "on." or "off."))
end

function Commands.reset()
    ns.db.pos = nil
    Print("Splash position reset.")
end

function Commands.config()
    ns.OpenOptions()
end
Commands.options = Commands.config

function Commands.debug()
    ns.db.debug = not ns.db.debug
    Print("Debug " .. (ns.db.debug and "on." or "off."))
end

SLASH_PETABILITYLEARNED1 = "/pal"
SLASH_PETABILITYLEARNED2 = "/petabilitylearned"
SlashCmdList.PETABILITYLEARNED = function(message)
    local name, rest = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local command = Commands[(name or ""):lower()]
    if command then
        command(rest or "")
    else
        status()
    end
end
