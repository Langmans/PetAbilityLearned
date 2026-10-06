// Line coverage for the addon's Lua files.
//
// Hits come from a Lua line hook (debug.sethook with "l") installed in every
// test state before the addon loads; CoverageDump() hands them back as text.
// Which lines count as executable comes from luaparse: the first line of every
// statement. Comments, blank lines and lone `end`s are therefore not counted.
// Two statements need the line Lua itself reports:
// - A function (statement or expression) is created by an instruction on its
//   closing `end` line, so that line is the one the hook sees.
// - `local a, b` without values compiles to a LOADNIL that Lua merges into
//   the previous one; it has no instruction of its own and is skipped.
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import luaparse from "luaparse";

// ANSI colours for a terminal; off when piped or with NO_COLOR, forced on with FORCE_COLOR.
const useColor = !process.env.NO_COLOR && (process.stdout.isTTY || !!process.env.FORCE_COLOR);
const paint = (code) => (text) => (useColor ? `\x1b[${code}m${text}\x1b[0m` : String(text));
export const color = { green: paint(32), red: paint(31), yellow: paint(33), bold: paint(1) };

const byPercent = (pct, text) => (pct >= 100 ? color.green(text) : pct >= 90 ? color.yellow(text) : color.red(text));

export const HOOK = `
COVERAGE = {}
debug.sethook(function(_, line)
    local source = debug.getinfo(2, "S").source
    local hits = COVERAGE[source]
    if not hits then
        hits = {}
        COVERAGE[source] = hits
    end
    hits[line] = (hits[line] or 0) + 1
end, "l")

function CoverageDump()
    debug.sethook()
    local out = {}
    for source, hits in pairs(COVERAGE) do
        for line, count in pairs(hits) do
            out[#out + 1] = source .. "\\t" .. line .. "\\t" .. count
        end
    end
    return table.concat(out, "\\n")
end
`;

/** Lines that start a statement, for one Lua file. */
function executableLines(source) {
    const lines = new Set();
    const visit = (node) => {
        if (!node || typeof node !== "object") return;
        if (Array.isArray(node)) return node.forEach(visit);
        if (node.type === "FunctionDeclaration") {
            lines.add(node.loc.end.line);
        } else if (node.type === "LocalStatement" && node.init.length === 0) {
            // no instruction of its own
        } else if (typeof node.type === "string" && /Statement$/.test(node.type) && node.loc) {
            lines.add(node.loc.start.line);
        }
        for (const [key, value] of Object.entries(node)) {
            if (key !== "loc" && key !== "range") visit(value);
        }
    };
    visit(luaparse.parse(source, { luaVersion: "5.1", locations: true, comments: false }));
    return lines;
}

export class Coverage {
    constructor(root, files) {
        this.root = root;
        this.files = files; // repo-relative paths, from the .toc
        this.hits = new Map(files.map((f) => [f, new Map()]));
    }

    /** Adds the text returned by CoverageDump() from one Lua state. */
    add(dump) {
        for (const row of dump.split("\n")) {
            if (!row) continue;
            const [source, line, count] = row.split("\t");
            const file = source.replace(/^@/, "").replace(`${this.root}/`, "");
            const hits = this.hits.get(file);
            if (hits) hits.set(+line, (hits.get(+line) || 0) + +count);
        }
    }

    /** Prints a per-file table and writes coverage/lcov.info. Returns the total percentage. */
    report() {
        let lcov = "";
        let totalHit = 0;
        let totalLines = 0;
        console.log("\nCoverage (statement lines hit / executable):");
        for (const file of this.files) {
            const executable = [...executableLines(readFileSync(join(this.root, file), "utf8"))].sort((a, b) => a - b);
            const hits = this.hits.get(file);
            const missed = executable.filter((line) => !hits.has(line));
            const hit = executable.length - missed.length;
            totalHit += hit;
            totalLines += executable.length;
            const pct = executable.length ? (100 * hit) / executable.length : 100;
            const missing = missed.length ? color.red(`  missed: ${missed.join(", ")}`) : "";
            const figure = byPercent(pct, `${pct.toFixed(1).padStart(5)}%`);
            console.log(`  ${figure}  ${String(hit).padStart(3)}/${String(executable.length).padEnd(3)} ${file}${missing}`);
            lcov += `SF:${join(this.root, file)}\n`;
            for (const line of executable) lcov += `DA:${line},${hits.get(line) || 0}\n`;
            lcov += `LH:${hit}\nLF:${executable.length}\nend_of_record\n`;
        }
        const total = totalLines ? (100 * totalHit) / totalLines : 100;
        console.log(`  ${byPercent(total, `${total.toFixed(1).padStart(5)}%`)}  ${totalHit}/${totalLines} total`);
        mkdirSync(join(this.root, "coverage"), { recursive: true });
        writeFileSync(join(this.root, "coverage", "lcov.info"), lcov);
        return total;
    }
}
