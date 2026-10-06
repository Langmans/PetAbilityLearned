// Static checks: StyLua formatting, then WoW Lua LS diagnostics.
//
// WoW Lua LS ships inside its VS Code extension; the newest installed version
// is used. Without the extension that check is skipped with a warning rather
// than failing, so `npm run lint` still works on a machine without VS Code.
import { spawnSync } from "node:child_process";
import { existsSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { color } from "./coverage.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
let failed = false;

function run(label, command, args) {
    console.log(color.bold(`# ${label}`));
    // No shell: the repo path may contain spaces ("My Games").
    const result = spawnSync(command, args, { cwd: root, stdio: "inherit" });
    if (result.status === 0) {
        console.log(color.green(`ok - ${label}`));
    } else {
        console.log(color.red(`not ok - ${label}`));
        failed = true;
    }
}

// The npm package's entry point is a Node script that downloads and runs the binary.
const stylua = join(root, "node_modules", "@johnnymorganz", "stylua-bin", "run.js");
run("StyLua", process.execPath, [stylua, "--check", "."]);

const extensions = join(homedir(), ".vscode", "extensions");
const versions = existsSync(extensions)
    ? readdirSync(extensions)
          .filter((name) => name.startsWith("tradeskillmaster.wowlua-ls-"))
          .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))
    : [];
const platform = { win32: "win32-x64", darwin: "darwin-x64", linux: "linux-x64" }[process.platform];
const binary = versions.length
    ? join(extensions, versions.at(-1), "server", platform, process.platform === "win32" ? "wowlua_ls.exe" : "wowlua_ls")
    : null;

if (binary && existsSync(binary)) {
    run(`WoW Lua LS (${versions.at(-1)})`, binary, ["check", "."]);
} else {
    console.log(color.yellow("skip - WoW Lua LS: VS Code extension tradeskillmaster.wowlua-ls not found"));
}

process.exitCode = failed ? 1 : 0;
