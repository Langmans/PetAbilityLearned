local ADDON_NAME, ns = ...

-- The panel in the game's settings (Esc > Options > AddOns, or /pal config). From top to bottom:
--   - the version, author and license from the .toc, and the website in a box to copy it from (a
--     link in the game cannot open a browser) when the .toc names one, and what the addon does;
--   - the settings: sliders for /pal duration and /pal scale, the three /pal sound choices,
--     checkboxes for /pal screenshot, /pal hints and /pal debug, and buttons for /pal test and
--     /pal sim;
--   - the history: every pet ability this character learned, newest first (/pal history).
-- Everything is filled from ns.db and ns.char every time the panel is shown, so a change made
-- with /pal in the meantime shows up; a click writes straight to ns.db. The whole panel scrolls,
-- since the history grows. Registered through the Settings API, which every targeted flavor has.

local L = ns.L

local panel = CreateFrame("Frame")
ns.OptionsPanel = panel

-- Everything is laid out on `content`, the scroll child. Its height is set when the panel is
-- shown: the fixed part (CONTENT_BASE) plus one ROW_HEIGHT per history line. Its width follows
-- the scroll frame, whose size the settings window decides; CONTENT_WIDTH only holds until then.
-- UIPanelScrollFrameTemplate puts its scroll bar just outside the frame's right edge, hence the
-- room on the right.
local CONTENT_WIDTH, CONTENT_BASE, ROW_HEIGHT = 600, 700, 16
local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 0, -4)
scroll:SetPoint("BOTTOMRIGHT", -28, 4)
local content = CreateFrame("Frame", nil, scroll)
content:SetSize(CONTENT_WIDTH, CONTENT_BASE)
scroll:SetScrollChild(content)
---@param _ ScrollFrame
---@param width number
local function onScrollSized(_, width)
    content:SetWidth(width)
end
scroll:SetScript("OnSizeChanged", onScrollSized)

---Stretches a text anchored at its top left to 16 pixels from the content's right edge, so it
---wraps there.
---@param fontString FontString
local function toRightEdge(fontString)
    fontString:SetPoint("RIGHT", content, "RIGHT", -16, 0)
    fontString:SetJustifyH("LEFT")
end

local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -12)
title:SetText(L.OPTIONS_TITLE)

-- C_AddOns has GetAddOnMetadata on newer clients, the global on older ones.
---@type fun(addon: string, key: string): string?
local GetMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
---A "## Key: value" line of this addon's .toc.
---@param key string
---@return string?
local function Metadata(key)
    return GetMetadata(ADDON_NAME, key)
end

local about = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
about:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
about:SetText(
    ns.Format("OPTION_ABOUT", Metadata("Version") or "?", Metadata("Author") or "?", Metadata("X-License") or "?")
)
---@type Region
local below = about

local URL = Metadata("X-Website")
if URL then
    local websiteLabel = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    websiteLabel:SetPoint("TOPLEFT", about, "BOTTOMLEFT", 0, -12)
    websiteLabel:SetText(L.OPTION_WEBSITE)
    local website = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    -- InputBoxTemplate draws its border outside the box; the extra x keeps it clear.
    website:SetPoint("LEFT", websiteLabel, "RIGHT", 12, 0)
    website:SetSize(340, 20)
    website:SetAutoFocus(false)
    website:SetFontObject("GameFontHighlightSmall")
    website:SetText(URL)
    website:SetCursorPosition(0)
    -- Read-only: whatever is typed is put back, and a click selects it all for Ctrl+C.
    ---@param _ EditBox the website box
    ---@param userInput boolean true when the player typed, false when code set the text
    local function onTextChanged(_, userInput)
        if not userInput then return end
        website:SetText(URL)
        website:HighlightText()
    end
    website:SetScript("OnTextChanged", onTextChanged)
    website:SetScript("OnEditFocusGained", function()
        website:HighlightText()
    end)
    website:SetScript("OnEditFocusLost", function()
        website:HighlightText(0, 0)
    end)
    website:SetScript("OnEscapePressed", function()
        website:ClearFocus()
    end)
    website:SetScript("OnEnterPressed", function()
        website:ClearFocus()
    end)
    ns.WebsiteBox = website
    below = websiteLabel
end

