local ADDON_NAME, ns = ...

ns.defaults = {
    duration = 6, -- seconds the splash stays up before it fades
    sound = true,
    scale = 1.0,
    debug = false, -- /pal debug
    pos = nil, -- { point, relativePoint, x, y } once the splash has been dragged
}

function ns.Print(msg)
    print("|cffabd473PetAbilityLearned|r: " .. tostring(msg))
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

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON_NAME then return end
    PetAbilityLearnedDB = PetAbilityLearnedDB or {}
    for key, value in pairs(ns.defaults) do
        if PetAbilityLearnedDB[key] == nil then PetAbilityLearnedDB[key] = value end
    end
    ns.db = PetAbilityLearnedDB
    self:UnregisterEvent("ADDON_LOADED")
end)
