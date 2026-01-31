# Phase 2 Review Synopsis - simple_sculptor Contracts

**Project**: simple_sculptor
**Date**: 2026-01-31
**Reviews Completed**: Ollama (basic issues) + Claude (semantic/MML analysis)
**Status**: **NOT READY FOR PHASE 4 - CRITICAL ISSUES FOUND**

---

## Executive Summary

Phase 2 reviews identified **10 critical and high-priority contract gaps** that must be fixed before Phase 4 implementation can proceed. The skeleton contracts from Phase 1 are well-structured but lack crucial semantic rigor and mathematical specifications needed for correct implementation.

**Overall Quality Score: 1.3/5** (down from 2.3/5 after MML analysis)

**Verdict**: **APPROVED WITH CRITICAL FIXES** - Must address 10 issues before proceeding

---

## Critical Issues (Must Fix Before Phase 4)

### 1. XOR Invariant Allows Nonsensical States
**Classes**: SCULPTOR_RESULT, SCULPTOR_INFERENCE_RESULT
**Severity**: CRITICAL
**Current Contract**:
```eiffel
invariant
  success_xor_error: is_success xor (not error_message.is_empty)
```
**Problem**: Allows state where both are false (is_success=False AND error_message="")
            This violates semantic XOR (should be exactly one true)
**Required Fix**:
```eiffel
invariant
  exactly_one: is_success xor (error_message.count > 0)
  success_implies_no_error: is_success implies error_message.is_empty
  failure_implies_error: (not is_success) implies (not error_message.is_empty)
```
**Implementation Impact**: HIGH - Will cause assertion failures if empty error messages are allowed

---

### 2. Empty Error Messages Violate Precondition Intent
**Classes**: SCULPTOR_RESULT.make_failure, SCULPTOR_INFERENCE_RESULT.make_failure
**Severity**: CRITICAL
**Current Contract**:
```eiffel
make_failure (a_message: STRING)
  require
    message_not_void: a_message /= Void  -- Allows empty string!
```
**Problem**: Precondition allows empty string "", but semantics of "failure with no message" undefined
**Required Fix**:
```eiffel
make_failure (a_message: STRING)
  require
    message_not_void: a_message /= Void
    message_not_empty: not a_message.is_empty  -- NEW
```
**Implementation Impact**: CRITICAL - All postconditions depend on meaningful error messages

---

### 3. Configuration Setters Have No Frame Conditions
**Classes**: SIMPLE_SCULPTOR (all set_* methods)
**Severity**: CRITICAL
**Current Contract**:
```eiffel
set_voxel_size (a_size: REAL): like Current
  ensure
    result_is_current: Result = Current
```
**Problem**: Doesn't specify what changes/doesn't change. Implementation could silently corrupt:
- device when setting voxel_size
- voxel_size when setting device
- model_loaded state
**Required Fix**:
```eiffel
set_voxel_size (a_size: REAL): like Current
  ensure
    result_is_current: Result = Current
    voxel_size_set: config.voxel_size = a_size
    device_preserved: engine.device = old engine.device
    model_preserved: is_model_loaded = old is_model_loaded
    seed_preserved: config.seed = old config.seed
    steps_preserved: config.num_inference_steps = old config.num_inference_steps
```
**Apply to**: set_device, set_voxel_size, set_seed, set_num_inference_steps (5 methods total)
**Implementation Impact**: CRITICAL - Caller assumptions about side effects undefined

---

### 4. Mesh Topology Validation Missing
**Classes**: SCULPTOR_MESH.make()
**Severity**: CRITICAL
**Current Contract**:
```eiffel
make (a_vertices: ARRAY [REAL_32]; a_faces: ARRAY [INTEGER])
  require
    faces_divisible_by_3: a_faces.count \\ 3 = 0  -- Only checks count, not validity
```
**Problem**: Face indices can reference non-existent vertices
**Required Fix**:
```eiffel
make (a_vertices: ARRAY [REAL_32]; a_faces: ARRAY [INTEGER])
  require
    faces_divisible_by_3: a_faces.count \\ 3 = 0
    faces_valid_indices: forall i in 0..a_faces.count-1:
                           a_faces[i] >= 0 and a_faces[i] < (a_vertices.count // 3)
```
**Implementation Impact**: CRITICAL - Without this, mesh can have invalid topology

---

### 5. Floating-Point Sanity Not Validated
**Classes**: SCULPTOR_POINT_3D, SCULPTOR_VECTOR_3D, POINT_CLOUD, BOUNDING_BOX_3D
**Severity**: CRITICAL
**Current Contract**: No validation that coordinates are finite (not NaN, not Inf)
**Problem**: NaN/Inf propagates through entire 3D pipeline, producing garbage output
**Required Fix**: Add invariants to all geometry classes:
```eiffel
class SCULPTOR_POINT_3D
  invariant
    coordinates_finite: x.is_finite and y.is_finite and z.is_finite
end

class POINT_CLOUD
  invariant
    all_points_finite: across points as ic all
                         (ic.item >= 0 implies ic.item.is_finite)
                       end
end
```
**Implementation Impact**: CRITICAL - Core geometry validity depends on this

