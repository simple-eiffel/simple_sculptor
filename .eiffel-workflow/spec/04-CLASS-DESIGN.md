# CLASS DESIGN: Eiffel Architecture with OOSC2 Principles

## Overview

This document specifies the Eiffel class architecture for simple_sculptor, following Object-Oriented Software Construction (OOSC2) principles: single responsibility, open/closed, Liskov substitution, interface segregation, and dependency inversion.

---

## Layer Architecture

```
┌─────────────────────────────────────────────────┐
│         CLI LAYER (Eiffel)                      │
│  SCULPTOR_CLI → argument parsing → CONFIG      │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│      FACADE LAYER (Eiffel)                      │
│      SIMPLE_SCULPTOR                            │
│   (orchestrator, public API)                    │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│   GENERATION LAYER (Eiffel + C++)              │
│  ┌──────────────┐  ┌──────────────┐            │
│  │SCULPTOR_ENGINE   │MESH_CONVERTER            │
│  └──────┬───────┘  └────────┬─────┘            │
│         │                    │                  │
│    ┌────▼────────────┬──────▼────────────┐     │
│    │  ONNX_SESSION   │   OpenVDB (C++)   │     │
│    │   (C++ FFI)     │     (C++ FFI)     │     │
│    └────────────────────────────────────┘     │
└────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│    EXPORT LAYER (Eiffel)                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │GLB_EXPORTER │OBJ_EXPORTER │STL_EXPORTER    │
│  └──────────┘  └──────────┘  └──────────┘     │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│     VIEWER LAYER (Eiffel + JavaScript)         │
│        WEB_VIEWER                              │
│  (HTTP server + THREE.js)                      │
└─────────────────────────────────────────────────┘
```

---

## Core Classes

### 1. SIMPLE_SCULPTOR (Main Facade)

**Responsibility:** Orchestrate entire pipeline, provide public API

**Visibility:** Public

```eiffel
class SIMPLE_SCULPTOR
  create make, make_with_model

  feature -- Initialization
    make
      -- Create unconfigured instance
      require
        -- None (fresh start)
      ensure
        not is_ready
        not is_configured
      end

    make_with_model (model_path: STRING)
      -- Create with model pre-loaded
      require
        model_path /= Void
        file_exists (model_path)
      ensure
        is_ready
        model_path_set: model_path_stored = model_path
      end

  feature -- Configuration (Builder Pattern)
    set_prompt (text: STRING): like Current
      require
        text /= Void
        text.count >= 10
        text.count <= 500
      ensure
        prompt_set: prompt = text
        result = Current
      end

    set_output_path (path: STRING): like Current
      require path /= Void
      ensure output_path_set: output_path = path; result = Current
      end

    set_format (fmt: STRING): like Current
      require
        fmt /= Void
        valid_format (fmt)  -- "glb", "obj", "stl"
      ensure format_set: output_format = fmt; result = Current
      end

    set_vram_limit (mb: INTEGER): like Current
      require mb > 0
      ensure vram_limit_set: vram_limit_mb = mb; result = Current
      end

    with_interactive: like Current
      -- Enable interactive viewer mode
      ensure interactive_mode_set; result = Current
      end

    set_seed (seed: INTEGER): like Current
      require seed >= 0
      ensure seed_set: generation_seed = seed; result = Current
      end

  feature -- Status Queries
    is_ready: BOOLEAN
      -- True if configured and model loaded
      ensure
        result = (is_configured and model_loaded)
      end

    is_configured: BOOLEAN
      -- True if minimum config set (prompt, output path)
      ensure
        result = (prompt /= Void and output_path /= Void)
      end

    is_model_loaded: BOOLEAN
      -- True if ONNX model in memory
      do
        result := onnx_engine.is_loaded
      end

    estimated_inference_time: INTEGER
      -- Milliseconds (30-120 seconds typical)
      require is_ready
      ensure
        result >= 30000 and result <= 120000
      end

  feature -- Operations
    generate: SCULPTOR_RESULT
      -- Execute generation (inference → mesh → export)
      require
        is_ready
      ensure
        result /= Void
        not result.is_success implies result.error /= Void
        result.is_success implies result.data /= Void
        result.total_time_ms > 0
      end

    generate_and_view: SCULPTOR_RESULT
      -- Generate + launch browser viewer
      require
        is_ready
        with_interactive
      ensure
        result /= Void
        result.is_success implies viewer.is_running
      end

    batch_generate (configs: LIST[SCULPTOR_CONFIG]): LIST[SCULPTOR_RESULT]
      -- Generate multiple models
      require
        configs /= Void
        configs.count > 0
      ensure
        result /= Void
        result.count = configs.count
      end

  feature {NONE} -- Implementation
    onnx_engine: SCULPTOR_ENGINE
    mesh_converter: MESH_CONVERTER
    exporter: SCULPTOR_EXPORTER
    viewer: WEB_VIEWER

    validate_config
      require is_configured
      ensure True
      end

  invariant
    -- Either ready or not configured
    is_ready xor not is_configured

    -- Output path must be set
    is_configured implies output_path /= Void
end
```

