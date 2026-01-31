# PARSED REQUIREMENTS: simple_sculptor Library

## Problem Statement

**Challenge:** Generate 3D geometry models directly from natural language text prompts, entirely locally without cloud dependencies or Python runtime overhead.

**Current Landscape:**
- Cloud-first solutions (OpenAI API, Zoo) require internet connectivity
- Python-dependent tools (ComfyUI) require Python runtime at generation time
- GPU inference frameworks (TensorFlow, PyTorch) are heavyweight

**simple_sculptor Goal:** Bring text-to-3D generation into the Simple Eiffel ecosystem as a pure Eiffel+C++ library with local GPU inference capability. Users can input text descriptions and receive 3D models viewable in browser within 30-120 seconds, entirely on their local machine.

---

## Scope Definition

### In-Scope (Phase 1 MVP)
1. **Text Input:** Accept natural language prompts (10-500 characters, UTF-8)
2. **ONNX Inference:** Execute Point-E v1 model via ONNX Runtime + CUDA
3. **Mesh Generation:** Convert point clouds to triangle meshes with normals
4. **Browser Viewer:** Launch local THREE.js viewer for 3D model inspection
5. **Export Formats:** GLB primary, OBJ/STL support
6. **CLI Interface:** `simple_sculptor generate --prompt "description"`
7. **Library Interface:** Programmatic API for Eiffel integration

### Out-of-Scope (Phase 1)
- Cloud API endpoints
- Python runtime dependency (models converted offline)
- Real-time interactive generation
- Texture/material synthesis
- Animation or rigging
- Multi-GPU distribution
- AMD/Intel GPU support (NVIDIA CUDA only)

---

## Functional Requirements

### FR-001: Text Prompt Input
**Description:** Accept natural language text prompts from user

**Specification:**
- CLI: `simple_sculptor generate --prompt "a blue ceramic vase"`
- Programmatic API: `sculptor.generate(prompt: STRING): GENERATION_JOB`
- Prompt length: 10-500 characters
- Character encoding: UTF-8
- Validation: Reject empty or whitespace-only prompts
- Error reporting: Clear messages for invalid input

**Success Criteria:**
- User can specify prompt via command line
- API accepts STRING input without crashes
- Clear error messages for invalid input
- Example prompts work reliably

---

### FR-002: 3D Point Cloud Generation via ONNX Inference
**Description:** Execute Point-E model inference to generate 3D point cloud from prompt

**Specification:**
- Model: OpenAI Point-E v1 (text-to-image + image-to-3D stages)
- Runtime: ONNX Runtime with CUDA Execution Provider
- Input: Text embedding (derived from prompt)
- Output: Point cloud (1M+ points in 3D space with (x,y,z) coordinates)
- GPU Memory: Must fit in 16GB VRAM (leaving 2GB headroom)
- Timeout: 120 seconds max per inference
- Performance targets:
  - RTX 5070 Ti: 30-60 seconds inference time
  - RTX 4090: 15-30 seconds inference time
  - RTX 4070: 45-90 seconds inference time

**Success Criteria:**
- Point cloud generated with > 500K points
- All points have valid (x, y, z) coordinates
- Inference completes within timeout
- GPU memory not exceeded (< 14GB on 16GB systems)
- No CUDA out-of-memory crashes
- Reproducible results with seed control

---

### FR-003: Point Cloud → Mesh Conversion with Normals
**Description:** Convert sparse point cloud to solid triangle mesh with vertex normals

**Specification:**
- Input: Point cloud (1M+ points, sparse distribution)
- Algorithm: OpenVDB point-to-mesh conversion
- Output: Triangle mesh with:
  - Vertex positions (x, y, z)
  - Triangle indices (face definitions)
  - Vertex normals (for shading)
  - UV coordinates (optional, Phase 2)
- Normal Calculation: Per-vertex normals computed from adjacent faces
- Manifold Output: Mesh should be closed/manifold (no holes, no self-intersections)
- Triangle Optimization: Remove degenerate triangles (area < epsilon)
- Quality targets:
  - No self-intersecting triangles
  - Manifold topology (watertight mesh)
  - Reasonable normal distributions (no inverted faces)
  - Triangle density: 1M-5M triangles for GLB optimization

