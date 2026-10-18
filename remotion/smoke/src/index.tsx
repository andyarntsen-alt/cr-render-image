// Smoke test for the image: one tiny composition, no project code. Rendered by smoke.mjs in CI and on the pod.
// Frame 0 logs which WebGL renderer Chrome got (NVIDIA = GPU; SwiftShader/llvmpipe = CPU) as "GLRENDERER ...".
import React, { useEffect } from "react";
import { AbsoluteFill, Composition, registerRoot, useCurrentFrame } from "remotion";

const glRenderer = (): string => {
  try {
    const c = document.createElement("canvas").getContext("webgl");
    if (!c) return "no-webgl";
    const e = c.getExtension("WEBGL_debug_renderer_info");
    return String(e ? c.getParameter(e.UNMASKED_RENDERER_WEBGL) : c.getParameter(c.RENDERER));
  } catch (err) {
    return `error ${String(err)}`;
  }
};

const Smoke: React.FC = () => {
  const f = useCurrentFrame();
  useEffect(() => {
    if (f === 0) console.log(`GLRENDERER ${glRenderer()}`);
  }, [f]);
  return (
    <AbsoluteFill style={{ background: "#101010", alignItems: "center", justifyContent: "center" }}>
      <div style={{ color: "#f2b24c", fontSize: 120, fontFamily: "DejaVu Sans", filter: "blur(1px)", transform: `translateX(${f * 4}px)` }}>
        SMOKE {f}
      </div>
    </AbsoluteFill>
  );
};

const Root: React.FC = () => (
  <Composition id="Smoke" component={Smoke} durationInFrames={50} fps={25} width={1920} height={1080} />
);

registerRoot(Root);
