# SPECIFICATION: Complete Eiffel Class Specifications

## Overview

This document provides the complete specification for all simple_sculptor classes in detail, including feature signatures, contracts, and implementation notes.

---

## CLASS: SIMPLE_SCULPTOR

**Location:** `library/sculptor/simple_sculptor.e`

**Inheritance:** None (no parent class)

**Creation:** make, make_with_model

**Exported:** All

### Feature List

#### make
```eiffel
make
  -- Initialize unconfigured sculptor instance
  require True
  ensure not is_ready; not is_configured
  end
```

#### make_with_model
```eiffel
make_with_model (model_path: STRING)
  require model_path /= Void; file_exists(model_path)
  ensure is_ready
  end
```

#### set_prompt
```eiffel
set_prompt (text: STRING): like Current
  require text /= Void; text.count >= 10; text.count <= 500
  ensure prompt = text; result = Current
  end
```

#### set_output_path
```eiffel
set_output_path (path: STRING): like Current
  require path /= Void; path.count > 0
  ensure output_path = path; result = Current
  end
```

#### set_format
```eiffel
set_format (fmt: STRING): like Current
  require valid_format(fmt)  -- "glb", "obj", "stl"
  ensure output_format = fmt; result = Current
  end
```

#### set_vram_limit
```eiffel
set_vram_limit (mb: INTEGER): like Current
  require mb >= 512; mb <= 32768
  ensure vram_limit_mb = mb; result = Current
  end
```

#### set_seed
```eiffel
set_seed (seed: INTEGER): like Current
  require seed >= 0
  ensure generation_seed = seed; result = Current
  end
```

#### with_interactive
```eiffel
with_interactive: like Current
  ensure interactive_enabled = True; result = Current
  end
```

#### generate
```eiffel
generate: SCULPTOR_RESULT
  require is_ready
  ensure result /= Void
  end
```

#### generate_and_view
```eiffel
generate_and_view: SCULPTOR_RESULT
  require is_ready; interactive_enabled
  ensure result /= Void
  end
```

#### batch_generate
```eiffel
batch_generate (configs: LIST[SCULPTOR_CONFIG]): LIST[SCULPTOR_RESULT]
  require configs /= Void; configs.count > 0
  ensure result /= Void; result.count = configs.count
  end
```

#### is_ready
```eiffel
is_ready: BOOLEAN
  ensure result = (is_configured and is_model_loaded)
  end
```

#### is_configured
```eiffel
is_configured: BOOLEAN
  ensure result = (prompt /= Void and output_path /= Void)
  end
```

#### is_model_loaded
```eiffel
is_model_loaded: BOOLEAN
  ensure result = onnx_engine.is_loaded
  end
```

#### estimated_inference_time
```eiffel
estimated_inference_time: INTEGER
  require is_ready
  ensure result >= 30000; result <= 120000
  end
```

---

## CLASS: SCULPTOR_ENGINE

**Location:** `library/generation/sculptor_engine.e`

**Inheritance:** None

**Visibility:** Private to SIMPLE_SCULPTOR

### Features

#### load_model
```eiffel
load_model (model_path: STRING): BOOLEAN
  require
    model_path /= Void
    not is_loaded
    file_exists(model_path)
  ensure
    (Result = True) implies is_loaded
    (Result = False) implies not is_loaded
  end
```

#### execute
```eiffel
execute (prompt: TEXT_PROMPT; seed: INTEGER): SCULPTOR_INFERENCE_RESULT
  require
    is_loaded
    prompt /= Void
    not inference_in_progress
  ensure
    result /= Void
    not inference_in_progress
    result.total_time_ms > 0
  end
```

#### is_loaded
```eiffel
is_loaded: BOOLEAN
  -- True if ONNX model in GPU memory
end
```

#### inference_in_progress
```eiffel
inference_in_progress: BOOLEAN
  -- True during generate execution
end
```

---

## CLASS: POINT_CLOUD

**Location:** `library/geometry/point_cloud.e`

**Inheritance:** None

**Creation:** from_vertices

### Features

#### from_vertices
```eiffel
from_vertices (verts: ARRAY[SCULPTOR_POINT_3D];
                cols: detachable ARRAY[SCULPTOR_COLOR]): POINT_CLOUD
  require verts /= Void; verts.count >= 100000
  ensure result.point_count = verts.count
  end
```

#### vertices
```eiffel
vertices: ARRAY[SCULPTOR_POINT_3D]
  -- Array of (x,y,z) coordinates
end
```

