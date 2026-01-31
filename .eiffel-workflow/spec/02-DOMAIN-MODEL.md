# DOMAIN MODEL: Core Concepts & Classes

## Domain Concepts Becoming Classes

This document maps domain concepts from the problem space to Eiffel classes that will form the core architecture.

---

## Core Domain Entities

### 1. TEXT_PROMPT (Input Concept)

**Domain Concept:** Natural language description that guides geometry generation

**Purpose:** Users describe what 3D object they want to create

**Mapping to Class:**
```eiffel
class TEXT_PROMPT
  feature
    content: STRING

    is_valid: BOOLEAN
      -- True if prompt is valid (10-500 chars, non-empty)

    character_count: INTEGER
      -- Length of prompt text
end
```

**Relationships:**
- INPUT to ONNX_MODEL.encode_to_embedding

**Design Rationale:**
- Encapsulates validation logic (10-500 chars, UTF-8)
- Separate from raw STRING allows future enhancements (tokenization, compression)

---

### 2. ONNX_MODEL (Inference Component)

**Domain Concept:** Machine learning model loaded from disk, ready to execute inference

**Purpose:** Execute Point-E model on GPU via ONNX Runtime

**Mapping to Class:**
```eiffel
class ONNX_MODEL
  feature
    load_from_file (path: STRING): BOOLEAN
      -- Load ONNX model file

    encode_text (prompt: TEXT_PROMPT): TENSOR_ARRAY
      -- Stage 1: Text → embedding

    generate_point_cloud (image: TENSOR_ARRAY): POINT_CLOUD
      -- Stage 2: Image embedding → 3D points

    input_specification: HASH_TABLE[STRING, TENSOR_INFO]
    output_specification: HASH_TABLE[STRING, TENSOR_INFO]
end
```

**Internal Components:**
- ONNX_SESSION: C++ wrapper for ONNX Runtime (via FFI)
- TENSOR_ARRAY: GPU memory buffer (1M points × 3 coordinates)
- TENSOR_INFO: Shape and data type information

**Relationships:**
- CONSUMES: TEXT_PROMPT
- PRODUCES: POINT_CLOUD
- DEPENDS_ON: ONNX_SESSION (C++ FFI)

**Design Rationale:**
- Abstracts ONNX Runtime complexity
- Encapsulates model loading, input/output handling
- Reusable pattern for other models (Shap-E, LGM in Phase 2)

---

### 3. POINT_CLOUD (Raw Inference Output)

**Domain Concept:** Sparse set of 3D points in space (raw from neural network)

**Purpose:** Intermediate representation between inference and mesh conversion

**Mapping to Class:**
```eiffel
class POINT_CLOUD
  feature
    points: ARRAY[SCULPTOR_POINT_3D]
      -- Array of (x,y,z) coordinates from inference

    point_count: INTEGER
      -- Number of points (typically 1M+)

    colors: detachable ARRAY[SCULPTOR_COLOR]
      -- Optional RGB colors from model (for visualization)

    bounding_box: BOUNDING_BOX_3D
      -- Min/max coordinates

    center: SCULPTOR_POINT_3D
      -- Centroid of point cloud

    normalize_position
      -- Center at origin for mesh generation

    decimate (target_count: INTEGER): POINT_CLOUD
      -- Reduce point count (for memory constraints)
end
```

**Data Types:**
```eiffel
class SCULPTOR_POINT_3D
  feature
    x, y, z: REAL
end

class SCULPTOR_COLOR
  feature
    r, g, b: INTEGER  -- 0-255
    alpha: detachable INTEGER
end

class BOUNDING_BOX_3D
  feature
    min_x, min_y, min_z: REAL
    max_x, max_y, max_z: REAL
    size: SCULPTOR_VECTOR_3D
end
```

**Relationships:**
- OUTPUT FROM: ONNX_MODEL
- INPUT TO: MESH_CONVERTER (mesh generation)
- VALIDATION: POINT_CLOUD_VALIDATOR

**Design Rationale:**
- Immutable after creation (pure representation of inference output)
- Includes metadata (colors, bounds) for downstream processing
- Decimate method handles VRAM constraints

---

### 4. MESH_CONVERTER (Algorithm Component)

**Domain Concept:** Algorithm that transforms point clouds into triangle meshes

**Purpose:** Convert sparse point cloud to solid geometry with normals

