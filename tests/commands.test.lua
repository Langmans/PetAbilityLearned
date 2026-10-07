-- /pal

test("/pal without a known command prints the status line with the commands", function()
    local client = NewClient():login():slash("")
    ok(
        client:printedContains(
            "Splash for 6 s at scale 1.00, sound pet family, screenshot off, pet hints on, debug off."
                .. " Commands: /pal test [name]"
        )
    )
    client.printed = {}
    client:slash("bogus")
    ok(client:printedContains("/pal sound family|levelup|off"))
    eq(#client.printed, 1)
end)

test("the status line on another class says nothing is watched", function()
    local client = NewClient({ class = "WARRIOR" }):login():slash("")
    ok(client:printedContains("Only hunters learn pet abilities"))
end)

test("/pal test shows the splash only, for Claw or a named spell", function()
    local client = NewClient():login():slash("test")
    eq(client:splashName(), "Claw")
    eq(client.splash.Rank.text, "Rank 2", "the pet's rank")
    client.ns.HideSplash()
    client:slash("test Growl")
    eq(client:splashName(), "Growl", "test shows anything")
    eq(client.splash.Rank.text, "Rank 1")
    client.ns.HideSplash()
    client:slash("TEST Demoralizing Screech")
    eq(client:splashName(), "Demoralizing Screech", "the name keeps its case and spaces")
end)

test("/pal test without a pet uses the client's text for rank 2", function()
    local client = NewClient({ locale = "deDE" }):login()
    client.pet = nil
    client:slash("test")
    eq(client:splashName(), "Klaue")
    eq(client.splash.Rank.text, "Rang 2")
end)

test("/pal test on a client that knows no Claw still says something", function()
    local client = NewClient():login()
    client.pet = nil
    C_Spell.GetSpellName = function() end
    C_Spell.GetSpellSubtext = function()
        return ""
    end
    C_Spell.GetSpellTexture = function() end
    client:slash("test")
    eq(client:splashName(), "Claw")
    eq(client.splash.Rank.text, "Rank 2")
end)

test("/pal sim runs a learn line through the detection, even at a trainer", function()
    local client = NewClient():login(false)
    client:fire("TRAINER_SHOW")
    client:slash("sim")
    ok(client:printedContains("Simulating: You have learned a new ability: Claw (Rank 2)."))
    client:advance(0.3)
    eq(client:splashName(), "Claw")
    client.ns.HideSplash()
    client:slash("sim")
    client:advance(0.3)
    eq(#client.sounds, 2, "a repeat is not swallowed as a duplicate")
    client.ns.HideSplash()
    client:chat(client:learnLine("Bite (Rank 1)"))
    client:advance(0.3)
    eq(client:splashName(), nil, "the guards are back afterwards")
end)

test("without a name, test and sim use an ability the pet out has, so a boar gets its own sound", function()
    local client = NewClient():login()
    client.pet = {
        name = "Kaldor",
        familyID = 5,
        spells = {
            { id = 2649, name = "Growl", rank = "Rank 1" },
            { id = 17253, name = "Bite", rank = "Rank 1" },
        },
    }
    client:slash("sim")
    ok(client:printedContains("Simulating: You have learned a new ability: Bite (Rank 1)."))
    client:advance(0.3)
    eq(client:splashName(), "Bite")
    eq(client.sounds[1].file, 545134, "the boar's aggro sound")
    client.ns.HideSplash()
    client:slash("sim Claw")
    client:advance(0.3)
    eq(client.sounds[2].id, 888, "Claw cannot have come from a boar")
end)

test("a pet with only trainer abilities, or none, leaves the default at Claw", function()
    local client = NewClient():login()
    client.pet.spells = { { id = 2649, name = "Growl", rank = "Rank 1" } }
    client:slash("test")
    eq(client:splashName(), "Claw")
end)

test("/pal sim of a trainer ability says it is ignored", function()
    local client = NewClient():login():slash("sim Growl")
    ok(client:printedContains("Growl is not a pet ability learned in the wild"))
    client:advance(1)
    eq(client:splashName(), nil)
end)

test("/pal sim on a client without learn strings says so", function()
    local client = NewClient({ noLearnStrings = true }):login():slash("sim")
    ok(client:printedContains("no learn message"))
end)

test("/pal duration takes whole seconds from 1", function()
    local client = NewClient():login()
    client:slash("duration 9.7")
    eq(Saved().duration, 9)
    ok(client:printedContains("Splash duration: 9 seconds."))
    client:slash("duration 0")
    eq(Saved().duration, 1)
    client.printed = {}
    client:slash("duration soon")
    eq(Saved().duration, 1)
    ok(client:printedContains("Commands:"), "a bad number shows the status line")
end)

test("/pal scale stays between 0.3 and 3", function()
    local client = NewClient():login()
    client:slash("scale 5")
    eq(Saved().scale, 3)
    client:slash("scale 0.1")
    eq(Saved().scale, 0.3)
    client:slash("scale 1.25")
    ok(client:printedContains("Splash scale: 1.25."))
    client.printed = {}
    client:slash("scale big")
    eq(Saved().scale, 1.25)
    ok(client:printedContains("Commands:"))
end)

test("/pal sound family|levelup|off, with on and level-up as other words", function()
    local client = NewClient():login()
    client:slash("sound off")
    eq(Saved().sound, "off")
    ok(client:printedContains("Sound off."))
    client:slash("SOUND LevelUp")
    eq(Saved().sound, "levelup")
    ok(client:printedContains("Sound: the level-up sound."))
    client:slash("sound family")
    eq(Saved().sound, "family")
    ok(client:printedContains("Sound: the call of your pet's family"))
    client:slash("sound off")
    client:slash("sound on")
    eq(Saved().sound, "family", "on is the default, family")
    client:slash("sound level-up")
    eq(Saved().sound, "levelup")
    client.printed = {}
    client:slash("sound loud")
    eq(Saved().sound, "levelup")
    ok(client:printedContains("Commands:"))
    client:slash("")
    ok(client:printedContains("sound level-up,"), "the status line names the mode")
end)

test("/pal reset forgets the dragged position", function()
    local client = NewClient({ savedDB = { pos = { "TOPLEFT", "BOTTOMLEFT", 1, 2 } } }):login()
    client:slash("reset")
    eq(Saved().pos, nil)
    ok(client:printedContains("Splash position reset."))
end)

test("/pal options is /pal config", function()
    local client = NewClient():login():slash("options")
    eq(client.opened[1], "Pet Ability Learned")
end)
