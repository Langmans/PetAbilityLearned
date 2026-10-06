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
local GetMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
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
    website:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        self:SetText(URL)
        self:HighlightText()
    end)
    website:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    website:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)
    website:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    website:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
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
-- The label's parentKey is Text on newer clients, text on older ones.
local debugLabel = debugBox.Text or debugBox.text
debugLabel:SetFontObject("GameFontHighlight")
debugLabel:SetText(L.OPTION_DEBUG)
local debugNote = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
debugNote:SetPoint("TOPLEFT", debugLabel, "BOTTOMLEFT", 0, -2)
debugNote:SetText(L.OPTION_DEBUG_NOTE)
debugBox:SetScript("OnClick", function(self)
    -- GetChecked returns 1/nil on some clients; the saved value must be a boolean.
    ns.db.debug = self:GetChecked() and true or false
end)
panel:SetScript("OnShow", function()
    debugBox:SetChecked(ns.db.debug)
end)
ns.DebugBox = debugBox

local function AddButton(label, anchor, x, onClick)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, -16)
    button:SetSize(160, 24)
    button:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

ns.TestButton = AddButton(L.OPTION_TEST, debugNote, 2, function()
    SlashCmdList.PETABILITYLEARNED("test")
end)
ns.SimButton = AddButton(L.OPTION_SIM, debugNote, 174, function()
    SlashCmdList.PETABILITYLEARNED("sim")
end)

local category = Settings.RegisterCanvasLayoutCategory(panel, L.OPTIONS_TITLE)
Settings.RegisterAddOnCategory(category)

-- In combat the settings window is not opened from an addon: the call can be blocked or taint
-- the window. /pal config then waits for the end of combat and opens it once.
local afterCombat = CreateFrame("Frame")
afterCombat:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    Settings.OpenToCategory(category:GetID())
end)

function ns.OpenOptions()
    if InCombatLockdown() then
        afterCombat:RegisterEvent("PLAYER_REGEN_ENABLED")
        ns.Print(L.OPTIONS_AFTER_COMBAT)
        return
    end
    Settings.OpenToCategory(category:GetID())
end
