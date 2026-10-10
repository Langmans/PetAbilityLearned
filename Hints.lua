local _, ns = ...

-- What a pet can still teach. When a pet is summoned or tamed, its spellbook is compared with
-- what this character knows (History.lua), and the abilities learned in the wild that it has at
-- a higher rank are named in chat: "Fluffy can teach you: Claw (Rank 3)."
--
-- What the character knows comes from every learn the addon saw, and from the Beast Training
-- window, read whenever it opens. Until that window has been read once, an ability missing from
-- what is known may simply not have been seen yet, so the hint then adds that opening Beast
-- Training once makes it complete.
--
-- On Forever, Beast Training is the trainer window (ClassTrainerFrame), opened by TRAINER_SHOW
-- with no NPC; a pet trainer is the same window with an NPC, selling ranks the hunter does not
-- have yet. Every row of Beast Training is a rank the hunter has learned, but only those the pet
-- out can be taught: its family's abilities. GetTrainerServiceInfo gives the name, not the rank,
-- so the row's spell ID comes from a hidden tooltip and the rank from that spell.

-- The last list said for each pet, so summoning the same pet again stays quiet until there is
-- something new to say.
---@type table<string, string>
local lastSaid = {}

local scanTip = CreateFrame("GameTooltip", "PetAbilityLearnedScanTooltip", nil, "GameTooltipTemplate")

---The spell behind a trainer row, through the hidden tooltip.
---@param index number
---@return number?
local function ServiceSpellID(index)
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    local ok = pcall(scanTip.SetTrainerService, scanTip, index)
    local _, spellID = scanTip:GetSpell()
    scanTip:Hide()
    return ok and spellID or nil
end

---Reads the hunter's learned ranks from the Beast Training window. A trainer window with an NPC
---is a pet trainer's (ranks for sale, not known), and is left alone.
function ns.ReadBeastTraining()
    if UnitExists("npc") or not GetNumTrainerServices then return end
    ---@type boolean, GameValue
    local okCount, rows = pcall(GetNumTrainerServices)
    local count = okCount and tonumber(rows) or 0
    local read = 0
    for i = 1, count do
        local ok, name, kind = pcall(GetTrainerServiceInfo, i)
        local spellID = ok and type(name) == "string" and kind ~= "header" and ServiceSpellID(i) or nil
        if spellID then
            local _, rank = ns.SpellInfo(spellID)
            ns.MarkKnown(name --[[@as string]], ns.RankNumber(rank))
            read = read + 1
        end
    end
    if read > 0 then
        local char = ns.char
        char.trainingRead = true
        ns.Debug(("Beast Training read: %d of %d rows"):format(read, count))
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
    if unsure and not ns.char.trainingRead then ns.Print(ns.L.HINT_OPEN_TRAINING) end
end
