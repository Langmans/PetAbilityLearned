-- A simulated WoW client: just the API this addon touches, with every value a
-- test may want to vary exposed on the client object. NewClient() resets all
-- globals and loads the addon files in .toc order into a fresh namespace, so
-- tests never share state.

-- The spells the simulated client knows, per locale: id -> { name, rank, icon }.
local SPELLS = {
    enUS = {
        [16827] = { "Claw", "Rank 1", 132140 },
        [16828] = { "Claw", "Rank 2", 132140 },
        [17253] = { "Bite", "Rank 1", 132278 },
        [2649] = { "Growl", "Rank 1", 132270 },
        [24423] = { "Demoralizing Screech", "Rank 1", 132182 },
        [1265843] = { "Web", "Rank 1", 136113 },
        [5308] = { "Execute", "Rank 1", 135358 },
    },
    deDE = {
        [16827] = { "Klaue", "Rang 1", 132140 },
        [16828] = { "Klaue", "Rang 2", 132140 },
        [17253] = { "Biss", "Rang 1", 132278 },
        [2649] = { "Knurren", "Rang 1", 132270 },
    },
}

local LEARN_STRINGS = {
    enUS = { ability = "You have learned a new ability: %s.", spell = "You have learned a new spell: %s." },
    deDE = {
        ability = "Ihr habt eine neue Fähigkeit erlernt: %s.",
        spell = "Ihr habt einen neuen Zauber erlernt: %s.",
    },
}

---The chat link the client builds for a spell.
function SpellLink(id, name)
    return ("|cff71d5ff|Hspell:%d:0|h[%s]|h|r"):format(id, name)
end

