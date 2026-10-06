-- The about panel in the game's settings.

---The text of the first font string that starts with `prefix`.
local function textStarting(client, prefix)
    for _, fontString in ipairs(client.fontStrings) do
        local text = fontString.text
        if type(text) == "string" and text:sub(1, #prefix) == prefix then return text end
    end
end

test("the panel is registered under the addon's name", function()
    local client = NewClient():login()
    eq(#client.categories, 1)
    eq(client.categories[1].name, "Pet Ability Learned")
    eq(client.categories[1].frame, client.ns.OptionsPanel)
end)

test("the about line comes from the .toc, through either metadata API", function()
    for _, old in ipairs({ false, true }) do
        local client = NewClient({ noAddOnsAPI = old })
        local expected = ("Version %s by %s, %s license."):format(
            TOC_METADATA.Version,
            TOC_METADATA.Author,
            TOC_METADATA["X-License"]
        )
        eq(textStarting(client, "Version "), expected)
    end
end)

test("missing metadata shows question marks and no website box", function()
    local client = NewClient({
        metadata = { Version = false, Author = false, ["X-License"] = false, ["X-Website"] = false },
    })
    eq(textStarting(client, "Version "), "Version ? by ?, ? license.")
    eq(client.ns.WebsiteBox, nil)
    eq(textStarting(client, "Website"), nil)
end)

test("a website in the .toc gets a read-only copy box", function()
    local url = "https://example.invalid/petabilitylearned"
    local client = NewClient({ metadata = { ["X-Website"] = url } })
    local box = client.ns.WebsiteBox
    eq(box.text, url)
    box:SetText("typed")
    box.scripts.OnTextChanged(box, false)
    eq(box.text, "typed", "a change by code is left alone")
    box.scripts.OnTextChanged(box, true)
    eq(box.text, url, "typing is undone")
    box.scripts.OnEditFocusGained(box)
    box.scripts.OnEditFocusLost(box)
    box.scripts.OnEscapePressed(box)
    box.scripts.OnEnterPressed(box)
end)

test("the buttons run /pal test and /pal sim", function()
    local client = NewClient():login()
    client.ns.TestButton.scripts.OnClick(client.ns.TestButton)
    eq(client:splashName(), "Claw")
    client.ns.HideSplash()
    client.ns.SimButton.scripts.OnClick(client.ns.SimButton)
    ok(client:printedContains("Simulating:"))
    client:advance(0.3)
    eq(client:splashName(), "Claw")
end)

test("/pal config opens the panel, or waits for the end of combat", function()
    local client = NewClient():login():slash("config")
    eq(client.opened[1], "Pet Ability Learned")
    client.inCombat = true
    client:slash("config")
    eq(#client.opened, 1)
    ok(client:printedContains("when combat ends"))
    client.inCombat = false
    client:fire("PLAYER_REGEN_ENABLED")
    eq(#client.opened, 2)
    client:fire("PLAYER_REGEN_ENABLED")
    eq(#client.opened, 2, "only once")
end)
