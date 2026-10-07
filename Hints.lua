local _, ns = ...

-- What a pet can still teach. When a pet is summoned or tamed, its spellbook is compared with
-- what this character knows (History.lua), and the abilities learned in the wild that it has at
-- a higher rank are named in chat: "Fluffy can teach you: Claw (Rank 3)."
--
-- What the character knows comes from every learn the addon saw, and from the Beast Training
-- window, read whenever it opens: each row there is an ability the hunter has learned. Until that
-- window has been read once, an ability missing from what is known may simply not have been seen
-- yet, so the hint then adds that opening Beast Training once makes it complete.

-- The last list said for each pet, so summoning the same pet again stays quiet until there is
-- something new to say.
---@type table<string, string>
local lastSaid = {}

---Reads the hunter's learned ranks from the Beast Training window (the Craft API), when the
---client has it and the window is showing Beast Training.
function ns.ReadBeastTraining()
    if not (GetNumCrafts and GetCraftInfo) then return end
    ---@type boolean, GameValue
    local okCount, rows = pcall(GetNumCrafts)
    local count = okCount and tonumber(rows) or 0
    local read = false
    for i = 1, count do
        local ok, name, rank, kind = pcall(GetCraftInfo, i)
        if ok and type(name) == "string" and name ~= "" and kind ~= "header" then
            ns.MarkKnown(name, ns.RankNumber(type(rank) == "string" and rank or nil))
            read = true
        end
    end
    if read then
        local char = ns.char
        char.craftRead = true
        ns.Debug(("Beast Training read: %d rows"):format(count))
    end
end

---The abilities learned in the wild that the pet out has at a higher rank than this character
---knows, as "Claw (Rank 3)", sorted by name.
---@return string[] teachable
---@return boolean unsure whether one of them is an ability with no known rank at all
local function Teachable()
    ---@type string[]
    local list = {}
    local unsure = false
    for name, spell in pairs(ns.PetSpells()) do
        if ns.IsWildAbility(name) then
            local known = ns.KnownRank(name)
            if ns.RankNumber(spell.rank) > (known or 0) then
                list[#list + 1] = spell.rank and ("%s (%s)"):format(name, spell.rank) or name
                if not known then unsure = true end
            end
        end
    end
    table.sort(list)
    return list, unsure
end

---Says in chat what the pet out can still teach, unless hints are off or it said the same for
---this pet before.
function ns.CheckPetHints()
    if not ns.db.hints or not UnitExists("pet") then return end
    local pet = UnitName("pet") or "?"
    local list, unsure = Teachable()
    local said = table.concat(list, ", ")
    if said == "" or lastSaid[pet] == said then return end
    lastSaid[pet] = said
    ns.Print(ns.Format("HINT_TEACHES", pet, said))
    if unsure and not ns.char.craftRead then ns.Print(ns.L.HINT_OPEN_TRAINING) end
end
