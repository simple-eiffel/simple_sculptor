# REFERENCES: Complete Source Documentation

## Text-to-3D Models

### Point-E (OpenAI, 2022)
- **Official Paper:** https://openai.com/index/point-e/
- **GitHub Repository:** https://github.com/openai/point-e
- **Blog Post:** "Point-E: A system for generating 3D point clouds from complex prompts"
- **Status:** Stable, production-proven
- **Model Downloads:** https://huggingface.co/openai/point-e (includes ONNX exports)
- **Key Reference:**
  - "Generating 3D Models from Text Prompts" - OpenAI Blog
  - Reference: https://aibusiness.com/ml/openai-s-point-e-generates-3d-models-from-text
  - Reference: https://deepgram.com/learn/what-you-need-to-know-about-openai-s-new-3d-model-making-ai-point-e

### Shap-E (OpenAI, 2023)
- **Official GitHub:** https://github.com/openai/shap-e
- **Paper:** "Shap-E: Generating Conditional 3D Implicit Functions" (2023)
- **Model Hub:** https://huggingface.co/openai/shap-e
- **Status:** Stable, improved quality over Point-E
- **Resources:**
  - Reference: https://voicebot.ai/2023/05/08/openai-releases-new-text-to-3d-model-shap-e/
  - Reference: https://unite.ai/how-text-to-3d-ai-generation-works-meta-3d-gen-openai-shap-e-and-more/
  - Reference: https://www.tomshardware.com/news/openai-shap-e-creates-3d-models
  - Local Implementation: https://github.com/kedzkiest/shap-e-local

### TRELLIS (Microsoft, CVPR 2025)
- **Official GitHub:** https://github.com/microsoft/TRELLIS
- **Official Demo:** https://microsoft.github.io/TRELLIS/
- **Paper:** "Structured 3D Latents for Scalable and Versatile 3D Generation" (CVPR 2025 Spotlight)
- **TRELLIS.2:** https://microsoft.github.io/TRELLIS.2/ (Native Structured Latents v2)
- **Model Hub:** https://huggingface.co/microsoft/TRELLIS-text-xlarge / https://huggingface.co/microsoft/TRELLIS.2-4B
- **Status:** Cutting-edge, very recent (2025)
- **Availability:** NVIDIA NIM https://build.nvidia.com/microsoft/trellis/modelcard
- **Resources:**
  - Reference: https://clubwritter.medium.com/microsoft-trellis-changing-how-3d-assets-are-made-17e9c9bde884
  - Reference: https://www.vset3d.com/microsoft-trellis/

### LGM (Large Multi-View Gaussian Model, 2024)
- **Official GitHub:** https://github.com/3DTopia/LGM
- **Paper:** "LGM: Large Multi-View Gaussian Model for High-Resolution 3D Content Creation"
- **Publication:** ECCV 2024 Oral Presentation
- **Model Hub:** https://huggingface.co/ashawkey/LGM
- **Paper PDF:** https://www.ecva.net/papers/eccv_2024/papers_ECCV/papers/00465.pdf
- **Status:** Proven at ECCV 2024, high-quality, fast (5 seconds)
- **Resources:**
  - Reference: https://radiancefields.com/lgm-prompt-to-3d-using-gaussians

### DreamFusion & Variants (2022+)
- **Original DreamFusion:** https://dreamfusion3d.github.io/
- **Paper:** "DreamFusion: Text-to-3D using 2D Diffusion" https://arxiv.org/abs/2209.14988
- **Implementation (Stable Diffusion):** https://github.com/ashawkey/stable-dreamfusion
- **2024 Variants:**
  - DreamFlow: https://proceedings.iclr.cc/paper_files/paper/2024/file/57568e093cbe0a222de0334b36e83cf5-Paper-Conference.pdf
  - Comparison: https://datarootlabs.com/blog/text-to-3d-dreamfusion-vs-shape-e
