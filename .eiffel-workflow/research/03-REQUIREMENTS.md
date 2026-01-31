# REQUIREMENTS: simple_sculptor Library

## Functional Requirements

### FR-001: Text Prompt Input
**Description:** Accept natural language text prompts from user

**Specification:**
- CLI: `simple_sculptor generate --prompt "a blue ceramic vase"`
- Programmatic API: `sculptor.generate(prompt: STRING): GENERATION_JOB`
- Prompt length: 10-500 characters (reasonable descriptions)
- Character encoding: UTF-8
- Validation: Reject empty or whitespace-only prompts

**Success Criteria:**
- User can specify prompt via command line
- API accepts STRING input without crashes
- Clear error messages for invalid input

---

### FR-002: 3D Point Cloud Generation via ONNX Inference
**Description:** Execute Point-E model inference to generate 3D point cloud from prompt

**Specification:**
- Model: OpenAI Point-E (text-to-image + image-to-3D stages)
- Runtime: ONNX Runtime with CUDA Execution Provider
- Input: Text embedding (derived from prompt)
- Output: Point cloud (1M+ points in 3D space with coordinates)
- GPU Memory: Must fit in 16GB VRAM
- Timeout: 120 seconds max per inference

**Performance Requirements:**
- RTX 5070 Ti: 30-60 seconds inference time
- RTX 4090: 15-30 seconds inference time
- RTX 4070: 45-90 seconds inference time

**Success Criteria:**
- Point cloud generated with > 500K points
- All points have (x, y, z) coordinates
- Inference completes within timeout
- GPU memory not exceeded
- No CUDA out-of-memory crashes

---

### FR-003: Point Cloud → Mesh Conversion with Normals
**Description:** Convert sparse point cloud to solid triangle mesh with vertex normals

**Specification:**
- Input: Point cloud (1M+ points, sparse distribution)
- Algorithm: OpenVDB point-to-mesh conversion
- Output: Triangle mesh with:
  - Vertex positions (x, y, z)
  - Triangle indices (face definitions)
  - Vertex normals (shading normals)
  - UV coordinates (optional, Phase 2)
- Normal Calculation: Per-vertex normals computed from adjacent faces
- Manifold Output: Mesh should be closed/manifold (no holes, no self-intersections)
- Triangle Optimization: Remove degenerate triangles (area < epsilon)

**Quality Targets:**
- No self-intersecting triangles
- Manifold topology (watertight mesh)
- Reasonable normal distributions (no inverted faces)
- Reasonable triangle density (1M-5M triangles for GLB size optimization)

**Success Criteria:**
- Output mesh passes Blender validation (manifold check)
- Mesh visually represents original prompt concept
- Normal vectors point outward (for lighting)
- File size reasonable (< 100MB uncompressed)

---

### FR-004: Export Formats (GLB/GLTF primary)
**Description:** Export generated mesh to standard interchange formats

**Specification:**

#### GLB (Primary - Phase 1)
- **Format:** GL Transmission Format Binary
- **Contents:**
  - Triangle mesh geometry
  - Vertex normals
  - Basic PBR material (metallic=0.5, roughness=0.7)
  - Center model at origin
  - Unit scale (1m = 1 unit)
- **Compression:** Draco compression optional (Phase 2)
- **CLI:** `--format glb`
- **File Size Target:** < 50MB for typical model

#### OBJ (Phase 1 Support)
- **Format:** Wavefront OBJ + associated MTL
- **Contents:** Geometry + basic material definition
- **CLI:** `--format obj`
- **Limitation:** No PBR materials (standard OBJ limitation)

#### STL (Phase 1 Support)
- **Format:** Stereolithography (ASCII or Binary)
- **Use Case:** 3D printing workflows
- **CLI:** `--format stl`
- **Limitation:** Geometry only, no materials or colors

#### PLY (Phase 2)
- **Format:** Polygon File Format
- **Contents:** Full point cloud or mesh with attributes
- **CLI:** `--format ply`

**Success Criteria:**
- GLB exports load in THREE.js, Babylon.js, Blender, Unity
- OBJ/STL exports work in standard CAD software
- File formats verified with Blender import/export
- Metadata preserved (model name, generation timestamp)

---

### FR-005: Interactive Web Viewer (LOCAL SERVER)
**Description:** Launch local web server with THREE.js-based 3D model viewer

**Specification:**
- **CLI Command:** `simple_sculptor view model.glb --port 8080`
- **Server Technology:** simple_web_server (Eiffel ecosystem)
- **Frontend:** HTML + THREE.js + THREE.js GLTFLoader
- **Functionality:**
  - Load and display GLB/GLTF models
  - Orbit camera controls (mouse drag rotate, scroll zoom)
  - Pan controls (middle-click or SHIFT+drag)
  - Full-screen toggle (F key)
  - Model info display (triangle count, file size, bounds)
  - Lighting: Three-point lighting + environment map
  - Wireframe mode toggle (W key)
  - Reset view (HOME key)

- **UI Features:**
  - Auto-rotate toggle
  - Background color selector (dark/light)
  - Download current view as PNG screenshot
  - Display generation metadata (prompt, timestamp, GPU time)

