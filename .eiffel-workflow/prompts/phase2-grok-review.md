# Eiffel Contract Review - Grok

You are reviewing Eiffel contracts with a focus on **edge cases, boundary conditions, and adversarial thinking**.

Ask: "What could go wrong with these contracts? What scenarios do they NOT handle?"

## Contracts Under Review

See prompts/phase2-ollama-review.md for full contract specifications.

## Previous Reviews (paste here)

### Ollama's Findings

```
[PASTE OLLAMA'S RESPONSE HERE]
```

### Claude's Findings

```
[PASTE CLAUDE'S RESPONSE HERE]
```

## Grok-Specific: Edge Case & Adversarial Analysis

### Edge Cases by Class

#### SIMPLE_SCULPTOR Edge Cases
- What if `set_device("GPU")` is called (not CPU/CUDA/TensorRT)? Precondition rejects it ✓
- What if `generate()` is called before loading model? Precondition `model_loaded` prevents it ✓
- What if `batch_generate(empty_list)` is called? Precondition `prompts_not_empty` prevents it ✓
- **Question**: What if `load_model` fails (file not found, corrupted ONNX)? Should there be a result type?
- **Question**: What if VRAM runs out during `load_model`? Currently no error handling.
- **Question**: What if `generate` takes longer than estimated_inference_time? Should there be a timeout?

#### SCULPTOR_ENGINE Edge Cases
- What if `set_model_path` is called with a non-existent file? Precondition checks not_void/not_empty but not existence
- **ISSUE**: Precondition should verify file exists before allowing load_model
- What if `execute()` is called with empty prompt? Precondition prevents it ✓
- **Question**: What if inference returns invalid point cloud (points outside expected range)? No validation.
- What if same model is loaded twice? Precondition `not_already_loaded` prevents it ✓

#### POINT_CLOUD Edge Cases
- What if points array has 4 elements? Precondition `count_divisible_by_3` would reject. But postcondition says `point_count = 4 // 3 = 1`. Mismatch? No, precondition prevents it ✓
- What if array is [Inf, NaN, -Inf, ...]? No validation of floating-point sanity
- **ISSUE**: Should have invariant `coordinates_valid: all points are finite numbers`
- What if bounding_box is called on empty cloud? Currently returns (0,0,0,0,0,0). Should it?
- **Question**: Should is_empty be a precondition for bounding_box?

#### MESH_CONVERTER Edge Cases
- What if voxel_size is exactly 0.1 or 1.0 (boundary)? Precondition allows it ✓
- What if convert() produces zero vertices? Postcondition says `result_not_void` but doesn't guarantee non-empty
- **ISSUE**: Should postcondition verify `Result.vertex_count > 0` if input is non-empty?
- What if smoothing iterations is 0 (no smoothing)? Precondition allows it ✓
- What if a point is NaN or Inf? Voxelization would fail silently or produce garbage

#### SCULPTOR_MESH Edge Cases
- What if make() is called with 0 vertices and 0 faces? Precondition allows it (empty is valid)
- What if face indices reference non-existent vertices (e.g., face = [0, 1, 1000])? No precondition validation
- **ISSUE**: make() should validate face indices <= vertex_count
- What if export paths are invalid (e.g., "/invalid/path/file.glb")? No precondition checks
- **ISSUE**: to_glb/to_obj/to_stl should verify path is writable or handle errors

#### SCULPTOR_RESULT Edge Cases
- What if make_failure receives empty string ""? Precondition allows it (message_not_void allows empty)
- **ISSUE**: Should have `message_not_empty: not a_message.is_empty`
- What if make_success receives mesh with 0 vertices? Currently allowed
- **ISSUE**: Maybe postcondition should verify `mesh.vertex_count > 0` OR `mesh.vertex_count = 0` is acceptable?

### Adversarial Scenarios

