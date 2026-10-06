-- A minimal test framework: test() registers, the assertions raise errors,
-- RunTests() runs everything and reports in TAP style.

local registered = {}

function test(name, fn)
    registered[#registered + 1] = { name = name, fn = fn }
end

local function show(value)
    if type(value) == "string" then return string.format("%q", value) end
    return tostring(value)
end

function eq(actual, expected, message)
    if actual ~= expected then
        error((message and message .. ": " or "") .. "expected " .. show(expected) .. ", got " .. show(actual), 2)
    end
end

function ok(value, message)
    if not value then error(message or "expected a truthy value", 2) end
end

function contains(list, value, message)
    for _, item in ipairs(list) do
        if item == value then return end
    end
    error((message and message .. ": " or "") .. show(value) .. " not in list of " .. #list, 2)
end

function startsWith(text, prefix, message)
    if type(text) ~= "string" or text:sub(1, #prefix) ~= prefix then
        error((message and message .. ": " or "") .. show(text) .. " does not start with " .. show(prefix), 2)
    end
end

function RunTests()
    local lines, passed, failed = {}, 0, 0
    for _, t in ipairs(registered) do
        local success, err = pcall(t.fn)
        if success then
            passed = passed + 1
            lines[#lines + 1] = "ok - " .. t.name
        else
            failed = failed + 1
            lines[#lines + 1] = "not ok - " .. t.name .. "\n    " .. tostring(err)
        end
    end
    return table.concat(lines, "\n"), passed, failed
end
