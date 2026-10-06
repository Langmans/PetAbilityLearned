local ADDON_NAME, ns = ...

-- Shared helpers and the saved settings. Loaded after Locale.lua (ns.Print needs ns.L) and before
-- every module that uses them.
--
-- Globals this file writes: PetAbilityLearnedDB, the SavedVariables from the .toc. The language
-- server only knows it when it reads the .toc, so each write carries a create-global exception.

-- Saved account-wide. The saved file keeps only what the player changed: ns.db reads a missing
-- value from here through a metatable, and StripDefaults removes values equal to their default
-- at logout. A default changed in a later version so reaches everyone who never changed it.
-- pos has no default: without it the splash sits in its standard spot.
---@type {duration: number, scale: number, sound: boolean, debug: boolean}
ns.DEFAULTS = {
    duration = 6, -- /pal duration <seconds>
    scale = 1, -- /pal scale <0.3-3>
    sound = true, -- /pal sound on|off
    debug = false, -- /pal debug
}

---@param message string
function ns.Print(message)
    print("|cffabd473" .. ns.L.CHAT_PREFIX .. "|r " .. message)
end

---/pal debug traces the detection in chat: every learn it sees and what it decided.
function ns.Debug(message)
    if ns.db and ns.db.debug then ns.Print("|cff88ccff[debug]|r " .. message) end
end

-- Spell info across client generations: C_Spell on newer clients, GetSpellInfo on older ones.
function ns.SpellInfo(id)
    if not id then return nil end
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
        rank = GetSpellSubtext(id)
    end
    if rank == "" then rank = nil end
    return name, rank, icon
end

-- The spells in the active pet's spellbook, keyed by name, to fill in the rank and icon of an
-- ability learned from it. C_SpellBook names the pet's book with an Enum number, the old
-- globals with the string BOOKTYPE_PET.
function ns.PetSpells()
    local spells = {}
    local hasPetSpells = (C_SpellBook and C_SpellBook.HasPetSpells) or HasPetSpells
    if not hasPetSpells then return spells end
    local ok, num = pcall(hasPetSpells)
    num = ok and tonumber(num) or 0
    for i = 1, num do
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
---@param saved any
---@return table?
local function cleanPos(saved)
    if type(saved) ~= "table" then return nil end
    local point, relativePoint, x, y = saved[1], saved[2], saved[3], saved[4]
    if type(point) ~= "string" or type(relativePoint) ~= "string" then return nil end
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return { point, relativePoint, x, y }
end

---Creates or repairs the saved settings and makes them ns.db. Called on ADDON_LOADED, when the
---client has filled in the saved table.
function ns.LoadSettings()
    ---@diagnostic disable-next-line: create-global
    if type(PetAbilityLearnedDB) ~= "table" then PetAbilityLearnedDB = {} end
    local db = PetAbilityLearnedDB
    -- A broken value is dropped, so the default shows through.
    for key, default in pairs(ns.DEFAULTS) do
        if db[key] ~= nil and type(db[key]) ~= type(default) then db[key] = nil end
    end
    setmetatable(db, { __index = ns.DEFAULTS })
    -- Numbers are put back in range: whole seconds from 1, a scale from 0.3 to 3.
    db.duration = math.max(1, math.floor(db.duration))
    db.scale = math.min(3, math.max(0.3, db.scale))
    db.pos = cleanPos(db.pos)
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

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event, name)
    if event == "PLAYER_LOGOUT" then return ns.StripDefaults() end
    if name ~= ADDON_NAME then return end
    ns.LoadSettings()
    self:UnregisterEvent("ADDON_LOADED")
end)