**Success Criteria:**
- Output mesh passes Blender validation (manifold check)
- Mesh visually represents original prompt concept
- Normal vectors point outward (for lighting)
- File size reasonable (< 100MB uncompressed)

---

### FR-004: Export Formats (GLB/GLTF Primary)
**Description:** Export generated mesh to standard interchange formats

**GLB (Primary - Phase 1):**
- Format: GL Transmission Format Binary
- Contents: Triangle mesh, vertex normals, basic PBR material
- Compression: Draco optional (Phase 2)
- File size target: < 50MB for typical model

**OBJ (Phase 1 Support):**
- Format: Wavefront OBJ + MTL
- Contents: Geometry + basic material definition
- Limitation: No PBR materials (OBJ format limitation)

**STL (Phase 1 Support):**
- Format: Stereolithography (binary)
- Use case: 3D printing workflows
- Limitation: Geometry only, no materials or colors

**Success Criteria:**
- GLB exports load in THREE.js, Babylon.js, Blender, Unity
- OBJ/STL exports work in standard CAD software
- File formats verified with Blender import/export
- Metadata preserved (model name, generation timestamp)

---

### FR-005: Interactive Web Viewer (LOCAL SERVER)
**Description:** Launch local web server with THREE.js-based 3D model viewer

**Specification:**
- CLI Command: `simple_sculptor view model.glb --port 8080`
- Server Technology: simple_web_server (Eiffel ecosystem)
- Frontend: HTML + THREE.js + GLTFLoader
- Functionality:
  - Load and display GLB/GLTF models
  - Orbit camera controls (mouse drag rotate, scroll zoom)
  - Pan controls (middle-click or SHIFT+drag)
  - Full-screen toggle (F key)
  - Model info display (triangle count, file size, bounds)
  - Three-point lighting + environment map
  - Wireframe mode toggle (W key)
  - Reset view (HOME key)
  - Auto-rotate toggle
  - Background color selector
  - Download current view as PNG screenshot
  - Display generation metadata (prompt, timestamp, GPU time)
- Browser Compatibility: Chrome 90+, Firefox 88+, Safari 15+

**Success Criteria:**
- Viewer launches automatically after generation
- Model fully visible with good camera framing
- Controls responsive and intuitive
- Screenshots work correctly
- No WebGL errors in console

---

### FR-006: Export Options & Pipeline Integration
**Description:** Support batch processing and downstream tool integration

**Batch Mode:**
- Input: File with line-separated prompts
- CLI: `simple_sculptor batch prompts.txt --output-dir ./models`
- Concurrency: Process multiple prompts sequentially (single GPU)
- Output: Numbered GLB files (model_001.glb, model_002.glb, ...)
- Metadata: CSV index file mapping prompt → output file

**Screenshot Export:**
- CLI: `simple_sculptor generate --prompt "..." --screenshot out.png`
- Output: PNG image from default camera angle
- Size: 1920x1080 pixels
- Timeout: Must complete within 5 seconds

**Metadata JSON Export:**
- CLI: `simple_sculptor generate --prompt "..." --metadata meta.json`
- Contents: Prompt, timestamp, GPU time, triangle count, bounding box

**Success Criteria:**
- Batch processing completes without errors
- Output files properly indexed
- Screenshots are correct PNG format
- Metadata JSON is valid

---

## Non-Functional Requirements

### NFR-001: Performance (GPU Inference)
**Requirement:** Generation completes in user-acceptable timeframe

**Specification:**
- Target GPU: NVIDIA RTX 5070 Ti
- Target Time: 30-120 seconds end-to-end
- Breakdown:
  - Point-E inference: 45-60 seconds
  - Mesh conversion: 5-15 seconds
  - Export: 1-5 seconds
  - Total nominal: 51-80 seconds
- Peak Memory: < 14GB VRAM (leave 2GB headroom on 16GB systems)

