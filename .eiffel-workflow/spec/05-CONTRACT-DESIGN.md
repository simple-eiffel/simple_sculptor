# CONTRACT DESIGN: Design by Contract Specifications

## Introduction

This document details all Design by Contract (DBC) specifications for simple_sculptor classes. Each feature includes preconditions, postconditions, and invariants following OOSC2 principles. Postconditions use MML (Modular Model Language) where applicable.

---

## SIMPLE_SCULPTOR Contracts

### Invariants
```eiffel
invariant
  -- Either ready (configured + model loaded) or not configured
  (is_ready and is_model_loaded) xor not is_configured

  -- If configured, must have prompt and output path
  is_configured implies (prompt /= Void and output_path /= Void)

  -- Model engine exists
  onnx_engine /= Void
```

### Feature: make

```eiffel
make
  -- Create unconfigured instance
  require
    True  -- No preconditions
  ensure
    not is_ready
      -- No model loaded yet
    not is_configured
      -- No prompt or output path set
    onnx_engine /= Void
      -- Engine created but not initialized
end
```

### Feature: make_with_model

```eiffel
make_with_model (model_path: STRING)
  require
    model_path /= Void
      -- Path must be provided
    model_path.count > 0
      -- Path is not empty
    file_exists (model_path)
      -- Model file must exist
    file_size (model_path) > 100000000
      -- Model file is substantial (>100MB)
  ensure
    is_ready
      -- Model loaded, ready to generate
    model_path_stored = model_path
      -- Path saved for reference
    onnx_engine.is_loaded
      -- ONNX model in GPU memory
end
```

### Feature: set_prompt

```eiffel
set_prompt (text: STRING): like Current
  require
    text /= Void
      -- Prompt text provided
    text.count >= 10
      -- Minimum 10 characters
    text.count <= 500
      -- Maximum 500 characters
    text.has_non_whitespace
      -- Not just spaces
  ensure
    prompt = text
      -- Prompt stored exactly as provided
    result = Current
      -- Returns self for chaining
    is_partially_configured
      -- Step toward is_configured
end
```

### Feature: set_output_path

```eiffel
set_output_path (path: STRING): like Current
  require
    path /= Void
      -- Path must be provided
    path.count > 0
      -- Non-empty path
    valid_output_directory (path)
      -- Directory exists or can be created
  ensure
    output_path = path
      -- Path stored
    result = Current
      -- Returns self for chaining
end
```

### Feature: set_format

```eiffel
set_format (fmt: STRING): like Current
  require
    fmt /= Void
      -- Format string provided
    (fmt.is_equal ("glb") or
     fmt.is_equal ("obj") or
     fmt.is_equal ("stl"))
      -- Valid format
  ensure
    output_format = fmt
      -- Format stored
    result = Current
      -- Returns self
end
```

### Feature: set_vram_limit

```eiffel
set_vram_limit (mb: INTEGER): like Current
  require
    mb >= 512
      -- Minimum 512MB
    mb <= 32768
      -- Maximum 32GB
  ensure
    vram_limit_mb = mb
      -- Limit stored
    result = Current
  end
```

### Feature: is_ready

```eiffel
is_ready: BOOLEAN
  -- Pre-generation status check
  ensure
    result = (is_configured and onnx_engine.is_loaded)
      -- Ready iff configured and model loaded
    result = True implies can_generate_without_error
      -- Ready implies next generate() won't fail on setup
end
```

### Feature: is_configured

```eiffel
is_configured: BOOLEAN
  -- Minimum configuration complete
  ensure
    result = (prompt /= Void and
              output_path /= Void and
              output_format /= Void)
      -- All required fields set
end
```

### Feature: estimated_inference_time

```eiffel
estimated_inference_time: INTEGER
  -- Expected GPU inference time in milliseconds
  require
    is_ready
      -- Must be ready to estimate
  ensure
    result >= 30000
      -- Minimum 30 seconds
    result <= 120000
      -- Maximum 120 seconds
    result = estimate_from_gpu_model (onnx_engine.gpu_type)
      -- Based on GPU hardware
end
```

### Feature: generate

```eiffel
generate: SCULPTOR_RESULT
  require
    is_ready
      -- Must have model loaded and config set
    not onnx_engine.inference_in_progress
      -- Not already running
    disk_space_available (output_path) > 1000000000
      -- At least 1GB free disk space
  ensure
    result /= Void
      -- Always return result object
    not onnx_engine.inference_in_progress
      -- Inference complete
    result.total_time_ms > 0
      -- Timing recorded

    -- If successful:
    result.is_success implies (
      result.data /= Void and
      result.data.vertex_count > 1000 and
      result.data.triangle_count > 1000 and
      file_exists (output_path) and
      file_size (output_path) > 0
    )
      -- Valid mesh written to output

    -- If failed:
    (not result.is_success) implies (
      result.error /= Void and
      result.error_code /= Void
    )
      -- Error information populated
end
```

