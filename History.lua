local _, ns = ...

-- What this character has learned: every pet ability the addon saw it learn (/pal history), and
-- from that and other sources the highest rank known per ability (used to tell what a pet can
-- still teach). Saved per character in PetAbilityLearnedDBPC, the SavedVariablesPerCharacter from
-- the .toc.

local MAX_HISTORY = 200

---One learn as kept in the history.
---@class HistoryEntry
---@field name string the ability's name, in the client's language at the time
---@field rank string? the rank text ("Rank 2")
---@field pet string? the name of the pet that taught it, when it was out
---@field familyID number? that pet's CreatureFamily ID
---@field zone string? where it happened
---@field t number server time

---@class CharacterData
---@field history HistoryEntry[] oldest first, at most MAX_HISTORY
---@field known table<string, number> ability name -> highest rank number known
---@field trainingRead boolean? whether the Beast Training window has been read: then `known` is
---complete, and an ability missing from it is one this character does not have

---The character's data: empty until LoadCharacterData runs on ADDON_LOADED.
---@type CharacterData
ns.char = { history = {}, known = {} }

---The number in a rank text, whatever the language calls it: "Rank 2", "Rang 2", "2 레벨" -> 2.
---A spell without ranks counts as rank 1.
---@param rank string?
---@return number
function ns.RankNumber(rank)
    local digits = type(rank) == "string" and rank:match("%d+")
    return tonumber(digits) or 1
end

---An entry as saved, or nil when it is broken.
---@param saved GameValue
---@return HistoryEntry?
local function cleanEntry(saved)
    if type(saved) ~= "table" then return nil end
    ---@type table<string, GameValue>
    local fields = saved
    local name, t = fields["name"], fields["t"]
    if type(name) ~= "string" or type(t) ~= "number" then return nil end
    local rank, pet, familyID, zone = fields["rank"], fields["pet"], fields["familyID"], fields["zone"]
    return {
        name = name,
        t = t,
        rank = type(rank) == "string" and rank or nil,
        pet = type(pet) == "string" and pet or nil,
        familyID = type(familyID) == "number" and familyID or nil,
        zone = type(zone) == "string" and zone or nil,
    }
end

---Creates or repairs the character's saved data and makes it ns.char.
function ns.LoadCharacterData()
    if type(PetAbilityLearnedDBPC) ~= "table" then PetAbilityLearnedDBPC = {} end
    ---@type table<string, GameValue>
    local saved = PetAbilityLearnedDBPC
    ---@type HistoryEntry[]
    local history = {}
    for _, entry in ipairs(type(saved.history) == "table" and saved.history or {}) do
        local clean = cleanEntry(entry)
        if clean then history[#history + 1] = clean end
    end
    ---@type table<string, number>
    local known = {}
    for name, rank in pairs(type(saved.known) == "table" and saved.known or {}) do
        if type(name) == "string" and type(rank) == "number" then known[name] = rank end
    end
    saved.history, saved.known = history, known
    saved.trainingRead = saved.trainingRead == true or nil
    ---@type CharacterData
    ns.char = saved
end

---The highest rank of an ability this character is known to have, or nil when nothing says so.
---@param name string
---@return number?
function ns.KnownRank(name)
    return ns.char.known[name]
end

---Records that this character knows an ability at a rank; a lower rank never overwrites a
---higher one.
---@param name string
---@param rank number
function ns.MarkKnown(name, rank)
    local known = ns.char.known
    if rank > (known[name] or 0) then known[name] = rank end
end

---One history line: "2026-10-07 14:03  Claw (Rank 2), from Fluffy, Darkshore".
---@param entry HistoryEntry
---@return string
function ns.FormatHistoryEntry(entry)
    ---@type string
    local line = date("%Y-%m-%d %H:%M", entry.t) .. "  " .. entry.name
    if entry.rank then line = line .. " (" .. entry.rank .. ")" end
    if entry.pet then line = line .. ", " .. ns.Format("HISTORY_FROM", entry.pet) end
    if entry.zone then line = line .. ", " .. entry.zone end
    return line
end

---Adds a learn to the history and to what is known.
---@param entry HistoryEntry
function ns.RecordLearn(entry)
    local history = ns.char.history
    history[#history + 1] = entry
    while #history > MAX_HISTORY do
        table.remove(history, 1)
    end
    ns.MarkKnown(entry.name, ns.RankNumber(entry.rank))
end
