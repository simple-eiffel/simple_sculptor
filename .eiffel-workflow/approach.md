# Implementation Approach: simple_sculptor Phase 4

## Overview

This document sketches the implementation strategy for simple_sculptor's feature bodies, keeping all contracts frozen.

## Phase 4 Implementation Strategy

### Principle: Contracts First

- All preconditions and postconditions are FROZEN (Phase 1)
- Postconditions define success criteria - implementation must satisfy them
- Preconditions define caller obligations - implementation can assume they're met
- Invariants must be maintained by every feature

### Architectural Layers

```
┌─────────────────────────────────────┐
│  SIMPLE_SCULPTOR (Facade)           │ Public API
├─────────────────────────────────────┤
│  • generate(prompt)                 │ Orchestrates pipeline
│  • load_model(path)                 │ ONNX model management
│  • set_device(device)               │ Device selection
└────────┬────────────────────────────┘
         │ delegates to
         ▼
┌─────────────────────────────────────┐
│  SCULPTOR_ENGINE (ONNX Integration) │ System layer
├─────────────────────────────────────┤
│  • load_model(path)                 │ Load ONNX Runtime
│  • execute_inference(...)           │ Call ONNX model
│  • estimated_inference_time()       │ Device-specific estimates
└────────┬────────────────────────────┘
         │ produces
         ▼
┌─────────────────────────────────────┐
│  SCULPTOR_INFERENCE_RESULT          │ ONNX output
├─────────────────────────────────────┤
│  • points: POINT_CLOUD              │ Success: 3D points
│  • error_message: STRING            │ Failure: error
└────────┬────────────────────────────┘
         │ feeds into
         ▼
┌─────────────────────────────────────┐
│  MESH_CONVERTER (Geometry)           │ Processing layer
├─────────────────────────────────────┤
│  • convert(points) → SCULPTOR_MESH  │ Voxelization + meshing
│  • convert_with_smoothing(...)      │ Optional smoothing
└────────┬────────────────────────────┘
         │ produces
         ▼
┌─────────────────────────────────────┐
│  SCULPTOR_MESH (Output)             │ Final geometry
├─────────────────────────────────────┤
│  • vertices: ARRAY [REAL_32]        │ XYZ coordinates
│  • faces: ARRAY [INTEGER]           │ Triangle indices
│  • to_glb(path)                     │ Export to formats
└─────────────────────────────────────┘
```

## Implementation Order (Dependency Graph)

### Level 0: Utility Classes (No dependencies)
1. **SCULPTOR_POINT_3D** - Simple data holder (3 REAL_32 fields)
2. **SCULPTOR_VECTOR_3D** - Math operations (magnitude, normalize)
3. **TEXT_PROMPT** - Validation only
4. **BOUNDING_BOX_3D** - Geometric bounds calculation

### Level 1: Data Structures (Depend on Level 0)
5. **POINT_CLOUD** - Array of points, bounding box query
6. **MESH_VALIDATION_REPORT** - Error collection
7. **SCULPTOR_CONFIG** - Builder pattern, store settings

### Level 2: Core Logic (Depend on Level 1)
8. **SCULPTOR_RESULT** - Generic success/failure
9. **SCULPTOR_INFERENCE_RESULT** - ONNX-specific result
10. **MESH_CONVERTER** - Point cloud → mesh algorithm

### Level 3: System Integration (Depend on Level 2)
11. **SCULPTOR_EXPORTER** - Format conversion
12. **SCULPTOR_MESH** - Mesh data + operations
13. **SCULPTOR_ENGINE** - ONNX Runtime integration

### Level 4: Public API (Depend on Level 3)
14. **SIMPLE_SCULPTOR** - Facade orchestration

## Class Implementation Details

### SCULPTOR_POINT_3D

**Purpose:** Immutable 3D point
**Data:** x, y, z (REAL_32)
**Methods:**
- `make(x, y, z)` - Direct initialization
- `make_from_array(coords)` - Array unpacking
- `distance_to(other)` - Euclidean distance (√(Δx² + Δy² + Δz²))
- `to_array()` - Export to [x, y, z]

**Implementation notes:**
- All operations use floating-point arithmetic
- No special ONNX integration needed
- Pure geometry class

### SCULPTOR_VECTOR_3D

**Purpose:** 3D direction vector with magnitude operations
**Data:** x, y, z (REAL_32)
**Methods:**
- `make(x, y, z)` - Direct initialization
- `make_zero()` - Zero vector
- `make_from_points(start, end)` - Displacement vector
- `magnitude()` - Length calculation
- `dot_product(other)` - Dot product
- `scale(factor)` - In-place scaling
- `normalize()` - Unit length (if non-zero)

**Implementation notes:**
- `magnitude()` uses sqrt() on sum of squares
- `normalize()` checks for zero vector before scaling
- `scale()` modifies self (not functional)

### POINT_CLOUD

