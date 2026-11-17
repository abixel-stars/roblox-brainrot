// Pasar Malam Brainrot: the entrypoint for make.fun roblox-brainrot-01.
// Node 22, standard library only. It copies the game (game.rbxl,
// src/, screenshots/ and PLAY.json) from this repository into the
// output directory and writes /output/dossier.json with the kit's
// buildDossier, unchanged, from vendor/makefun-roblox.ts.
// Run it as the grader does: mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
// Run it twice and the two outputs are byte-identical.

import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const repoRoot = process.cwd();
const outDir = process.env.MAKEFUN_OUTPUT_DIR || "/output";

function copyTree(srcDir, destDir) {
  mkdirSync(destDir, { recursive: true });
  for (const entry of readdirSync(srcDir, { withFileTypes: true }).sort((a, b) => (a.name < b.name ? -1 : 1))) {
    if (entry.name.startsWith(".")) {
      continue;
    }
    const from = join(srcDir, entry.name);
    const to = join(destDir, entry.name);
    if (entry.isDirectory()) {
      copyTree(from, to);
    } else if (entry.isFile()) {
      cpSync(from, to);
    }
  }
}

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

const placeFile = join(repoRoot, "game.rbxl");
if (!existsSync(placeFile)) {
  throw new Error("game.rbxl is missing: build it first with rojo build default.project.json --output game.rbxl");
}
cpSync(placeFile, join(outDir, "game.rbxl"));
copyTree(join(repoRoot, "src"), join(outDir, "src"));
copyTree(join(repoRoot, "screenshots"), join(outDir, "screenshots"));
cpSync(join(repoRoot, "PLAY.json"), join(outDir, "PLAY.json"));

const dossier = buildDossier(outDir, { text_max_bytes: 65536 });
writeFileSync(join(outDir, "dossier.json"), dossier);

console.log("Pasar Malam Brainrot handed in: game.rbxl, src/, screenshots/, PLAY.json and dossier.json are in " + outDir);