- **Browser Compatibility:** Chrome 90+, Firefox 88+, Safari 15+

**Success Criteria:**
- Viewer launches automatically after generation
- Model fully visible with good camera framing
- Controls responsive and intuitive
- Screenshots work correctly
- No WebGL errors in console

---

### FR-006: Export Options & Pipeline Integration
**Description:** Support batch processing and downstream tool integration

**Specification:**

#### Batch Mode
- **Input:** File with line-separated prompts
- **CLI:** `simple_sculptor batch prompts.txt --output-dir ./models`
- **Concurrency:** Process multiple prompts (SCOOP-based, configurable parallelism)
- **Output:** Numbered GLB files (model_001.glb, model_002.glb, ...)
- **Metadata:** CSV index file mapping prompt → output file

#### Screenshot Export
- **CLI:** `simple_sculptor generate --prompt "..." --screenshot out.png`
- **Output:** PNG image from default camera angle
- **Size:** 1920x1080 pixels
- **Timeout:** Must complete within 5 seconds (viewer overhead)

#### Metadata JSON Export
- **CLI:** `simple_sculptor generate --prompt "..." --metadata meta.json`
- **Contents:**
  ```json
  {
    "prompt": "a blue ceramic vase",
    "timestamp": "2025-01-31T10:30:00Z",
    "gpu_time_ms": 45000,
    "model_name": "model_001",
    "statistics": {
      "point_count": 1048576,
      "triangle_count": 523412,
      "bounding_box": {"min": [-0.5, -0.5, -0.5], "max": [0.5, 0.5, 0.5]}
    }
  }
  ```

**Success Criteria:**
- Batch processing completes without errors
- Output files properly indexed
- Screenshots are correct PNG format
- Metadata JSON is valid and useful for downstream tools

---

## Non-Functional Requirements

### NFR-001: Performance (GPU Inference)
**Requirement:** Generation completes in user-acceptable timeframe

**Specification:**
- Target GPU: NVIDIA RTX 5070 Ti
- Target Time: 30-120 seconds end-to-end (inference + meshing + export)
- Breakdown:
  - Point-E inference: 45-60 seconds
  - Mesh conversion: 5-15 seconds
  - Export: 1-5 seconds
  - Total: 51-80 seconds nominal case

- Acceptable Range:
  - Consumer RTX 4070: 60-120 seconds
  - High-end RTX 4090: 20-45 seconds

- Peak Memory: < 14GB VRAM (leave 2GB headroom on 16GB systems)

**Success Criteria:**
- Measured on actual hardware, not estimates
- No CUDA OOM errors on 16GB VRAM with typical prompts
- User can specify timeout (abort if exceeds threshold)

---

### NFR-002: Locality & Offline Capability
**Requirement:** Tool operates entirely locally without external service calls

**Specification:**
- **No API Calls:** Zero internet connectivity required after model download
- **No Cloud:** No communication with external services
- **No Python Runtime:** Python not needed for inference (only model conversion, offline)
- **Model Files:** Downloaded once, cached locally (~3.5GB for Point-E)
- **Reproducibility:** Same prompt always generates similar geometry (deterministic seed option)

**Success Criteria:**
- Tool works on isolated/offline machine
- No network traffic during `generate` command
- All dependencies bundled or easily installable locally
- Model cache location configurable (default: ~/.simple_sculptor/models/)

---

### NFR-003: C++ & Eiffel Native Integration
**Requirement:** Library written in Eiffel with C++ integration for inference

**Specification:**
- **Core Library:** 100% Eiffel (no Python, no Node.js)
- **Inference Runtime:** C++ via inline C/C++ integration
  - ONNX Runtime C++ API
  - OpenVDB C++ library
  - Simple_web_server Eiffel bindings

- **Design by Contract:** All Eiffel classes use DBC (preconditions, postconditions, invariants)
- **Void Safety:** All code void-safe (no Void references except after explicit checks)
- **SCOOP Compatible:** Concurrency-ready architecture for batch processing

**Success Criteria:**
- Compiles with EiffelStudio 25.02 with `-void_safety all`
- Passes DBC checking at runtime
- SCOOP features usable for parallel generation
- Clear Eiffel/C++ boundary (FFI wrapper module)

---

### NFR-004: Browser-Based Viewing (Offline-Capable)
**Requirement:** Generated models viewable in web browser without external CDN dependency

**Specification:**
- **Technology:** THREE.js (MIT license, free to include)
- **Delivery:** Self-hosted from simple_web_server
- **Asset Loading:** All JavaScript/CSS bundled with library
- **Fallback:** If web browser unavailable, generate files only (no viewer)
- **No Dependencies:** Viewer works without internet (all assets local)

**Success Criteria:**
- Viewer loads in < 1 second after generation
- Works in Chrome, Firefox, Safari (latest versions)
- THREE.js library bundled (not CDN-dependent)
- Responsive to window resize

---

### NFR-005: Scalability & Concurrency
**Requirement:** Support batch generation with efficient resource utilization

