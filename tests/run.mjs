// Runs every tests/*.test.lua in its own fengari (Lua 5.3 in JS) state, with
// tests/framework.lua and tests/wow.lua loaded first. fengari has no `io`, so
// the .toc file list and the repo root are handed to Lua as globals.
//
// WoW runs Lua 5.1; fengari is 5.3. The addon only uses the common subset, and
// WoW Lua LS (npm run lint) flags anything outside what WoW offers.
//
// Line coverage of the addon files is collected in every state and reported
// at the end (see coverage.mjs), with coverage/lcov.info for editor plugins.
import { readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import fengari from "fengari";
import { color, Coverage, HOOK } from "./coverage.mjs";

const { lua, lauxlib, lualib, to_luastring, to_jsstring } = fengari;
const testsDir = dirname(fileURLToPath(import.meta.url));
const root = join(testsDir, "..").replace(/\\/g, "/");

const tocText = readFileSync(join(root, "PetAbilityLearned.toc"), "utf8");
const toc = tocText
    .split(/\r?\n/)
    .filter((line) => line.trim() && !line.startsWith("#"))
    .map((line) => line.trim().replace(/\\/g, "/"));
// The client creates these globals from the saved files; tests seed and read them by these names.
const savedPerCharacter = (tocText.match(/^## SavedVariablesPerCharacter:\s*(\S+)/m) || [])[1] || "";
const savedPerAccount = (tocText.match(/^## SavedVariables:\s*(\S+)/m) || [])[1] || "";
// The "## Key: value" lines, for GetAddOnMetadata.
const metadata = [...tocText.matchAll(/^## ([^:]+):\s*(.*?)\s*$/gm)].map((m) => [m[1], m[2]]);

const filter = process.argv[2];
const files = readdirSync(testsDir)
    .filter((f) => f.endsWith(".test.lua"))
    .filter((f) => !filter || f.includes(filter))
    .sort();

let passed = 0;
let failed = 0;
const coverage = new Coverage(root, toc);

function collectCoverage(L) {
    lua.lua_getglobal(L, to_luastring("CoverageDump"));
    if (lua.lua_pcall(L, 0, 1, 0) === 0) coverage.add(to_jsstring(lua.lua_tostring(L, -1)));
}

for (const file of files) {
    const L = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(L);
    lauxlib.luaL_dostring(L, to_luastring(HOOK));
    lua.lua_pushstring(L, to_luastring(root));
    lua.lua_setglobal(L, to_luastring("ROOT"));
    lua.lua_createtable(L, toc.length, 0);
    toc.forEach((entry, i) => {
        lua.lua_pushstring(L, to_luastring(entry));
        lua.lua_rawseti(L, -2, i + 1);
    });
    lua.lua_setglobal(L, to_luastring("TOC_FILES"));
    lua.lua_pushstring(L, to_luastring(savedPerCharacter));
    lua.lua_setglobal(L, to_luastring("TOC_SAVED_PER_CHARACTER"));
    lua.lua_pushstring(L, to_luastring(savedPerAccount));
    lua.lua_setglobal(L, to_luastring("TOC_SAVED_PER_ACCOUNT"));
    lua.lua_createtable(L, 0, metadata.length);
    for (const [key, value] of metadata) {
        lua.lua_pushstring(L, to_luastring(value));
        lua.lua_setfield(L, -2, to_luastring(key));
    }
    lua.lua_setglobal(L, to_luastring("TOC_METADATA"));

    const chunks = ["tests/framework.lua", "tests/wow.lua", `tests/${file}`];
    let loadError = null;
    for (const chunk of chunks) {
        if (lauxlib.luaL_dofile(L, to_luastring(`${root}/${chunk}`)) !== 0) {
            loadError = to_jsstring(lua.lua_tostring(L, -1));
            break;
        }
    }
    console.log(color.bold(`# ${file}`));
    if (loadError) {
        console.log(color.red(`not ok - ${file} failed to load: ${loadError}`));
        failed++;
        continue;
    }
    // RunTests returns a report string plus pass and fail counts.
    lua.lua_getglobal(L, to_luastring("RunTests"));
    if (lua.lua_pcall(L, 0, 3, 0) !== 0) {
        console.log(color.red(`not ok - ${file}: ${to_jsstring(lua.lua_tostring(L, -1))}`));
        failed++;
        continue;
    }
    // A failure's message sits on the indented line after its "not ok".
    let inFailure = false;
    for (const line of to_jsstring(lua.lua_tostring(L, -3)).split("\n")) {
        if (line.startsWith("not ok")) inFailure = true;
        else if (!line.startsWith(" ")) inFailure = false;
        console.log(line.startsWith("ok") ? color.green(line) : inFailure ? color.red(line) : line);
    }
    passed += lua.lua_tointeger(L, -2);
    failed += lua.lua_tointeger(L, -1);
    collectCoverage(L);
}

// Every executable line must run in some test. A full run below 100% fails, so a new line
// without a test cannot slip in; a filtered run covers only part and is not held to it.
let coverageShort = false;
if (!filter) {
    const total = coverage.report();
    if (total < 100) {
        console.log(color.red(`not ok - line coverage is ${total.toFixed(1)}%, must be 100%`));
        coverageShort = true;
    }
}
console.log(`\n${color.green(`${passed} passed`)}, ${failed ? color.red(`${failed} failed`) : "0 failed"}`);
process.exitCode = failed > 0 || files.length === 0 || coverageShort ? 1 : 0;
