# DECISIONS: Architectural & Technology Choices

## Decision Template
Each decision follows this format:
- **ID:** D-NNN (unique identifier)
- **Context:** Why this decision matters
- **Options:** Alternatives considered
- **Decision:** The chosen path
- **Rationale:** Why this option wins
- **Risks:** Known risks and mitigations
- **Reversibility:** Can we change this later?

---

## D-001: Model Selection (Point-E vs Shap-E for MVP)

**Context:** Must choose primary text-to-3D model for Phase 1 MVP. Point-E and Shap-E both proven, but trade off speed vs quality.

**Options Evaluated:**

| Option | Pros | Cons | Recommendation |
|--------|------|------|---|
| **Point-E (2022)** | Faster (60-120s), simpler, proven stable, ONNX-compatible, less VRAM | Lower mesh quality, sparse output | **SELECTED** |
| **Shap-E (2023)** | Better mesh quality, direct output, still fast (30-60s) | More VRAM, larger models, newer (less proven) | Phase 2 upgrade |
| **TRELLIS (2025)** | SOTA quality, compact models, MIT licensed | Very new, complex, less proven at scale | Phase 3+ research |
| **LGM (2024)** | 5s generation, high quality, proven | Gaussian output (mesh conversion harder) | Alternative if ONNX Point-E fails |

**Decision:** **Point-E v1 for MVP, Shap-E as Phase 2 upgrade**

**Rationale:**
1. **Proven Stability:** Used in production since Dec 2022, community support mature
2. **ONNX Compatibility:** Official ONNX export exists; no conversion step needed
3. **Acceptable Quality:** Good enough for MVP "wow factor"; Phase 2 can improve
4. **Simplicity:** Two-stage pipeline straightforward to implement
5. **Community:** Large ecosystem of examples, tutorials, known issues documented
6. **Fallback:** If ONNX conversion problematic, LGM is documented alternative

**Risks:**
- **Risk:** Point-E ONNX models unavailable or broken
  - **Mitigation:** Validate model export in Week 1 of implementation; switch to LGM if needed
- **Risk:** Users disappointed by quality vs Shap-E
  - **Mitigation:** Set expectations in docs; publish "Point-E vs Shap-E" comparison; offer Phase 2 upgrade path

**Reversibility:** **HIGH** - Can switch to Shap-E or LGM later; Phase 2 was always planned

**Phase 2 Plan:**
- Add Shap-E model support alongside Point-E
- Allow `--model point-e` vs `--model shap-e` CLI selection
- Automatic model download/caching for both

---

## D-002: Inference Runtime (ONNX Runtime vs TensorRT vs ncnn)

**Context:** Must choose C++ inference engine for GPU model execution. Performance, compatibility, and maintenance burden differ significantly.

**Options Evaluated:**

| Aspect | ONNX Runtime | TensorRT | ncnn | PyTorch C++ |
|--------|-------------|----------|------|----------|
| **Cross-Platform** | Yes (Win/Lin/Mac) | NVIDIA only | Limited | Yes |
| **Model Support** | Universal | NVIDIA-optimized | Mobile-focused | PyTorch models |
| **Setup Burden** | Moderate | High (model optimization) | Low | High (PyTorch deps) |
| **Performance** | Good | Excellent | Excellent mobile | Good |
| **License** | Apache 2.0 | Proprietary | BSD | BSD |
| **Documentation** | Excellent | Good | Moderate | Good |
| **Point-E Support** | Proven | Not tested | Not tested | Requires PyTorch |

**Decision:** **ONNX Runtime with CUDA Execution Provider**

**Rationale:**
1. **Universal Format:** Not locked to single vendor (could add TensorRT EP later)
2. **Model Maturity:** Point-E ONNX models publicly available and verified
3. **Cross-Platform:** Can expand to Linux/macOS without runtime changes
4. **Proven Production:** Microsoft, Meta, Google use ONNX Runtime in production
5. **C++ API Quality:** Well-documented, stable C++ interfaces
6. **Licensing:** Apache 2.0 (permissive, commercial-friendly)