**Success Criteria:**
- Measured on actual hardware, not estimates
- No CUDA OOM errors on 16GB VRAM
- User can specify timeout (abort if exceeds threshold)

---

### NFR-002: Locality & Offline Capability
**Requirement:** Tool operates entirely locally without external service calls

**Specification:**
- No API Calls: Zero internet connectivity required after model download
- No Cloud: No communication with external services
- No Python Runtime: Python not needed for inference
- Model Files: Downloaded once, cached locally (~3.5GB for Point-E)
- Reproducibility: Same prompt always generates similar geometry (deterministic seed)

**Success Criteria:**
- Tool works on isolated/offline machine
- No network traffic during `generate` command
- All dependencies bundled or easily installable locally
- Model cache location configurable (default: ~/.simple_sculptor/models/)

---

### NFR-003: C++ & Eiffel Native Integration
**Requirement:** Library written in Eiffel with C++ integration for inference

**Specification:**
- Core Library: 100% Eiffel (no Python, no Node.js)
- Inference Runtime: C++ via inline C/C++ integration
  - ONNX Runtime C++ API
  - OpenVDB C++ library
  - simple_web_server Eiffel bindings
- Design by Contract: All Eiffel classes use DBC
- Void Safety: All code void-safe
- SCOOP Compatible: Concurrency-ready architecture

**Success Criteria:**
- Compiles with EiffelStudio 25.02 with `-void_safety all`
- Passes DBC checking at runtime
- SCOOP features usable for parallel generation
- Clear Eiffel/C++ boundary

---

### NFR-004: Browser-Based Viewing (Offline-Capable)
**Requirement:** Generated models viewable in web browser without external CDN

**Specification:**
- Technology: THREE.js (MIT license)
- Delivery: Self-hosted from simple_web_server
- Asset Loading: All JavaScript/CSS bundled with library
- Fallback: If web browser unavailable, generate files only
- No Dependencies: Viewer works without internet

**Success Criteria:**
- Viewer loads in < 1 second after generation
- Works in Chrome, Firefox, Safari (latest versions)
- THREE.js library bundled (not CDN-dependent)
- Responsive to window resize

---

### NFR-005: Scalability & Concurrency
**Requirement:** Support batch generation with efficient resource utilization

**Specification:**
- Batch Processing: Process multiple prompts via SCOOP task pool
- GPU Sharing: Single GPU, sequential inference (not parallel)
- Memory Management: Clean up between generations
- Timeout Handling: Abort long-running generations gracefully
- Error Recovery: Failed generation doesn't crash batch

**Success Criteria:**
- Batch of 10 prompts processes sequentially without crashes
- Memory stable across 50+ generations
- Clear logs for successful/failed generations
- User can cancel in-progress batch (Ctrl+C handling)

---

### NFR-006: Platform & Compatibility
**Requirement:** Work on Windows, Linux, and macOS

**Specification:**
- Phase 1 (MVP): Windows + NVIDIA CUDA (RTX series)
- Phase 2: Linux support (Ubuntu 20.04+)
- Phase 3: macOS (Metal GPU support)
- Minimum NVIDIA Driver: 515.x or later
- CUDA Version: 11.8+ or 12.x
- EiffelStudio: 25.02 (standard for simple_* ecosystem)

**Success Criteria:**
- Builds cleanly on Windows + Visual Studio
- No platform-specific hardcoded paths
- CI/CD verified on both Windows and Linux

---

## Key Decisions Made (from Research Phase)

### D-001: Model Selection → Point-E v1
- Chosen for stability, ONNX compatibility, proven community support
- Fallback: LGM (ECCV 2024) if ONNX export problematic
- Phase 2: Shap-E for quality improvements

### D-002: Inference Runtime → ONNX Runtime with CUDA
- Universal format (not vendor-locked)
- Point-E ONNX models publicly available
- Apache 2.0 licensing (permissive)
- Cross-platform support

### D-003: Mesh Conversion → OpenVDB
- Industry standard (DreamWorks VFX)
- Proven robust meshing algorithm
- Handles noisy point clouds well
- Native C++ integration

