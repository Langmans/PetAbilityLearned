local ADDON_NAME, ns = ...

-- The about panel in the game's settings (Esc > Options > AddOns, or /pal config): version, author
-- and license from the .toc, the website in a box to copy it from (a link in the game cannot open
-- a browser) when the .toc names one, what the addon does, the debug trace checkbox, and buttons for
-- /pal test and /pal sim.
-- Registered through the Settings API, which every targeted flavor has.

local L = ns.L

local panel = CreateFrame("Frame")
ns.OptionsPanel = panel

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
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

local about = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
about:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
about:SetText(
    ns.Format("OPTION_ABOUT", Metadata("Version") or "?", Metadata("Author") or "?", Metadata("X-License") or "?")
)
local below = about

local URL = Metadata("X-Website")
if URL then
    local websiteLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    websiteLabel:SetPoint("TOPLEFT", about, "BOTTOMLEFT", 0, -12)
    websiteLabel:SetText(L.OPTION_WEBSITE)
    local website = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
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

local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
description:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -20)
description:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
description:SetJustifyH("LEFT")
description:SetText(L.OPTION_DESCRIPTION)

-- Debug trace: the same setting as /pal debug. The box is synced from the setting whenever the
-- panel is shown, so a /pal debug in the meantime shows up.
local debugBox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
debugBox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", -2, -16)
-- The label's parentKey is Text on newer clients, text on older ones (which the language server's
-- stubs do not know, hence rawget).
local debugLabel = debugBox.Text or rawget(debugBox, "text") --[[@as FontString]]
debugLabel:SetFontObject("GameFontHighlight")
debugLabel:SetText(L.OPTION_DEBUG)
local debugNote = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
debugNote:SetPoint("TOPLEFT", debugLabel, "BOTTOMLEFT", 0, -2)
debugNote:SetText(L.OPTION_DEBUG_NOTE)
debugBox:SetScript("OnClick", function()
    -- GetChecked returns 1/nil on some clients; the saved value must be a boolean.
    local db = ns.db
    db.debug = debugBox:GetChecked() and true or false
end)
panel:SetScript("OnShow", function()
    debugBox:SetChecked(ns.db.debug)
end)
ns.DebugBox = debugBox

---A button under `anchor`, `x` pixels to the right of its left edge.
---@param label string
---@param anchor Region
---@param x number
---@param onClick fun()
---@return UIPanelButtonTemplate
local function AddButton(label, anchor, x, onClick)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, -16)
    button:SetSize(160, 24)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

---@type UIPanelButtonTemplate
ns.TestButton = AddButton(L.OPTION_TEST, debugNote, 2, function()
    SlashCmdList.PETABILITYLEARNED("test")
end)
---@type UIPanelButtonTemplate
ns.SimButton = AddButton(L.OPTION_SIM, debugNote, 174, function()
    SlashCmdList.PETABILITYLEARNED("sim")
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