---

### 6. Device Lifecycle Conflict
**Classes**: SIMPLE_SCULPTOR, SCULPTOR_ENGINE
**Severity**: CRITICAL
**Problem**:
- SCULPTOR_ENGINE.set_device() has precondition: `not_loaded: not is_model_loaded`
- But SIMPLE_SCULPTOR.set_device() delegates without checking
- Result: User calls set_device after load_model → precondition violated
**Required Fix**: Either:
```
(A) Remove not_loaded guard from SCULPTOR_ENGINE.set_device()
    (Allow device changes even if model loaded - risky)
OR
(B) Add check in SIMPLE_SCULPTOR.set_device():
      require not is_model_loaded
    (Then user cannot change device after loading model)
OR
(C) Make it an error result type:
      set_device(...): SCULPTOR_RESULT  (returns failure if model loaded)
```
**Recommended**: Option (A) - remove not_loaded guard, add warning in comment
**Implementation Impact**: CRITICAL - Contract contradiction prevents valid use cases

---

### 7. File I/O Operations Lack Error Handling
**Classes**: SCULPTOR_ENGINE.load_model(), SCULPTOR_MESH.to_glb/to_obj/to_stl()
**Severity**: CRITICAL
**Current Contract**:
```eiffel
load_model
  ensure
    loaded: is_model_loaded
```
**Problem**: Precondition only checks model_path /= Void, not file existence or validity
             If file doesn't exist, load fails but postcondition guarantees success
**Required Fix**: Either:
```
(A) Add precondition:
      file_exists: {EXTERNAL}.file_exists(model_path)
OR
(B) Make load_model return result type:
      load_model: SCULPTOR_RESULT
      (returns failure if file not found, parsing fails, etc.)
```
**Apply to**: load_model, to_glb, to_obj, to_stl (all file operations)
**Recommended**: Option (B) - use result types for I/O operations
**Implementation Impact**: CRITICAL - File operations can fail silently

---

### 8. Missing MML Model Queries for POINT_CLOUD
**Classes**: POINT_CLOUD
**Severity**: CRITICAL (for MML-based verification)
**Current Contract**: No model query specified
**Required Addition**:
```eiffel
class POINT_CLOUD
  points_model: MML_SEQUENCE [REAL_32]
    do
      create Result
      across points as ic loop
        Result := Result.appended (@ic.item)
      end
    ensure
      result_size: Result.count = points.count
    end

  make (a_points: ARRAY [REAL_32])
    ensure
      points_model_set: points_model.items = a_points_model.items
      points_count: point_count = a_points.count // 3
    end
end
```
**Implementation Impact**: HIGH - Enables precise frame conditions for postconditions

---

### 9. Missing MML Topological Model for SCULPTOR_MESH
**Classes**: SCULPTOR_MESH
**Severity**: HIGH (for MML-based verification)
**Current Contract**: Only counts, no topology model
**Required Addition**:
```eiffel
class SCULPTOR_MESH
  vertices_model: MML_SEQUENCE [SCULPTOR_POINT_3D]
  faces_model: MML_SEQUENCE [INTEGER_TRIPLE]

  make (a_vertices: ARRAY [REAL_32]; a_faces: ARRAY [INTEGER])
    ensure
      vertices_model_set: vertices_model.count = a_vertices.count // 3
      faces_model_set: faces_model.count = a_faces.count // 3
    end
end
```
**Implementation Impact**: HIGH - Enables verification that mesh structure preserved

---

### 10. Mesh Conversion Semantics Undefined
**Classes**: MESH_CONVERTER.convert()
**Severity**: HIGH
**Current Contract**: Only says result_not_void
**Required Fix**:
```eiffel
convert (a_points: POINT_CLOUD): SCULPTOR_MESH
  ensure
    result_not_void: Result /= Void
    output_not_empty: Result.vertex_count > 0
    output_bounds_input: Result.bounding_box.contains(a_points.bounding_box)
    voxel_size_effect: Result vertex density inversely proportional to voxel_size
  end
```
**Implementation Impact**: HIGH - Voxelization correctness depends on input-output invariant

---

## High-Priority Issues (Should Fix)

| Issue | Class | Problem | Fix |
|-------|-------|---------|-----|
| generate() too weak | SIMPLE_SCULPTOR.generate | Postcondition only says result_not_void | Add success_xor_error verification |
| batch_generate incomplete | SIMPLE_SCULPTOR.batch_generate | No verification of individual results | Each result must satisfy XOR invariant |
| Model loading no error path | SCULPTOR_ENGINE | load_model assumes success | Change to return SCULPTOR_RESULT |
| Export paths unchecked | SCULPTOR_MESH | to_glb/to_obj/to_stl assume writable | Check path validity or return result |
| Success with empty mesh | SCULPTOR_RESULT | Allows is_success=True, vertex_count=0 | Add: success implies mesh.vertex_count > 0 |

---