#### point_count
```eiffel
point_count: INTEGER
  -- Number of points (typically 1M+)
end
```

#### bounding_box
```eiffel
bounding_box: BOUNDING_BOX_3D
  -- Min/max coordinates
end
```

#### center
```eiffel
center: SCULPTOR_POINT_3D
  -- Centroid of point cloud
end
```

#### normalize_position
```eiffel
normalize_position: POINT_CLOUD
  require point_count > 0
  ensure result.center.is_near_zero
  end
```

#### decimate
```eiffel
decimate (target_count: INTEGER): POINT_CLOUD
  require target_count > 100; target_count < point_count
  ensure result.point_count <= target_count
  end
```

---

## CLASS: MESH_CONVERTER

**Location:** `library/geometry/mesh_converter.e`

**Inheritance:** None

**Creation:** make

### Features

#### make
```eiffel
make
  ensure not is_converting; voxel_size = 0.01
  end
```

#### set_voxel_size
```eiffel
set_voxel_size (size: REAL): like Current
  require size > 0; size < 1.0
  ensure voxel_size = size; result = Current
  end
```

#### convert
```eiffel
convert (cloud: POINT_CLOUD): SCULPTOR_MESH
  require
    cloud /= Void
    cloud.point_count >= 100000
    not is_converting
  ensure
    result /= Void
    not is_converting
    result.vertex_count > 0
  end
```

#### is_converting
```eiffel
is_converting: BOOLEAN
  -- True during conversion
end
```

---

## CLASS: SCULPTOR_MESH

**Location:** `library/geometry/sculptor_mesh.e`

**Inheritance:** None

**Creation:** from_triangles

### Features

#### vertices
```eiffel
vertices: ARRAY[SCULPTOR_POINT_3D]
  -- Vertex positions
end
```

#### normals
```eiffel
normals: ARRAY[SCULPTOR_VECTOR_3D]
  -- Per-vertex shading normals
end
```

#### faces
```eiffel
faces: ARRAY[SCULPTOR_FACE]
  -- Triangle definitions
end
```

#### vertex_count
```eiffel
vertex_count: INTEGER
  -- Number of vertices
end
```

#### triangle_count
```eiffel
triangle_count: INTEGER
  -- Number of triangles
end
```

#### export_glb
```eiffel
export_glb (path: STRING): BOOLEAN
  require path /= Void; directory_exists(directory_of(path))
  ensure Result implies file_exists(path)
  end
```

#### export_obj
```eiffel
export_obj (path: STRING): BOOLEAN
  require path /= Void
  ensure Result implies file_exists(path)
  end
```

#### export_stl
```eiffel
export_stl (path: STRING): BOOLEAN
  require path /= Void
  ensure Result implies file_exists(path)
  end
```

#### is_valid
```eiffel
is_valid: BOOLEAN
  -- Mesh passes validation checks
end
```

#### validate
```eiffel
validate: MESH_VALIDATION_REPORT
  ensure result /= Void
  end
```

---

## CLASS: SCULPTOR_RESULT

**Location:** `library/results/sculptor_result.e`

**Inheritance:** None

### Features

#### is_success
```eiffel
is_success: BOOLEAN
  -- True if generation succeeded
end
```

#### data
```eiffel
data: detachable SCULPTOR_MESH
  -- Generated mesh (if is_success)
end
```

#### error
```eiffel
error: detachable STRING
  -- Error message (if not is_success)
end
```

#### error_code
```eiffel
error_code: detachable STRING
  -- Machine-readable code
end
```

#### inference_time_ms
```eiffel
inference_time_ms: INTEGER
  -- GPU inference duration
end
```

#### mesh_conversion_time_ms
```eiffel
mesh_conversion_time_ms: INTEGER
  -- Point cloud → mesh conversion duration
end
```

#### export_time_ms
```eiffel
export_time_ms: INTEGER
  -- Export to file duration
end
```

#### total_time_ms
```eiffel
total_time_ms: INTEGER
  -- End-to-end time
  ensure result = inference_time_ms + mesh_conversion_time_ms + export_time_ms
  end
```

**Invariant:**
```eiffel
invariant
  is_success xor (error /= Void)
  is_success implies data /= Void
  (not is_success) implies error /= Void
  total_time_ms > 0
end
```

---

## CLASS: SCULPTOR_CONFIG

**Location:** `library/configuration/sculptor_config.e`

**Inheritance:** None