- **Status:** Academic reference (slow but high quality)
- **Resources:**
  - Reference: https://www.louisbouchard.ai/dreamfusion/
  - Reference: https://www.deeplearning.ai/the-batch/how-dreamfusion-generates-3d-images-from-text/

---

## Inference & ML Infrastructure

### ONNX Runtime
- **Official GitHub:** https://github.com/microsoft/onnxruntime
- **Documentation:** https://onnxruntime.ai/
- **Installation Guide:** https://onnxruntime.ai/docs/install/
- **CUDA Execution Provider:** https://onnxruntime.ai/docs/execution-providers/CUDA-ExecutionProvider.html
- **TensorRT Execution Provider:** https://onnxruntime.ai/docs/execution-providers/TensorRTRTX-ExecutionProvider.html
- **Execution Providers:** https://onnxruntime.ai/docs/execution-providers/
- **Python GPU Guide:** https://huggingface.co/docs/optimum-onnx/onnxruntime/usage_guides/gpu
- **C++ Examples:** https://github.com/developer0hye/onnxruntime-cuda-cpp-example
- **C++ Tutorial:** https://jinscott.medium.com/onnx-runtime-on-c-67f69de9b95c
- **Status:** Production-ready, widely used
- **License:** Apache 2.0

### ONNX Format
- **Official:** https://onnx.ai/
- **Specification:** ONNX is an open standard for machine learning models
- **Model Zoo:** https://github.com/onnx/models

---

## Mesh Conversion & Geometry Processing

### OpenVDB
- **Official Website:** https://www.openvdb.org/
- **About:** https://www.openvdb.org/about/
- **Documentation:** https://www.openvdb.org/documentation/doxygen/
- **Tools:**
  - MeshToVolume: https://www.openvdb.org/documentation/doxygen/MeshToVolume_8h.html
  - VolumeToMesh: https://www.openvdb.org/documentation/doxygen/VolumeToMesh_8h_source.html
  - Cookbook/Examples: https://www.openvdb.org/documentation/doxygen/codeExamples.html
- **Latest Updates:** https://academicsoftwarefoundation.github.io/openvdb/changes.html
- **NVIDIA fVDB Integration:** https://www.aswf.io/blog/fvdb/
- **Discussion Forum:** https://groups.google.com/g/openvdb-forum
- **GitHub Discussions:**
  - Point cloud to mesh: https://github.com/AcademySoftwareFoundation/openvdb/discussions/1265
  - Mesh examples: https://github.com/AcademySoftwareFoundation/openvdb
- **Status:** Industry-standard (DreamWorks), active development
- **License:** Permissive (DreamWorks license)

### Alternative Mesh Libraries

#### libigl
- **GitHub:** https://github.com/libigl/libigl
- **Status:** Academic-proven, comprehensive
- **Approach:** Header-only, single-library solution
- **Use Case:** Alternative to OpenVDB for Phase 2 evaluation

#### Poisson Reconstruction
- **Academic Method:** Standard for mesh reconstruction from point clouds
- **Implementation:** Available in multiple libraries
- **Trade-off:** Slower than OpenVDB, requires parameter tuning

---

## 3D File Formats & Standards

### GLB/GLTF
- **Khronos Official:** https://www.khronos.org/gltf/
- **Wikipedia:** https://en.wikipedia.org/wiki/GlTF
- **Specification:** glTF 2.0 released as ISO/IEC 12113:2022 (July 2022)
- **Format Guide:** https://www.khronos.org/gltf/ ("JPEG of 3D")
- **Sketchfab Reference:** https://sketchfab.com/features/gltf
- **Blender Export:** https://docs.blender.org/manual/en/2.80/addons/io_scene_gltf2.html
- **Rhino Support:** http://docs.mcneel.com/rhino/8/help/en-us/fileio/gltf_import_export.htm
- **Draco Compression:** glTF extension for mesh compression
- **Tools:**
  - GLTF Viewers: Sketchfab, Babylon.js, Three.js
  - Export from Blender, Fusion 360, Maya, 3DS Max
