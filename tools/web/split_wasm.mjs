import { copyFileSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const PART_BYTES = 20 * 1024 * 1024;
const buildDir = process.argv[2] ?? "build/web";
const wasmPath = join(buildDir, "index.wasm");

const wasm = readFileSync(wasmPath);
const parts = [];
for (let offset = 0; offset < wasm.length; offset += PART_BYTES) {
	const name = `index.part${parts.length}.wasm`;
	writeFileSync(join(buildDir, name), wasm.subarray(offset, offset + PART_BYTES));
	parts.push(name);
}
writeFileSync(join(buildDir, "index.wasm.parts.json"), JSON.stringify({ size: wasm.length, parts }));
rmSync(wasmPath);
copyFileSync(join(dirname(fileURLToPath(import.meta.url)), "wasm_parts.js"), join(buildDir, "wasm_parts.js"));
console.log(`index.wasm split into ${parts.length} parts`);
