# Phase 3: Task Decomposition - simple_sculptor

**Date**: 2026-01-31
**Status**: Implementation task breakdown from Phase 2 fixed contracts
**Total Tasks**: 24 implementation tasks organized by dependency layer

---

## Task Dependency Layers

```
LAYER 0: Utility Classes (no dependencies)
  ├─ Task 01: SCULPTOR_POINT_3D
  ├─ Task 02: SCULPTOR_VECTOR_3D
  ├─ Task 03: TEXT_PROMPT
  └─ Task 04: BOUNDING_BOX_3D

LAYER 1: Data Structures (depend on Layer 0)
  ├─ Task 05: POINT_CLOUD
  ├─ Task 06: MESH_VALIDATION_REPORT
  └─ Task 07: SCULPTOR_CONFIG

LAYER 2: Core Logic (depend on Layer 0-1)
  ├─ Task 08: SCULPTOR_RESULT
  ├─ Task 09: SCULPTOR_INFERENCE_RESULT
  └─ Task 10: MESH_CONVERTER

LAYER 3: System Integration (depend on Layer 0-2)
  ├─ Task 11: SCULPTOR_EXPORTER
  ├─ Task 12: SCULPTOR_MESH
  └─ Task 13: SCULPTOR_ENGINE

LAYER 4: Public API (depend on all)
  ├─ Task 14: SIMPLE_SCULPTOR (Facade)
  └─ Task 15-24: Integration & Testing
```

---

## LAYER 0: Utility Classes

### Task 01: Implement SCULPTOR_POINT_3D

**Acceptance Criteria**:
- ✓ make(x, y, z) initializes x, y, z correctly
- ✓ make_from_array(coords) unpacks first 3 elements as x, y, z
- ✓ distance_to(other) returns correct Euclidean distance √(Δx² + Δy² + Δz²)
- ✓ to_array() returns [x, y, z] in position 1-3
- ✓ All invariants satisfied: coordinates_finite, x_valid, y_valid, z_valid

**Implementation Notes**:
- Simple data holder with 3 REAL_32 fields
- distance_to() uses sqrt() function
- Make operations just assign fields

---

### Task 02: Implement SCULPTOR_VECTOR_3D

**Acceptance Criteria**:
- ✓ make(x, y, z) initializes x, y, z correctly
- ✓ make_zero() creates vector with x=y=z=0.0
- ✓ make_from_points(start, end) calculates displacement (end - start)
- ✓ magnitude() returns √(x² + y² + z²)
- ✓ dot_product(other) returns x*ox + y*oy + z*oz
- ✓ is_zero returns true only when x=y=z=0.0
- ✓ scale(factor) multiplies all components by factor
- ✓ normalize() divides by magnitude if magnitude > 0
- ✓ All invariants satisfied: components_finite, x_valid, y_valid, z_valid

**Implementation Notes**:
- scale() modifies self (not functional)
- normalize() should be safe (check for zero before dividing)

---

### Task 03: Implement TEXT_PROMPT

**Acceptance Criteria**:
- ✓ make(a_text) stores text as copy (twin)
- ✓ length returns text.count
- ✓ is_valid returns true if text.count > 0 and <= 1000
- ✓ Invariants: text_not_void, text_not_empty

**Implementation Notes**:
- Simple wrapper around STRING
- Store as twin to ensure independence from caller's string

---

### Task 04: Implement BOUNDING_BOX_3D

**Acceptance Criteria**:
- ✓ make(min_x, min_y, min_z, max_x, max_y, max_z) initializes all fields
- ✓ make_empty() creates (0,0,0,0,0,0)
- ✓ width = max_x - min_x
- ✓ height = max_y - min_y
- ✓ depth = max_z - min_z
- ✓ volume = width * height * depth
- ✓ contains_point(p) returns true iff p.x in [min_x, max_x] and p.y in [min_y, max_y] and p.z in [min_z, max_z]
- ✓ center() returns SCULPTOR_POINT_3D at (min+max)/2
- ✓ All invariants: bounds_consistent, coordinates_finite, min/max_valid

**Implementation Notes**:
- All operations are pure arithmetic
- center() creates new SCULPTOR_POINT_3D

---

## LAYER 1: Data Structures

### Task 05: Implement POINT_CLOUD

**Acceptance Criteria**:
- ✓ make(a_points) stores points array
- ✓ point_count = points.count // 3
- ✓ get_point(index) returns SCULPTOR_POINT_3D with coordinates from points[index*3..index*3+2]
- ✓ bounding_box() scans all points, returns BOUNDING_BOX_3D with min/max
- ✓ is_empty returns (point_count = 0)
- ✓ points_model returns copy of points array
- ✓ All invariants: points_not_void, count_valid