**Mapping to Class:**
```eiffel
class MESH_CONVERTER
  feature
    convert (point_cloud: POINT_CLOUD): SCULPTOR_MESH
      -- Primary operation: point cloud → mesh

    set_voxel_size (size: REAL)
      -- Quality parameter (larger = simpler mesh)

    set_smoothing_iterations (count: INTEGER)
      -- Post-processing smoothing

    is_configured: BOOLEAN
end
```

**Internal Implementation:**
- Wraps OpenVDB C++ library (via FFI)
- Handles voxelization, implicit function generation, triangulation
- Computes vertex normals

**Relationships:**
- CONSUMES: POINT_CLOUD
- PRODUCES: SCULPTOR_MESH
- DEPENDS_ON: OpenVDB (C++ FFI)

**Design Rationale:**
- Single responsibility: Point cloud → mesh conversion
- Configurable (voxel size, smoothing) without changing interface
- Handles memory management of intermediate structures

---

### 5. SCULPTOR_MESH (Solid Geometry Output)

**Domain Concept:** Solid triangle mesh with normals, ready for export/viewing

**Purpose:** Core representation of generated 3D geometry

**Mapping to Class:**
```eiffel
class SCULPTOR_MESH
  feature
    vertices: ARRAY[SCULPTOR_POINT_3D]
      -- Vertex positions

    normals: ARRAY[SCULPTOR_VECTOR_3D]
      -- Per-vertex shading normals (outward-pointing)

    faces: ARRAY[SCULPTOR_FACE]
      -- Triangle definitions (vertex indices)

    colors: detachable ARRAY[SCULPTOR_COLOR]
      -- Optional per-vertex colors from inference

    uv_coordinates: detachable ARRAY[SCULPTOR_UV]
      -- Texture coordinates (Phase 2)

    vertex_count: INTEGER
    triangle_count: INTEGER
    bounding_box: BOUNDING_BOX_3D

    export_glb (path: STRING)
    export_obj (path: STRING)
    export_stl (path: STRING)

    is_valid: BOOLEAN
      -- Mesh passes validation checks

    validate: MESH_VALIDATION_REPORT
      -- Check manifold, self-intersections, etc.
end

class SCULPTOR_FACE
  feature
    vertex_indices: TUPLE[v1, v2, v3: INTEGER]
    is_degenerate: BOOLEAN
end

class SCULPTOR_VECTOR_3D
  feature
    x, y, z: REAL
    normalize: SCULPTOR_VECTOR_3D
    dot_product (other: SCULPTOR_VECTOR_3D): REAL
    cross_product (other: SCULPTOR_VECTOR_3D): SCULPTOR_VECTOR_3D
end

class SCULPTOR_UV
  feature
    u, v: REAL
end
```

**Relationships:**
- OUTPUT FROM: MESH_CONVERTER
- INPUT TO: GLB_EXPORTER, OBJ_EXPORTER, STL_EXPORTER, WEB_VIEWER
- VALIDATION: MESH_VALIDATOR

**Design Rationale:**
- Immutable mesh representation (stable once created)
- Includes validation and export methods
- Separate validation report (non-throwing design)

---

### 6. SCULPTOR_RESULT (Command Result)

**Domain Concept:** Outcome of a generation request (success with mesh, or failure with error)

**Purpose:** Encapsulate success/failure in type-safe way

**Mapping to Class:**
```eiffel
class SCULPTOR_RESULT
  feature
    is_success: BOOLEAN
      -- True if generation succeeded

    data: detachable SCULPTOR_MESH
      -- The generated mesh (only if is_success)

    error: detachable STRING
      -- Error message (only if not is_success)

    error_code: detachable STRING
      -- Machine-readable error (e.g., "CUDA_OOM", "INVALID_PROMPT")

    inference_time_ms: INTEGER
      -- GPU inference duration

    mesh_conversion_time_ms: INTEGER
      -- Point cloud → mesh conversion duration

    total_time_ms: INTEGER
      -- End-to-end time

    invariant
      is_success xor (error /= Void)
      -- Either success with data OR failure with error, not both
  end
```

**Relationships:**
- OUTPUT FROM: SCULPTOR_ENGINE.generate
- INPUT TO: Export operations, CLI output handlers

**Design Rationale:**
- Type-safe result (avoids null checks)
- Includes timing information for performance monitoring
- Invariant ensures consistency (xor between success/failure)

---

### 7. SCULPTOR_CONFIG (Builder Pattern)

**Domain Concept:** Configuration and generation options

**Purpose:** Fluent API for setting up generation parameters