**Creation:** make

### Features

#### make
```eiffel
make: SCULPTOR_CONFIG
  ensure not is_configured; prompt = Void; output_path = Void
  end
```

#### set_prompt
```eiffel
set_prompt (text: STRING): like Current
  require text /= Void; text.count >= 10
  ensure prompt = text; result = Current
  end
```

#### set_output_path
```eiffel
set_output_path (path: STRING): like Current
  require path /= Void
  ensure output_path = path; result = Current
  end
```

#### set_format
```eiffel
set_format (fmt: STRING): like Current
  require valid_format(fmt)
  ensure output_format = fmt; result = Current
  end
```

#### set_vram_limit
```eiffel
set_vram_limit (mb: INTEGER): like Current
  require mb > 512
  ensure vram_limit_mb = mb; result = Current
  end
```

#### set_seed
```eiffel
set_seed (seed: INTEGER): like Current
  require seed >= 0
  ensure generation_seed = seed; result = Current
  end
```

#### is_configured
```eiffel
is_configured: BOOLEAN
  ensure result = (prompt /= Void and output_path /= Void)
  end
```

---

## CLASS: WEB_VIEWER

**Location:** `library/viewing/web_viewer.e`

**Inheritance:** None

**Creation:** make

### Features

#### make
```eiffel
make (port: INTEGER)
  require port > 1024; port < 65536
  ensure not is_running
  end
```

#### show_model
```eiffel
show_model (mesh: SCULPTOR_MESH; port: INTEGER)
  require mesh /= Void; port_available(port); not is_running
  ensure is_running
  end
```

#### is_running
```eiffel
is_running: BOOLEAN
  -- True if HTTP server running
end
```

#### shutdown
```eiffel
shutdown
  require is_running
  ensure not is_running
  end
```

---

## CLASS: TEXT_PROMPT

**Location:** `library/geometry/text_prompt.e`

**Inheritance:** None

**Creation:** make

### Features

#### make
```eiffel
make (text: STRING): TEXT_PROMPT
  require text /= Void; text.count >= 10
  ensure content = text; is_valid = True
  end
```

#### content
```eiffel
content: STRING
  -- The prompt text
end
```

#### is_valid
```eiffel
is_valid: BOOLEAN
  ensure result = (content.count >= 10 and content.count <= 500)
  end
```

#### character_count
```eiffel
character_count: INTEGER
  ensure result = content.count
  end
```

---

## CLASS: SCULPTOR_POINT_3D

**Location:** `library/geometry/sculptor_point_3d.e`

**Inheritance:** None

**Creation:** make

### Features

#### make
```eiffel
make (x_val, y_val, z_val: REAL): SCULPTOR_POINT_3D
  ensure x = x_val; y = y_val; z = z_val
  end
```

#### x, y, z
```eiffel
x: REAL
y: REAL
z: REAL
end
```

#### distance_to
```eiffel
distance_to (other: SCULPTOR_POINT_3D): REAL
  require other /= Void
  ensure result >= 0
  end
```

#### is_near_zero
```eiffel
is_near_zero (epsilon: REAL): BOOLEAN
  require epsilon > 0
  ensure result = (distance_to (zero_point) < epsilon)
  end
```

---

## CLASS: SCULPTOR_VECTOR_3D

**Location:** `library/geometry/sculptor_vector_3d.e`

**Inheritance:** None

**Creation:** make

### Features

#### make
```eiffel
make (x_val, y_val, z_val: REAL): SCULPTOR_VECTOR_3D
  ensure x = x_val; y = y_val; z = z_val
  end
```

#### x, y, z
```eiffel
x: REAL
y: REAL
z: REAL
end
```

#### magnitude
```eiffel
magnitude: REAL
  ensure result >= 0
  end
```

#### normalize
```eiffel
normalize: SCULPTOR_VECTOR_3D
  require magnitude > epsilon
  ensure result.magnitude ≈ 1.0
  end
```

#### dot_product
```eiffel
dot_product (other: SCULPTOR_VECTOR_3D): REAL
  require other /= Void
  end
```

#### cross_product
```eiffel
cross_product (other: SCULPTOR_VECTOR_3D): SCULPTOR_VECTOR_3D
  require other /= Void
  ensure result /= Void
  end
```

---

## CLASS: SCULPTOR_FACE

**Location:** `library/geometry/sculptor_face.e`

**Inheritance:** None

**Creation:** make

### Features

