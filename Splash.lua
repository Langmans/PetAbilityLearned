local _, ns = ...

-- The splash follows GnomeLevelUp's look: a black panel whose edges fade out, a round icon in a
-- gold ring, and text with a soft glow made of offset copies behind it.

local FRAME_WIDTH, FRAME_HEIGHT = 440, 254
local ICON_SIZE = 64
local RING_SIZE = ICON_SIZE + 6
local PORTRAIT_SIZE = 34
local PORTRAIT_RING_SIZE = PORTRAIT_SIZE + 4
local BG_OPACITY = 0.75
local BG_LAYERS = 28
local BG_FADE_FRACTION = 0.12 -- fade band per side, as a fraction of that side
local GLOW_ALPHA = 0.15
local GOLD = { 1, 0.82, 0.2 }
local HUNTER_GREEN = { 0.67, 0.83, 0.45 }
local FALLBACK_ICON = "Interface\\Icons\\Ability_Hunter_BeastTraining"
local CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local LEVEL_UP_SOUND = 888

-- The aggro sound of each pet family, by CreatureFamily ID (the second return of
-- UnitCreatureFamily, the same on every client language), as a FileDataID for PlaySoundFile.
-- FileDataIDs from the wago.tools community listfile; the file names are given so they can be
-- looked up again. No aggro sound was found for Crocolisk (6), Scorpid (20) and Bat (24): those
-- get the level-up sound.
---@type table<number, number>
local FAMILY_SOUNDS = {
    [1] = 564215, -- Wolf: sound/creature/wolf/mwolfaggro1.ogg
    [2] = 562387, -- Cat: sound/creature/tiger/mtigeraggroa.ogg
    [3] = 561415, -- Spider: sound/creature/tarantula/mtarantulaaggroa.ogg
    [4] = 544959, -- Bear: sound/creature/bear/mbearaggroa.ogg
    [5] = 545134, -- Boar: sound/creature/boar/mwildboaraggro1.ogg
    [7] = 545937, -- Carrion Bird: sound/creature/carrion/mcarrionaggroa.ogg
    [8] = 546423, -- Crab: sound/creature/crab/crabaggro.ogg
    [9] = 550967, -- Gorilla: sound/creature/gorilla/gorillaaggroa.ogg
    [11] = 558877, -- Raptor: sound/creature/raptor/mraptoraggroa.ogg
    [12] = 561390, -- Tallstrider: sound/creature/tallstrider/tallstrideraggroa.ogg
    [21] = 559878, -- Turtle: sound/creature/seaturtle/seaturtleaggroa.ogg
    [25] = 552339, -- Hyena: sound/creature/hyena/hyenaaggroa.ogg
    [26] = 557977, -- Bird of Prey: sound/creature/owl/owlaggro.ogg
    [27] = 559967, -- Wind Serpent: sound/creature/serpent/serpentaggro.ogg
}

-- Intro timings, in seconds.
local BG_FADE = 0.25
local CONTENT_DELAY, CONTENT_FADE = 0.10, 0.30
local ICON_POP = 0.45
local FADE_OUT = 0.6

local frame = CreateFrame("Frame", "PetAbilityLearnedSplash", UIParent)
frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
frame:SetFrameStrata("HIGH")
frame:SetClampedToScreen(true)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:Hide()
ns.splash = frame

---Puts the splash where it was dragged to, or in its standard spot above the centre.
local function PositionFrame()
    frame:ClearAllPoints()
    local pos = ns.db.pos
    if pos and pos[1] then
        frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 160)
    end
end

frame:SetScript("OnDragStart", function(
    self --[[@as Frame]]
)
    self:StartMoving()
end)
frame:SetScript("OnDragStop", function(
    self --[[@as Frame]]
)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    local db = ns.db
    if point then db.pos = { point, relativePoint, x, y } end
end)

-- Background: stacked black layers, each inset a little further, so the panel is solid in the
-- middle and fades to nothing at the edges. Each layer's alpha is chosen so the stacked result
-- follows a smoothstep curve from edge to centre.
local bg = CreateFrame("Frame", nil, frame)
bg:SetAllPoints(frame)

---@param t number from 0 to 1
---@return number
local function SmoothStep(t)
    return t * t * (3 - 2 * t)
end

---Creates the background layers once.
local function BuildBackground()
    local fadeX, fadeY = FRAME_WIDTH * BG_FADE_FRACTION, FRAME_HEIGHT * BG_FADE_FRACTION
    local previous = 0
    for k = 1, BG_LAYERS do
        local layer = bg:CreateTexture(nil, "BACKGROUND")
        local insetX, insetY = fadeX * (k - 1) / BG_LAYERS, fadeY * (k - 1) / BG_LAYERS
        layer:SetPoint("TOPLEFT", bg, "TOPLEFT", insetX, -insetY)
        layer:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -insetX, insetY)
        local target = BG_OPACITY * SmoothStep(k / BG_LAYERS)
        local alpha = math.max(0, 1 - (1 - target) / (1 - previous))
        layer:SetColorTexture(0, 0, 0, alpha)
        previous = target
    end