**Mapping to Class:**
```eiffel
class SCULPTOR_CONFIG
  feature
    set_prompt (text: STRING): like Current
    set_model_path (path: STRING): like Current
    set_output_format (fmt: STRING): like Current
      -- "glb", "obj", "stl", "ply"

    set_output_path (path: STRING): like Current
    set_voxel_size (size: REAL): like Current
    set_point_count (count: INTEGER): like Current
    set_vram_limit (mb: INTEGER): like Current
    set_seed (seed: INTEGER): like Current
    set_timeout_seconds (seconds: INTEGER): like Current
    set_batch_mode (enable: BOOLEAN): like Current

    prompt: STRING
    model_path: STRING
    output_format: STRING
    is_configured: BOOLEAN

    invariant
      is_configured implies (prompt /= Void and model_path /= Void)
  end
```

**Relationships:**
- INPUT TO: SCULPTOR_ENGINE.generate
- USED BY: CLI argument parser

**Design Rationale:**
- Fluent API (method chaining for clean CLI)
- Immutable config once created (commands return like Current)
- Invariant ensures validity before generation

---

### 8. RENDERING_CONTEXT (GPU/Viewer Setup)

**Domain Concept:** Viewer infrastructure (web server, browser connection)

**Purpose:** Handle local HTTP server and browser launching

**Mapping to Class:**
```eiffel
class WEB_VIEWER
  feature
    show_model (mesh: SCULPTOR_MESH; port: INTEGER)
      -- Launch browser viewer for mesh

    launch_server (port: INTEGER): SIMPLE_WEB_SERVER
      -- Start local HTTP server

    open_browser (url: STRING)
      -- Open default browser to URL

    serve_glb (path: STRING): FILE_HANDLER
      -- HTTP handler for GLB file serving

    serve_viewer_ui: STATIC_FILE_HANDLER
      -- Serve THREE.js viewer HTML/JS
end
```

**Relationships:**
- CONSUMES: SCULPTOR_MESH
- DEPENDS_ON: simple_web_server (Eiffel library)
- DEPENDS_ON: THREE.js (JavaScript library, bundled)

**Design Rationale:**
- Encapsulates web server complexity
- Separates concerns: geometry generation vs viewing
- Optional (graceful fallback if no browser available)

---

### 9. GLB_FILE / OBJ_FILE / STL_FILE (Export Formats)

**Domain Concept:** Serialized mesh in standard formats

**Purpose:** Enable interchange with other tools

**Mapping to Class:**
```eiffel
class GLB_EXPORTER
  feature
    export (mesh: SCULPTOR_MESH; path: STRING): GLB_FILE
      -- Write mesh to GLB format with PBR material

    compress_with_draco (enable: BOOLEAN)
end

class OBJ_EXPORTER
  feature
    export (mesh: SCULPTOR_MESH; path: STRING): OBJ_FILE
      -- Write mesh to OBJ + MTL format
end

class STL_EXPORTER
  feature
    export (mesh: SCULPTOR_MESH; path: STRING): STL_FILE
      -- Write mesh to binary STL format
end

class GLB_FILE
  feature
    path: STRING
    file_size: INTEGER
    vertex_count: INTEGER
    triangle_count: INTEGER
end
```

**Relationships:**
- INPUT FROM: SCULPTOR_MESH
- OUTPUT TO: Filesystem, browsers, CAD tools

**Design Rationale:**
- Separate exporters per format (Open/Closed principle)
- Each exporter encapsulates format-specific logic

---

### 10. SCULPTOR_ENGINE (Main Facade)

**Domain Concept:** Orchestrator of entire generation pipeline

**Purpose:** Coordinate inference → meshing → export

**Mapping to Class:**
```eiffel
class SCULPTOR_ENGINE
  feature
    generate (config: SCULPTOR_CONFIG): SCULPTOR_RESULT
      -- Text prompt → mesh (end-to-end)

    generate_and_view (config: SCULPTOR_CONFIG): SCULPTOR_RESULT
      -- Generate + show in browser

    batch_generate (configs: LIST[SCULPTOR_CONFIG]): LIST[SCULPTOR_RESULT]
      -- Multiple prompts

    is_ready: BOOLEAN
      -- Model loaded and configured

    estimated_inference_time: INTEGER
      -- Milliseconds (for UI feedback)

  feature {NONE}
    onnx_model: ONNX_MODEL
    mesh_converter: MESH_CONVERTER
    glb_exporter: GLB_EXPORTER
    obj_exporter: OBJ_EXPORTER
    stl_exporter: STL_EXPORTER
    viewer: WEB_VIEWER

    invariant
      is_ready implies onnx_model.is_loaded
  end
```

