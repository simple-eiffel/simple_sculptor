# LANDSCAPE: Text-to-3D Generation Ecosystem

## Existing Solutions & Competitive Analysis

### 1. OpenAI Point-E
**Status:** Released December 2022, stable, actively referenced
**Link:** https://github.com/openai/point-e / https://openai.com/index/point-e/

**Architecture:**
- Two-stage diffusion model: text → image → point cloud
- First stage: Text-to-image diffusion model (understands text)
- Second stage: Image-to-3D diffusion model (converts 2D view to 3D point cloud)
- Output: 3D point cloud (sparse, ~1M points)

**Characteristics:**
- Single GPU inference: 1-2 minutes on consumer NVIDIA GPU
- Point cloud output (not mesh) → requires post-processing
- Open source with permissive license
- No Python at runtime possible (run model conversion offline)
- Proven stable for production use

**Advantage for simple_sculptor:** Native compatibility with ONNX export, simplest architecture for MVP

### 2. OpenAI Shap-E
**Status:** Released May 2023, mature, more advanced than Point-E
**Link:** https://github.com/openai/shap-e / https://huggingface.co/openai/shap-e

**Architecture:**
- Encoder-based approach: Maps 3D assets to implicit function parameters
- Diffusion model trained on encoded 3D representations
- Output: Implicit function parameters that directly generate 3D geometry
- Can generate: NeRF, mesh, or 3D Gaussians depending on configuration

**Characteristics:**
- Better mesh quality than Point-E (higher geometric fidelity)
- ~30-60 seconds inference on modern GPU
- Runs fully locally, no API key needed
- Supports both text and image conditioning
- More memory-intensive than Point-E

**Advantage for simple_sculptor:** Phase 2 upgrade path; better quality output for production use

### 3. Microsoft TRELLIS
**Status:** CVPR 2025 Spotlight (very recent), state-of-the-art
**Link:** https://github.com/microsoft/TRELLIS / https://microsoft.github.io/TRELLIS/

**Architecture:**
- Structured LATent (SLAT) representation for unified 3D generation
- Rectified Flow Transformers for fast generation
- Supports multiple output formats: NeRF, 3D Gaussians, meshes
- Up to 2 billion parameters

**Characteristics:**
- Generates high-quality 3D geometry and appearance
- Recommended pipeline: text → text-to-image (FLUX) → TRELLIS-image
- Direct mesh output (no post-processing needed)
- Latest research (2025), less proven for production
- Heavier compute requirements

**Assessment:** Too new for MVP; consider Phase 2+ after validation

### 4. LGM (Large Multi-View Gaussian Model)
**Status:** ECCV 2024 Oral, emerging standard
**Link:** https://github.com/3DTopia/LGM / https://huggingface.co/ashawkey/LGM

**Architecture:**
- Multi-view Gaussian representation
- Input: text prompt or single image → generates multi-view synthesis
- Asymmetric U-Net backbone operating on multi-view images
- Output: 3D Gaussian Splatting representation

**Characteristics:**
- 5-second inference for high-resolution 3D generation
- Trained on ~80K Objaverse dataset
- Gaussians must be converted to mesh for export
- Recently published, good community support

**Assessment:** Strong alternative to Point-E; similar timeline, comparable quality

### 5. DreamFusion & Variants
**Status:** Original 2022, multiple improvements in 2024
**Link:** https://dreamfusion3d.github.io / https://github.com/ashawkey/stable-dreamfusion

**Architecture:**
- Optimizes a NeRF via gradient descent using 2D diffusion as prior
- Text → random NeRF → optimized via CLIP/diffusion guidance
- Slow: generates 3D through iterative refinement

**Characteristics:**
- Very slow (hours on GPU)
- High quality results (photorealistic)
- Solves Janus problem better than earlier methods
- Variants: DreamFlow, DITTO-NeRF, Tactile DreamFusion (2024)

**Assessment:** Too slow for interactive use; good reference for Phase 3 quality improvements

### 6. Zoo (Cloud-First)
**Status:** Commercial offering from KittyCAD ecosystem
**Link:** https://kittycad.io/zoo