---@param opts {locale: string?, class: string?, savedDB: table?, oldSpellAPI: boolean?, oldSpellBookAPI: boolean?, noPetSpellAPI: boolean?, noLearnStrings: boolean?, noMasks: boolean?, noTextureAPI: boolean?}?
function NewClient(opts)
    opts = opts or {}
    -- opts.locale: the client's language. Spell names and the learn line exist here for enUS and
    -- deDE; any other locale reads the English ones.
    local locale = opts.locale or "enUS"
    local spells = SPELLS[locale] or SPELLS.enUS
    function GetLocale()
        return locale
    end
    local client = {
        time = 100,
        timers = {},
        frames = {},
        printed = {},
        sounds = {},
        events = {},
        -- The active pet: its name and spellbook. nil means no pet out.
        pet = {
            name = "Nightstalker",
            spells = {
                { id = 16828, name = spells[16828][1], rank = spells[16828][2] },
                { id = 2649, name = spells[2649][1], rank = spells[2649][2] },
            },
        },
        mouseOver = false,
        -- With a list, RegisterEvent raises for any other event, like an older client.
        knownEvents = opts.knownEvents,
    }

    function GetTime()
        return client.time
    end
    function GetServerTime()
        return client.time
    end
    function UnitClass()
        local classFile = opts.class or "HUNTER"
        return classFile, classFile
    end
    function UnitExists(unit)
        return unit == "player" or (unit == "pet" and client.pet ~= nil)
    end
    function UnitName(unit)
        if unit == "player" then return "Langmans" end
        return client.pet and client.pet.name
    end
    function wipe(tbl)
        for key in pairs(tbl) do
            tbl[key] = nil
        end
        return tbl
    end
    function PlaySound(id, channel)
        client.sounds[#client.sounds + 1] = { id = id, channel = channel }
    end
    function print(text)
        client.printed[#client.printed + 1] = text
    end
    issecretvalue = function(value)
        return value == client.secret
    end

    local strings = LEARN_STRINGS[locale] or LEARN_STRINGS.enUS
    if opts.noLearnStrings then
        ERR_LEARN_ABILITY_S, ERR_LEARN_SPELL_S = nil, nil
    else
        ERR_LEARN_ABILITY_S, ERR_LEARN_SPELL_S = strings.ability, strings.spell
    end

    -- Spell lookups: C_Spell on newer clients, the old globals with opts.oldSpellAPI. A name passed
    -- instead of an ID works for textures, as in the client.
    local function spell(idOrName)
        if spells[idOrName] then return spells[idOrName] end
        for _, s in pairs(spells) do
            if s[1] == idOrName then return s end
        end
    end
    local function getName(id)
        local s = spell(id)
        return s and s[1]
    end
    local function getRank(id)
        local s = spell(id)
        return s and s[2] or ""
    end
    local function getTexture(idOrName)
        local s = spell(idOrName)
        return s and s[3]
    end
    if opts.oldSpellAPI then
        C_Spell = nil
        function GetSpellInfo(id)
            local s = spell(id)
            if s then return s[1], nil, s[3] end
        end
        GetSpellSubtext = getRank
        GetSpellTexture = not opts.noTextureAPI and getTexture or nil
    else
        C_Spell = {
            GetSpellName = getName,
            GetSpellTexture = getTexture,
            GetSpellSubtext = getRank,
        }
        GetSpellInfo, GetSpellSubtext, GetSpellTexture = nil, nil, nil
    end

    -- The pet spellbook: C_SpellBook on newer clients, the old globals with opts.oldSpellBookAPI,
    -- nothing at all with opts.noPetSpellAPI.
    local function petCount()
        return client.pet and #client.pet.spells or 0, client.pet and "PET" or nil
    end
    local function petEntry(index)
        return client.pet and client.pet.spells[index]
    end
    Enum = { SpellBookSpellBank = { Player = 0, Pet = 1 } }
    BOOKTYPE_PET = "pet"
    if opts.noPetSpellAPI then
        C_SpellBook, HasPetSpells, GetSpellBookItemName = nil, nil, nil
    elseif opts.oldSpellBookAPI then
        C_SpellBook = nil
        HasPetSpells = petCount
        function GetSpellBookItemName(index, bank)
            assert(bank == BOOKTYPE_PET, "the old API names the pet's book with BOOKTYPE_PET")
            local entry = petEntry(index)
            if entry then return entry.name, entry.rank, entry.id end
        end
    else
        HasPetSpells, GetSpellBookItemName = nil, nil
        C_SpellBook = {
            HasPetSpells = petCount,
            GetSpellBookItemInfo = function(index, bank)
                assert(bank == Enum.SpellBookSpellBank.Pet, "pet spellbook bank expected")
                local entry = petEntry(index)
                if entry then return { name = entry.name, subName = entry.rank, spellID = entry.id } end
            end,
        }
    end

    C_Timer = {
        After = function(seconds, callback)
            client.timers[#client.timers + 1] = { at = client.time + seconds, callback = callback }
        end,
    }

    -- Layout calls only matter to the real UI; they do nothing here. A region keeps what tests
    -- read back: text, texture, alpha, scale, shown state, points and font.
    local function noop() end
    local Region = {}
    -- Methods the addon tests for before calling them stay absent unless defined.
    -- So do parentKeys, which are fields rather than methods.
    local OPTIONAL = { CreateMaskTexture = true, Text = true, text = true }
    Region.__index = function(_, key)
        if OPTIONAL[key] then return Region[key] end
        return Region[key] or noop
    end
    function Region:SetText(text)
        self.text = text
    end
    function Region:GetText()
        return self.text
    end
    function Region:SetTexture(texture)
        self.texture = texture
    end
    function Region:SetAlpha(alpha)
        self.alpha = alpha
    end
    function Region:SetScale(scale)
        self.scale = scale
    end
    function Region:SetSize(width, height)
        self.width, self.height = width, height
    end
    function Region:Show()
        self.shown = true
    end
    function Region:Hide()
        self.shown = false
    end
    function Region:IsShown()
        return self.shown
    end
    function Region:ClearAllPoints()
        self.points = {}
    end
    function Region:SetPoint(point, relativeTo, relativePoint, x, y)
        self.points[#self.points + 1] = { point, relativeTo, relativePoint, x, y }
    end
    function Region:GetPoint(index)
        local p = self.points[index]
        return p[1], p[2], p[3], p[4], p[5]
    end
    function Region:GetFont()
        return self.fontPath or "Fonts\\FRIZQT__.TTF", self.fontSize or 12, self.fontFlags
    end
    function Region:SetFont(path, size, flags)
        self.fontPath, self.fontSize, self.fontFlags = path, size, flags
    end

    local function newRegion(fields)
        fields = fields or { shown = true }
        fields.points = {}
        return setmetatable(fields, Region)
    end

    function Region:CreateTexture()
        return newRegion()
    end
    client.fontStrings = {}
    function Region:CreateFontString()
        local region = newRegion()
        client.fontStrings[#client.fontStrings + 1] = region
        return region
    end
    if not opts.noMasks then
        function Region:CreateMaskTexture()
            return newRegion()
        end
    end
    function Region:RegisterEvent(event)
        if not client.knownEvents or client.knownEvents[event] then
            self.events[event] = true
        else
            error("unknown event " .. event)
        end
    end
    function Region:UnregisterEvent(event)
        self.events[event] = nil
    end
    function Region:SetScript(script, handler)
        self.scripts[script] = handler
    end
    function Region:IsMouseOver()
        return client.mouseOver
    end
    function Region:StopMovingOrSizing()
        -- The real client leaves the frame anchored where it was dropped.
        self.points = { { "TOPLEFT", nil, "BOTTOMLEFT", 300, 700 } }
    end

    function CreateFrame(kind, name, parent)
        local frame = newRegion({ kind = kind, parent = parent, events = {}, scripts = {}, shown = true })
        client.frames[#client.frames + 1] = frame
        if name then _G[name] = frame end
        -- Like UICheckButtonTemplate: a checked state and its label as the Text parentKey, or as
        -- `text` on older clients (opts.oldCheckButton).
        if kind == "CheckButton" then
            local label = newRegion()
            if opts.oldCheckButton then
                frame.text = label
            else
                frame.Text = label
            end
            function frame:SetChecked(checked)
                self.checked = checked and true or false
            end
            -- Some clients answer 1/nil rather than true/false.
            function frame:GetChecked()
                return self.checked and 1 or nil
            end
        end
        return frame
    end
    UIParent = newRegion()
    WorldFrame = newRegion()

    -- The .toc's "## Key: value" lines (handed over by run.mjs), plus opts.metadata on top:
    -- through C_AddOns, or the global on older clients (opts.noAddOnsAPI).
    local function getMetadata(name, key)
        if name ~= "PetAbilityLearned" then return nil end
        if opts.metadata and opts.metadata[key] ~= nil then return opts.metadata[key] or nil end
        return TOC_METADATA[key]
    end
    if opts.noAddOnsAPI then
        C_AddOns, GetAddOnMetadata = nil, getMetadata
    else
        C_AddOns, GetAddOnMetadata = { GetAddOnMetadata = getMetadata }, nil
    end

    -- client.inCombat: whether the player is in combat.
    function InCombatLockdown()
        return client.inCombat == true
    end
    -- The settings window: client.categories holds what was registered, client.opened the IDs
    -- of the categories opened.
    client.categories, client.opened = {}, {}
    Settings = {
        RegisterCanvasLayoutCategory = function(frame, name)
            local category = { frame = frame, name = name }
            function category:GetID()
                return self.name
            end
            return category
        end,
        RegisterAddOnCategory = function(category)
            client.categories[#client.categories + 1] = category
        end,
        OpenToCategory = function(id)
            client.opened[#client.opened + 1] = id
        end,
    }

    SlashCmdList = {}
    PetAbilityLearnedDB = opts.savedDB

    local ns = {}
    for _, file in ipairs(TOC_FILES) do
        local chunk = assert(loadfile(ROOT .. "/" .. file))
        chunk("PetAbilityLearned", ns)
    end
    client.ns = ns
    client.splash = ns.splash

    ---Delivers an event to every frame registered for it.
    function client:fire(event, ...)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
        end
        return self
    end

    ---Moves the clock on and runs the C_Timer callbacks that came due.
    function client:advance(seconds)
        self.time = self.time + seconds
        local due = {}
        for i = #self.timers, 1, -1 do
            if self.timers[i].at <= self.time then table.insert(due, 1, table.remove(self.timers, i)) end
        end
        for _, timer in ipairs(due) do
            timer.callback()
        end
        return self
    end

    ---What the client does at login: ADDON_LOADED for each addon, then PLAYER_LOGIN. With
    ---settle, the addon's start-up wait is over too.
    function client:login(settle)
        self:fire("ADDON_LOADED", "SomeOtherAddon")
        self:fire("ADDON_LOADED", "PetAbilityLearned")
        self:fire("PLAYER_LOGIN")
        if settle ~= false then self:advance(5) end
        return self
    end

    ---A system chat line saying the hunter learned `text`.
    function client:learnLine(text, which)
        return strings[which or "ability"]:format(text)
    end

    function client:chat(text)
        return self:fire("CHAT_MSG_SYSTEM", text)
    end

    ---Runs the splash's OnUpdate for `seconds`, in frames of `step`. Like the client, a hidden
    ---frame gets no more updates.
    function client:animate(seconds, step)
        step = step or 0.05
        local elapsed = 0
        while elapsed < seconds - 1e-9 and self.splash.shown and self.splash.scripts.OnUpdate do
            self.splash.scripts.OnUpdate(self.splash, step)
            elapsed = elapsed + step
        end
        return self
    end

    function client:slash(message)
        SlashCmdList.PETABILITYLEARNED(message)
        return self
    end

    function client:printedContains(text)
        for _, line in ipairs(self.printed) do
            if line:find(text, 1, true) then return true end
        end
        return false
    end

    ---Whether the splash is up, and with which name.
    function client:splashName()
        if not self.splash.shown then return nil end
        return self.splash.Name.text
    end

    return client
end

function Saved()
    return PetAbilityLearnedDB
end