**Relationships:**
- ORCHESTRATES: ONNX_MODEL, MESH_CONVERTER, exporters, WEB_VIEWER
- PRODUCES: SCULPTOR_RESULT
- CONSUMED BY: CLI, library clients

**Design Rationale:**
- Single entry point (Facade pattern)
- Coordinates complex workflow
- Keeps implementation details private
- Testable with mock components

---

## Data Flow Diagram

```
TEXT_PROMPT
    ↓
SCULPTOR_ENGINE.generate(config)
    ↓
  ┌─────────────────────────────────┐
  │   ONNX_MODEL.generate           │
  │  (1) encode_text → embedding    │
  │  (2) image → point_cloud        │  ← GPU inference
  └─────────────────────────────────┘
    ↓
POINT_CLOUD
  (1M+ sparse points in 3D)
    ↓
MESH_CONVERTER.convert()
  ┌─────────────────────────────────┐
  │   OpenVDB meshing               │
  │  Point cloud → voxelization     │
  │  Implicit function generation   │
  │  Triangulation + normals        │  ← CPU-intensive
  └─────────────────────────────────┘
    ↓
SCULPTOR_MESH
  (Solid geometry with normals)
    ↓
  ┌─────────────────────────────────┐
  │   Export Options                │
  ├─────────────────────────────────┤
  │ GLB_EXPORTER → model.glb        │
  │ OBJ_EXPORTER → model.obj        │
  │ STL_EXPORTER → model.stl        │
  └─────────────────────────────────┘
    ↓
SCULPTOR_RESULT
  (Success: with mesh, or Failure: with error)
    ↓
  ┌─────────────────────────────────┐
  │   CLI / Viewer                  │
  ├─────────────────────────────────┤
  │ WEB_VIEWER.show_model           │
  │   (HTTP server + THREE.js)      │
  │ or                              │
  │ Filesystem output               │
  └─────────────────────────────────┘
```

---

## Class Relationships Summary

| Class | Role | Depends On | Used By |
|-------|------|-----------|---------|
| TEXT_PROMPT | Input | (none) | ONNX_MODEL |
| ONNX_MODEL | Inference | ONNX_SESSION (C++) | SCULPTOR_ENGINE |
| POINT_CLOUD | Intermediate | (none) | MESH_CONVERTER |
| MESH_CONVERTER | Algorithm | OpenVDB (C++) | SCULPTOR_ENGINE |
| SCULPTOR_MESH | Output | (geometry types) | Exporters, WEB_VIEWER |
| SCULPTOR_RESULT | Result | SCULPTOR_MESH | CLI, clients |
| SCULPTOR_CONFIG | Builder | (none) | SCULPTOR_ENGINE |
| WEB_VIEWER | Viewing | simple_web_server | CLI |
| GLB/OBJ/STL_EXPORTER | Export | (format libs) | SCULPTOR_ENGINE |
| SCULPTOR_ENGINE | Facade | All others | CLI, library users |

---

## Invariants & Constraints

### ONNX_MODEL Invariants
- `model_loaded implies input_specification /= Void`
- `inference_in_progress xor model_loaded` (not both)

### SCULPTOR_MESH Invariants
- `vertex_count > 0`
- `triangle_count > 0`
- `faces.count = triangle_count`
- `normals.count = vertex_count`
- `is_valid implies (no_self_intersections and is_manifold)`

### SCULPTOR_RESULT Invariants
- `is_success xor (error /= Void)` (exclusive or)
- `is_success implies (data /= Void and total_time_ms > 0)`
- `(not is_success) implies (error /= Void)`

### SCULPTOR_ENGINE Invariants
- `is_ready implies (onnx_model.is_loaded and not inference_in_progress)`
- `batch_processing xor standalone_mode` (can't be both)

---

## Validation & Quality Gates

### POINT_CLOUD Validation
- Point count > 100K (minimum viable)
- Bounds reasonable (not NaN/Inf)
- No isolated outlier points (> 5σ from centroid)

### SCULPTOR_MESH Validation
- Manifold check (all edges shared by 2 triangles)
- No self-intersections
- Watertight (closed mesh)
- Normal vectors pointing outward (consistent orientation)
- Reasonable triangle density (1M-5M triangles)

### SCULPTOR_RESULT Validation
- Either success with mesh OR failure with error (not both)
- Timing information present
- Error code machine-readable

---

**Document Status:** DOMAIN MODEL COMPLETE, ready for CHALLENGE ASSUMPTIONS
