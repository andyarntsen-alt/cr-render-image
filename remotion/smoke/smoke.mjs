// node smoke.mjs <out-dir> [gl]   renders 50 frames of the Smoke comp with the image's Chrome Headless Shell.
// Prints: SMOKE gl=<gl> frames=50 secs=<s> renderer=<WebGL renderer string>   (exit 1 if a frame is missing)
import { bundle } from "@remotion/bundler";
import { ensureBrowser, renderFrames, selectComposition } from "@remotion/renderer";
import fs from "node:fs";
import path from "node:path";

const out = process.argv[2] ?? "/tmp/smoke";
const gl = process.argv[3] ?? "swangle";
fs.mkdirSync(out, { recursive: true });
await ensureBrowser();
const here = path.dirname(new URL(import.meta.url).pathname);
const serveUrl = await bundle({ entryPoint: path.join(here, "src/index.tsx") });
const composition = await selectComposition({ serveUrl, id: "Smoke", chromiumOptions: { gl } });
let renderer = "?";
const t0 = Date.now();
await renderFrames({
  serveUrl, composition, imageFormat: "png", outputDir: out, concurrency: 4, chromiumOptions: { gl },
  onStart: () => {}, onFrameUpdate: () => {},
  onBrowserLog: (l) => { const m = /GLRENDERER (.*)/.exec(l.text); if (m) renderer = m[1]; },
});
const secs = (Date.now() - t0) / 1000;
const files = fs.readdirSync(out).filter((f) => f.endsWith(".png"));
console.log(`SMOKE gl=${gl} frames=${files.length} secs=${secs.toFixed(1)} renderer=${renderer}`);
if (files.length !== 50) process.exit(1);
