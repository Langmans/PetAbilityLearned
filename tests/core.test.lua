-- Settings and the lookups across client APIs.

test("a new install gets the defaults; saved values stay", function()
    NewClient():login()
    eq(Saved().duration, 6)
    eq(Saved().sound, true)
    eq(Saved().scale, 1)
    NewClient({ savedDB = { duration = 10, sound = false } }):login()
    eq(Saved().duration, 10)
    eq(Saved().sound, false)
end)

test("spell info through C_Spell and through the old globals", function()
    for _, old in ipairs({ false, true }) do
        local client = NewClient({ oldSpellAPI = old })
        local name, rank, icon = client.ns.SpellInfo(16828)
        eq(name, "Claw")
        eq(rank, "Rank 2")
        eq(icon, 132140)
        eq(client.ns.SpellInfo(nil), nil)
        local _, noRank = client.ns.SpellInfo(999999)
        eq(noRank, nil, "an empty rank reads as none")
    end
end)

test("spell info on a client with neither API returns nothing", function()
    local client = NewClient({ oldSpellAPI = true })
    GetSpellInfo, GetSpellSubtext = nil, nil
    eq(client.ns.SpellInfo(16828), nil)
end)

test("the pet spellbook through C_SpellBook and through the old globals", function()
    for _, old in ipairs({ false, true }) do
        local client = NewClient({ oldSpellBookAPI = old })
        local spells = client.ns.PetSpells()
        eq(spells.Claw.rank, "Rank 2")
        eq(spells.Claw.id, 16828)
        eq(spells.Claw.icon, 132140)
        eq(spells.Growl.rank, "Rank 1")
    end
end)

test("a pet spell without a rank text takes the rank from its spell ID", function()
    local client = NewClient()
    client.pet.spells[1].rank = ""
    eq(client.ns.PetSpells().Claw.rank, "Rank 2")
end)

test("no pet, no pet API, or a failing API gives an empty spellbook", function()
    local client = NewClient()
    client.pet = nil
    eq(next(client.ns.PetSpells()), nil)
    eq(next(NewClient({ noPetSpellAPI = true }).ns.PetSpells()), nil)

    client = NewClient()
    C_SpellBook.GetSpellBookItemInfo = function()
        error("boom")
    end
    eq(next(client.ns.PetSpells()), nil)
    C_SpellBook.HasPetSpells = function()
        error("boom")
    end
    eq(next(client.ns.PetSpells()), nil)

    client = NewClient({ oldSpellBookAPI = true })
    GetSpellBookItemName = function()
        error("boom")
    end
    eq(next(client.ns.PetSpells()), nil)
    GetSpellBookItemName = nil
    eq(next(client.ns.PetSpells()), nil, "count but no way to read entries")
end)
