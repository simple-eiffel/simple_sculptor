# INTERFACE DESIGN: Public API & Usage Examples

## Overview

This document specifies the public API for simple_sculptor library, including all public classes, methods, and usage examples. The interface follows OOSC2 principles and is designed for ease of use.

---

## Library Entry Point

### SIMPLE_SCULPTOR (Main Class)

**Module:** `library/sculptor/simple_sculptor.e`

**Purpose:** Single entry point for library consumers

**Visibility:** Public (exported in ECF)

---

## Creation Routines

### make: SIMPLE_SCULPTOR
```eiffel
create {SIMPLE_SCULPTOR}.make

-- Result:
-- - Empty sculptor instance
-- - No model loaded
-- - No configuration set
-- - Ready for configuration via builder pattern
```

### make_with_model: SIMPLE_SCULPTOR
```eiffel
create {SIMPLE_SCULPTOR}.make_with_model (model_path: "/path/to/point-e.onnx")

-- Result:
-- - Model loaded into VRAM
-- - Ready to generate immediately
-- - Useful for repeated generations with same model
```

---

## Configuration Methods (Builder Pattern)

All configuration methods return `like Current` for method chaining.

### set_prompt (text: STRING): like Current
```eiffel
sculptor.set_prompt ("a blue ceramic vase")

-- Stores the text description for generation
-- Length: 10-500 characters
-- Encoding: UTF-8
```

### set_output_path (path: STRING): like Current
```eiffel
sculptor.set_output_path ("output.glb")

-- Sets where to write generated mesh file
-- Can be relative or absolute path
```

### set_format (fmt: STRING): like Current
```eiffel
sculptor.set_format ("glb")  -- "glb", "obj", "stl"

-- Selects output format
-- Default: "glb"
```

### set_vram_limit (mb: INTEGER): like Current
```eiffel
sculptor.set_vram_limit (12000)  -- MB

-- Sets VRAM budget for inference
-- Default: 14000 (2GB headroom on 16GB system)
-- If exceeded: graceful degradation (reduce point count)
```

### set_seed (seed: INTEGER): like Current
```eiffel
sculptor.set_seed (42)

-- Sets random seed for reproducibility
-- seed = 0: Random (non-deterministic)
-- seed > 0: Deterministic (same output for same input)
-- Default: 0 (random)
```

### with_interactive: like Current
```eiffel
sculptor.with_interactive

-- Enables interactive viewer mode
-- After generation: launches browser viewer
-- Serves local HTTP server for 3D inspection
```

### with_batch: like Current
```eiffel
sculptor.with_batch

-- Enables batch processing mode
-- Use with batch_generate for multiple prompts
```

---

## Status Queries (Read-Only)

### is_ready: BOOLEAN
```eiffel
if sculptor.is_ready then
  result := sculptor.generate
end

-- True if:
-- - Model loaded AND
-- - Configured (prompt + output path set)
```

### is_configured: BOOLEAN
```eiffel
if sculptor.is_configured then
  -- Have prompt and output_path, but maybe no model
end

-- True if minimum config set:
-- - prompt /= Void
-- - output_path /= Void
-- - output_format /= Void
```

### is_model_loaded: BOOLEAN
```eiffel
if sculptor.is_model_loaded then
  print ("Ready for inference")
end

-- True if ONNX model in GPU memory
```

### estimated_inference_time: INTEGER
```eiffel
time_ms := sculptor.estimated_inference_time
print ("Estimated time: " + (time_ms // 1000).out + " seconds")

-- Returns milliseconds (30,000 - 120,000)
-- Based on GPU type detected
-- RTX 5070 Ti: ~45,000ms
-- RTX 4090: ~20,000ms
-- RTX 4070: ~60,000ms
```

---

## Generation Operations

### generate: SCULPTOR_RESULT
```eiffel
result := sculptor
  .set_prompt ("a gothic cathedral")
  .set_output_path ("cathedral.glb")
  .set_format ("glb")
  .generate

if result.is_success then
  print ("Success! Mesh: " + result.data.triangle_count.out + " triangles")
  print ("Time: " + result.total_time_ms.out + "ms")
else
  print ("Error: " + result.error)
  print ("Code: " + result.error_code)
end
```

**Behavior:**
1. Validate configuration
2. Download model if needed (first run)
3. Execute Point-E inference (45-60 seconds)
4. Convert point cloud to mesh (5-15 seconds)
5. Export to specified format (1-5 seconds)
6. Return result (success with mesh or failure with error)

**Error Codes:**
- `"INVALID_PROMPT"` - Prompt validation failed
- `"CUDA_OOM"` - Out of GPU memory
- `"CUDA_ERROR"` - GPU driver issue
- `"DOWNLOAD_FAILED"` - Model download failed
- `"MESH_CONVERSION_FAILED"` - OpenVDB error
- `"EXPORT_FAILED"` - File write error
- `"TIMEOUT"` - Exceeded max time
- `"UNKNOWN"` - Unexpected error