**Implementation Notes**:
- Index calculation: point i stored at array indices [i*3, i*3+1, i*3+2]
- bounding_box() must handle empty point cloud (min=max=0 for empty)
- points_model is for postcondition verification only

---

### Task 06: Implement MESH_VALIDATION_REPORT

**Acceptance Criteria**:
- ✓ make() initializes vertex_count=0, face_count=0, is_valid=true, error_messages empty
- ✓ error_count returns error_messages.count
- ✓ has_errors returns (error_count > 0)
- ✓ add_error(msg) appends message to list, sets is_valid=false
- ✓ set_mesh_stats(vc, fc) stores vertex_count, face_count
- ✓ All invariants: error_messages_not_void, error_count_matches, valid_xor_errors

**Implementation Notes**:
- Simple data aggregator
- error_messages is ARRAYED_LIST [STRING]
- XOR invariant: is_valid must be opposite of has_errors

---

### Task 07: Implement SCULPTOR_CONFIG

**Acceptance Criteria**:
- ✓ make() initializes voxel_size=0.1, seed=0, num_inference_steps=64
- ✓ set_voxel_size(size) stores size, returns Current
- ✓ set_seed(seed) stores seed, returns Current
- ✓ set_num_inference_steps(steps) stores steps, returns Current
- ✓ All postconditions verify correct assignment + frame conditions
- ✓ Invariants: voxel_size_valid

**Implementation Notes**:
- Builder pattern: all setters return like Current for chaining
- Frame conditions ensure other attributes unchanged

---

## LAYER 2: Core Logic

### Task 08: Implement SCULPTOR_RESULT

**Acceptance Criteria**:
- ✓ make_success(mesh) sets is_success=true, mesh=a_mesh, error_message=""
- ✓ make_failure(message) sets is_success=false, error_message=message.twin, mesh=Void
- ✓ summary() returns "Generation succeeded. Mesh: Vertices: X, Faces: Y" or "Generation failed: ERROR"
- ✓ Postconditions satisfied:
  - Success: is_success_set, mesh_set, error_cleared
  - Failure: is_failure, error_set, no_mesh
- ✓ Invariants: success_xor_error, success_implies_no_error, failure_implies_error, success_has_mesh, error_has_message

**Implementation Notes**:
- message_not_empty precondition enforced
- summary() must use attached check on detachable mesh
- XOR invariant enforced by precondition + postcondition design

---

### Task 09: Implement SCULPTOR_INFERENCE_RESULT

**Acceptance Criteria**:
- ✓ make_success(points) sets is_success=true, points=a_points, error_message=""
- ✓ make_failure(message) sets is_success=false, error_message=message.twin, points=Void
- ✓ message_not_empty precondition checked
- ✓ All postconditions and invariants satisfied (same as SCULPTOR_RESULT)

**Implementation Notes**:
- Parallel to SCULPTOR_RESULT but for POINT_CLOUD instead of SCULPTOR_MESH
- Identical semantics and invariants

---

### Task 10: Implement MESH_CONVERTER

**Acceptance Criteria**:
- ✓ make(voxel_size) stores voxel_size, verifies bounds [0.1, 1.0]
- ✓ convert(points) returns SCULPTOR_MESH with vertex_count > 0
- ✓ Output vertex count <= input point_count * 8
- ✓ convert_with_smoothing(points, iterations) same as convert, plus Laplacian smoothing
- ✓ Postconditions: output_not_empty, vertices_reasonable, smoothing_reduces_roughness
- ✓ Invariant: voxel_size_valid

**Implementation Notes**:
- Core algorithm: point cloud → voxel grid → marching cubes → mesh
- Voxelization: quantize points to grid (divide by voxel_size, round)
- Marching cubes: generate triangles from voxel occupancy
- Smoothing: iterative Laplacian filter (average vertex with neighbors)
- This is the most complex class in Phase 4

---

## LAYER 3: System Integration

### Task 11: Implement SCULPTOR_EXPORTER

**Acceptance Criteria**:
- ✓ make() initializes is_initialized=true
- ✓ export_to_glb(mesh, path) creates binary GLB file, returns success SCULPTOR_RESULT
- ✓ export_to_obj(mesh, path) creates text OBJ file, returns success SCULPTOR_RESULT
- ✓ export_to_stl(mesh, path) creates binary STL file, returns success SCULPTOR_RESULT
- ✓ All postconditions: result_not_void satisfied

**Implementation Notes**:
- GLB: binary glTF format with embedded geometry
- OBJ: text format with vertex/face definitions
- STL: binary format with triangle definitions
- File I/O error handling: return failure SCULPTOR_RESULT on I/O error
- Simple placeholder: can return success for Phase 4 (actual export in Phase 5+)

---

### Task 12: Implement SCULPTOR_MESH

