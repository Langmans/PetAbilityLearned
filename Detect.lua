local ADDON_NAME, ns = ...

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
---@type table<string, true>, boolean?
local petAbilityNames, complete
---@param name string
---@return boolean
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
ns.IsWildAbility = IsPetAbilityName

---A game format string such as "You have learned a new ability: %s." as a Lua pattern capturing %s.
---@param fmt string?
---@return string?
local function Pattern(fmt)
    if type(fmt) ~= "string" then return nil end
    -- Positional arguments (%1$s) become plain %s, each %s a marker, the rest of the text is
    -- escaped, and each marker becomes a capture.
    local plain = fmt:gsub("%%%d%$", "%%")
    local marked = plain:gsub("%%s", "\1")
    local escaped = marked:gsub("([%%%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
    local pattern = escaped:gsub("\1", "(.+)")
    return "^" .. pattern .. "$"
end

---@type string[]
local LEARN_PATTERNS = {}
for _, fmt in ipairs({ ERR_LEARN_ABILITY_S, ERR_LEARN_SPELL_S }) do
    local pattern = Pattern(fmt)
    if pattern then LEARN_PATTERNS[#LEARN_PATTERNS + 1] = pattern end
end

---A string the addon may read: not secret (Forever hides some values in combat) and not empty.
---@param v GameValue
---@return string?
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

---A learn waiting out the merge window.
---@class PendingLearn
---@field name string
---@field rank string?
---@field icon (number|string)?
---@field petSpell PetSpell? the active pet's spell of that name
---@field simulated boolean? from /pal sim: shown, but not kept in the history

---@type PendingLearn?
local pending
-- True while /pal sim feeds its line through the detection.
local simulating = false
---@type table<string, number>
local lastShown = {} -- name -> GetTime() of the last splash, against late duplicates

---@param name string
---@return (number|string)?
local function SpellTextureByName(name)
    -- Both return the icon and the original icon; only the first is wanted.
    if C_Spell and C_Spell.GetSpellTexture then return (C_Spell.GetSpellTexture(name)) end
    return GetSpellTexture and (GetSpellTexture(name))
end

---Shows the pending learn, if any.
local function Flush()
    local info = pending
    pending = nil
    if not info then return end
    lastShown[info.name] = GetTime()
    ns.Debug(("splash: %s, rank %s"):format(info.name, tostring(info.rank)))

    -- When the pet out has the ability, it is the one that taught it.
    local petSpell = info.petSpell
    local teacher = petSpell and UnitExists("pet") and UnitName("pet") or nil
    local familyID = petSpell and ns.PetFamilyID() or nil
    local rank = info.rank or (petSpell and petSpell.rank)
    local freePoints = teacher and ns.PetFreeTrainingPoints()
    ns.ShowSplash({
        points = freePoints and ns.Format("SPLASH_POINTS", teacher, freePoints) or nil,
        name = info.name,
        rank = rank,
        icon = info.icon or (petSpell and petSpell.icon) or SpellTextureByName(info.name),
        source = teacher and ns.Format("SPLASH_FROM_PET", teacher, info.name) or nil,
        petPortrait = petSpell ~= nil,
        familyID = familyID,
    })
    if info.simulated then return end
    ns.RecordLearn({
        name = info.name,
        rank = rank,
        pet = teacher,
        familyID = familyID,
        zone = GetZoneText(),
        t = GetServerTime(),
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
    pending = { name = name, rank = rank or idRank, icon = idIcon, petSpell = petSpell, simulated = simulating }
    C_Timer.After(MERGE_WINDOW, Flush)
    return true
end

---A system chat line; returns whether it reported learning a pet ability.
---@param line string?
---@return boolean
local function OnChat(line)
    local msg = Plain(line)
    if not msg then return false end
    for _, pattern in ipairs(LEARN_PATTERNS) do
        ---@type string?
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

---@param event string
---@param spellID number
local function SpellbookLearned(event, spellID)
    ns.Debug(("%s: spell %s"):format(event, tostring(spellID)))
    local name, rank = ns.SpellInfo(spellID)
    Learned(Plain(name), Plain(rank), spellID)
end

-- Events: one method per event on this frame, named after the event and called with the event's
-- own arguments. Only ADDON_LOADED is registered up front; it registers the rest once the saved
-- settings are there. PLAYER_LOGOUT strips the default values from them before the client saves
-- them.
--
-- Only a hunter learns pet abilities. On any other class the addon stays loaded (the addon list is
-- account-wide, so disabling it here would disable it for the hunters too) but registers nothing
-- past PLAYER_LOGOUT, while /pal and the options panel keep working.
local frame = CreateFrame("Frame")

---@param name string the addon that finished loading
function frame:ADDON_LOADED(name)
    if name ~= ADDON_NAME then return end
    self:UnregisterEvent("ADDON_LOADED")
    ns.LoadSettings()
    ns.LoadCharacterData()
    self:RegisterEvent("PLAYER_LOGOUT")
    local _, class = UnitClass("player")
    ---@type boolean
    ns.isHunter = class == "HUNTER"
    if not ns.isHunter then return end
    self:RegisterEvent("PLAYER_LOGIN")
    for _, event in ipairs({
        "CHAT_MSG_SYSTEM",
        "LEARNED_SPELL_IN_TAB",
        "LEARNED_SPELL_IN_SKILL_LINE",
        "TRAINER_SHOW",
        "TRAINER_CLOSED",
        "UNIT_PET",
        "CRAFT_SHOW",
        "CRAFT_UPDATE",
    }) do
        pcall(self.RegisterEvent, self, event) -- not every client has every event
    end
end

function frame:PLAYER_LOGOUT()
    ns.StripDefaults()
end

-- The spells replayed at login arrive in the next seconds; learns count after that. A pet
-- already out at login gets its hint then too.
function frame:PLAYER_LOGIN()
    C_Timer.After(5, function()
        ready = true
        ns.CheckPetHints()
    end)
end

-- A pet summoned, tamed or dismissed. Its spellbook fills in just after, hence the wait.
---@param unit string
function frame:UNIT_PET(unit)
    if unit ~= "player" or not ready then return end
    C_Timer.After(1, ns.CheckPetHints)
end

function frame:CRAFT_SHOW()
    ns.ReadBeastTraining()
end

function frame:CRAFT_UPDATE()
    ns.ReadBeastTraining()
end

---@param msg string
function frame:CHAT_MSG_SYSTEM(msg)
    OnChat(msg)
end

---@param spellID number
function frame:LEARNED_SPELL_IN_TAB(spellID)
    SpellbookLearned("LEARNED_SPELL_IN_TAB", spellID)
end

---@param spellID number
function frame:LEARNED_SPELL_IN_SKILL_LINE(spellID)
    SpellbookLearned("LEARNED_SPELL_IN_SKILL_LINE", spellID)
end

function frame:TRAINER_SHOW()
    atTrainer = true
    ns.Debug("trainer window open: learns are ignored")
end

function frame:TRAINER_CLOSED()
    atTrainer = false
    ns.Debug("trainer window closed")
end

frame:SetScript("OnEvent", function(
    self,
    event --[[@as string]],
    ...
)
    self[event](self, ...)
end)
frame:RegisterEvent("ADDON_LOADED")

---For /pal sim: feed a system chat line through the real detection, as if it had just arrived.
---The login and trainer guards and the duplicate window are lifted for it, so it works anytime;
---what it shows is not kept in the history.
---@param msg string
---@return boolean counted whether the line counted as learning a pet ability
function ns.SimulateChat(msg)
    local wasReady, wasAtTrainer = ready, atTrainer
    ready, atTrainer, simulating = true, false, true
    wipe(lastShown)
    local counted = OnChat(msg)
    ready, atTrainer, simulating = wasReady, wasAtTrainer, false
    return counted
end
