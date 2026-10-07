-- The settings and the history in the panel.

local function showPanel(client)
    client.ns.OptionsPanel.scripts.OnShow(client.ns.OptionsPanel)
    return client
end

test("the panel shows the current settings when it opens", function()
    local client = NewClient({ savedDB = { duration = 9, scale = 1.5, sound = "levelup", screenshot = true } })
    client:login()
    showPanel(client)
    eq(client.ns.DurationSlider.value, 9)
    eq(client.ns.DurationSlider.Text.text, "Splash stays for 9 seconds")
    eq(client.ns.ScaleSlider.value, 1.5)
    eq(client.ns.ScaleSlider.Text.text, "Splash size: 1.50")
    eq(client.ns.SoundButtons.levelup.checked, true)
    eq(client.ns.SoundButtons.family.checked, false)
    eq(client.ns.ScreenshotBox.checked, true)
    eq(client.ns.HintsBox.checked, true)
    eq(client.ns.DebugBox.checked, false)
end)

test("an unchanged value still gets its title", function()
    local client = showPanel(NewClient():login())
    client.ns.DurationSlider.Text.text = nil
    showPanel(client)
    eq(client.ns.DurationSlider.Text.text, "Splash stays for 6 seconds")
end)

test("moving a slider saves the value, snapped to its step", function()
    local client = showPanel(NewClient():login())
    client.ns.DurationSlider:SetValue(12.4)
    eq(Saved().duration, 12)
    client.ns.ScaleSlider:SetValue(1.2999)
    eq(Saved().scale, 1.3)
    eq(client.ns.ScaleSlider.Text.text, "Splash size: 1.30")
end)

test("a sound radio button saves its mode and unchecks the others", function()
    local client = showPanel(NewClient():login())
    local off = client.ns.SoundButtons.off
    off.scripts.OnClick(off)
    eq(Saved().sound, "off")
    eq(off.checked, true)
    eq(client.ns.SoundButtons.family.checked, false)
    eq(client.ns.SoundButtons.levelup.Text.text, "The level-up sound")
end)

test("the screenshot and hints checkboxes save their setting", function()
    local client = showPanel(NewClient():login())
    local box = client.ns.ScreenshotBox
    box:SetChecked(true)
    box.scripts.OnClick(box)
    eq(Saved().screenshot, true)
    box = client.ns.HintsBox
    box:SetChecked(false)
    box.scripts.OnClick(box)
    eq(Saved().hints, false)
end)

test("older sliders keep their labels under global names", function()
    local client = showPanel(NewClient({ oldSlider = true }):login())
    eq(_G.PetAbilityLearnedDurationSliderText.text, "Splash stays for 6 seconds")
    eq(_G.PetAbilityLearnedScaleSliderLow.text, "0.3")
    eq(rawget(client.ns.DurationSlider, "obeyStep"), nil, "no SetObeyStepOnDrag to call")
    eq(rawget(NewClient():login().ns.DurationSlider, "obeyStep"), true, "newer sliders obey the step")
end)

test("the history is listed newest first, and the list grows and shrinks", function()
    local history = {
        { name = "Bite", rank = "Rank 1", t = 1000, zone = "Teldrassil" },
        { name = "Claw", rank = "Rank 2", t = 2000, pet = "Fluffy" },
    }
    local client = showPanel(NewClient({ savedDBPC = { history = history } }):login())
    local rows = client.ns.HistoryRows
    eq(#rows, 2)
    ok(rows[1].text:find("Claw (Rank 2), from Fluffy", 1, true), "newest first")
    ok(rows[2].text:find("Bite (Rank 1), Teldrassil", 1, true))
    local note
    for _, fs in ipairs(client.fontStrings) do
        if fs.text == "2 learned, newest first. Same as /pal history." then note = fs end
    end
    ok(note, "the count above the list")

    client.ns.char.history = { history[1] }
    showPanel(client)
    eq(rows[1].shown, true)
    eq(rows[2].shown, false, "a row no longer needed is hidden")
    eq(#rows, 2, "rows are reused")
end)

test("an empty history says so", function()
    local client = showPanel(NewClient():login())
    local said = false
    for _, fs in ipairs(client.fontStrings) do
        if fs.text and fs.text:find("has not learned a pet ability", 1, true) then said = true end
    end
    ok(said)
    eq(#client.ns.HistoryRows, 0)
end)

test("the scroll child follows the scroll frame's width", function()
    local client = NewClient():login()
    for _, frame in ipairs(client.frames) do
        if frame.kind == "ScrollFrame" then frame.scripts.OnSizeChanged(frame, 512, 300) end
    end
    local resized = false
    for _, frame in ipairs(client.frames) do
        if frame.kind == "Frame" and frame.width == 512 then resized = true end
    end
    ok(resized)
end)