**Model:** API-based, uses geometry engine
**Characteristics:**
- Cloud-dependent (violates simple_sculptor constraint)
- Professional integration with KittyCAD modeling-app
- Not applicable for "local-first" approach

## Eiffel Ecosystem Compatibility Assessment

### Existing Libraries for Geometry & Rendering

#### simple_vulkan / simple_shaderc
**Status:** Available in ecosystem
**Applicability:**
- Could replace THREE.js for native 3D rendering (vs browser)
- KittyCAD uses Vulkan for geometry engine
- Browser viewer preferred for Phase 1 (web accessibility)
- Consider for Phase 2 native desktop viewer

#### simple_sdf
**Status:** Available in ecosystem
**Applicability:**
- SDF (Signed Distance Field) output format for generated geometry
- Point cloud → SDF conversion as alternative to mesh
- Lower file size than triangle meshes
- Consider Phase 2 feature: `--format sdf`

#### simple_web_server
**Status:** Core library
**Applicability:**
- Host the THREE.js viewer locally
- Serve generated GLB files to browser
- Handle WebSocket connections for interactive features
- **CRITICAL DEPENDENCY** for MVP

#### simple_uuid, simple_json, simple_thread
**Status:** Standard ecosystem libraries
**Applicability:**
- UUID: Job/model identifiers for batch processing
- JSON: Metadata export, configuration files
- Thread: SCOOP compatibility for concurrent generation

### Missing / Needed Library Enhancements

1. **ONNX Runtime Wrapper**
   - Currently: No simple_onnx library exists
   - Decision: Build inline C++ integration via simple_sculpt itself
   - Pattern: Similar to other inline C++ in simple_* libs

2. **Mesh Conversion Library**
   - Point cloud → triangle mesh needs new code
   - Options: OpenVDB integration, libigl, custom SDF rasterization
   - Recommendation: Phase 1 uses OpenVDB directly

## C++ ONNX Inference Solutions

### ONNX Runtime (Recommendation)
**Provider:** Microsoft, Apache 2.0 License
**Link:** https://github.com/microsoft/onnxruntime / https://onnxruntime.ai/docs/

**Features:**
- Multi-platform: Windows, Linux, macOS
- GPU support: CUDA, TensorRT, ROCm, CoreML
- C++ API fully documented
- NuGet package available for Windows
- Production-proven (Microsoft, Meta, Google use it)

**Execution Providers (GPU):**
- **CUDA EP:** Standard NVIDIA GPU support (requires CUDA 11.8+ / 12.x)
- **TensorRT EP:** NVIDIA TensorRT optimization (Ampere+ architectures)
- **ROCm EP:** AMD GPU support (future consideration)

**Advantages:**
1. Universal format support (not vendor-locked)
2. Model optimization tooling
3. Robust error handling
4. Cross-platform build straightforward
5. Mature ecosystem (tons of documentation)

**Dependencies:**
- CUDA 11.8+ or 12.x (matched with cuDNN)
- Visual Studio 2019+ for Windows builds
- ~400MB installed (vs 1GB+ for TensorFlow/PyTorch)

### Alternative: TensorRT
**Provider:** NVIDIA
**Applicability:** Limited to NVIDIA Ampere+ (RTX 30xx and newer)
- More optimized than ONNX CUDA EP
- Requires model conversion/optimization
- Steeper learning curve
- Better for production performance-critical apps

**Verdict:** ONNX Runtime recommended for MVP (broader hardware support)

### Alternative: ncnn
**Provider:** Tencent, highly optimized
**Applicability:** Mobile-first (ARM optimization)
- Point-E/Shap-E not well-tested with ncnn
- Heavier optimization overhead
- Not recommended for desktop GPU workload

## Model File Distribution & Licensing

### Point-E Models
**Licensing:** OpenAI Models License (research + commercial)
**Availability:** Hugging Face, GitHub releases
**Size:** ~1.5GB (text-to-image stage) + ~2GB (image-to-3D stage) = ~3.5GB total
**Distribution:** Must be downloaded separately; not embedded in executable