end
BuildBackground()

local content = CreateFrame("Frame", nil, frame)
content:SetAllPoints(frame)

local GLOW_DIRS = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 }, { -1, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 } }

---A font string with eight faint copies around it; every setter goes to all nine.
---@class GlowText
---@field main FontString the readable text; the copies are anchored to it
---@field layers FontString[] the text and its copies
local GlowTextMethods = {}

---Calls a FontString method with the same arguments on the text and all its copies.
---@param method string
---@param ... GameValue the method's arguments
function GlowTextMethods:Set(method, ...)
    for _, fs in ipairs(self.layers) do
        fs[method](fs, ...)
    end
end

---@param template string font object for the text
---@param radius number how far the copies sit from the text, in pixels
---@param size number? font size, when the template's is not the one wanted
---@return GlowText
local function GlowText(template, radius, size)
    local main = content:CreateFontString(nil, "OVERLAY", template)
    ---@type FontString[]
    local layers = { main }
    for _, dir in ipairs(GLOW_DIRS) do
        local glow = content:CreateFontString(nil, "ARTWORK", template)
        glow:SetPoint("TOPLEFT", main, "TOPLEFT", dir[1] * radius, dir[2] * radius)
        glow:SetPoint("TOPRIGHT", main, "TOPRIGHT", dir[1] * radius, dir[2] * radius)
        glow:SetAlpha(GLOW_ALPHA)
        layers[#layers + 1] = glow
    end
    ---@type GlowText
    local text = setmetatable({ main = main, layers = layers }, { __index = GlowTextMethods })
    if size then
        local path, _, flags = main:GetFont()
        text:Set("SetFont", path, size, flags or "")
    end
    text:Set("SetWidth", FRAME_WIDTH - 60)
    text:Set("SetJustifyH", "CENTER")
    return text
end

local ring = content:CreateTexture(nil, "ARTWORK", nil, 1)
ring:SetSize(RING_SIZE, RING_SIZE)
ring:SetPoint("TOP", content, "TOP", 0, -18)
ring:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)

local icon = content:CreateTexture(nil, "ARTWORK", nil, 2)
icon:SetSize(ICON_SIZE, ICON_SIZE)
icon:SetPoint("CENTER", ring, "CENTER")
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- The pet's portrait as a badge on the lower right of the ring, in a ring of its own. It hangs
-- off the ring, so it follows the ring's pop.
local portraitRing = content:CreateTexture(nil, "ARTWORK", nil, 3)
portraitRing:SetSize(PORTRAIT_RING_SIZE, PORTRAIT_RING_SIZE)
portraitRing:SetPoint("CENTER", ring, "BOTTOMRIGHT", -6, 6)
portraitRing:SetColorTexture(HUNTER_GREEN[1], HUNTER_GREEN[2], HUNTER_GREEN[3], 1)

local portrait = content:CreateTexture(nil, "ARTWORK", nil, 4)
portrait:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
portrait:SetPoint("CENTER", portraitRing, "CENTER")