local description = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
description:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -20)
toRightEdge(description)
description:SetText(L.OPTION_DESCRIPTION)
below = description

---A heading in the panel's own gold, `gap` pixels under what came before.
---@param text string
---@param gap number
local function AddHeading(text, gap)
    local heading = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -gap)
    heading:SetText(text)
    below = heading
end

-- Settings.

AddHeading(L.OPTION_SETTINGS, 28)

-- Functions that put a setting's current value into its control, run when the panel is shown.
---@type fun()[]
local syncs = {}

-- OptionsSliderTemplate's labels have parentKeys on newer clients and only global names
-- ($parentText, ...) on older ones, hence a global name per slider.
---A slider for a number setting, with its value in its title.
---@param name string the slider's global name
---@param key "duration"|"scale"
---@param low number
---@param high number
---@param step number
---@param format fun(value: number): string the title for a value
---@return Slider
local function AddSlider(name, key, low, high, step, format)
    local slider = CreateFrame("Slider", name, content, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 6, -32)
    slider:SetWidth(300)
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    ---@type FontString
    local text = slider.Text or _G[name .. "Text"]
    ---@type FontString
    local lowText = slider.Low or _G[name .. "Low"]
    ---@type FontString
    local highText = slider.High or _G[name .. "High"]
    lowText:SetText(tostring(low))
    highText:SetText(tostring(high))
    ---@param _ Slider
    ---@param value number
    local function onValueChanged(_, value)
        -- Snapped to the step and to two decimals, so a drag cannot leave 1.2999 behind.
        local snapped = math.floor(math.floor(value / step + 0.5) * step * 100 + 0.5) / 100
        local db = ns.db
        db[key] = snapped
        text:SetText(format(snapped))
    end
    slider:SetScript("OnValueChanged", onValueChanged)
    syncs[#syncs + 1] = function()
        slider:SetValue(ns.db[key])
        -- SetValue only reports a change; the title must show an unchanged value too.
        text:SetText(format(ns.db[key]))
    end
    below = slider
    return slider
end

---@type Slider
ns.DurationSlider = AddSlider("PetAbilityLearnedDurationSlider", "duration", 1, 30, 1, function(value)
    return ns.Format("OPTION_DURATION", value)
end)
---@type Slider
ns.ScaleSlider = AddSlider("PetAbilityLearnedScaleSlider", "scale", 0.3, 3, 0.05, function(value)
    return ns.Format("OPTION_SCALE", value)
end)

---A check button's label: the parentKey Text on newer clients, text on older ones (the language
---server's stubs know neither, hence rawget).
---@param button CheckButton
---@return FontString
local function LabelOf(button)
    return (rawget(button, "Text") or rawget(button, "text")) --[[@as FontString]]
end

-- The sound: three radio buttons under a label, one per mode.
local soundLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
soundLabel:SetPoint("TOPLEFT", below, "BOTTOMLEFT", -6, -28)
soundLabel:SetText(L.OPTION_SOUND)
below = soundLabel
---@type table<SoundMode, CheckButton>
local soundButtons = {}
for _, choice in ipairs({
    { "family", L.OPTION_SOUND_FAMILY },
    { "levelup", L.OPTION_SOUND_LEVELUP },
    { "off", L.OPTION_SOUND_OFF },
}) do
    ---@type SoundMode
    local mode = choice[1]
    local radio = CreateFrame("CheckButton", nil, content, "UIRadioButtonTemplate")
    radio:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -6)
    local label = LabelOf(radio)
    label:SetFontObject("GameFontHighlightSmall")
    label:SetText(choice[2])
    radio:SetScript("OnClick", function()
        local db = ns.db
        db.sound = mode
        for other, button in pairs(soundButtons) do
            button:SetChecked(other == mode)
        end
    end)
    soundButtons[mode] = radio
    below = radio