### generate_and_view: SCULPTOR_RESULT
```eiffel
result := sculptor
  .set_prompt ("red racing helmet")
  .set_output_path ("helmet.glb")
  .with_interactive
  .generate_and_view

-- Generates mesh, then:
-- 1. Launches local HTTP server (port 8080)
-- 2. Opens browser to http://localhost:8080/view
-- 3. Displays GLB model with interactive controls
-- 4. User can: rotate, zoom, screenshot, download
```

**Controls:**
- **Rotate:** Left-click + drag mouse
- **Pan:** Middle-click + drag
- **Zoom:** Mouse wheel or pinch
- **Full-screen:** F key
- **Wireframe:** W key
- **Reset view:** HOME key
- **Screenshot:** Right-click menu or button
- **Download:** File menu

---

## Batch Generation (Phase 2)

### batch_generate (configs: LIST[SCULPTOR_CONFIG]): LIST[SCULPTOR_RESULT]
```eiffel
configs: LIST[SCULPTOR_CONFIG]
results: LIST[SCULPTOR_RESULT]

create {ARRAYED_LIST[SCULPTOR_CONFIG]} configs.make
configs.extend (
  create {SCULPTOR_CONFIG}.make
    .set_prompt ("wooden chair")
    .set_output_path ("chair.glb")
)
configs.extend (
  create {SCULPTOR_CONFIG}.make
    .set_prompt ("metal table")
    .set_output_path ("table.glb")
)

results := sculptor.batch_generate (configs)

-- Results: 2 SCULPTOR_RESULT objects
-- Processing: Sequential (one inference at a time)
-- Parallelism: Mesh conversion + export happen in parallel with next inference
```

---

## Usage Examples

### Example 1: Single Generation (Minimal)
```eiffel
local
  sculptor: SIMPLE_SCULPTOR
  result: SCULPTOR_RESULT
do
  create sculptor.make
  result := sculptor
    .set_prompt ("a cat")
    .set_output_path ("cat.glb")
    .generate

  if result.is_success then
    print ("Generated: cat.glb")
  else
    print ("Error: " + result.error)
  end
end
```

### Example 2: Interactive Generation
```eiffel
local
  sculptor: SIMPLE_SCULPTOR
  result: SCULPTOR_RESULT
do
  create {SIMPLE_SCULPTOR}.make_with_model ("/models/point-e.onnx")

  result := sculptor
    .set_prompt ("a vintage leather armchair")
    .set_output_path ("armchair.glb")
    .set_seed (42)          -- Reproducible
    .with_interactive
    .generate_and_view

  -- Browser opens automatically
  -- User inspects in 3D viewer
  -- Downloads or continues generating
end
```

### Example 3: Batch Processing
```eiffel
local
  prompts: LIST[STRING]
  configs: LIST[SCULPTOR_CONFIG]
  sculptor: SIMPLE_SCULPTOR
  results: LIST[SCULPTOR_RESULT]
  i: INTEGER
do
  create {ARRAYED_LIST[STRING]} prompts.make

  -- Load prompt list from file
  from_file.read_prompts (prompts)  -- e.g., 50 prompts

  -- Convert prompts to configs
  create {ARRAYED_LIST[SCULPTOR_CONFIG]} configs.make
  across prompts as p loop
    configs.extend (
      create {SCULPTOR_CONFIG}.make
        .set_prompt (p.item)
        .set_output_path ("output/model_" + i.out + ".glb")
    )
    i := i + 1
  end

  -- Generate all
  results := sculptor.batch_generate (configs)

  -- Process results
  i := 1
  across results as r loop
    if r.item.is_success then
      print ("Success: model_" + i.out + ".glb")
    else
      print ("Failed: " + r.item.error)
    end
    i := i + 1
  end
end
```

### Example 4: Different Export Formats
```eiffel
local
  sculptor: SIMPLE_SCULPTOR
  result_glb, result_obj, result_stl: SCULPTOR_RESULT
do
  -- Generate GLB (default)
  result_glb := sculptor
    .set_prompt ("a sword")
    .set_output_path ("sword.glb")
    .set_format ("glb")
    .generate

  -- Export same model as OBJ
  result_obj := sculptor
    .set_prompt ("a sword")
    .set_output_path ("sword.obj")
    .set_format ("obj")
    .generate

  -- Export as STL for 3D printing
  result_stl := sculptor
    .set_prompt ("a sword")
    .set_output_path ("sword.stl")
    .set_format ("stl")
    .generate
end
```

### Example 5: Error Handling
```eiffel
local
  sculptor: SIMPLE_SCULPTOR
  result: SCULPTOR_RESULT
do
  result := sculptor
    .set_prompt ("a bicycle")
    .set_output_path ("bicycle.glb")
    .set_vram_limit (8000)  -- Tight memory limit
    .generate

  inspect result.error_code
  when "CUDA_OOM" then
    print ("GPU out of memory")
    print ("Try: Close other GPU apps or reduce VRAM limit")

  when "INVALID_PROMPT" then
    print ("Prompt too short or empty")

  when "DOWNLOAD_FAILED" then
    print ("Model download failed")
    print ("Try: Manual download or check internet")

  else
    print ("Error: " + result.error)
  end
end
```