if content.CreateMaskTexture then
    for _, tex in ipairs({ ring, icon, portraitRing, portrait }) do
        local mask = content:CreateMaskTexture()
        mask:SetAllPoints(tex)
        mask:SetTexture(CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        tex:AddMaskTexture(mask)
    end
end

local title = GlowText("GameFontNormalLarge", 2)
title.main:SetPoint("TOP", ring, "BOTTOM", 0, -10)
title:Set("SetTextColor", HUNTER_GREEN[1], HUNTER_GREEN[2], HUNTER_GREEN[3])
title:Set("SetText", ns.L.SPLASH_TITLE)

local spellName = GlowText("GameFontNormalHuge", 3, 30)
spellName.main:SetPoint("TOP", title.main, "BOTTOM", 0, -8)
spellName:Set("SetTextColor", GOLD[1], GOLD[2], GOLD[3])

local rankText = GlowText("GameFontHighlightLarge", 2)
rankText.main:SetPoint("TOP", spellName.main, "BOTTOM", 0, -4)

local subText = GlowText("GameFontHighlightSmall", 1.5)
subText.main:SetPoint("TOP", rankText.main, "BOTTOM", 0, -12)
subText:Set("SetTextColor", 0.8, 0.8, 0.8)

local pointsText = GlowText("GameFontHighlightSmall", 1.5)
pointsText.main:SetPoint("TOP", subText.main, "BOTTOM", 0, -4)
pointsText:Set("SetTextColor", HUNTER_GREEN[1], HUNTER_GREEN[2], HUNTER_GREEN[3])

-- The visible parts as fields, the way a template's parentKeys would be.
frame.Icon, frame.Name, frame.Rank, frame.Source = icon, spellName.main, rankText.main, subText.main
frame.Points = pointsText.main
frame.Portrait = portrait

-- Intro and outro run on one OnUpdate clock so a new splash can restart them cleanly.

---@param p number from 0 to 1
---@return number
local function EaseOut(p)
    return 1 - (1 - p) * (1 - p)
end

---Overshoots a little before settling at 1: the icon's pop.
---@param p number from 0 to 1
---@return number
local function EaseOutBack(p)
    local c = 1.70158
    return 1 + (c + 1) * (p - 1) ^ 3 + c * (p - 1) ^ 2
end

---How far an animation that starts at `delay` and lasts `duration` is at time `t`, from 0 to 1.
---@param t number
---@param delay number
---@param duration number
---@return number
local function Progress(t, delay, duration)
    return math.max(0, math.min(1, (t - delay) / duration))
end

---Seconds since the splash was shown, when it starts to fade, and when the fade began.
---@type number, number, number?
local clock, fadeAt, fadeStart = 0, 0, nil
-- With the screenshot setting on, one screenshot per splash once it has faded in.
local SCREENSHOT_AT = CONTENT_DELAY + CONTENT_FADE + 0.2
local screenshotTaken = false

-- Splashes waiting while another is up; each shows when the one before it is gone.
---@type SplashInfo[]
local queue = {}
---@type fun(info: SplashInfo)
local Display

---Shows the next queued splash, if any; called whenever one is gone.
local function ShowNext()
    local info = table.remove(queue, 1)
    if info then Display(info) end
end

---@param _ Frame the splash
---@param elapsed number seconds since the previous frame
local function Animate(_, elapsed)
    clock = clock + elapsed
    if not screenshotTaken and clock >= SCREENSHOT_AT then
        screenshotTaken = true
        if ns.db.screenshot then Screenshot() end
    end
    bg:SetAlpha(EaseOut(Progress(clock, 0, BG_FADE)))
    content:SetAlpha(EaseOut(Progress(clock, CONTENT_DELAY, CONTENT_FADE)))
    local pop = EaseOutBack(Progress(clock, CONTENT_DELAY, ICON_POP))
    local size = math.max(1, RING_SIZE * (0.3 + 0.7 * pop))
    ring:SetSize(size, size)
    icon:SetSize(size - 6, size - 6)

    if not fadeStart and clock >= fadeAt then
        -- Hovering holds the splash so it can be read; it fades once the mouse leaves.
        if frame:IsMouseOver() then
            fadeAt = clock + 0.2
        else
            fadeStart = clock
        end
    end
    if fadeStart then
        local p = Progress(clock, fadeStart, FADE_OUT)
        frame:SetAlpha(1 - p)
        if p >= 1 then
            frame:Hide()
            ShowNext()
        end
    end
end

---Closes the splash at once, without the fade; the next queued one, if any, follows.
function ns.HideSplash()
    frame:SetScript("OnUpdate", nil)
    frame:Hide()
    ShowNext()
end

frame:SetScript("OnMouseUp", function(
    _,
    button --[[@as string]]
)
    if button == "RightButton" then ns.HideSplash() end
end)

---What the splash shows.
---@class SplashInfo
---@field name string?
---@field rank string?
---@field icon (number|string)? texture; the Beast Training icon when nil
---@field source string? the line under the rank, such as where it came from
---@field petPortrait boolean? show the active pet's portrait as a badge on the icon
---@field familyID number? the CreatureFamily ID of the pet that taught it, for its sound
---@field points string? a line under the source, the teaching pet's free training points

---The sound for a splash, as the sound setting asks.
---@param familyID number?
local function PlaySplashSound(familyID)
    local mode = ns.db.sound
    if mode == "off" then return end
    local familySound = mode == "family" and familyID and FAMILY_SOUNDS[familyID]
    if familySound then
        PlaySoundFile(familySound, "Master")
    else
        PlaySound(LEVEL_UP_SOUND, "Master")
    end
end

---Fills the splash with `info` and starts it.
---@param info SplashInfo
function Display(info)
    local db = ns.db
    icon:SetTexture(info.icon or FALLBACK_ICON)
    spellName:Set("SetText", info.name or "?")
    rankText:Set("SetText", info.rank or "")
    subText:Set("SetText", info.source or ns.L.SPLASH_TEACH)
    pointsText:Set("SetText", info.points or "")

    -- The portrait is drawn from the pet as it is right now, the pet the ability came from.
    local withPortrait = info.petPortrait and UnitExists("pet") and SetPortraitTexture ~= nil
    if withPortrait then SetPortraitTexture(portrait, "pet") end
    portrait:SetShown(withPortrait)
    portraitRing:SetShown(withPortrait)

    frame:SetScale(db.scale)
    PositionFrame()
    frame:SetAlpha(1)
    bg:SetAlpha(0)
    content:SetAlpha(0)
    clock, fadeStart, screenshotTaken = 0, nil, false
    fadeAt = db.duration
    frame:SetScript("OnUpdate", Animate)
    frame:Show()

    PlaySplashSound(info.familyID)
end

---Shows a splash now, or after the one that is up.
---@param info SplashInfo
function ns.ShowSplash(info)
    if frame:IsShown() then
        queue[#queue + 1] = info
    else
        Display(info)
    end
end
