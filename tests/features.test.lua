-- The queue, the screenshot option, training points, and the hints about what a pet can teach.

local function showSplash(client, name)
    client.ns.ShowSplash({ name = name })
end

test("a splash shown while another is up waits; right-click brings the next", function()
    local client = NewClient():login()
    showSplash(client, "Claw")
    showSplash(client, "Bite")
    showSplash(client, "Dash")
    eq(client:splashName(), "Claw")
    client.splash.scripts.OnMouseUp(client.splash, "RightButton")
    eq(client:splashName(), "Bite")
    client:animate(10)
    eq(client:splashName(), "Dash", "the next follows the fade too")
    client.ns.HideSplash()
    eq(client:splashName(), nil, "the queue is empty")
end)

test("the screenshot option is off by default", function()
    local client = NewClient():login()
    showSplash(client, "Claw")
    client:animate(2)
    eq(client.screenshots, 0)
    eq(Saved().screenshot, false)
end)

test("with screenshots on, one is taken per splash once it has faded in", function()
    local client = NewClient({ savedDB = { screenshot = true } }):login()
    showSplash(client, "Claw")
    client:animate(0.4)
    eq(client.screenshots, 0, "not during the fade-in")
    client:animate(0.4)
    eq(client.screenshots, 1)
    client:animate(3)
    eq(client.screenshots, 1, "only one")
    client.ns.HideSplash()
    showSplash(client, "Bite")
    client:animate(1)
    eq(client.screenshots, 2, "one for the next splash")
end)

test("/pal screenshot on|off", function()
    local client = NewClient():login():slash("screenshot on")
    eq(Saved().screenshot, true)
    ok(client:printedContains("A screenshot is taken of each splash."))
    client:slash("screenshot off")
    eq(Saved().screenshot, false)
    ok(client:printedContains("No screenshots."))
    client.printed = {}
    client:slash("screenshot maybe")
    ok(client:printedContains("Commands:"))
end)

test("the splash names the teaching pet's free training points", function()
    local client = NewClient():login()
    client:chat(client:learnLine("Claw (Rank 2)"))
    client:advance(0.3)
    eq(client.splash.Points.text, "Nightstalker has 15 training points free.")
end)

test("no points line without the teaching pet, or without the API", function()
    local client = NewClient():login()
    client:chat(client:learnLine("Bite (Rank 1)"))
    client:advance(0.3)
    eq(client.splash.Points.text, "", "Nightstalker did not teach Bite")

    client = NewClient({ noTrainingPointsAPI = true }):login()
    client:chat(client:learnLine("Claw (Rank 2)"))
    client:advance(0.3)
    eq(client.splash.Points.text, "")
end)

test("training points through the old global; a failing call or no pet gives none", function()
    local client = NewClient({ oldTrainingPointsAPI = true }):login()
    eq(client.ns.PetFreeTrainingPoints(), 15)
    client.pet.points = { 3, 9 }
    eq(client.ns.PetFreeTrainingPoints(), 0, "never below 0")
    GetPetTrainingPoints = function()
        error("boom")
    end
    eq(client.ns.PetFreeTrainingPoints(), nil)
    client.pet = nil
    eq(client.ns.PetFreeTrainingPoints(), nil)
end)

test("at login, a pet out says what it can teach that is not known", function()
    local client = NewClient():login()
    ok(client:printedContains("Nightstalker can teach you: Claw (Rank 2)."))
    ok(client:printedContains("Open Beast Training once"), "nothing is known yet")
end)