**Technical Details:**
- CUDA Execution Provider (not TensorRT initially)
- ONNX Runtime built against CUDA 12.x
- cuDNN 8.x required for GPU inference
- Model optimization via ONNX converter tools (offline)

**Risks:**
- **Risk:** ONNX Runtime version mismatches between Windows/Linux builds
  - **Mitigation:** Pin ONNX Runtime version in build config; use official releases only
- **Risk:** Point-E ONNX model has unforeseen bugs
  - **Mitigation:** Extensive testing with varied prompts; document known failures

**Reversibility:** **MEDIUM** - Could switch to TensorRT EP later with code changes; PyTorch would require full rewrite

**Performance Optimization Path (Phase 3+):**
- Benchmark ONNX Runtime CUDA EP vs TensorRT EP
- If performance critical, compile TensorRT-optimized models
- Fallback to TensorRT only for RTX Ampere+ (will enforce minimum GPU)

---

## D-003: Mesh Conversion (OpenVDB vs libigl vs Custom SDF)

**Context:** Point cloud output must become triangle mesh. Three proven approaches; tradeoff speed, quality, and maintainability.

**Options Evaluated:**

| Method | Pros | Cons | Verdict |
|--------|------|------|--------|
| **OpenVDB** | Industry standard, robust, fast, DreamWorks proven, good normal computation | Extra dependency, larger compile | **SELECTED** |
| **libigl** | Academic-proven, comprehensive mesh algorithms, single header library | Slower meshing, header-only (larger compile), less optimized | Phase 2 alternative |
| **Custom SDF Rasterization** | Full control, no deps, interesting R&D | High complexity, time-consuming, unproven quality | Research track |
| **Poisson Reconstruction** | Classic academic method, proven | Requires careful parameter tuning, slower than OpenVDB | Fallback if OpenVDB fails |

**Decision:** **OpenVDB for Phase 1, evaluate libigl for Phase 2**

**Rationale:**
1. **Proven Quality:** DreamWorks' VFX pipeline uses OpenVDB; production-tested
2. **Good Defaults:** Meshing parameters work well without tuning
3. **Performance:** Fast enough for MVP (<15 seconds mesh conversion)
4. **Normal Computation:** Automatic per-vertex normal calculation
5. **Manifold Output:** Produces watertight meshes reliably
6. **Community Support:** Active development; ASWF (Pixar et al.) backing

**Implementation Plan:**
1. Wrap OpenVDB C++ library in simple Eiffel interface
2. Input: STL point cloud file or in-memory point array
3. Output: Triangle mesh with normals (input to GLB exporter)
4. Configuration: Expose voxel size parameter for quality tuning

**Risks:**
- **Risk:** OpenVDB build complexity on Windows
  - **Mitigation:** Use pre-built binaries; document build requirements; provide Docker build image
- **Risk:** Memory explosion with very large point clouds (>10M points)
  - **Mitigation:** Implement point cloud decimation; set reasonable limits on input size

**Reversibility:** **MEDIUM** - Could replace with libigl later; interface abstraction enables swapping

**Phase 2 Plan:**
- Evaluate libigl for comparison (simpler header-only approach)
- Benchmark quality & performance on diverse prompts
- Consider hybrid approach (OpenVDB fast path, libigl fallback)

---

## D-004: Browser Viewer (THREE.js vs Babylon.js vs Native Vulkan)

**Context:** Generated models need visualization. Three options: web-based JavaScript, or native 3D API.

**Options Evaluated:**

| Aspect | THREE.js | Babylon.js | Vulkan Native |
|--------|----------|------------|---------------|
| **Setup** | Simple, npm/CDN | Simple, npm/CDN | Complex, platform-specific |
| **Learning Curve** | Moderate | Moderate | Steep |
| **Feature Set** | Excellent for viewers | More comprehensive | Maximum control |
| **Browser Support** | Chrome, Firefox, Safari 15+ | Same | N/A (desktop only) |
| **Community** | Huge, tons of examples | Growing, good docs | Smaller, specialist |
| **Performance** | Good for this use case | Similar to THREE.js | Potential better |
| **Integration** | simple_web_server + HTML | same | Would need simple_vulkan binding |

