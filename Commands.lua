local _, ns = ...

local CLAW, CLAW_RANK_2 = 16827, 16828

local HELP = {
    "/pal config - open the about panel",
    "/pal test [name] - show the splash only (default: Claw)",
    "/pal sim [name] - pretend the game said you learned it; runs the real detection (default: Claw)",
    "/pal duration <seconds> - how long the splash stays up (now %d)",
    "/pal scale <number> - size of the splash (now %.2f)",
    "/pal sound - toggle the sound (now %s)",
    "/pal reset - put the splash back in its default spot",
    "/pal debug - trace in chat what the detection sees and decides (now %s)",
    "Drag the splash to move it; right-click closes it; hovering keeps it up.",
}

-- The ability a test uses, with the rank and icon the active pet has for it. Without a pet the
-- rank is the client's own text for Claw rank 2, so the line reads right in any language.
local function TestSpell(name)
    if name == "" then name = ns.SpellInfo(CLAW) or "Claw" end
    local petSpell = ns.PetSpells()[name]
    local _, rank2, icon = ns.SpellInfo(CLAW_RANK_2)
    return name, (petSpell and petSpell.rank) or rank2 or "Rank 2", (petSpell and petSpell.icon) or icon
end

local function Test(name)
    local spell, rank, icon = TestSpell(name)
    ns.ShowSplash({ name = spell, rank = rank, icon = icon })
end

local function Simulate(name)
    local format = ERR_LEARN_ABILITY_S or ERR_LEARN_SPELL_S
    if not format then return ns.Print("This client has no learn message to imitate.") end
    local spell, rank = TestSpell(name)
    local msg = format:format(("%s (%s)"):format(spell, rank))
    ns.Print("Simulating: " .. msg)
    if not ns.SimulateChat(msg) then ns.Print(spell .. " is not a pet ability learned in the wild; no splash.") end
end

SLASH_PETABILITYLEARNED1 = "/pal"
SLASH_PETABILITYLEARNED2 = "/petabilitylearned"
SlashCmdList.PETABILITYLEARNED = function(input)
    local db = ns.db
    local cmd, rest = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd, rest = (cmd or ""):lower(), rest or ""
    local number = tonumber(rest)
    if cmd == "config" then
        ns.OpenOptions()
    elseif cmd == "test" then
        Test(rest)
    elseif cmd == "sim" then
        Simulate(rest)
    elseif cmd == "duration" and number then
        db.duration = math.max(1, math.floor(number))
        ns.Print(("Splash duration: %d seconds."):format(db.duration))
    elseif cmd == "scale" and number then
        db.scale = math.min(3, math.max(0.3, number))
        ns.Print(("Splash scale: %.2f."):format(db.scale))
    elseif cmd == "sound" then
        db.sound = not db.sound
        ns.Print("Sound " .. (db.sound and "on." or "off."))
    elseif cmd == "reset" then
        db.pos = nil
        ns.Print("Splash position reset.")
    elseif cmd == "debug" then
        db.debug = not db.debug
        ns.Print("Debug " .. (db.debug and "on." or "off."))
    else
        local values = {
            false,
            false,
            false,
            db.duration,
            db.scale,
            db.sound and "on" or "off",
            false,
            db.debug and "on" or "off",
        }
        for i, line in ipairs(HELP) do
            ns.Print(values[i] and line:format(values[i]) or line)
        end
    end
end