### D-004: Viewer → THREE.js + Browser
- Low friction UX (no native dependencies)
- Industry-standard (thousands of production sites)
- Bundled THREE.js (no CDN dependency)
- Fall-back: Babylon.js if needed

### D-005: Architecture → Library + CLI
- Library-first design (reusable in other Eiffel code)
- CLI wrapper for end users
- Matches simple_* ecosystem pattern

### D-006: Model Management → Auto-Download + Local Cache
- Convenience: First-time UX just works
- Control: Power users can specify model location
- Bandwidth: Models downloaded once, cached locally
- Flexibility: Support multiple models

### D-007: Coordinate System → Unit Scale (Meters)
- GLB/OBJ: 1 unit = 1 meter (standard)
- STL: Configurable scale (default 100× for mm)
- Metadata includes bounding box and scale info

### D-008: Error Handling → Fail-Fast with Fallbacks
- Inference failure: Return detailed error + suggestions
- Mesh conversion failure: Return best-effort mesh + warning
- Export failure: Try multiple format fallbacks

---

## Innovation Highlights

1. **Local-First Text-to-3D in Pure Eiffel:** First generative 3D tool in Eiffel ecosystem
2. **ONNX Runtime FFI Pattern:** Reusable wrapper for other models (Whisper, BERT, Mistral)
3. **Procedural Geometry Pipeline:** SDF-compatible output enables downstream applications
4. **Browser-Viewable Offline 3D:** Generated models immediately viewable, no external CDN
5. **Deterministic Generation:** Seed control enables reproducibility and design space exploration
6. **SCOOP-Compatible Concurrency:** Efficient batch processing respecting GPU limits
7. **Automated Mesh Validation:** Quality checks ensure print-ready meshes
8. **KittyCAD Integration (Phase 3):** Bridge between generative AI and parametric CAD

---

## Risks to Address

### RISK-001: ONNX Runtime Point-E Model Stability (MEDIUM)
- Mitigation: Early validation Week 1, fallback to LGM if needed

### RISK-002: Mesh Conversion Quality & Artifacts (MEDIUM-HIGH)
- Mitigation: Parameter tuning, preprocessing, quality scoring

### RISK-003: VRAM Management & Out-of-Memory Crashes (HIGH)
- Mitigation: FP16 quantization, memory profiling, graceful degradation

### RISK-004: Model File Distribution & Download Failures (MEDIUM)
- Mitigation: Hugging Face + GitHub hosting, resume capability, SHA256 verification

### RISK-005: Browser Viewer Compatibility (LOW)
- Mitigation: Graceful fallback, THREE.js well-supported

### RISK-006: User Expectation vs Reality (MEDIUM)
- Mitigation: Clear documentation, Phase 2 upgrade path (Shap-E)

### RISK-007: ONNX Model Download at First Run (MEDIUM)
- Mitigation: Pre-download option, progress bar, Docker image

### RISK-008: Eiffel Library Integration Complexity (MEDIUM)
- Mitigation: Phased implementation, FFI reference patterns

---

## Success Metrics (Phase 1)

1. **Functional Completeness:**
   - Generate valid 3D mesh from any text prompt < 120s on RTX 5070 Ti
   - Generated mesh passes Blender validation (manifold)
   - Browser viewer loads and renders GLB correctly
   - 10+ diverse test prompts work without crashes

2. **Performance:**
   - End-to-end time: 30-120 seconds nominal case
   - Peak memory: < 14GB on 16GB systems
   - Inference time variance < 20% between runs

3. **Quality:**
   - Mesh visual quality matches prompt concept
   - No self-intersecting triangles
   - Normal vectors properly oriented
   - File sizes reasonable (< 50MB typical)

4. **User Satisfaction:**
   - NPS > 0 (people recommend to others)
   - Issue resolution time < 1 week
   - User feedback positive on ease of use

---

**Document Status:** REQUIREMENTS PARSED, ready for DOMAIN ANALYSIS
