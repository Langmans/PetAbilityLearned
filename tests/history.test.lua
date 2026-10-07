-- What this character learned: the history and the known ranks.

test("a learn is kept with rank, pet, family, zone and time", function()
    local client = NewClient():login()
    client:chat(client:learnLine("Claw (Rank 2)"))
    client:advance(0.3)
    local entry = SavedPC().history[1]
    eq(entry.name, "Claw")
    eq(entry.rank, "Rank 2")
    eq(entry.pet, "Nightstalker")
    eq(entry.familyID, 2)
    eq(entry.zone, "Darkshore")
    eq(entry.t, math.floor(client.time))
    eq(SavedPC().known.Claw, 2)
    eq(client.ns.KnownRank("Claw"), 2)
    eq(client.ns.KnownRank("Dash"), nil)
end)

test("a learn not from the pet out is kept without pet or family", function()
    local client = NewClient():login()
    client:chat(client:learnLine("Bite (Rank 1)"))
    client:advance(0.3)
    local entry = SavedPC().history[1]
    eq(entry.pet, nil)
    eq(entry.familyID, nil)
    eq(SavedPC().known.Bite, 1)
end)

test("/pal sim and /pal test are not kept", function()
    local client = NewClient():login():slash("sim"):slash("test")
    client:advance(0.3)
    eq(#SavedPC().history, 0)
    eq(next(SavedPC().known), nil)
end)

test("a lower rank never overwrites a higher known one", function()
    local client = NewClient({ savedDBPC = { known = { Claw = 4 } } }):login()
    client:chat(client:learnLine("Claw (Rank 2)"))
    client:advance(0.3)
    eq(SavedPC().known.Claw, 4)
    eq(#SavedPC().history, 1, "the learn itself is still kept")
end)

test("the rank number is read in any language; no rank counts as 1", function()
    local ns = NewClient().ns
    eq(ns.RankNumber("Rank 3"), 3)
    eq(ns.RankNumber("Rang 7"), 7)
    eq(ns.RankNumber("2 레벨"), 2)
    eq(ns.RankNumber("Уровень 5"), 5)
    eq(ns.RankNumber(nil), 1)
    eq(ns.RankNumber("Passive"), 1)
end)

test("the history keeps the last 200 learns", function()
    local history = {}
    for i = 1, 200 do
        history[i] = { name = "Bite", rank = "Rank 1", t = i }
    end
    local client = NewClient({ savedDBPC = { history = history } }):login()
    client:chat(client:learnLine("Claw (Rank 2)"))
    client:advance(0.3)
    eq(#SavedPC().history, 200)
    eq(SavedPC().history[1].t, 2, "the oldest dropped")
    eq(SavedPC().history[200].name, "Claw")
end)

test("broken saved data is repaired", function()
    NewClient({ savedDBPC = "junk" }):login()
    eq(#SavedPC().history, 0)
    NewClient({
        savedDBPC = {
            history = {
                "junk",
                { name = 5, t = 1 },
                { name = "Claw", t = "now" },
                { name = "Claw", t = 9, rank = 2, pet = false, familyID = "cat", zone = {} },
                { name = "Bite", t = 10, rank = "Rank 1", pet = "Fluffy", familyID = 1, zone = "Teldrassil" },
            },
            known = { Claw = 2, Bite = "one", [3] = 1 },
        },
    }):login()
    local history = SavedPC().history
    eq(#history, 2)
    eq(history[1].rank, nil)
    eq(history[1].pet, nil)
    eq(history[1].familyID, nil)
    eq(history[1].zone, nil)
    eq(history[2].pet, "Fluffy")
    eq(SavedPC().known.Claw, 2)
    eq(SavedPC().known.Bite, nil)
    NewClient({ savedDBPC = { history = "x", known = "y" } }):login()
    eq(#SavedPC().history, 0)
end)

test("/pal history lists the last learns, or says there are none", function()
    local client = NewClient():login():slash("history")
    ok(client:printedContains("has not learned a pet ability"))
    client:chat(client:learnLine("Claw (Rank 2)"))
    client:advance(0.3)
    client:advance(10)
    client:chat(client:learnLine("Bite (Rank 1)"))
    client:advance(0.3)
    client.printed = {}
    client:slash("history")
    ok(client:printedContains("(last 2 of 2)"))
    ok(client:printedContains("  Claw (Rank 2), from Nightstalker, Darkshore"))
    ok(client:printedContains("  Bite (Rank 1), Darkshore"))
    client.printed = {}
    client:slash("history 1")
    ok(client:printedContains("(last 1 of 2)"))
    ok(not client:printedContains("Claw (Rank 2)"), "only the newest")
end)

test("/pal history leaves out a missing rank or zone", function()
    local client = NewClient({ savedDBPC = { history = { { name = "Dash", t = 5 } } } }):login()
    client:slash("history")
    ok(client:printedContains("  Dash"))
    ok(not client:printedContains("Dash ("))
end)