**Purpose:** Collection of 3D points from ONNX inference
**Data:** points (ARRAY [REAL_32]) - flat [x0, y0, z0, x1, y1, z1, ...]
**Methods:**
- `make(points)` - Initialize from flat array
- `point_count` - Calculate count (array.count // 3)
- `get_point(index)` - Retrieve point as SCULPTOR_POINT_3D
- `bounding_box()` - Min/max bounds
- `is_empty` - Check if zero points

**Implementation notes:**
- Precondition: array.count must be divisible by 3
- Index calculation: point i starts at position i*3
- Bounding box: scan all points, track min/max in x, y, z

### MESH_CONVERTER

**Purpose:** Voxel-based conversion from point cloud to mesh
**Data:** voxel_size (REAL_32, 0.1 to 1.0)
**Methods:**
- `make(voxel_size)` - Initialize with voxel resolution
- `convert(points)` - Produce mesh
- `convert_with_smoothing(points, iterations)` - With Laplacian smoothing

**Implementation notes:**
- Voxelization: Quantize points to grid (voxel_size)
- Marching cubes or similar: Generate triangles from voxel grid
- Smoothing: Iterative Laplacian filter (average neighbor vertices)
- This is Phase 4 skeleton - full algorithm in Phase 4 implementation

### SCULPTOR_RESULT

**Purpose:** Generic success/failure result with mesh
**Data:**
- is_success (BOOLEAN)
- mesh (detachable SCULPTOR_MESH)
- error_message (STRING)
**Methods:**
- `make_success(mesh)` - Create success result
- `make_failure(message)` - Create failure result
- `summary()` - Human-readable text

**Implementation notes:**
- XOR invariant: success XOR has_error (never both, never neither)
- Postconditions verify this invariant after creation
- `summary()` uses attached check on mesh for safe access

### SCULPTOR_INFERENCE_RESULT

**Purpose:** ONNX-specific result (points or error)
**Data:**
- is_success (BOOLEAN)
- points (detachable POINT_CLOUD)
- error_message (STRING)
**Methods:**
- `make_success(points)` - ONNX succeeded, return point cloud
- `make_failure(message)` - ONNX failed, return error

**Implementation notes:**
- Same XOR pattern as SCULPTOR_RESULT
- Preconditions ensure non-void inputs
- Postconditions verify state consistency

### SCULPTOR_MESH

**Purpose:** Solid geometry with vertices and triangular faces
**Data:**
- vertex_count (INTEGER)
- face_count (INTEGER)
- vertices (ARRAY [REAL_32]) - flat [x0, y0, z0, ...]
- faces (ARRAY [INTEGER]) - flat [v0, v1, v2, v0, v1, v2, ...]
**Methods:**
- `make_empty()` - Create empty mesh
- `make(vertices, faces)` - Initialize with data
- `bounding_box()` - Spatial bounds
- `validate()` - Check topology
- `to_glb/obj/stl(path)` - Export formats

**Implementation notes:**
- Faces are stored as flat array of vertex indices (3 per triangle)
- Bounding box: scan all vertices (same as POINT_CLOUD)
- Validation: Check face indices < vertex count, detect non-manifold edges
- Export: Each format has different serialization (binary GLB, text OBJ, binary STL)

### SCULPTOR_ENGINE

**Purpose:** ONNX Runtime integration
**Data:**
- model_path (STRING)
- device (STRING)
- model_handle (external C handle to ONNX model)
- is_model_loaded (BOOLEAN)
**Methods:**
- `set_model_path(path)` - Configure model file
- `set_device(device)` - CPU/CUDA/TensorRT
- `load_model()` - Load ONNX model
- `execute_inference(prompt, steps)` - Run ONNX model
- `estimated_inference_time()` - Device-specific estimate
- `unload_model()` - Free VRAM

**Implementation notes:**
- ONNX Runtime integration via external C library
- Inline C calling: `external "C inline use \"onnxruntime_c_api.h\""`
- load_model: Call `ONNXCreateSession(model_path, ...)`
- execute_inference: Call `ONNXRun(session, tensors)` → returns ONNX_TENSOR
- estimated_inference_time: Return hardcoded values (CPU: 60s, CUDA: 15s, TensorRT: 10s)

### SIMPLE_SCULPTOR (Facade)

**Purpose:** Public API orchestrating the pipeline
**Data:**
- engine (SCULPTOR_ENGINE)
- config (SCULPTOR_CONFIG)
**Methods:**
- `make()` - Initialize engine and config
- `set_device/set_voxel_size/set_seed/set_num_inference_steps()` - Configuration
- `load_model/unload_model()` - Model management
- `generate(prompt)` - Main pipeline
- `generate_and_view(prompt)` - With browser viewer
- `batch_generate(prompts)` - Multiple generation

**Implementation notes:**
- `generate()` orchestrates:
  1. Call engine.execute_inference(prompt) → SCULPTOR_INFERENCE_RESULT
  2. If error, return failure result
  3. If points, call MESH_CONVERTER.convert(points) → SCULPTOR_MESH
  4. Return success result with mesh
- `batch_generate()` loops generate() over prompt list
- `generate_and_view()` calls generate() then exports to web viewer

## Contract Satisfaction Strategy

### Preconditions
- Assume all preconditions are satisfied (caller's responsibility)
- Check boundaries and validity only where postcondition requires verification
- Example: `estimated_inference_time()` requires `model_loaded` - assume it's true

### Postconditions
- Every postcondition is a hard requirement that implementation must satisfy
- Use postcondition contracts to verify correctness after each feature
- Example: `mesh_set: mesh = a_mesh` - must assign exact same mesh object

### Invariants
- XOR patterns must be maintained: success XOR error
- Resource invariants: collections non-void
- Bounds invariants: voxel_size in range

## Testing Strategy (Phase 5)

Each postcondition becomes a test assertion:
- `test_generate_returns_result`: Verify `result_not_void`
- `test_mesh_set_on_success`: Verify `mesh_set: mesh = expected`
- `test_error_set_on_failure`: Verify `error_set: error_message.same_string(...)`

## Known Gaps (Phase 4)

- ONNX Runtime C API integration (external C code needed)
- Marching cubes algorithm for mesh generation (geometry algorithm)
- Laplacian smoothing implementation (numerical computation)
- GLB/OBJ/STL format serialization (file I/O)

These will be implemented in Phase 4 with full contract compliance.

## Summary

Phase 4 will implement ~2000 lines of logic code while keeping all 120+ contracts frozen. Implementation follows strict layering: utilities → data structures → core logic → system integration → public API.

Every feature body must satisfy its postcondition. Every invariant must be maintained. Every precondition can be assumed.
