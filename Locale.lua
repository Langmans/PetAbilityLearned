local _, ns = ...

-- Picks the client's locale from ns.Locales (filled by Locales\*.lua).
--
-- ns.L: strings. A locale lists only what it translates; every other key falls back to enUS
-- through a metatable. A key missing from enUS as well returns the key itself, so a typo shows up
-- in game instead of erroring on a nil concatenation.

---@type PetAbilityLearnedLocale
local enUS = ns.Locales.enUS
---@type PetAbilityLearnedLocale
local current = ns.Locales[GetLocale()] or enUS
ns.LocaleCode = ns.Locales[GetLocale()] and GetLocale() or "enUS"

setmetatable(enUS.strings, {
    ---@param _ table<string, string> the enUS strings
    ---@param key string
    ---@return string
    __index = function(_, key)
        return key
    end,
})
-- enUS must not get itself as __index: the lookup would chain forever.
if current ~= enUS then setmetatable(current.strings, { __index = enUS.strings }) end

---@type table<string, string>
ns.L = current.strings

---Formats a locale entry with string.format.
---@param key string
---@param ... string|number the values for its format directives
---@return string
function ns.Format(key, ...)
    return string.format(ns.L[key], ...)
end