**Acceptance Criteria**:
- ✓ make_empty() creates mesh with vertex_count=0, face_count=0
- ✓ make(vertices, faces) validates topology via faces_indices_valid()
- ✓ All face indices < vertex_count
- ✓ vertex_count = vertices.count // 3
- ✓ face_count = faces.count // 3
- ✓ bounding_box() scans vertices, returns BOUNDING_BOX_3D
- ✓ validate() returns MESH_VALIDATION_REPORT with topology checks
- ✓ to_glb/to_obj/to_stl delegate to SCULPTOR_EXPORTER
- ✓ Invariants: vertex_count_non_negative, face_count_non_negative

**Implementation Notes**:
- Store vertices/faces as arrays
- faces_indices_valid() is helper: validates range [0, vertex_count)
- validate() checks: non-manifold edges, degenerate triangles, isolated vertices
- Export methods: delegate to SCULPTOR_EXPORTER instance

---

### Task 13: Implement SCULPTOR_ENGINE

**Acceptance Criteria**:
- ✓ make() initializes is_model_loaded=false, device="CPU"
- ✓ set_model_path(path) stores path (only when not loaded)
- ✓ set_device(device) stores device, allows change even if loaded
- ✓ estimated_inference_time() returns: CUDA=15s, TensorRT=10s, CPU=60s
- ✓ load_model() loads ONNX model, sets is_model_loaded=true
- ✓ unload_model() unloads model, sets is_model_loaded=false
- ✓ execute(prompt, seed) runs inference, returns SCULPTOR_INFERENCE_RESULT
- ✓ All postconditions and frame conditions satisfied
- ✓ Invariant: device_valid

**Implementation Notes**:
- ONNX Runtime integration via C API (external "C inline")
- load_model: call ONNXCreateSession(model_path, ...)
- execute: call ONNXRun(session, input_tensor) → output_tensor
- output_tensor to POINT_CLOUD conversion
- This is Phase 4 skeleton; actual ONNX integration in Phase 5+
- For Phase 4: placeholder returns dummy POINT_CLOUD

---

## LAYER 4: Public API

### Task 14: Implement SIMPLE_SCULPTOR (Facade)

**Acceptance Criteria**:
- ✓ make() creates engine and config
- ✓ engine/config properties return non-void instances
- ✓ is_model_loaded delegates to engine.is_model_loaded
- ✓ estimated_inference_time delegates to engine (requires model_loaded)
- ✓ set_model_path(path) delegates, returns Current, frame conditions satisfied
- ✓ set_device(device) delegates (no model_loaded guard now), returns Current, frame conditions satisfied
- ✓ set_voxel_size(size) delegates, returns Current, frame conditions satisfied
- ✓ set_seed(seed) delegates, returns Current, frame conditions satisfied
- ✓ set_num_inference_steps(steps) delegates, returns Current, frame conditions satisfied
- ✓ load_model() delegates to engine, postcondition verified
- ✓ unload_model() delegates to engine, postcondition verified
- ✓ generate(prompt) orchestrates: engine.execute → POINT_CLOUD → mesh_converter.convert → SCULPTOR_RESULT
- ✓ generate_and_view(prompt) calls generate, exports via SCULPTOR_EXPORTER
- ✓ batch_generate(prompts) loops generate, each result satisfies XOR invariant
- ✓ All invariants: engine_not_void, config_not_void

**Implementation Notes**:
- Facade coordinates: config + engine + converter + exporter
- generate() pipeline:
  1. Call engine.execute(prompt, config.seed) → SCULPTOR_INFERENCE_RESULT
  2. If failure, return SCULPTOR_RESULT.make_failure(error)
  3. If success with points, call mesh_converter.convert(points, config.voxel_size) → SCULPTOR_MESH
  4. Return SCULPTOR_RESULT.make_success(mesh)
- generate_and_view(): after generate, call exporter.export_to_glb(mesh, temp_path), open in browser
- batch_generate(): for each prompt, call generate, append results to list

---

## LAYER 5: Integration & Testing

### Task 15: Integration - Configuration Pipeline

**Acceptance Criteria**:
- ✓ Chaining works: sculptor.set_device(...).set_voxel_size(...).set_seed(...)
- ✓ Each setter returns Current (verified by fluent API)
- ✓ Frame conditions ensure no cross-talk between setters
- ✓ After set_device, voxel_size unchanged
- ✓ After set_voxel_size, device unchanged
- ✓ After set_seed, all other settings unchanged
- ✓ After set_num_inference_steps, all other settings unchanged

**Implementation Notes**:
- Test via postcondition verification in unit tests
- Frame conditions are acceptance test

---

### Task 16: Integration - Model Lifecycle

**Acceptance Criteria**:
- ✓ set_model_path → load_model → is_model_loaded=true
- ✓ set_device can be called after load_model (no error)
- ✓ unload_model → is_model_loaded=false
- ✓ Double load_model fails (precondition: not_already_loaded)
- ✓ Double unload_model fails (precondition: is_loaded)