end
ns.SoundButtons = soundButtons
syncs[#syncs + 1] = function()
    for mode, button in pairs(soundButtons) do
        button:SetChecked(ns.db.sound == mode)
    end
end

---A checkbox for one boolean setting, with a line of explanation under it.
---@param key "screenshot"|"hints"|"debug"
---@param label string
---@param note string
---@return CheckButton
local function AddCheckbox(key, label, note)
    local box = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    box:SetPoint("TOPLEFT", below, "BOTTOMLEFT", -2, -12)
    local text = LabelOf(box)
    text:SetFontObject("GameFontHighlight")
    text:SetText(label)
    local noteText = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    noteText:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -2)
    toRightEdge(noteText)
    noteText:SetText(note)
    box:SetScript("OnClick", function()
        -- GetChecked returns 1/nil on some clients; the saved value must be a boolean.
        local db = ns.db
        db[key] = box:GetChecked() and true or false
    end)
    syncs[#syncs + 1] = function()
        box:SetChecked(ns.db[key])
    end
    below = noteText
    return box
end

---@type CheckButton
ns.ScreenshotBox = AddCheckbox("screenshot", L.OPTION_SCREENSHOT, L.OPTION_SCREENSHOT_NOTE)
---@type CheckButton
ns.HintsBox = AddCheckbox("hints", L.OPTION_HINTS, L.OPTION_HINTS_NOTE)
---@type CheckButton
ns.DebugBox = AddCheckbox("debug", L.OPTION_DEBUG, L.OPTION_DEBUG_NOTE)

---A button under `anchor`, `x` pixels to the right of its left edge.
---@param label string
---@param anchor Region
---@param x number
---@param onClick fun()
---@return UIPanelButtonTemplate
local function AddButton(label, anchor, x, onClick)
    local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, -16)
    button:SetSize(160, 24)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

local buttonsAnchor = below
---@type UIPanelButtonTemplate
ns.TestButton = AddButton(L.OPTION_TEST, buttonsAnchor, 2, function()
    SlashCmdList.PETABILITYLEARNED("test")
end)
---@type UIPanelButtonTemplate
ns.SimButton = AddButton(L.OPTION_SIM, buttonsAnchor, 174, function()
    SlashCmdList.PETABILITYLEARNED("sim")
end)
below = ns.TestButton

-- History.

AddHeading(L.OPTION_HISTORY, 32)
local historyNote = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
historyNote:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -4)
toRightEdge(historyNote)
below = historyNote

-- One font string per line, made as the history grows and reused after that.
---@type FontString[]
local historyRows = {}
ns.HistoryRows = historyRows

---Fills the history list, newest first, and sizes the scroll child to it.
local function RefreshHistory()
    local history = ns.char.history
    historyNote:SetText(#history > 0 and ns.Format("OPTION_HISTORY_NOTE", #history) or L.HISTORY_EMPTY)
    for i = 1, #history do
        local row = historyRows[i]
        if not row then
            row = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row:SetPoint("TOPLEFT", historyNote, "BOTTOMLEFT", 0, -6 - (i - 1) * ROW_HEIGHT)
            toRightEdge(row)
            historyRows[i] = row
        end
        row:SetText(ns.FormatHistoryEntry(history[#history - i + 1]))
        row:Show()
    end
    for i = #history + 1, #historyRows do
        historyRows[i]:Hide()
    end
    content:SetHeight(CONTENT_BASE + #history * ROW_HEIGHT)
end

panel:SetScript("OnShow", function()
    for i = 1, #syncs do
        syncs[i]()
    end
    RefreshHistory()
end)

---What Settings.RegisterCanvasLayoutCategory returns; the language server's stubs leave it untyped.
---@class SettingsCategory
---@field GetID fun(self: SettingsCategory): string|number

---@type SettingsCategory
local category = Settings.RegisterCanvasLayoutCategory(panel, L.OPTIONS_TITLE)
Settings.RegisterAddOnCategory(category)

-- In combat the settings window is not opened from an addon: the call can be blocked or taint
-- the window. /pal config then waits for the end of combat and opens it once.
local afterCombat = CreateFrame("Frame")
afterCombat:SetScript("OnEvent", function()
    afterCombat:UnregisterEvent("PLAYER_REGEN_ENABLED")
    Settings.OpenToCategory(category:GetID())
end)

---Opens the panel in the game's settings, or once combat ends.
function ns.OpenOptions()
    if InCombatLockdown() then
        afterCombat:RegisterEvent("PLAYER_REGEN_ENABLED")
        ns.Print(L.OPTIONS_AFTER_COMBAT)
        return
    end
    Settings.OpenToCategory(category:GetID())
end