**Design Rationale:**
- Single entry point for library users
- Builder pattern for fluent configuration
- Separates public API from implementation
- Queries are side-effect free

---

### 2. SCULPTOR_ENGINE (Core Inference)

**Responsibility:** Load ONNX model, execute inference, produce point clouds

**Visibility:** Private to SIMPLE_SCULPTOR

```eiffel
class SCULPTOR_ENGINE
  create make

  feature -- Initialization
    make
      require True
      ensure
        not is_loaded
        inference_in_progress = False
      end

  feature -- Model Management
    load_model (model_path: STRING): BOOLEAN
      require model_path /= Void
      ensure
        result = True implies is_loaded
        result = False implies not is_loaded
      end

    is_loaded: BOOLEAN
      -- True if ONNX model in memory

  feature -- Inference Operations
    execute (prompt: TEXT_PROMPT; seed: INTEGER): SCULPTOR_INFERENCE_RESULT
      require
        is_loaded
        prompt /= Void
        not inference_in_progress
      ensure
        inference_complete: not inference_in_progress
        result /= Void
        result.is_success implies result.point_cloud /= Void
      end

    inference_in_progress: BOOLEAN

  feature -- Properties
    model_info: ONNX_MODEL_INFO
      -- Shape, version, requirements

    input_specification: HASH_TABLE[STRING, TENSOR_INFO]
      -- Expected input format

  feature {NONE} -- Implementation
    onnx_session: ONNX_SESSION
      -- C++ wrapper for ONNX Runtime (FFI)

    stage_1_text_to_image (prompt: TEXT_PROMPT): TENSOR_ARRAY
      require prompt /= Void
      ensure result /= Void
      end

    stage_2_image_to_points (image: TENSOR_ARRAY): POINT_CLOUD
      require image /= Void
      ensure result /= Void
      end
end
```

**Design Rationale:**
- Encapsulates ONNX Runtime complexity (FFI hidden)
- Two-stage pipeline (text → image → points)
- Testable with mock ONNX_SESSION
- VRAM management handled internally

---

### 3. SCULPTOR_INFERENCE_RESULT (Inference Output)

**Responsibility:** Encapsulate inference result (point cloud or error)

```eiffel
class SCULPTOR_INFERENCE_RESULT
  feature
    is_success: BOOLEAN

    point_cloud: detachable POINT_CLOUD
      -- Set if is_success = True

    error: detachable STRING
      -- Error message if is_success = False

    error_code: detachable STRING
      -- Machine-readable code: "CUDA_OOM", etc.

    inference_time_ms: INTEGER

    invariant
      is_success xor (error /= Void)
      is_success implies point_cloud /= Void
    end
end
```

---

### 4. POINT_CLOUD (Inference Output Data)

**Responsibility:** Immutable representation of sparse 3D points

```eiffel
class POINT_CLOUD
  create from_vertices

  feature
    vertices: ARRAY[SCULPTOR_POINT_3D]
    point_count: INTEGER

    bounding_box: BOUNDING_BOX_3D
    center: SCULPTOR_POINT_3D

    colors: detachable ARRAY[SCULPTOR_COLOR]

    normalize_position: POINT_CLOUD
      -- Return new cloud centered at origin
      require point_count > 0
      ensure result.center.is_near_zero
      end

    decimate (target_count: INTEGER): POINT_CLOUD
      require target_count > 100 and target_count < point_count
      ensure result.point_count <= target_count
      end

  invariant
    point_count > 0
    vertices.count = point_count
    if colors /= Void then colors.count = point_count end
end
```

---

### 5. MESH_CONVERTER (Point Cloud → Mesh)

**Responsibility:** Convert point clouds to triangle meshes with normals