**Scenario 1: Malformed Input**
```
1. Create SIMPLE_SCULPTOR
2. set_model_path("nonexistent.onnx")
3. load_model()  -- What happens?
   - Precondition allows it (path is set, not void, not empty)
   - Implementation will fail but no contract covers this
   - No error result returned
```
**Fix**: Either (a) add file existence check to precondition, or (b) make load_model return a result type

**Scenario 2: Resource Exhaustion**
```
1. load_model("large_model.onnx")  -- 10GB ONNX model
2. generate("cat")
3. generate_and_view("dog")  -- VRAM exhausted
   - No postcondition guarantees success
   - No timeout handling
```
**Fix**: Document resource requirements or add timeout handling

**Scenario 3: Invalid Geometry**
```
1. Generate mesh with NaN coordinates
2. Export to GLB
3. Viewer crashes
```
**Fix**: Add invariant validating all coordinates are finite

**Scenario 4: Type Confusion**
```
1. set_device("cpu")  -- lowercase, not "CPU"
   - Precondition rejects it ✓ (correct)
2. set_device("NVIDIA")  -- common user mistake
   - Precondition rejects it ✓ (correct)
```
**Note**: Preconditions properly prevent this

### Contract Violation Scenarios

| Scenario | Precondition | Postcondition | Invariant | Current Status |
|----------|--------------|---------------|-----------|-----------------|
| Empty point cloud to convert | prompts_not_empty ✓ | points_not_empty ✓ | - | Prevented ✓ |
| Invalid device string | valid_device ✓ | - | device_valid ✓ | Prevented ✓ |
| Null pointer dereference | Various not_void ✓ | - | - | Prevented ✓ |
| NaN/Inf coordinates | MISSING ✗ | MISSING ✗ | MISSING ✗ | NOT Prevented ✗ |
| Invalid face indices | MISSING ✗ | MISSING ✗ | - | NOT Prevented ✗ |
| File write failures | MISSING ✗ | - | - | NOT Prevented ✗ |
| Empty error messages | MISSING ✗ | - | - | Allowed ✗ |

## Critical Issues Found

**CRITICAL-1**: No validation of floating-point sanity
- Where: POINT_CLOUD, SCULPTOR_POINT_3D, SCULPTOR_VECTOR_3D
- Impact: NaN/Inf coordinates can propagate through entire pipeline
- Fix: Add invariant `coordinates_valid: x.is_finite and y.is_finite and z.is_finite`

**CRITICAL-2**: No validation of mesh topology
- Where: SCULPTOR_MESH.make()
- Impact: Face indices can reference non-existent vertices, causing crashes
- Fix: Add precondition or postcondition validating all face indices

**CRITICAL-3**: Model loading has no error handling
- Where: SCULPTOR_ENGINE.load_model()
- Impact: If file doesn't exist or is corrupted, contract doesn't cover failure
- Fix: Either verify file exists (precondition) or return result type (postcondition)

**CRITICAL-4**: Empty error messages violate XOR invariant
- Where: SCULPTOR_RESULT, SCULPTOR_INFERENCE_RESULT
- Impact: `success_xor_error: is_success xor (not error_message.is_empty)`
- Current: Empty string is treated as "no error" - is this correct?
- Fix: Make precondition `message_not_empty: not a_message.is_empty`

## High Priority Issues

**HIGH-1**: Frame conditions missing for configuration setters
- `set_voxel_size` changes voxel_size but should specify other config unchanged

**HIGH-2**: File I/O without error handling
- `to_glb/to_obj/to_stl` assume path is writable, but don't verify

**HIGH-3**: Detachable attributes without clear semantics
- `model_path: detachable STRING` - when is it void? Precondition requires set before use ✓

## Recommendations

1. **Add coordinate validation**: Invariant on all geometry classes
2. **Add topology validation**: Precondition/postcondition for mesh creation
3. **Add file handling**: Either precondition (path exists) or postcondition (file created)
4. **Clarify error semantics**: Empty string vs. meaningful error messages
5. **Consider result types**: For I/O operations that can fail

---

**Provide your adversarial analysis and edge case findings.**