### Shap-E Models
**Licensing:** OpenAI Models License
**Size:** ~4-6GB (larger than Point-E)
**Distribution:** Same as Point-E

### TRELLIS Models
**Licensing:** MIT (very permissive for 2B models)
**Size:** ~4GB for primary model
**Availability:** Hugging Face, GitHub

## Reference Architecture: KittyCAD Modeling-App

**Link:** https://github.com/KittyCAD/modeling-app

**Key Architectural Patterns:**
1. **GPU-First Geometry Engine:** All 3D computation on Vulkan
2. **Video Stream Protocol:** UI receives rendered frames via WebSocket, sends commands
3. **Parallel Rendering:** GPU parallelization for real-time performance
4. **Hybrid Interaction:** Code-based (KCL) + point-and-click UI
5. **Technology Stack:** React UI + Rust WASM + Vulkan geometry engine

**Relevance to simple_sculptor:**
- Model for how to structure geometry generation pipeline
- Potential future integration: simple_sculptor generates geometry → KittyCAD refines
- Browser-to-backend communication pattern (WebSocket)
- GPU compute separation from UI

## Comparison Matrix

| Aspect | Point-E | Shap-E | TRELLIS | LGM | DreamFusion |
|--------|---------|--------|---------|-----|------------|
| **Status** | Stable 2022 | Stable 2023 | CVPR'25 New | ECCV'24 | Academic |
| **Inference Speed** | 60-120s | 30-60s | 20-40s | 5s | Hours |
| **Output Quality** | Good | Excellent | SOTA | High | SOTA |
| **ONNX Support** | Yes, proven | Partial | Limited | No | No |
| **Mesh Direct?** | No (post-process) | Yes | Yes | No (Gaussians) | No (NeRF) |
| **Memory (16GB)** | Fits | Fits | Fits | Fits | Fits |
| **Production Ready** | Yes | Yes | Beta | Good | Research |
| **Local Only** | Yes | Yes | Yes | Yes | Yes |
| **Popularity** | High | High | Rising | Growing | Reference |

## KittyCAD & Geometry Integration

**Modeling-App Architecture Insights:**
- Uses **Vulkan** (not WebGL) for geometry engine
- **WebSocket** protocol for UI ↔ Engine communication
- **Frames as video stream:** Real-time ~60fps rendering
- **KCL Language:** Parametric geometry commands

**Integration Opportunities:**
1. Phase 2: Export simple_sculptor output → KittyCAD-compatible format
2. Phase 3: Bi-directional: KittyCAD geometry → simple_sculptor refinement
3. Vulkan native viewer alternative to THREE.js (Phase 3)

## Risk Assessment: Technology Choices

| Choice | Risk Level | Mitigation |
|--------|-----------|-----------|
| Point-E as MVP model | LOW | Proven stable, widely adopted, fallback to Shap-E known |
| ONNX Runtime C++ | LOW | Mature Microsoft product, extensive documentation |
| OpenVDB for meshing | MEDIUM | Proven for VFX, document expected output quality |
| THREE.js browser viewer | LOW | Industry standard, tons of examples |
| Model file distribution | MEDIUM | Plan download/caching strategy early |
| GPU VRAM management | MEDIUM | Profile early with actual hardware |

## Recommendation

**For simple_sculptor MVP:**
1. **Model:** Point-E (stable, proven, ONNX-compatible)
2. **Inference:** ONNX Runtime with CUDA EP
3. **Meshing:** OpenVDB (proven, good quality)
4. **Export:** GLB primary, OBJ/STL in Phase 1
5. **Viewer:** THREE.js in browser via simple_web_server
6. **Phase 2:** Add Shap-E support for quality increase

**Alternative Strategy (if ONNX Point-E unavailable):**
- Switch to LGM (ECCV'24, Hugging Face integration exists)
- Gaussian → mesh conversion more complex but documented

---

**Document Status:** LANDSCAPE COMPLETE, ready for REQUIREMENTS definition
