local _, ns = ...

-- Shared helpers and the saved settings. Loaded after Locale.lua (ns.Print needs ns.L) and before
-- every module that uses them.
--
-- Globals this file writes: PetAbilityLearnedDB, the SavedVariables from the .toc. WoW Lua LS
-- reads that from the .toc, so writing it needs no diagnostic exception.

-- Saved account-wide. The saved file keeps only what the player changed: ns.db reads a missing
-- value from here through a metatable, and StripDefaults removes values equal to their default
-- at logout. A default changed in a later version so reaches everyone who never changed it.
-- pos has no default: without it the splash sits in its standard spot. The fields are described
-- in annotations\PetAbilityLearned.lua (PetAbilityLearnedSettings).

---The sound modes /pal sound takes (PetAbilityLearnedSoundMode).
---@type table<string, true>
ns.SOUND_MODES = { family = true, levelup = true, off = true }

---A value the game hands over without a known type: from a SavedVariables file, an event
---argument or an API return.
---@alias GameValue string|number|boolean|table|nil

---A spell in the active pet's spellbook.
---@class PetSpell
---@field id number?
---@field rank string?
---@field icon (number|string)?

---@type PetAbilityLearnedSettings
ns.DEFAULTS = {
    duration = 6, -- /pal duration <seconds>
    scale = 1, -- /pal scale <0.3-3>
    sound = "family", -- /pal sound family|levelup|off
    screenshot = false, -- /pal screenshot on|off
    hints = true, -- /pal hints on|off
    debug = false, -- /pal debug
}

---The settings: the defaults until LoadSettings replaces them with the saved table on
---ADDON_LOADED. Nothing writes to them before then (no command or event runs that early).
---@type PetAbilityLearnedSettings
ns.db = ns.DEFAULTS

---Whether this character is a hunter; set on ADDON_LOADED.
ns.isHunter = false

---@param message string
function ns.Print(message)
    print("|cffabd473" .. ns.L.CHAT_PREFIX .. "|r " .. message)
end

---/pal debug traces the detection in chat: every learn it sees and what it decided.
---@param message string
function ns.Debug(message)
    if ns.db.debug then ns.Print("|cff88ccff[debug]|r " .. message) end
end

---Spell info across client generations: C_Spell on newer clients, GetSpellInfo on older ones.
---@param id number?
---@return string? name
---@return string? rank the rank text ("Rank 2"), nil when the spell has none
---@return (number|string)? icon
function ns.SpellInfo(id)
    if not id then return nil end
    ---@type string?, (number|string)?, string?
    local name, icon, rank
    if C_Spell and C_Spell.GetSpellName then
        name = C_Spell.GetSpellName(id)
        icon = C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
    elseif GetSpellInfo then
        local n, _, ic = GetSpellInfo(id)
        name, icon = n, ic
    end
    if C_Spell and C_Spell.GetSpellSubtext then
        rank = C_Spell.GetSpellSubtext(id)
    elseif GetSpellSubtext then
        -- The language server's own stub for this global returns any; it gives a rank text or "".
        rank = GetSpellSubtext(id) --[[@as string?]]
    end
    return name, rank ~= "" and rank or nil, icon
end

---The active pet's CreatureFamily ID (1 wolf, 2 cat, ...), the same on every client language;
---nil without a pet.
---@return number?
function ns.PetFamilyID()
    if not UnitExists("pet") then return nil end
    local _, familyID = UnitCreatureFamily("pet")
    return tonumber(familyID)
end

---The active pet's free training points (total minus used), or nil without a pet or the API.
---C_PetInfo has them on Forever, the global on older clients.
---@return number?
function ns.PetFreeTrainingPoints()
    if not UnitExists("pet") then return nil end
    ---@type (fun(): number, number)?
    local get = (C_PetInfo and C_PetInfo.GetPetTrainingPoints) or GetPetTrainingPoints
    if not get then return nil end
    local ok, total, used = pcall(get)
    if not ok or type(total) ~= "number" then return nil end
    return math.max(0, total - (tonumber(used) or 0))
end

---The spells in the active pet's spellbook, keyed by name, to fill in the rank and icon of an
---ability learned from it. C_SpellBook names the pet's book with an Enum number, the old
---globals with the string BOOKTYPE_PET.
---@return table<string, PetSpell>
function ns.PetSpells()
    ---@type table<string, PetSpell>
    local spells = {}
    ---@type (fun(): GameValue)?
    local hasPetSpells = (C_SpellBook and C_SpellBook.HasPetSpells) or HasPetSpells
    if not hasPetSpells then return spells end
    -- The first value is the count; the client also returns the pet's type ("PET", "DEMON").
    ---@type boolean, GameValue
    local ok, count = pcall(hasPetSpells)
    local num = ok and tonumber(count) or 0
    for i = 1, num do
        ---@type string?, string?, number?
        local name, rank, id
        if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
            local okInfo, info = pcall(C_SpellBook.GetSpellBookItemInfo, i, Enum.SpellBookSpellBank.Pet)
            if okInfo and type(info) == "table" then
                name, rank, id = info.name, info.subName, info.spellID
            end
        elseif GetSpellBookItemName then
            local okName, n, r, sid = pcall(GetSpellBookItemName, i, BOOKTYPE_PET or "pet")
            if okName then
                name, rank, id = n, r, sid
            end
        end
        if type(name) == "string" and name ~= "" then
            local _, idRank, icon = ns.SpellInfo(id)
            spells[name] = { id = id, rank = (rank ~= "" and rank) or idRank, icon = icon }
        end
    end
    return spells
end

---A dragged position as saved: { point, relativePoint, x, y }, or nil when anything is off.
---@param saved GameValue
---@return [string, string, number, number]?
local function cleanPos(saved)
    if type(saved) ~= "table" then return nil end
    ---@type GameValue, GameValue, GameValue, GameValue
    local point, relativePoint, x, y = saved[1], saved[2], saved[3], saved[4]
    if type(point) ~= "string" or type(relativePoint) ~= "string" then return nil end
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return { point, relativePoint, x, y }
end

---Creates or repairs the saved settings and makes them ns.db. Called on ADDON_LOADED, when the
---client has filled in the saved table.
function ns.LoadSettings()
    if type(PetAbilityLearnedDB) ~= "table" then PetAbilityLearnedDB = {} end
    ---@type PetAbilityLearnedSettings
    local db = PetAbilityLearnedDB
    -- A broken value is dropped, so the default shows through.
    for key, default in pairs(ns.DEFAULTS) do
        if db[key] ~= nil and type(db[key]) ~= type(default) then db[key] = nil end
    end
    -- A string that is no sound mode is dropped as well; rawset, since the field may hold only a
    -- mode once loaded, and nil here just lets the default show through.
    if db.sound ~= nil and not ns.SOUND_MODES[db.sound] then rawset(db, "sound", nil) end
    setmetatable(db, { __index = ns.DEFAULTS })
    -- Numbers are put back in range: whole seconds from 1, a scale from 0.3 to 3.
    db.duration = math.max(1, math.floor(db.duration))
    db.scale = math.min(3, math.max(0.3, db.scale))
    db.pos = cleanPos(db.pos)
    ---@type PetAbilityLearnedSettings
    ns.db = db
end

---Removes the settings that equal their default, so the saved file keeps only what the player
---changed. Called on PLAYER_LOGOUT, just before the client writes the file; ns.db keeps working
---through its metatable.
function ns.StripDefaults()
    for key, default in pairs(ns.DEFAULTS) do
        if rawget(ns.db, key) == default then ns.db[key] = nil end
    end
end