test("summoning a pet says what it can teach, once per new list", function()
    local client = NewClient({ savedDBPC = { known = { Claw = 1 }, trainingRead = true } }):login()
    ok(client:printedContains("Nightstalker can teach you: Claw (Rank 2)."))
    ok(not client:printedContains("Open Beast Training once"), "the window was read before")
    client.printed = {}
    client:fire("UNIT_PET", "player")
    client:advance(1)
    eq(#client.printed, 0, "the same pet with the same list stays quiet")

    client.pet = { name = "Snarl", familyID = 1, spells = { { id = 17253, name = "Bite", rank = "Rank 1" } } }
    client:fire("UNIT_PET", "target")
    client:advance(1)
    eq(#client.printed, 0, "another unit's pet")
    client:fire("UNIT_PET", "player")
    client:advance(1)
    ok(client:printedContains("Snarl can teach you: Bite (Rank 1)."))
end)

test("nothing is said for known ranks, trainer abilities, no pet, or with hints off", function()
    local client = NewClient({ savedDBPC = { known = { Claw = 2 } } }):login()
    eq(#client.printed, 0, "Claw 2 is known; Growl is a trainer ability")

    client = NewClient({ savedDB = { hints = false } }):login()
    eq(#client.printed, 0)

    client = NewClient():login(false)
    client.pet = nil
    client:advance(5)
    eq(#client.printed, 0)
end)

test("UNIT_PET before the login wait is over is ignored", function()
    local client = NewClient():login(false)
    client:fire("UNIT_PET", "player")
    client:advance(1)
    eq(#client.printed, 0)
end)

test("a pet spell without a rank counts as rank 1", function()
    local client = NewClient({ savedDBPC = { trainingRead = true } }):login(false)
    client.pet.spells = { { name = "Bite" } } -- no rank text and no spell ID to read one from
    client:advance(5)
    ok(client:printedContains("Nightstalker can teach you: Bite."))
end)

test("/pal hints on|off", function()
    local client = NewClient():login():slash("hints off")
    eq(Saved().hints, false)
    ok(client:printedContains("No hints about new pets."))
    client:slash("hints on")
    eq(Saved().hints, true)
    ok(client:printedContains("Summoning or taming a pet says what it can still teach you."))
    client.printed = {}
    client:slash("hints")
    ok(client:printedContains("Commands:"))
end)

test("opening Beast Training reads the hunter's ranks from the rows' spells", function()
    local client = NewClient():login()
    client.trainer = {
        { "Pet abilities", "header", 16827 },
        { "Claw", "available", 16828 },
        { "Growl", "available", 2649 },
        { "Bite", "available", nil },
    }
    client:fire("TRAINER_SHOW")
    eq(SavedPC().known.Claw, 2, "rank from the spell, not the row")
    eq(SavedPC().known.Growl, 1, "trainer abilities are known ranks too")
    eq(SavedPC().known.Bite, nil, "no spell behind the row, so no rank")
    eq(SavedPC().known["Pet abilities"], nil, "headers are skipped")
    eq(SavedPC().trainingRead, true)
    client.trainer[#client.trainer + 1] = { "Bite", "available", 17253 }
    client:fire("TRAINER_UPDATE")
    eq(SavedPC().known.Bite, 1)
end)

test("a pet trainer's window (with an NPC) is not read", function()
    local client = NewClient():login()
    client.npc = true
    client.trainer = { { "Claw", "available", 16828 } }
    client:fire("TRAINER_SHOW")
    eq(SavedPC().known.Claw, nil)
    eq(SavedPC().trainingRead, nil)
end)

test("an empty window, a failing call or a client without the trainer API reads nothing", function()
    local client = NewClient():login()
    client:fire("TRAINER_SHOW")
    eq(SavedPC().trainingRead, nil, "no rows")
    GetNumTrainerServices = function()
        error("boom")
    end
    client:fire("TRAINER_UPDATE")
    eq(SavedPC().trainingRead, nil)
    client.trainer = { { "Claw", "available", 16828 } }
    GetNumTrainerServices = function()
        return 1
    end
    GetTrainerServiceInfo = function()
        error("boom")
    end
    client:fire("TRAINER_UPDATE")
    eq(SavedPC().known.Claw, nil)

    client = NewClient({ noTrainerAPI = true }):login()
    client:fire("TRAINER_SHOW")
    eq(SavedPC().trainingRead, nil)
end)

test("a tooltip that cannot show the row gives no rank", function()
    local client = NewClient():login()
    client.trainer = { { "Claw", "available", 16828 } }
    for _, frame in ipairs(client.frames) do
        if frame.kind == "GameTooltip" then
            frame.SetTrainerService = function()
                error("boom")
            end
        end
    end
    client:fire("TRAINER_SHOW")
    eq(SavedPC().known.Claw, nil)
end)

test("a saved trainingRead that is not true is dropped", function()
    NewClient({ savedDBPC = { trainingRead = "yes" } }):login()
    eq(SavedPC().trainingRead, nil)
end)

test("closing Beast Training with TRADE_SKILL_CLOSE ends the trainer guard", function()
    local client = NewClient():login()
    client:fire("TRAINER_SHOW")
    client:fire("TRADE_SKILL_CLOSE")
    client:chat(client:learnLine("Claw (Rank 2)"))
    client:advance(0.3)
    eq(client:splashName(), "Claw")
end)

test("a trainer window that is no longer shown ends the guard, even without a close event", function()
    local client = NewClient():login()
    ClassTrainerFrame = CreateFrame("Frame")
    client:fire("TRAINER_SHOW")
    client:chat(client:learnLine("Claw (Rank 2)"))
    client:advance(0.3)
    eq(client:splashName(), nil, "still open")
    ClassTrainerFrame:Hide()
    client:chat(client:learnLine("Claw (Rank 2)"))
    client:advance(0.3)
    eq(client:splashName(), "Claw")
end)
