---@meta
-- Editor-only type stubs for WoW: Forever (1.60.x) API that the language server knows only
-- loosely or not at all. Not listed in the .toc, so the game never loads this file. What they
-- return was seen in the game (the DevProbes probes of 2026-10-07) or read from Blizzard's own
-- source, as noted per function.

---How many rows the open trainer window has. On Forever, Beast Training is this window too.
---@return number numServices
function GetNumTrainerServices() end

---A trainer row. On Forever: the name, the kind ("available", "unavailable", "used" or
---"header") and the icon; there is no rank text (seen with the BeastTraining probe).
---@param index number
---@return string? name
---@return string? kind
---@return number? icon
function GetTrainerServiceInfo(index) end

---What Settings.RegisterCanvasLayoutCategory returns (Blizzard_Settings_Shared).
---@class SettingsCategory
---@field GetID fun(self: SettingsCategory): string|number

---Registers a frame drawn entirely by the addon as a page of the settings window. The window
---calls frame.OnRefresh, when the frame has one, each time it shows the page
---(SettingsPanelMixin:DisplayLayout).
---@param frame Frame
---@param name string
---@return SettingsCategory
function Settings.RegisterCanvasLayoutCategory(frame, name) end

---@class GameTooltip
local GameTooltip = {}

---Shows a trainer row in the tooltip; GetSpell then names its spell.
---@param index number
function GameTooltip:SetTrainerService(index) end

---The spell the tooltip shows.
---@return string? name
---@return number? spellID
function GameTooltip:GetSpell() end