- **Status:** Industry standard, widely supported
- **License:** Open standard (free)

### OBJ/MTL Format
- **History:** Wavefront OBJ (1988), still widely used
- **Use Cases:** Game engines, CAD software, 3D printing
- **Limitations:** No normals/colors native (use MTL companion file)
- **Advantages:** Universal compatibility, simple text format

### STL Format
- **Purpose:** 3D printing (stereolithography)
- **Variants:** ASCII (text), Binary (compact)
- **Limitations:** Geometry only, no appearance/material
- **Widespread:** Standard for 3D printing software/hardware
- **Reference:** https://en.wikipedia.org/wiki/STL_(file_format)

### PLY Format (Polygon File Format)
- **Origin:** Stanford University, 1994
- **Full Name:** "Stanford Triangle Format"
- **Flexibility:** Support custom vertex attributes (color, normals, texture coords)
- **Use Cases:** Academic research, point cloud processing
- **References:**
  - https://www.launcadental.com/blog/understanding-3d-model-file-formats-in-digital-dentistry-stl-vs-ply-vs-obj
  - https://www.medit.com/the-battle-of-file-formats-stl-vs-obj-vs-ply

### Comprehensive Format Comparison
- **KIRI Engine Guide:** https://www.kiriengine.app/blog/explained/3D-file-formats-what-are-they-and-which-one-to-choose
- **Digital Dentistry:** https://instituteofdigitaldentistry.com/cad-cam/understanding-stl-ply-obj-files-in-digital-dentistry
- **ConvertMesh Guide:** https://www.convertmesh.com/formats
- **Vivid Works 2025 Guide:** https://www.vividworks.com/blog/3d-model-formats-guide

---

## Browser 3D Rendering

### THREE.js
- **Official:** https://threejs.org/
- **GitHub:** https://github.com/mrdoob/three.js
- **Documentation:** https://threejs.org/docs/
- **GLTFLoader:** https://threejs.org/docs/pages/GLTFLoader.html
- **Tutorials:**
  - Loading GLB models: https://medium.com/@ertugrulyaman99/controlling-the-camera-and-loading-a-glb-model-with-three-js-65d0532cc61a
  - React + Three.js: https://medium.com/@kr4ckhe4d/loading-gltf-and-glb-models-in-reactjs-three-js-dcb3ac28231c
  - Interactive 3D Cards: https://tympanus.net/codrops/2025/05/31/building-interactive-3d-cards-in-webflow-with-three-js/
- **Forum:** https://discourse.threejs.org/
- **Status:** Industry standard, thousands of production sites
- **License:** MIT (free to include)

### Babylon.js (Alternative)
- **Official:** https://www.babylonjs.com/
- **Comparison with THREE.js:** https://medium.com/@avowed/which-is-easier-for-rendering-glb-models-three-js-or-babylon-js-bafdb46c9549
- **Status:** Comprehensive, similar capabilities to THREE.js
- **Note:** THREE.js preferred for viewer use case (simpler learning curve)

---

## KittyCAD & Modeling Architecture

### Modeling-App
- **GitHub:** https://github.com/KittyCAD/modeling-app
- **README:** https://github.com/KittyCAD/modeling-app/blob/main/README.md
- **Releases:** https://github.com/KittyCAD/modeling-app/releases
- **Official Website:** https://kittycad.io/ (Zoo Design Studio)
- **Technology Stack:**
  - UI: React, Headless UI, TailwindCSS, XState
  - Networking: WebSockets (TypeScript client)
  - Code Editor: CodeMirror + custom WASM LSP
  - Geometry Engine: Rust + WASM + Vulkan
- **Key Feature:** Video stream of 3D view from hosted geometry engine
- **Press Release:** https://www.prnewswire.com/news-releases/kittycad-announces-updated-api-with-highly-anticipated-geometry-engine-capabilities-301945685.html
- **News:** https://www.digitalengineering247.com/article/kittycad-updates-api-adds-geometry-engine/
- **Status:** Active development, production CAD tool
- **Relevance:** Reference architecture for geometry pipeline design

