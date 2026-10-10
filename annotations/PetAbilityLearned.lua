---@meta
-- Editor-only types for the addon's own tables: the saved settings, the saved per-character
-- data and the locale data in Locales\*.lua. Not listed in the .toc, so the game never loads
-- this file.

---What plays with the splash: the pet family's own sound (the level-up sound for a family
---without one), always the level-up sound, or nothing.
---@alias PetAbilityLearnedSoundMode "family"|"levelup"|"off"

---The account-wide settings, ns.db (PetAbilityLearnedDB). The fields fall back to Core.lua's
---DEFAULTS through a metatable, so they always read as a value; pos has no default.
---@class PetAbilityLearnedSettings
---@field duration number whole seconds the splash stays before it fades, from 1 (/pal duration)
---@field scale number from 0.3 to 3 (/pal scale)
---@field sound PetAbilityLearnedSoundMode (/pal sound)
---@field screenshot boolean take a screenshot of each splash (/pal screenshot)
---@field hints boolean say what a new pet can still teach (/pal hints)
---@field debug boolean trace the detection in chat (/pal debug)
---@field pos [string, string, number, number]? point, relativePoint, x, y of a dragged splash

---One learn as kept in the history.
---@class PetAbilityLearnedHistoryEntry
---@field name string the ability's name, in the client's language at the time
---@field rank string? the rank text ("Rank 2")
---@field pet string? the name of the pet that taught it, when it was out
---@field familyID number? that pet's CreatureFamily ID
---@field zone string? where it happened
---@field t number server time

---The per-character data, ns.char (PetAbilityLearnedDBPC).
---@class PetAbilityLearnedCharacter
---@field history PetAbilityLearnedHistoryEntry[] oldest first, at most 200
---@field known table<string, number> ability name -> highest rank number known
---@field trainingRead boolean? whether the Beast Training window has been read: then `known` is
---complete, and an ability missing from it is one this character does not have

---One entry of ns.Locales, from a file in Locales\.
---@class PetAbilityLearnedLocale
---@field strings table<string, string>
