-- Settings and the lookups across client APIs.

test("a new install reads the defaults; saved values stay", function()
    NewClient():login()
    eq(Saved().duration, 6)
    eq(Saved().sound, "family")
    eq(Saved().scale, 1)
    eq(Saved().debug, false)
    eq(Saved().pos, nil)
    NewClient({ savedDB = { duration = 10, sound = "off" } }):login()
    eq(Saved().duration, 10)
    eq(Saved().sound, "off")
end)

test("a saved file that is not a table is replaced", function()
    NewClient({ savedDB = "junk" }):login()
    eq(Saved().duration, 6)
end)

test("broken values fall back to the default; numbers are put in range", function()
    NewClient({ savedDB = { duration = "long", scale = true, sound = "yes", debug = 1 } }):login()
    eq(Saved().duration, 6)
    eq(Saved().scale, 1)
    eq(Saved().sound, "family", "a string that is no sound mode")
    eq(Saved().debug, false)
    NewClient({ savedDB = { sound = true } }):login()
    eq(Saved().sound, "family", "the on/off boolean of earlier versions")
    NewClient({ savedDB = { duration = 2.6, scale = 9 } }):login()
    eq(Saved().duration, 2)
    eq(Saved().scale, 3)
    NewClient({ savedDB = { duration = -4, scale = 0 } }):login()
    eq(Saved().duration, 1)
    eq(Saved().scale, 0.3)
end)

test("a dragged position is kept only when it is whole", function()
    NewClient({ savedDB = { pos = { "TOPLEFT", "BOTTOMLEFT", 10, 20 } } }):login()
    eq(Saved().pos[1], "TOPLEFT")
    eq(Saved().pos[4], 20)
    for _, broken in ipairs({ "here", { "TOPLEFT" }, { "TOPLEFT", 3, 10, 20 }, { "TOPLEFT", "BOTTOMLEFT", 10 } }) do
        NewClient({ savedDB = { pos = broken } }):login()
        eq(Saved().pos, nil)
    end
end)

test("at logout only values that differ from the default stay in the file", function()
    local client = NewClient({ savedDB = { duration = 6, sound = "off" } }):login()
    client:slash("debug")
    client:slash("debug")
    client:fire("PLAYER_LOGOUT")
    eq(rawget(Saved(), "duration"), nil, "equal to the default")
    eq(rawget(Saved(), "debug"), nil, "switched back to the default")
    eq(rawget(Saved(), "sound"), "off", "changed by the player")
    eq(Saved().duration, 6, "still readable through the defaults")
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