**Specification:**
- **Batch Processing:** Process multiple prompts via SCOOP task pool
- **GPU Sharing:** Single GPU, sequential inference (not parallel; GPUs don't share well)
- **Memory Management:** Clean up between generations (avoid memory leaks)
- **Timeout Handling:** Abort long-running generations gracefully
- **Error Recovery:** Failed generation doesn't crash batch process

**Success Criteria:**
- Batch of 10 prompts processes sequentially without crashes
- Memory stable across 50+ generations (no accumulation)
- Clear logs for successful/failed generations
- User can cancel in-progress batch (Ctrl+C handling)

---

### NFR-006: Platform & Compatibility
**Requirement:** Work on Windows, Linux, and macOS (in that priority order)

**Specification:**
- **Phase 1 (MVP):** Windows + NVIDIA CUDA (RTX series)
- **Phase 2:** Linux support (Ubuntu 20.04+)
- **Phase 3:** macOS (Metal GPU support)
- **Minimum NVIDIA Driver:** 515.x or later
- **CUDA Version:** 11.8+ or 12.x
- **EiffelStudio:** 25.02 (standard for simple_* ecosystem)

**Success Criteria:**
- Builds cleanly on Windows + Visual Studio
- No platform-specific hardcoded paths
- CI/CD verified on both Windows and Linux

---

## User Stories & Acceptance Tests

### User Story 1: Artist Generates Asset
**As an** indie game developer
**I want to** generate a 3D model from a text description
**So that** I can rapidly prototype game assets

**Acceptance Tests:**
```
Given: simple_sculptor installed with Point-E models
When: I run `simple_sculptor generate --prompt "wooden treasure chest"`
Then: A GLB file is created in current directory within 120 seconds
And: I can open it in the web viewer
And: The model visually resembles a treasure chest
```

### User Story 2: Batch Asset Pipeline
**As a** level designer
**I want to** generate 50 different environmental objects from a prompt list
**So that** I can build a diverse game environment quickly

**Acceptance Tests:**
```
Given: A file "prompts.txt" with 50 object descriptions
When: I run `simple_sculptor batch prompts.txt --output-dir assets/`
Then: 50 GLB files are created (model_001.glb through model_050.glb)
And: Index file "generation_log.csv" created with prompt → filename mapping
And: All files are ready for import into game engine
```

### User Story 3: Export for 3D Printing
**As a** product designer
**I want to** generate a model and export it as STL for 3D printing
**So that** I can validate designs before manufacturing

**Acceptance Tests:**
```
Given: simple_sculptor with STL export support
When: I run `simple_sculptor generate --prompt "coffee mug handle" --format stl`
Then: An STL file is created
And: The mesh is manifold (closed, no self-intersections)
And: I can open it in Fusion 360 or Cura for print preparation
```

### User Story 4: Integration with KittyCAD
**As a** hardware engineer
**I want to** generate a mechanical part and refine it in KittyCAD
**So that** I can combine AI-generated geometry with precise parametric design

**Acceptance Tests:**
```
Given: simple_sculptor generates GLB for "ball bearing housing"
When: I import the GLB into KittyCAD modeling-app
Then: The geometry loads correctly with proper scale
And: I can edit/refine the geometry in KittyCAD
And: Refined model can be exported back to STEP for CAD tools
```

---

## Constraints & Dependencies

### Input Constraints
- Prompt length: 10-500 characters
- Encoding: UTF-8 only
- No special characters that break ONNX text tokenizer

### Output Constraints
- GLB file: < 50MB (typical)
- Triangle count: 500K-5M range (quality ↔ file size tradeoff)
- Coordinate system: Right-handed (standard OpenGL)
- Texture resolution: None in Phase 1 (geometry only)

### Dependency Constraints
- ONNX Runtime: Must compile against v1.17+
- CUDA: 11.8, 12.0, 12.1, 12.2 officially supported
- Eiffel: Must compile void-safe in EiffelStudio 25.02
- OpenVDB: Must build with no external deps (bundled or simple compile)

### Licensing Constraints
- Point-E model: OpenAI Models License (allows research + commercial)
- ONNX Runtime: Apache 2.0 (permissive, commercial-friendly)
- OpenVDB: DreamWorks License (permissive, VFX industry standard)
- THREE.js: MIT (free, can be bundled)
- simple_sculptor: Must match simple_eiffel licensing (Apache 2.0 assumed)

---

## Out of Scope (Phase 1)

- **Real-time generation:** Cannot update model while user waits (too slow)
- **Material synthesis:** No colors/textures generated (Point-E outputs geometry only)
- **Animation:** No rigging or skeletal animation
- **Texture mapping:** UV coordinates generated but no texture image synthesis
- **Physics simulation:** No collision/physics validation
- **Multi-GPU:** Single GPU only
- **AMD/Intel GPU:** NVIDIA CUDA only (Phase 2+)
- **Web API:** No HTTP endpoint (local command-line only)
- **Model fine-tuning:** Cannot retrain or adjust model weights

---

**Document Status:** REQUIREMENTS LOCKED, ready for DECISIONS phase