### Feature: generate_and_view

```eiffel
generate_and_view: SCULPTOR_RESULT
  require
    is_ready
      -- Same as generate
    with_interactive = True
      -- Interactive mode enabled
  ensure
    result /= Void
      -- Always return result

    result.is_success implies (
      viewer.is_running and
      browser_window_opened = True
    )
      -- Viewer launched on success
end
```

---

## SCULPTOR_ENGINE Contracts

### Invariants
```eiffel
invariant
  inference_in_progress implies is_loaded
    -- Can't infer if model not loaded

  is_loaded implies onnx_session /= Void
    -- Loaded state implies session exists
end
```

### Feature: load_model

```eiffel
load_model (model_path: STRING): BOOLEAN
  require
    model_path /= Void
    not is_loaded
      -- Can't load twice without cleanup
    file_exists (model_path)
    file_extension (model_path).is_equal (".onnx")
      -- Must be ONNX format
    cuda_available
      -- CUDA/GPU required
  ensure
    (result = True) implies is_loaded
      -- Successful load → is_loaded = True
    (result = False) implies not is_loaded
      -- Failed load → is_loaded stays False
end
```

### Feature: execute

```eiffel
execute (prompt: TEXT_PROMPT; seed: INTEGER): SCULPTOR_INFERENCE_RESULT
  require
    is_loaded
      -- Model must be loaded
    prompt /= Void
    prompt.content.count >= 10
      -- Valid prompt text
    not inference_in_progress
      -- Serial execution (no concurrent runs)
    seed >= 0
      -- Valid seed (0 = random)
    available_gpu_memory >= minimum_vram_required
      -- Enough VRAM

  ensure
    result /= Void
      -- Always return result

    not inference_in_progress
      -- Inference complete

    old_available_gpu_memory >= available_gpu_memory
      -- GPU memory used (or same)

    -- Success case:
    result.is_success implies (
      result.point_cloud /= Void and
      result.point_cloud.point_count >= 500000 and
      result.inference_time_ms > 0 and
      result.inference_time_ms <= 120000
    )
      -- Point cloud produced, within time limit

    -- Failure case:
    (not result.is_success) implies (
      result.error /= Void and
      result.error_code in {"CUDA_OOM", "INVALID_PROMPT",
                            "TIMEOUT", "OTHER"}
    )
      -- Clear error information
end
```

---

## MESH_CONVERTER Contracts

### Feature: convert

```eiffel
convert (cloud: POINT_CLOUD): SCULPTOR_MESH
  require
    cloud /= Void
      -- Input point cloud required
    cloud.point_count >= 100000
      -- Minimum point density
    not is_converting
      -- Serial execution
    available_memory >= 2000000000
      -- 2GB scratch space needed

  ensure
    result /= Void
      -- Mesh always returned
    not is_converting
      -- Conversion complete

    result.vertex_count > 0 and
    result.triangle_count > 0
      -- Non-empty mesh

    result.vertex_count <= old.cloud.point_count * 10
      -- Reasonable triangle expansion

    result.normals.count = result.vertex_count
      -- Normals computed for all vertices

    for_all i in result.faces =>
      valid_triangle_indices (result.faces [i], result.vertex_count)
      -- All triangle indices valid

    manifold_property (result)
      -- Mesh is manifold (no internal edges)
end
```

---

## SCULPTOR_MESH Contracts

### Invariants
```eiffel
invariant
  vertex_count > 0
    -- Non-empty mesh

  triangle_count > 0
    -- Has triangles

  vertices.count = vertex_count
  normals.count = vertex_count
    -- Consistent dimensions

  if colors /= Void then
    colors.count = vertex_count
  end
    -- Optional colors must match vertex count

  if uv_coordinates /= Void then
    uv_coordinates.count = vertex_count
  end
    -- Optional UVs must match vertex count
end
```

### Feature: export_glb

```eiffel
export_glb (path: STRING): BOOLEAN
  require
    path /= Void
    path.count > 0
    directory_exists (directory_of (path))
      -- Directory must exist
    disk_space_available (path) > 100000000
      -- 100MB free

  ensure
    (result = True) implies (
      file_exists (path) and
      file_size (path) > 1000 and
      file_size (path) < 100000000
    )
      -- File created, reasonable size
end
```

### Feature: validate

