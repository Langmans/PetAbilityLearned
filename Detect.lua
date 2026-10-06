local _, ns = ...

-- A hunter learns a Beast Training ability by using it on a tamed pet that already has it. The game
-- reports it as a system chat line ("You have learned a new ability: Claw (Rank 2).") and possibly as
-- LEARNED_SPELL_IN_TAB / LEARNED_SPELL_IN_SKILL_LINE. Beast Training abilities live in their own
-- window rather than the spellbook, so those events may not fire for them; the chat line is the
-- dependable signal. All are watched; whichever arrives is enough.
--
-- Only abilities a hunter has to learn from a beast in the wild count. The ones bought from a pet
-- trainer (Growl, Great Stamina, Natural Armor, the five resistances) are left out on purpose.
-- Nothing compares English text: names come from the client, so the check works in any locale.

-- The rank 1 spell ID of each wild-learned ability, used only to look up its name in the client's
-- language; every rank carries the same name. IDs from Wowhead's Forever hunter pet abilities list.
local PET_ABILITY_IDS = {
    17253, -- Bite
    7371, -- Charge
    16827, -- Claw
    1742, -- Cower
    23099, -- Dash
    24423, -- Demoralizing Screech
    23145, -- Dive
    24604, -- Furious Howl
    24844, -- Lightning Breath
    24450, -- Prowl
    24640, -- Scorpid Poison
    26064, -- Shell Shield
    26090, -- Thunderstomp
    -- Family abilities new in Forever.
    1264758, -- Dismember (crocolisk)
    1265899, -- Dust Cloud (tallstrider)
    1265054, -- Mine! (bird of prey)
    1264735, -- Pinch (crab)
    1265065, -- Savage Rend (raptor)
    1264478, -- Sonic Blast (bat)
    1264494, -- Swipe (bear)
    1265038, -- Tendon Rip (hyena)
    1265843, -- Web (spider)
}

-- Built on first use, and rebuilt until every name resolved: spell names are not guaranteed to be
-- readable while the addon loads.
local petAbilityNames, complete
local function IsPetAbilityName(name)
    if not complete then
        petAbilityNames, complete = {}, true
        for _, id in ipairs(PET_ABILITY_IDS) do
            local spellName = ns.SpellInfo(id)
            if spellName then
                petAbilityNames[spellName] = true
            else
                complete = false
            end
        end
    end
    return petAbilityNames[name] == true
end

-- A game format string such as "You have learned a new ability: %s." as a Lua pattern capturing %s.
local function Pattern(fmt)
    if type(fmt) ~= "string" then return nil end
    fmt = fmt:gsub("%%%d%$", "%%"):gsub("%%s", "\1")
    fmt = fmt:gsub("([%%%(%)%.%+%-%*%?%[%]%^%$])", "%%%1"):gsub("\1", "(.+)")
    return "^" .. fmt .. "$"
end