#### make
```eiffel
make (v1_idx, v2_idx, v3_idx: INTEGER): SCULPTOR_FACE
  require v1_idx >= 0; v2_idx >= 0; v3_idx >= 0
  ensure v1 = v1_idx; v2 = v2_idx; v3 = v3_idx
  end
```

#### v1, v2, v3
```eiffel
v1: INTEGER
v2: INTEGER
v3: INTEGER
  -- Vertex indices
end
```

#### is_degenerate
```eiffel
is_degenerate: BOOLEAN
  ensure result = (v1 = v2 or v2 = v3 or v1 = v3)
  end
```

---

## CLASS: BOUNDING_BOX_3D

**Location:** `library/geometry/bounding_box_3d.e`

**Inheritance:** None

**Creation:** make

### Features

#### make
```eiffel
make (min_pt, max_pt: SCULPTOR_POINT_3D): BOUNDING_BOX_3D
  require min_pt /= Void; max_pt /= Void
  ensure min_point = min_pt; max_point = max_pt
  end
```

#### min_point, max_point
```eiffel
min_point: SCULPTOR_POINT_3D
max_point: SCULPTOR_POINT_3D
end
```

#### size
```eiffel
size: SCULPTOR_VECTOR_3D
  ensure result /= Void
  end
```

#### volume
```eiffel
volume: REAL
  ensure result >= 0
  end
```

---

## CLASS: SCULPTOR_COLOR

**Location:** `library/geometry/sculptor_color.e`

**Inheritance:** None

**Creation:** make_rgb

### Features

#### make_rgb
```eiffel
make_rgb (r_val, g_val, b_val: INTEGER): SCULPTOR_COLOR
  require r_val >= 0; r_val <= 255; g_val >= 0; g_val <= 255; b_val >= 0; b_val <= 255
  ensure r = r_val; g = g_val; b = b_val
  end
```

#### r, g, b, a
```eiffel
r: INTEGER
g: INTEGER
b: INTEGER
a: INTEGER  -- Alpha (opacity), default 255
end
```

---

## CLASS: MESH_VALIDATION_REPORT

**Location:** `library/validation/mesh_validation_report.e`

**Inheritance:** None

### Features

#### is_manifold
```eiffel
is_manifold: BOOLEAN
  -- No internal edges, properly oriented
end
```

#### has_self_intersections
```eiffel
has_self_intersections: BOOLEAN
  -- No triangles pass through each other
end
```

#### is_watertight
```eiffel
is_watertight: BOOLEAN
  -- No holes, closed mesh
end
```

#### normal_consistency_percent
```eiffel
normal_consistency_percent: INTEGER
  -- % of faces with outward-pointing normals (0-100)
end
```

#### printability_score
```eiffel
printability_score: REAL
  -- 0-1, suitable for 3D printing if > 0.9
end
```

#### bounds_reasonable
```eiffel
bounds_reasonable: BOOLEAN
  -- Bounding box within expected size ranges
end
```

#### issues: LIST[VALIDATION_ISSUE]
```eiffel
issues: LIST[VALIDATION_ISSUE]
  -- List of detected issues
end
```

#### is_valid
```eiffel
is_valid: BOOLEAN
  ensure result = (is_manifold and not has_self_intersections and
                   is_watertight and printability_score > 0.9)
  end
```

---

## CLASS: SCULPTOR_CLI

**Location:** `application/sculptor_cli.e`

**Inheritance:** None

### Features

#### run
```eiffel
run (args: ARRAY[STRING]): INTEGER
  require args /= Void; args.count > 0
  ensure Result = 0 or Result /= 0
  end
```

---

## Enumerations & Constants

### FORMAT_TYPES
```eiffel
constant
  format_glb: STRING = "glb"
  format_obj: STRING = "obj"
  format_stl: STRING = "stl"
end
```

### ERROR_CODES
```eiffel
constant
  error_invalid_prompt: STRING = "INVALID_PROMPT"
  error_cuda_oom: STRING = "CUDA_OOM"
  error_cuda_error: STRING = "CUDA_ERROR"
  error_download_failed: STRING = "DOWNLOAD_FAILED"
  error_mesh_conversion_failed: STRING = "MESH_CONVERSION_FAILED"
  error_export_failed: STRING = "EXPORT_FAILED"
  error_timeout: STRING = "TIMEOUT"
  error_unknown: STRING = "UNKNOWN"
end
```

---

**Document Status:** FULL SPECIFICATION COMPLETE, ready for VALIDATION