## Contract Quality Assessment

### Ollama Review (Basic Issues)
**Score: 2.3/5**

Strengths:
- ✓ Preconditions prevent invalid inputs (device validation, path not empty)
- ✓ Postconditions use proper naming (path_set, device_set)
- ✓ XOR pattern structure correct (is_success xor error)
- ✓ Detachable attributes handled (attached checks in code)

Weaknesses:
- ✗ Missing file validation
- ✗ Missing frame conditions
- ✗ No mesh topology validation
- ✗ No floating-point sanity checks
- ✗ Device lifecycle conflict

### Claude Review (Semantic + MML)
**Score: 1.3/5** (additional findings)

Strengths:
- ✓ Void-safety patterns correct (attached checks good)
- ✓ Invariant structure solid

Weaknesses:
- ✗ XOR semantically loose (allows empty error messages)
- ✗ **Missing MML model queries** (cannot specify precise postconditions)
- ✗ **No frame conditions** (configuration setters unspecified)
- ✗ **No old-state reasoning** (don't know what actually changed)
- ✗ Detachable semantics unclear (when is mesh void?)

### Combined Assessment
**Overall Quality: 1.3/5**

```
Precondition strength:      2/5  (missing file/mesh validation)
Postcondition completeness: 1/5  (too many "result_not_void" only)
Invariant coverage:         3/5  (XOR good but semantically loose)
Frame conditions:           0/5  (completely missing)
MML completeness:           1/5  (no model queries)
Void safety:                5/5  (patterns correct throughout)
File I/O handling:          0/5  (no error paths)
─────────────────────────────────
OVERALL:                    1.3/5
```

---

## Implementation Risk Assessment

**If we proceed WITHOUT fixes**:

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| File not found during load_model → assertion failure | CRITICAL | Implementation will violate postcondition | ADD: file existence check |
| Empty error messages → XOR invariant violated | CRITICAL | Code crashes on empty message | ADD: message_not_empty |
| NaN/Inf coordinates propagate | HIGH | Garbage geometry output | ADD: coordinate validation |
| Invalid face indices | HIGH | Mesh corruption/crashes | ADD: topology validation |
| Device changed silently during config | HIGH | User confusion, state corruption | ADD: frame conditions |
| Configuration modifications during batch_generate | MEDIUM | Batch processing corrupts state | ADD: frame conditions |

**Risk Level if Proceeding As-Is: CRITICAL**

---

## Recommendation: APPROVED WITH CRITICAL FIXES

### Status: **NOT READY FOR PHASE 4 YET**

### Action Required: Fix 10 issues, then re-review

### Priority (Order to Fix):
1. **CRITICAL-2**: Add message_not_empty to make_failure (5 min fix)
2. **CRITICAL-1**: Add frame conditions to all setters (10 min fix)
3. **CRITICAL-4**: Add mesh topology validation (10 min fix)
4. **CRITICAL-5**: Add coordinate validation to geometry (5 min fix)
5. **CRITICAL-6**: Fix device lifecycle conflict (5 min fix)
6. **CRITICAL-3**: Change file I/O to use result types (15 min fix)
7. **CRITICAL-7**: Add MML model queries to POINT_CLOUD (10 min fix)
8. **CRITICAL-8**: Add MML topological model to SCULPTOR_MESH (10 min fix)
9. **CRITICAL-9**: Add mesh conversion invariants (5 min fix)
10. **CRITICAL-10**: Strengthen error message semantics (5 min fix)

**Estimated total fix time: ~75 minutes**

---

## Next Steps

### Phase 2B: Contract Fixes (NEW)
1. Apply all 10 fixes to source classes
2. Update approach.md with implementation strategy
3. Recompile to verify contract syntax

### Phase 3: Task Decomposition (AFTER FIXES)
1. Break fixed contracts into 14-20 implementation tasks
2. Assign acceptance criteria from postconditions

### Phase 4: Implementation (AFTER PHASE 3)
1. Implement feature bodies (keep contracts frozen)
2. All postconditions must be satisfied
3. Test against MML model queries

---

## Conclusion

**Verdict**: **APPROVED WITH CRITICAL FIXES REQUIRED**

Phase 1 created a solid skeleton with good class structure and naming. Phase 2 reviews reveal that **semantic correctness and mathematical rigor are missing**, not the skeleton itself.

These 10 issues are **fixable** and **not fundamental redesign required**. They're mostly:
- Missing preconditions (file validation, message validation)
- Missing postconditions (frame conditions, state changes)
- Missing MML model queries (for precise verification)
- Semantic clarification (error handling, device lifecycle)

**After fixes**: Contracts will be Phase 4-ready with strong semantic guarantees.

**Estimated effort to fix**: ~1.5 hours to apply all 10 changes
**Estimated effort to re-review**: ~30 min for focused verification

**Proceed with contract fixes immediately to stay on schedule.**

---

**Review Complete**: 2026-01-31
**Status**: AWAITING CONTRACT FIXES
**Next Review**: After fixes applied to verify Phase 4 readiness