### KCL (KittyCAD Language)
- **Samples:** https://github.com/KittyCAD/kcl-samples
- **Parametric Geometry:** Code-based modeling language

---

## Eiffel Ecosystem References

### Simple Eiffel Libraries (Relevant)
These libraries will be integrated with simple_sculptor:

- **simple_uuid:** Model and job identifier generation
- **simple_json:** Configuration and metadata export
- **simple_web_server:** Local HTTP server for viewer
- **simple_thread:** SCOOP-compatible concurrency
- **simple_sdf:** Signed Distance Field export (Phase 2)
- **simple_vulkan:** Native 3D rendering alternative (Phase 3)
- **simple_shaderc:** Shader compilation support (Phase 3)

### Build Standards
- **Reference:** `/d/prod/reference_docs/briefings/BUILD_STANDARDS.md`
- **Covers:** Library selection, F_code finalization, binary placement
- **Critical for:** simple_sculptor library development

### Eiffel Expert Briefing
- **Reference:** `/d/prod/reference_docs/briefings/EIFFEL_EXPERT_BRIEFING.md`
- **Covers:** OOSC2 principles, DBC, void safety, SCOOP, language pitfalls
- **Critical for:** Design by Contract patterns, SCOOP concurrency

### EiffelStudio 25.02
- **Compiler:** Standard for Simple Eiffel ecosystem
- **Features:** Void-safe compilation, SCOOP support
- **Requirements:** Windows 10+ (for simple_sculptor on Windows)

---

## Local References (Non-Public)

### KittyCAD Modeling-App (Local Copy)
- **Path:** `/d/prod/_non-eiffel/modeling-app`
- **Content:** Reference for geometry pipeline architecture, Vulkan patterns
- **Use:** Study design patterns for GPU compute + UI interaction

### Vox Research Materials (Private)
- **Path:** `/d/priv/Vox/research/`
- **Content:** Proprietary research on 3D generation (if available)
- **Restricted:** Consult Larry for access

### Simple Eiffel Build Workspace
- **Path:** `/d/prod`
- **Content:** All 59+ simple_* libraries, build infrastructure
- **Use:** Reference implementations, build patterns

---

## Additional Resources

### Point-E Quality & Limitations
- **Blog:** "What Point-E does well and poorly"
- **Reference:** https://openai.com/index/point-e/ (limitations section)
- **Hacker News Discussion:** https://news.ycombinator.com/item?id=33109243

### Text-to-3D Comparison
- **Unite.AI Article:** https://www.unite.ai/how-text-to-3d-ai-generation-works-meta-3d-gen-openai-shap-e-and-more/
- **Comparative Analysis:** Point-E vs Shap-E vs TRELLIS vs LGM

### Mesh Processing Benchmarks
- **Google Scholar:** Search "point cloud to mesh reconstruction"
- **ArXiv:** Search "neural implicit functions 3D"

---

## Learning Resources for Implementation

### ONNX Runtime C++ Integration
- **Tutorial:** https://github.com/developer0hye/onnxruntime-cuda-cpp-example
- **Blog:** https://jinscott.medium.com/onnx-runtime-on-c-67f69de9b95c
- **Documentation:** https://onnxruntime.ai/docs/
- **GitHub Issues:** Common problems & solutions

### OpenVDB Integration
- **Cookbook:** https://www.openvdb.org/documentation/doxygen/codeExamples.html
- **Examples:** Point cloud → SDF → mesh workflow
- **Build Instructions:** Available in GitHub README

### THREE.js Web Viewer
- **Official Docs:** https://threejs.org/docs/
- **Examples:** https://threejs.org/examples/
- **Community:** https://discourse.threejs.org/

---

## Document Version & Maintenance

**Last Updated:** 2026-01-31
**Research Phase:** Complete

**Next Review:** After Phase 1 MVP completion (expected April 2026)

---

**Document Status:** REFERENCES COMPLETE