**Implementation Notes**:
- Test lifecycle state machine
- Verify preconditions prevent invalid transitions

---

### Task 17: Integration - Generation Pipeline

**Acceptance Criteria**:
- ✓ Model must be loaded before generate() (precondition enforced)
- ✓ generate(prompt) returns SCULPTOR_RESULT with is_success XOR error
- ✓ Success case: result.mesh not void, result.is_success=true
- ✓ Failure case: result.error_message not empty, result.is_success=false
- ✓ generate_and_view exports successfully
- ✓ batch_generate returns count = input count

**Implementation Notes**:
- Test with mock POINT_CLOUD and SCULPTOR_MESH
- Verify postconditions enforced

---

### Task 18: Integration - Mesh Validation

**Acceptance Criteria**:
- ✓ SCULPTOR_MESH.make validates face indices
- ✓ Invalid face index (>= vertex_count) fails precondition
- ✓ validate() detects topology issues
- ✓ to_glb/to_obj/to_stl succeed on valid mesh

**Implementation Notes**:
- Test topology validation helper
- Test MESH_VALIDATION_REPORT error collection

---

### Task 19: Integration - Error Handling

**Acceptance Criteria**:
- ✓ Empty error message prevented (precondition message_not_empty)
- ✓ XOR invariant enforced: success OR error, never both, never neither
- ✓ All failure paths return meaningful error messages
- ✓ No silent failures

**Implementation Notes**:
- Test with deliberately bad inputs
- Verify all error paths caught

---

### Task 20: Unit Test - SCULPTOR_POINT_3D

**Acceptance Criteria**:
- ✓ 7 test methods all pass (from test/test_sculptor_point_3d.e)
- ✓ Postconditions verified in each test

---

### Task 21: Unit Test - POINT_CLOUD

**Acceptance Criteria**:
- ✓ 5 test methods all pass
- ✓ Index calculations correct

---

### Task 22: Unit Test - SCULPTOR_MESH

**Acceptance Criteria**:
- ✓ 4 test methods all pass
- ✓ Topology validation works

---

### Task 23: Unit Test - MESH_CONVERTER

**Acceptance Criteria**:
- ✓ 4 test methods all pass
- ✓ Output bounds verified

---

### Task 24: Integration Test - Full Pipeline

**Acceptance Criteria**:
- ✓ SIMPLE_SCULPTOR.generate completes without assertion failure
- ✓ 26 test methods (from Phase 1) all pass
- ✓ TEST_APP test runner returns success
- ✓ 100% test pass rate

---

## Implementation Order

**Recommended parallel execution by layer**:

**Layer 0 (4 tasks)**: Tasks 01-04 (no dependencies)
- Can be implemented in parallel
- Estimated: 2-3 hours total

**Layer 1 (3 tasks)**: Tasks 05-07 (depend on Layer 0)
- Start after Layer 0 complete
- Estimated: 2-3 hours total

**Layer 2 (3 tasks)**: Tasks 08-10 (depend on Layer 0-1)
- Start after Layer 1 complete
- Task 10 (MESH_CONVERTER) most complex

**Layer 3 (3 tasks)**: Tasks 11-13 (depend on Layer 0-2)
- Estimated: 2-3 hours total

**Layer 4 (1 task)**: Task 14 (facade, depends on all)
- Start after Layer 3 complete
- Coordinates all subsystems

**Layer 5 (10 tasks)**: Tasks 15-24 (integration & testing)
- Start after Layer 4 complete
- Run in parallel

---

## Acceptance Criteria Summary

All 24 tasks have explicit acceptance criteria derived from Phase 2 postconditions:
- Each task describes testable conditions
- Each postcondition becomes acceptance test
- Each invariant becomes validation requirement
- Frame conditions become side-effect tests

---

## Phase 4 Implementation Strategy

1. **Weekly Standup**: Report progress per task (% complete)
2. **Acceptance Testing**: For each task, verify all acceptance criteria pass
3. **Continuous Integration**: After each task, run full test suite
4. **Code Review**: Peer review before marking task complete
5. **Documentation**: Update approach.md if assumptions change

---

## Completion Criteria for Phase 4

✓ All 24 tasks have acceptance criteria met
✓ All 26 test methods passing
✓ 100% test pass rate
✓ Zero assertion failures on postconditions
✓ Zero violations of invariants
✓ TEST_APP test runner exits with success

---

## Summary

**Phase 3 Complete**: 24 implementation tasks defined with explicit acceptance criteria.

Each task is:
- Testable (acceptance criteria are measurable)
- Traceable (back to Phase 2 postconditions)
- Independent (can be implemented in parallel within layer)
- Interdependent (clear dependency graph by layer)

**Ready for Phase 4 Implementation**
