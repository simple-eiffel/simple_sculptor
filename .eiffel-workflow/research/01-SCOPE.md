# SCOPE: simple_sculptor Library

## Problem Statement

**Challenge:** Generate 3D geometry models directly from natural language text prompts, entirely locally without cloud dependencies or Python runtime overhead.

Current landscape:
- Cloud-first solutions (OpenAI API, Zoo) require internet connectivity
- Python-dependent tools (ComfyUI) require Python runtime at generation time
- GPU inference frameworks (TensorFlow, PyTorch) are heavyweight

**simple_sculptor Goal:** Bring text-to-3D generation into the Simple Eiffel ecosystem as a pure Eiffel+C++ library with local GPU inference capability.

## Users and Use Cases

### Primary Users
1. **3D Designers & CAD Professionals**
   - Need rapid iteration: text prompt → rendered 3D preview
   - Want offline-capable workflows (no cloud requirement)
   - Examples: product designers, engineers, architects

2. **Artists & Creative Technologists**
   - Prompt-driven 3D asset generation for games, VFX, AR/VR
   - Local control over generation parameters
   - Examples: game devs, VFX studios, AR app creators

3. **Hardware Engineers**
   - Generate geometry for mechanical parts validation
   - Integrate into design review pipelines
   - Example: integration with KittyCAD's modeling-app architecture

4. **Researchers**
   - Study text-to-3D generation locally
   - Benchmark different models (Point-E, Shap-E, TRELLIS)
   - Contribute geometry conversion improvements

### Use Case Examples
- "Create a vintage leather armchair" → GLB model rendered in browser
- "Red racing helmet, aerodynamic shape" → Export to STL for 3D printing
- "Geometric vase with wave pattern" → Interactive THREE.js viewer
- Batch generation: 100 prompts → 100 GLB files for game asset pipeline

## Success Criteria

### Functional Success
- [x] Accept text prompts via CLI and programmatic API
- [x] Generate 3D point clouds within 30-120 seconds on modern GPU (RTX 5070 Ti)
- [x] Convert point clouds to proper triangle meshes with vertex normals
- [x] Export to standard formats (GLB, OBJ, STL, PLY)
- [x] Render models in browser via local web server + THREE.js viewer
- [x] Support interactive mesh inspection and screenshot export

### Non-Functional Success
- [x] **Fully Local:** No cloud calls, no external API dependencies
- [x] **Performance:** Inference time 30-120 seconds (dependent on GPU)
- [x] **SCOOP Compatible:** Architecture supports concurrent geometry processing
- [x] **C++/Eiffel Native:** Direct ONNX Runtime integration, no Python wrapper
- [x] **Memory Efficient:** Fit within 16GB VRAM during inference + conversion

## Constraints

### Hard Constraints
1. **No Cloud Dependency:** All inference must run locally on user's GPU
2. **Pure Eiffel/C++:** No Python runtime required (Python can be build-time only)
3. **No Separate Runtime:** Generated models must be viewable offline
4. **Local GPU Only:** Designed for NVIDIA CUDA (RTX series) initially
5. **Single File Deployment:** The tool should be a standalone executable + model files

### Soft Constraints
1. Model files (~4-8GB) must be downloadable separately (distribution challenge)
2. Browser viewing requires modern browser (Chrome, Firefox, Safari 15+)
3. First implementation uses Point-E (less advanced than Shap-E, but proven)

## Technical Assumptions to Validate

| Assumption | Risk | Validation Plan |
|-----------|------|-----------------|
| Point-E ONNX models exist and perform acceptably | MEDIUM | Download official models, test inference quality |
| ONNX Runtime C++ API sufficient for Point-E inference | MEDIUM | Prototype ONNX Runtime wrapper with sample model |
| OpenVDB can mesh point clouds to production quality | MEDIUM | Benchmark OpenVDB meshing vs libigl vs custom SDF approach |
| Single GPU (16GB VRAM) can hold Point-E + working set | MEDIUM | Profile memory during inference (worst case: Shap-E models) |
| THREE.js adequate for real-time 3D browser viewing | LOW | Confirmed by industry adoption (Sketchfab, Babylon.js competitor) |
| ONNX model files can be distributed as separate downloads | MEDIUM | Research licensing, file sizes, hosting strategy |
| Inference times acceptable to users (30-120s) | MEDIUM | Set expectations, measure with actual hardware |

## Deliverables (Phased)

### Phase 1 (MVP): Text-to-Point-Cloud
- Point-E v1 model integration via ONNX Runtime
- Basic CLI: `simple_sculptor generate --prompt "a cat" --output model.glb`
- Point cloud → triangle mesh conversion (OpenVDB)
- GLB export with basic PBR materials
- Simple THREE.js viewer in local web server

### Phase 2 (Enhanced): Shap-E & Advanced Rendering
- Shap-E model support (better mesh quality)
- Enhanced material properties (metallic, roughness, normals)
- OBJ, STL, PLY export options
- Interactive material editor in viewer
- Screenshot/animation export

### Phase 3 (Hardening): Production Integration
- Batch processing mode for asset pipelines
- KittyCAD integration (geometry engine interop)
- SCOOP task pool for multi-prompt generation
- Model caching and optimization
- Complete test coverage

## Ecosystem Integration Points

### simple_* Libraries Used
- **simple_uuid:** Model and job identifiers
- **simple_json:** Configuration and metadata export
- **simple_web_server:** LOCAL web server for THREE.js viewer
- **simple_thread:** SCOOP compatibility (concurrent generation)
- **simple_sdf:** Potential SDF export format

### External Dependencies
- **ONNX Runtime C++ API:** Inference engine (Microsoft, permissive license)
- **OpenVDB:** Mesh generation from point clouds (DreamWorks, permissive)
- **THREE.js:** Browser rendering (MIT licensed, CDN-based)
- **zlib/libpng:** Image encoding for Point-E intermediate outputs

### Reference Implementations
- **KittyCAD modeling-app:** Geometry pipeline + Vulkan rendering pattern
- **OpenAI Point-E repo:** Model architecture, licensing, known issues
- **Shap-E repo:** NeRF-based generation (Phase 2 reference)

## Risk Areas Needing Early Investigation

1. **ONNX Runtime Stability:** Does Point-E export convert cleanly to ONNX format?
2. **Mesh Quality:** Will OpenVDB produce print-ready meshes from noisy point clouds?
3. **VRAM Fragmentation:** Can we manage memory safely during point→mesh conversion?
4. **Model Distribution:** How to host 5-8GB model files securely/reliably?
5. **Quality Perception:** Will users accept Point-E output or demand Shap-E immediately?

## Success Measurement

- **User Feedback:** "I can generate a usable 3D model from text in < 2 minutes locally"
- **Integration:** KittyCAD can consume simple_sculptor GLB output in modeling-app
- **Quality Metrics:** Generated meshes pass Blender validation (manifold, no self-intersections)
- **Performance:** End-to-end pipeline 30-120s on RTX 5070 Ti with typical prompt
- **Adoption:** 5+ teams using simple_sculptor in production workflows

## Out of Scope (Phase 1)

- Real-time interactive generation (too slow for UI)
- Video/animation generation
- Texture synthesis (Point-E outputs geometry only)
- Multi-GPU distribution
- AMD/Intel GPU support (CUDA-only, Phase 2+)
- Material parameter editing pre-generation
- API-based cloud version (contradicts "local-first" goal)

---

**Document Status:** Research Phase, READY FOR LANDSCAPE ANALYSIS