```eiffel
class MESH_CONVERTER
  create make

  feature
    make
      require True
      ensure
        voxel_size = 0.01  -- Default
        not is_converting
      end

  feature -- Configuration
    set_voxel_size (size: REAL): like Current
      require size > 0 and size < 1.0
      ensure voxel_size_set: voxel_size = size; result = Current
      end

    set_smoothing_iterations (count: INTEGER): like Current
      require count >= 0 and count <= 5
      ensure result = Current
      end

  feature -- Conversion
    convert (cloud: POINT_CLOUD): SCULPTOR_MESH
      require
        cloud /= Void
        cloud.point_count > 100000
        not is_converting
      ensure
        not is_converting
        result /= Void
        result.vertex_count > 0
        result.triangle_count > 0
      end

    is_converting: BOOLEAN

  feature {NONE} -- Implementation
    openvdb_wrapper: OPENVDB_MESH_GENERATOR
      -- C++ FFI to OpenVDB library
end
```

---

### 6. SCULPTOR_MESH (Solid Geometry)

**Responsibility:** Immutable mesh with normals, suitable for export/viewing

```eiffel
class SCULPTOR_MESH
  create from_triangles

  feature
    vertices: ARRAY[SCULPTOR_POINT_3D]
    normals: ARRAY[SCULPTOR_VECTOR_3D]
    faces: ARRAY[SCULPTOR_FACE]
    colors: detachable ARRAY[SCULPTOR_COLOR]

    vertex_count: INTEGER
    triangle_count: INTEGER
    bounding_box: BOUNDING_BOX_3D

  feature -- Export
    export_glb (path: STRING): BOOLEAN
      require path /= Void
      ensure (Result = True) implies file_exists(path)
      end

    export_obj (path: STRING): BOOLEAN
    export_stl (path: STRING): BOOLEAN

  feature -- Validation
    is_valid: BOOLEAN

    validate: MESH_VALIDATION_REPORT
      ensure result /= Void
      end

  invariant
    vertex_count > 0
    triangle_count > 0
    normals.count = vertex_count
    vertices.count = vertex_count
end
```

---

### 7. SCULPTOR_CONFIG (Builder for Configuration)

**Responsibility:** Fluent API for configuration options

```eiffel
class SCULPTOR_CONFIG
  create make

  feature -- Builder Methods
    make: SCULPTOR_CONFIG
      ensure
        not is_configured
        prompt = Void
        output_path = Void
      end

    set_prompt (text: STRING): like Current
      require text /= Void and text.count >= 10
      ensure prompt = text; result = Current
      end

    set_output_path (path: STRING): like Current
      require path /= Void
      ensure output_path = path; result = Current
      end

    set_format (fmt: STRING): like Current
      require valid_format(fmt)  -- "glb", "obj", "stl"
      ensure output_format = fmt; result = Current
      end

    set_vram_limit (mb: INTEGER): like Current
      require mb > 512
      ensure vram_limit_mb = mb; result = Current
      end

    set_seed (seed: INTEGER): like Current
      require seed >= 0
      ensure generation_seed = seed; result = Current
      end

  feature -- Query
    is_configured: BOOLEAN
      ensure
        result = (prompt /= Void and output_path /= Void)
      end

    prompt: detachable STRING
    output_path: detachable STRING
    output_format: STRING
    vram_limit_mb: INTEGER
    generation_seed: INTEGER

  invariant
    is_configured implies (prompt /= Void and output_path /= Void)
end
```

---

### 8. WEB_VIEWER (HTTP Server + Browser)

**Responsibility:** Launch local viewer, serve files

```eiffel
class WEB_VIEWER
  create make

  feature
    make (port: INTEGER)
      require port > 1024 and port < 65536
      ensure not is_running
      end

  feature
    show_model (mesh: SCULPTOR_MESH; port: INTEGER)
      require mesh /= Void
      ensure is_running
      end

    is_running: BOOLEAN

    shutdown
      require is_running
      ensure not is_running
      end

  feature {NONE} -- Implementation
    server: SIMPLE_WEB_SERVER
    static_files_handler: STATIC_FILE_HANDLER
    glb_handler: GLB_API_HANDLER

    launch_browser (url: STRING)
    serve_three_js_viewer: STRING
      -- Return HTML + JavaScript for viewer
      end
end
```

---

### 9. SCULPTOR_RESULT (Generation Outcome)

**Responsibility:** Type-safe result of generation (success or failure)

```eiffel
class SCULPTOR_RESULT
  feature
    is_success: BOOLEAN

    data: detachable SCULPTOR_MESH
      -- Set only if is_success = True

    error: detachable STRING
      -- Set only if is_success = False

    error_code: detachable STRING
      -- "CUDA_OOM", "INVALID_PROMPT", etc.

    inference_time_ms: INTEGER
    mesh_conversion_time_ms: INTEGER
    export_time_ms: INTEGER

    total_time_ms: INTEGER
      ensure
        result = inference_time_ms + mesh_conversion_time_ms + export_time_ms
      end

  invariant
    -- Exclusive: success XOR error
    is_success xor (error /= Void)

    -- Success → data exists
    is_success implies data /= Void

    -- Failure → error message exists
    not is_success implies error /= Void

    -- Timing always positive
    total_time_ms > 0
end
```