```eiffel
validate: MESH_VALIDATION_REPORT
  require
    is_valid_mesh (Current)
      -- Mesh structure valid
  ensure
    result /= Void
      -- Report always created
    result.is_manifold = check_manifold_property (Current)
    result.has_self_intersections = check_self_intersections (Current)
    result.is_watertight = check_watertight (Current)
      -- All checks performed
end
```

---

## SCULPTOR_RESULT Contracts

### Invariants
```eiffel
invariant
  -- Exclusive: either success or failure, not both
  is_success xor (error /= Void)

  -- Success → data exists
  is_success implies data /= Void

  -- Failure → error message exists
  (not is_success) implies error /= Void

  -- Timing is positive
  inference_time_ms >= 0
  mesh_conversion_time_ms >= 0
  export_time_ms >= 0
  total_time_ms = inference_time_ms +
                  mesh_conversion_time_ms +
                  export_time_ms
end
```

---

## SCULPTOR_CONFIG Contracts

### Feature: set_prompt

```eiffel
set_prompt (text: STRING): like Current
  require
    text /= Void
    text.count >= 10
    text.count <= 500
  ensure
    prompt = text
    result = Current
end
```

### Feature: is_configured

```eiffel
is_configured: BOOLEAN
  ensure
    result = (
      prompt /= Void and
      output_path /= Void and
      output_format /= Void
    )
      -- All required fields set
end
```

---

## WEB_VIEWER Contracts

### Feature: show_model

```eiffel
show_model (mesh: SCULPTOR_MESH; port: INTEGER)
  require
    mesh /= Void
    port > 1024 and port < 65536
      -- Valid port range
    port_available (port)
      -- Port not in use
    not is_running
      -- Not already running

  ensure
    is_running
      -- Server started
    server_listening_on_port (port)
      -- Port bound
    browser_opened = True
      -- Browser window displayed
end
```

### Feature: shutdown

```eiffel
shutdown
  require
    is_running
      -- Must be running to shut down
  ensure
    not is_running
      -- Server stopped
    port_available (port)
      -- Port released
end
```

---

## POINT_CLOUD Contracts

### Feature: normalize_position

```eiffel
normalize_position: POINT_CLOUD
  require
    point_count > 0
  ensure
    result /= Void
    result.point_count = old.point_count
      -- Same number of points
    result.center.is_near_zero (epsilon := 0.0001)
      -- Centered at origin
    result.bounding_box.size ≈
      old.bounding_box.size
      -- Same overall size
end
```

### Feature: decimate

```eiffel
decimate (target_count: INTEGER): POINT_CLOUD
  require
    target_count > 100
    target_count < point_count
      -- Must reduce point count
  ensure
    result /= Void
    result.point_count <= target_count
      -- Target met
    result.point_count > target_count * 0.9
      -- Close to target (at least 90%)
end
```

---

## SCULPTOR_CLI Contracts

### Feature: run

```eiffel
run (args: ARRAY[STRING]): INTEGER
  require
    args /= Void
    args.count > 0
      -- Arguments provided
  ensure
    -- Success: exit code 0
    (result = 0) implies success_output_printed

    -- Failure: non-zero exit code
    (result /= 0) implies error_message_printed

    -- Help/version: exit code 1
    (args [0] = "--help" or args [0] = "--version")
      implies result = 0
end
```

---

## MML (Modular Model Language) Postconditions

For complex properties, use model functions:

```eiffel
-- Model function (ghost code for specs, not executed)
mesh_is_valid (m: SCULPTOR_MESH): BOOLEAN
  -- True if mesh passes all validation checks
  model ("mesh_valid")
end

-- Used in postcondition:
ensure
  result.is_success implies mesh_is_valid (result.data)
end
```

---

## Contract Enforcement Flags

**Compilation:**
```bash
ec -batch -config simple_sculptor.ecf -target tests \
   -check preconditions -check postconditions -check invariants
```

**Production (performance):**
```bash
ec -batch -config simple_sculptor.ecf -target app \
   -no_check  # Disable DBC overhead (only after validation)
```

---

## Testing Strategy (from Contracts)

Each contract defines test cases:

1. **Precondition Tests:**
   - Call features with invalid arguments
   - Verify precondition violations caught

2. **Postcondition Tests:**
   - Call valid features
   - Verify postconditions satisfied

3. **Invariant Tests:**
   - Create/modify objects
   - Verify invariants maintained

4. **MML Tests:**
   - Use model functions to check complex properties
   - Validate mesh quality, timing, etc.

---

**Document Status:** CONTRACT DESIGN COMPLETE, ready for INTERFACE DESIGN