local LEARN_PATTERNS = {}
for _, fmt in ipairs({ ERR_LEARN_ABILITY_S, ERR_LEARN_SPELL_S }) do
    local pattern = Pattern(fmt)
    if pattern then LEARN_PATTERNS[#LEARN_PATTERNS + 1] = pattern end
end

local function Plain(v)
    return type(v) == "string" and not (issecretvalue and issecretvalue(v)) and v ~= "" and v or nil
end

-- Spells are replayed in the first seconds after login; nothing counts until that is over.
local ready = false
-- Buying ranks (Growl, resistances) at a pet trainer is not news; the trainer window says so.
local atTrainer = false
-- The chat line and the spellbook event usually both fire for one learn. They are merged for a
-- moment so the splash shows once, with whatever rank and icon either of them supplied.
local MERGE_WINDOW = 0.3
local pending
local lastShown = {} -- name -> GetTime() of the last splash, against late duplicates

local function SpellTextureByName(name)
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(name) end
    return GetSpellTexture and GetSpellTexture(name)
end

local function Flush()
    local info = pending
    pending = nil
    if not info then return end
    lastShown[info.name] = GetTime()
    ns.Debug(("splash: %s, rank %s"):format(info.name, tostring(info.rank)))

    local petSpell = info.petSpell
    local source
    if petSpell and UnitExists("pet") then source = ns.Format("SPLASH_FROM_PET", UnitName("pet")) end
    ns.ShowSplash({
        name = info.name,
        rank = info.rank or (petSpell and petSpell.rank),
        icon = info.icon or (petSpell and petSpell.icon) or SpellTextureByName(info.name),
        source = source,
    })
end

-- Returns true when the learn counts as a pet ability (shown now or merged into a pending one).
---@param name string? the learned spell's name, possibly with its rank in parentheses
---@param rank string?
---@param spellID number?
---@return boolean
local function Learned(name, rank, spellID)
    if not name then return false end
    ns.Debug(("learned: %s, rank %s, spell %s"):format(name, tostring(rank), tostring(spellID)))
    if not ready then
        ns.Debug("ignored: still in the login wait")
        return false
    end
    if atTrainer then
        ns.Debug("ignored: a trainer window is open")
        return false
    end
    if not rank then
        local base, inParens = name:match("^(.-)%s*%((.-)%)$")
        if base and base ~= "" then
            name, rank = base, inParens
        end
    end
    if lastShown[name] and GetTime() - lastShown[name] < 5 then
        ns.Debug("ignored: " .. name .. " was shown less than 5 seconds ago")
        return true
    end

    local _, idRank, idIcon = ns.SpellInfo(spellID)
    if pending and pending.name == name then
        pending.rank = pending.rank or rank or idRank
        pending.icon = pending.icon or idIcon
        ns.Debug("merged into the pending " .. name)
        return true
    end

    if not IsPetAbilityName(name) then
        ns.Debug("ignored: " .. name .. " is not a pet ability learned in the wild")
        return false
    end
    -- The pet you learned it from has it too; its spellbook fills in a missing rank and icon.
    local petSpell = ns.PetSpells()[name]

    if pending then Flush() end
    pending = { name = name, rank = rank or idRank, icon = idIcon, petSpell = petSpell }
    C_Timer.After(MERGE_WINDOW, Flush)
    return true
end

local function OnChat(msg)
    msg = Plain(msg)
    if not msg then return false end
    for _, pattern in ipairs(LEARN_PATTERNS) do
        local learned = msg:match(pattern)
        if learned then
            ns.Debug("chat: " .. msg:gsub("|", "||"))
            local spellID = tonumber(learned:match("|Hspell:(%d+)"))
            -- The name can arrive as a spell link: |cff..|Hspell:123|h[Claw]|h|r
            learned = learned:gsub("|c%x+|H.-|h%[?(.-)%]?|h|r", "%1")
            return Learned(learned, nil, spellID)
        end
    end
    return false
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        local _, class = UnitClass("player")
        if class ~= "HUNTER" then return end
        for _, name in ipairs({
            "CHAT_MSG_SYSTEM",
            "LEARNED_SPELL_IN_TAB",
            "LEARNED_SPELL_IN_SKILL_LINE",
            "TRAINER_SHOW",
            "TRAINER_CLOSED",
        }) do
            pcall(self.RegisterEvent, self, name) -- not every client has every event
        end
        C_Timer.After(5, function()
            ready = true
        end)
    elseif event == "CHAT_MSG_SYSTEM" then
        OnChat(arg1)
    elseif event == "LEARNED_SPELL_IN_TAB" or event == "LEARNED_SPELL_IN_SKILL_LINE" then
        ns.Debug(("%s: spell %s"):format(event, tostring(arg1)))
        local name, rank = ns.SpellInfo(arg1)
        Learned(Plain(name), Plain(rank), arg1)
    elseif event == "TRAINER_SHOW" then
        atTrainer = true
        ns.Debug("trainer window open: learns are ignored")
    elseif event == "TRAINER_CLOSED" then
        atTrainer = false
        ns.Debug("trainer window closed")
    end
end)

-- For /pal sim: feed a system chat line through the real detection, as if it had just arrived.
-- The login and trainer guards and the duplicate window are lifted for it, so it works anytime.
-- Returns whether the line counted as learning a pet ability.
function ns.SimulateChat(msg)
    local wasReady, wasAtTrainer = ready, atTrainer
    ready, atTrainer = true, false
    wipe(lastShown)
    local counted = OnChat(msg)
    ready, atTrainer = wasReady, wasAtTrainer
    return counted
end