---

### 10. SCULPTOR_EXPORTER (Format Delegation)

**Responsibility:** Delegate export based on format

```eiffel
class SCULPTOR_EXPORTER
  feature
    export (mesh: SCULPTOR_MESH; format: STRING; path: STRING): BOOLEAN
      require
        mesh /= Void
        valid_format (format)
        path /= Void
      ensure
        if Result then file_exists(path) end
      end

  feature {NONE}
    export_glb (mesh: SCULPTOR_MESH; path: STRING): BOOLEAN
    export_obj (mesh: SCULPTOR_MESH; path: STRING): BOOLEAN
    export_stl (mesh: SCULPTOR_MESH; path: STRING): BOOLEAN
end
```

---

### 11. SCULPTOR_CLI (Command-Line Interface)

**Responsibility:** Parse arguments, invoke library, report to user

```eiffel
class SCULPTOR_CLI
  feature
    run (args: ARRAY[STRING]): INTEGER
      -- Main entry point, returns exit code
      require args /= Void and args.count > 0
      ensure
        Result = 0 implies success
        Result /= 0 implies failure
      end

  feature {NONE}
    parse_args (args: ARRAY[STRING]): SCULPTOR_CONFIG
      -- Convert command-line → config object

    execute_generation (config: SCULPTOR_CONFIG)
      -- Call library, handle results, print output
end
```

---

## Helper Classes

### SCULPTOR_POINT_3D (3D Point)
```eiffel
class SCULPTOR_POINT_3D
  feature
    x, y, z: REAL

    distance_to (other: SCULPTOR_POINT_3D): REAL
    is_near_zero: BOOLEAN
end
```

### SCULPTOR_VECTOR_3D (Direction Vector)
```eiffel
class SCULPTOR_VECTOR_3D
  feature
    x, y, z: REAL

    normalize: SCULPTOR_VECTOR_3D
    dot_product (other: SCULPTOR_VECTOR_3D): REAL
    cross_product (other: SCULPTOR_VECTOR_3D): SCULPTOR_VECTOR_3D
    magnitude: REAL
end
```

### SCULPTOR_FACE (Triangle)
```eiffel
class SCULPTOR_FACE
  feature
    v1, v2, v3: INTEGER  -- Vertex indices
    is_degenerate: BOOLEAN
end
```

### BOUNDING_BOX_3D
```eiffel
class BOUNDING_BOX_3D
  feature
    min_x, min_y, min_z: REAL
    max_x, max_y, max_z: REAL
    size: SCULPTOR_VECTOR_3D
end
```

---

## OOSC2 Compliance Analysis

### Single Responsibility Principle
- ✓ SIMPLE_SCULPTOR: Orchestration only
- ✓ SCULPTOR_ENGINE: Inference only
- ✓ MESH_CONVERTER: Point cloud → mesh only
- ✓ WEB_VIEWER: HTTP server + browser only
- ✓ SCULPTOR_EXPORTER: Format conversion only

### Open/Closed Principle
- ✓ Can add new exporters without modifying existing code
- ✓ Can replace ONNX_SESSION with mock for testing
- ✓ Can add new mesh algorithms via new MESH_CONVERTER subclasses

### Liskov Substitution
- ✓ All result types follow SCULPTOR_RESULT contract
- ✓ All exporters implement same interface

### Interface Segregation
- ✓ SIMPLE_SCULPTOR exposes minimal public API
- ✓ Internal classes private (SCULPTOR_ENGINE, etc.)

### Dependency Inversion
- ✓ SIMPLE_SCULPTOR depends on abstractions (not ONNX directly)
- ✓ ONNX_SESSION can be replaced with different runtime

---

## Concurrency (SCOOP Compatibility)

All classes designed to be SCOOP-safe:
- Immutable data: POINT_CLOUD, SCULPTOR_MESH
- Guarded operations: SCULPTOR_ENGINE.execute (one at a time)
- No shared mutable state (each operation independent)

Example SCOOP usage:
```eiffel
batch_processor: separate SCULPTOR_ENGINE
do
  create {separate SCULPTOR_ENGINE} batch_processor
  -- Can process prompts concurrently, each gets its own separate engine
end
```

---

**Document Status:** CLASS DESIGN COMPLETE, ready for CONTRACT DESIGN