### Example 6: Mesh Validation
```eiffel
local
  sculptor: SIMPLE_SCULPTOR
  result: SCULPTOR_RESULT
  validation: MESH_VALIDATION_REPORT
do
  result := sculptor.set_prompt ("...").set_output_path ("...").generate

  if result.is_success then
    validation := result.data.validate

    if validation.is_manifold then
      print ("✓ Mesh is manifold (suitable for 3D printing)")
    else
      print ("✗ Mesh has topology errors")
    end

    if validation.has_self_intersections then
      print ("✗ Self-intersecting triangles detected")
    else
      print ("✓ No self-intersections")
    end

    print ("Printability score: " + validation.printability_score.out)
  end
end
```

---

## Advanced Configuration

### SCULPTOR_CONFIG (Fluent Configuration Builder)

**Create standalone config:**
```eiffel
local
  config: SCULPTOR_CONFIG
do
  config := create {SCULPTOR_CONFIG}.make
    .set_prompt ("a teapot")
    .set_output_path ("teapot.glb")
    .set_format ("glb")
    .set_seed (123)
    .set_vram_limit (12000)

  -- Later, pass to library
  result := sculptor.generate_from_config (config)
end
```

---

## Error Handling Strategy

**Pattern 1: Check is_success**
```eiffel
result := sculptor.generate
if result.is_success then
  -- Use result.data (mesh)
else
  -- Use result.error and result.error_code
end
```

**Pattern 2: Inspect error_code**
```eiffel
result := sculptor.generate
inspect result.error_code
when "CUDA_OOM" then
  -- Handle GPU memory error
when "TIMEOUT" then
  -- Handle timeout
else
  -- Handle other errors
end
```

**Pattern 3: Try-Catch (Future Phase)**
```eiffel
-- Future: Could add exceptions for critical errors
-- For Phase 1: Use result.is_success pattern
```

---

## Performance Considerations

### Inference Time Estimation
```eiffel
-- Check GPU before starting
time_ms := sculptor.estimated_inference_time

-- RTX 5070 Ti: ~45,000ms (45 seconds)
-- RTX 4090: ~20,000ms (20 seconds)
-- RTX 4070: ~60,000ms (60 seconds)

-- Show progress bar to user
print ("Estimated time: " + (time_ms // 1000).out + " seconds")
```

### Memory Management
```eiffel
-- Check available VRAM
available := sculptor.available_gpu_memory_mb
if available < 8000 then
  sculptor.set_vram_limit (available - 1000)  -- Leave 1GB headroom
end
```

### Cancellation (Phase 2)
```eiffel
-- Future: Support Ctrl+C during generation
-- Phase 1: No interactive cancellation
```

---

## Testing the API

### Unit Tests (Feature-Level)
```eiffel
test_set_prompt
  local
    sculptor: SIMPLE_SCULPTOR
  do
    create sculptor.make
    sculptor.set_prompt ("a cube")
    assert ("Prompt stored", sculptor.prompt = "a cube")
  end

test_generate_creates_file
  local
    sculptor: SIMPLE_SCULPTOR
    result: SCULPTOR_RESULT
  do
    create {SIMPLE_SCULPTOR}.make_with_model ("/models/point-e.onnx")
    result := sculptor
      .set_prompt ("a ball")
      .set_output_path ("/tmp/ball.glb")
      .generate

    assert ("Generation successful", result.is_success)
    assert ("File created", file_exists ("/tmp/ball.glb"))
    assert ("File not empty", file_size ("/tmp/ball.glb") > 0)
  end
```

### Integration Tests (End-to-End)
```eiffel
test_full_pipeline
  local
    sculptor: SIMPLE_SCULPTOR
    result: SCULPTOR_RESULT
  do
    -- Full flow: create → config → generate → validate
    create {SIMPLE_SCULPTOR}.make_with_model (model_path)

    result := sculptor
      .set_prompt ("a complex gear mechanism")
      .set_output_path ("gear.glb")
      .set_format ("glb")
      .generate

    assert ("Success", result.is_success)
    assert ("Mesh exists", result.data /= Void)
    assert ("Valid mesh", result.data.is_valid)
    assert ("Timing recorded", result.total_time_ms > 0)
  end
```

---

## Command-Line Interface (CLI)

**Note:** CLI is separate from library API. It wraps the library.

### Usage
```bash
# Single generation
simple_sculptor generate --prompt "a cat" --output cat.glb

# Interactive mode
simple_sculptor generate --prompt "a cat" --output cat.glb --interactive

# Batch generation
simple_sculptor batch prompts.txt --output-dir ./models

# View generated model
simple_sculptor view cat.glb --port 8080

# Show help
simple_sculptor --help
```

---

**Document Status:** INTERFACE DESIGN COMPLETE, ready for FULL SPECIFICATION