**Decision:** **THREE.js for Phase 1; evaluate simple_vulkan for Phase 3+**

**Rationale:**
1. **Accessibility:** Browser-based viewer works for all users (no native deps)
2. **Simplicity:** Standard approach; thousand examples online
3. **Quick Development:** Can prototype viewer in days, not weeks
4. **Ecosystem Integration:** simple_web_server + static assets approach straightforward
5. **Offline Capable:** Can bundle THREE.js locally (doesn't need CDN)
6. **Babylon.js Parity:** No advantage over THREE.js for this use case

**Implementation Plan:**
1. Simple_web_server hosts HTML + JavaScript
2. GLTFLoader for loading generated GLB models
3. Orbit controls for interaction
4. Lighting: Three-point setup + environment mapping
5. UI: React (can use simple React starter) or vanilla JS

**Risks:**
- **Risk:** WebGL not available on some systems
  - **Mitigation:** Graceful fallback (generate files only, warn user)
- **Risk:** Large GLB files slow to load in browser
  - **Mitigation:** Draco compression (Phase 2); streaming loader (Phase 3)

**Reversibility:** **MEDIUM** - Could switch to Babylon.js with minor code changes; Vulkan would be separate native viewer

**Phase 3 Plan:**
- If performance critical, develop Vulkan-based viewer using simple_vulkan
- Keep THREE.js as web-based fallback
- Potential architecture: Eiffel → C++ → Vulkan → desktop window

---

## D-005: Library vs CLI Tool Architecture

**Context:** Should simple_sculptor be a reusable Eiffel library, a command-line tool, or both?

**Options Evaluated:**

| Option | Use Cases | Pros | Cons | Verdict |
|--------|-----------|------|------|--------|
| **Library Only** | Integrated into other tools | Reusable, composable | Requires wrapper for CLI | Not sufficient |
| **CLI Tool Only** | Standalone generation | Simple, focused | Can't integrate into Eiffel code | Limiting |
| **Library + CLI** | Both integration & standalone | Flexible, reusable, comprehensive | More development | **SELECTED** |

**Decision:** **Build as Library with CLI wrapper (standard simple_* pattern)**

**Rationale:**
1. **Library-First Design:** Core generation logic as reusable Eiffel library
2. **CLI Convenience:** Command-line tool for end users
3. **Integration:** Other Eiffel code can call library directly
4. **Ecosystem Fit:** Matches simple_* library pattern (simple_json, simple_uuid, etc.)
5. **Future-Proof:** Can add HTTP API, GUI, integrations on top of library

**Architecture:**
```
simple_sculptor/
├── library/              # Core Eiffel library
│   ├── sculptor_engine.e         # Main generation engine
│   ├── onnx_inference.e          # ONNX Runtime wrapper
│   ├── mesh_converter.e          # OpenVDB wrapper
│   ├── geometry_types.e          # Point, Mesh, etc.
│   └── ...
├── cli/                  # Command-line tool
│   ├── sculptor_cli.e            # CLI entry point
│   └── sculptor_interactive.e    # Web viewer handler
├── tests/                # Test suites
├── examples/             # Example code
└── docs/                 # Documentation
```

**Library API Design (public interface):**
```eiffel
class SCULPTOR_ENGINE
  generate(prompt: STRING): GENERATION_RESULT
  generate_async(prompt: STRING; callback: SCULPTOR_CALLBACK)
  batch_generate(prompts: LIST[STRING]): LIST[GENERATION_RESULT]

feature {NONE}
  inference_engine: ONNX_INFERENCE_ENGINE
  mesh_converter: MESH_CONVERTER
end
```

**Risks:**
- **Risk:** Library interface too broad/vague
  - **Mitigation:** Design in consultation with simple_* leads; iterate with feedback

**Reversibility:** **HIGH** - Library interface can change; breaking changes documented

---

## D-006: Configuration & Model Management

**Context:** How to manage ONNX model files, configuration, and caching?

**Options:**

1. **Embedded Models:** Pack models into executable (5-8GB binary)
2. **Separate Download:** User manually downloads models (~3.5GB)
3. **Auto-Download on First Run:** Fetch from CDN/GitHub on `simple_sculptor generate`
4. **Conda/Package Manager:** Distribute via package manager with model variants

**Decision:** **Auto-Download with Local Cache + Manual Download Option**

**Rationale:**
1. **Convenience:** First-time UX: `simple_sculptor generate --prompt "..."` just works
2. **Control:** Power users can pre-download and specify model location
3. **Bandwidth:** Don't bloat executable; models downloaded once, cached locally
4. **Flexibility:** Support multiple models (Point-E, Shap-E) without huge overhead

**Implementation:**
```
Default cache: ~/.simple_sculptor/models/
├── point-e-v1.onnx           (~3.5GB)
├── point-e-v1.metadata.json  (SHA256, version info)
└── shap-e-v1.onnx            (~5GB, Phase 2)

CLI Options:
--model-dir /custom/path       # Override cache location
--model-url https://...        # Custom model source
--no-download                  # Fail if model not cached
```

**Risks:**
- **Risk:** Model download fails (network issue, server down)
  - **Mitigation:** Retry logic; provide fallback download URLs; document manual download process
- **Risk:** 3.5GB download takes too long on slow internet
  - **Mitigation:** Estimate time; show progress bar; allow background download

---

## D-007: Coordinate Systems & Scale

**Context:** What coordinate system and unit scale for generated models?

**Options:**
1. Point-E native (typically centered at origin, -1 to +1 range)
2. Millimeters (CAD standard, easier for 3D printing)
3. Meters (engineering standard)
4. User-configurable

**Decision:** **Normalize to unit scale (center at origin, -1 to +1 bounds) + export in meters**

**Rationale:**
1. **3D Printing:** Standard to export as millimeters (convert from meters)
2. **CAD:** Meters are ISO standard for large assemblies
3. **Web Viewer:** Unit scale simplifies camera math
4. **Flexibility:** GLB can embed scale info; importer can rescale

**Export Behavior:**
- **GLB/OBJ:** 1 unit = 1 meter (standard assumption)
- **STL:** Export with scale factor user can specify (default 100× for mm)
- **Metadata:** Always include bounding box and scale info in JSON

**Risks:**
- **Risk:** Scale misunderstanding causes 3D printing failures
  - **Mitigation:** Document clearly; verify with test print; validate in Cura/Fusion 360

---

## D-008: Error Handling & Fallbacks

**Context:** What happens when inference fails, mesh conversion fails, or export fails?

**Decision:** **Fail-fast with detailed error messages + limited fallback**

**Specification:**
1. **Inference Failure:** Return detailed CUDA error; suggest troubleshooting
2. **Mesh Conversion Failure:** Return best-effort mesh + warning; don't crash
3. **Export Failure:** Try multiple format fallbacks (e.g., if GLB fails, try OBJ)
4. **Partial Mesh:** If conversion produces < 50% expected triangles, warn but return

**Example:**
```
$ simple_sculptor generate --prompt "invalid json payload"
ERROR: ONNX inference failed
  Message: CUDA Out of Memory (need 15GB, have 14GB available)
  Suggestion: Close other GPU applications or upgrade GPU memory
  Fallback: Reduce point cloud size with --point-count 500000
```

**Risks:**
- **Risk:** Partial failures confuse users
  - **Mitigation:** Clear logging; detailed error codes; link to FAQ in messages

---

## Summary: Decision Dependency Graph

```
D-001 (Model: Point-E)
  └─→ D-002 (Runtime: ONNX)
  └─→ D-003 (Meshing: OpenVDB)
  └─→ D-006 (Config: Auto-Download)

D-004 (Viewer: THREE.js)
  └─→ D-005 (Architecture: Library + CLI)

D-007 (Coordinates: Meters)
D-008 (Errors: Fail-fast)
```

All decisions are compatible and reinforce the overall architecture.

---

**Document Status:** DECISIONS LOCKED, ready for INNOVATIONS phase
