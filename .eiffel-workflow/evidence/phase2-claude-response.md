# Claude Contract Review - simple_sculptor (Semantic + MML Analysis)

**Status**: COMPLETE
**Date**: 2026-01-31
**Focus**: MML completeness, frame conditions, semantic correctness, void safety

## Context

This review builds on Ollama's findings (5 critical issues identified). Claude analysis focuses on:
- Semantic correctness of contracts
- Mathematical Modeling Language (MML) requirements
- Frame conditions using model equality
- Old-state reasoning with `old` expressions
- Void-safety patterns

## Semantic Analysis

### Contract Correctness Issues

**SEMANTIC-1: Frame condition semantic gap in SIMPLE_SCULPTOR**
```
LOCATION: SIMPLE_SCULPTOR.set_device, set_voxel_size, set_seed, set_num_inference_steps
SEVERITY: CRITICAL (Semantic)
ISSUE: Builder methods state result=Current (fluent API), but don't semantically specify
        what configuration state they modify vs preserve.
SEMANTIC PROBLEM: Caller assumes each setter only modifies its parameter, but contracts
                  don't guarantee this. Implementation could have cross-talk between settings.
EXAMPLE: set_device("CUDA") could accidentally reset voxel_size to default
CLAUDE_SUGGESTION: Use explicit frame conditions in postconditions:
  set_voxel_size(a_size) ensures:
    voxel_size_set: config.voxel_size = a_size
    device_preserved: engine.device = old engine.device
    seed_preserved: config.seed = old config.seed
    steps_preserved: config.num_inference_steps = old config.num_inference_steps
    is_model_loaded_preserved: is_model_loaded = old is_model_loaded
RATIONALE: Without frame conditions, postcondition is incomplete. "result_is_current"
           alone doesn't prevent silent state corruption.
```

**SEMANTIC-2: XOR invariant not fully enforced**
```
LOCATION: SCULPTOR_RESULT.invariant, SCULPTOR_INFERENCE_RESULT.invariant
SEVERITY: CRITICAL (Semantic)
ISSUE: Invariant: success_xor_error = is_success xor (not error_message.is_empty)
SEMANTIC PROBLEM: Allows state where is_success=True AND error_message="" (both false)
                  This is XOR compliant (T xor F = T), but semantically wrong:
                  - Success with error message? Contradictory
                  - Failure with no message? Silent failure
CLAUDE_SUGGESTION: Strengthen invariant:
  (A) Split XOR: success_implies_no_error: is_success implies error_message.is_empty
                 failure_implies_error: (not is_success) implies (not error_message.is_empty)
  (B) Or use: exactly_one: is_success xor (error_message.count > 0)
              (This prevents empty string)
RATIONALE: Current XOR is logically valid but semantically loose. Combined with Ollama's
           finding about message_not_void allowing "", this is major gap.
```

**SEMANTIC-3: Detachable mesh semantics unclear**
```
LOCATION: SCULPTOR_RESULT.mesh
SEVERITY: HIGH (Semantic)
ISSUE: mesh is detachable SCULPTOR_MESH
SEMANTIC PROBLEM: Not clear what void mesh means:
  - Failure case: mesh should be Void (clear)
  - Success case: mesh must not be Void (clear)
  - Empty mesh: is mesh=SCULPTOR_MESH.make_empty (with 0 vertices) allowed?
                or must it be Void?
CLAUDE_SUGGESTION: Make semantics explicit:
  Invariant: is_success implies (mesh /= Void and mesh.vertex_count > 0)
            (not is_success) implies mesh = Void
RATIONALE: Currently, success with 0 vertices is allowed but nonsensical.
```

**SEMANTIC-4: Device string semantics not validated**
```
LOCATION: SCULPTOR_ENGINE.device
SEVERITY: MEDIUM (Semantic)
ISSUE: device is STRING, precondition validates with string.is_equal
SEMANTIC PROBLEM: String case sensitivity not documented
  - "CPU" works
  - "cpu" rejected by precondition (is_equal is case-sensitive)
  - User likely expects "cpu" to work
CLAUDE_SUGGESTION: Document or add precondition helper:
  or_specify invariant: device = old device (once set)
RATIONALE: Semantic confusion around string case handling.
```

## MML (Mathematical Modeling Language) Analysis

### Missing MML Model Queries

**MML-1: POINT_CLOUD needs model query for precise postconditions**
```
LOCATION: POINT_CLOUD
SEVERITY: HIGH (MML)
ISSUE: POINT_CLOUD.make(points) has precondition count_divisible_by_3 but no model
CURRENT CONTRACT:
  make(a_points: ARRAY [REAL_32])
    require count_divisible_by_3: a_points.count \\ 3 = 0
    ensure points_set: points = a_points
MML PROBLEM: Postcondition "points_set" uses object identity (=) not model equality
             What if implementation does points := a_points.deep_clone?
             Postcondition says points = a_points (same object), but that's too strict
CLAUDE_SUGGESTION: Add MML model query:
  points_model: MML_SEQUENCE [REAL_32]
    do
      create Result
      across points as ic loop
        Result := Result.appended (@ic.item)
      end
    end

  Then postcondition becomes:
    ensure points_model_set: points_model = a_points.items_model
           (uses model equality, not object identity)
RATIONALE: Model queries enable precise specification of semantic equivalence without
           tying implementation to specific representation.
```

**MML-2: SCULPTOR_MESH needs topological model**
```
LOCATION: SCULPTOR_MESH
SEVERITY: HIGH (MML)
ISSUE: Mesh has vertices and faces, but no model query for topology
CURRENT CONTRACT:
  make(a_vertices, a_faces)
    ensure vertices_set: vertex_count = a_vertices.count // 3
           faces_set: face_count = a_faces.count // 3
MML PROBLEM: Doesn't specify HOW vertices/faces are stored, or if they're compressed
             Implementation could reorder, deduplicate, or compress vertices
             Postcondition only checks COUNTS, not actual mapping
CLAUDE_SUGGESTION: Add MML model queries:
  vertices_model: MML_SEQUENCE [SCULPTOR_POINT_3D]
    do
      create Result
      from i := 0 until i >= vertex_count loop
        Result := Result.appended(get_point(i))
        i := i + 1
      end
    end

  faces_model: MML_SEQUENCE [INTEGER_TRIPLE]
    do
      create Result
      from i := 0 until i >= face_count loop
        Result := Result.appended(get_face(i))
        i := i + 1
      end
    end

  Then postcondition:
    ensure vertices_model_set: vertices_model = a_vertices_model
           faces_model_set: faces_model = a_faces_model
RATIONALE: Topological correctness requires model queries, not just count checking.
```

**MML-3: MESH_CONVERTER frame condition needs model equality**
```
LOCATION: MESH_CONVERTER.convert()
SEVERITY: HIGH (MML)
ISSUE: convert(points) has no model constraint between input and output
CURRENT CONTRACT:
  convert(a_points: POINT_CLOUD): SCULPTOR_MESH
    ensure result_not_void: Result /= Void
MML PROBLEM: Doesn't specify what invariant relates input to output
             Valid interpretations:
             - Output geometry spans input point cloud
             - Each output vertex is near some input point
             - Output volume is monotonically increasing with point density
CLAUDE_SUGGESTION: Add model constraint:
  output_bounds_input: Result.bounding_box.contains_all(a_points.points_model)
  or: output_coverage: each vertex in Result.vertices_model is within voxel_size
                        of some point in a_points.points_model
RATIONALE: Voxelization semantics require input-output invariant for correctness.
```

### Frame Conditions Using MML |=| Operator

**MML-FRAME-1: Configuration preservation in batch_generate**
```
LOCATION: SIMPLE_SCULPTOR.batch_generate()
SEVERITY: MEDIUM (MML Frame)
ISSUE: batch_generate processes multiple prompts, but doesn't guarantee config unchanged
CURRENT CONTRACT:
  batch_generate(a_prompts) ensures result_count: Result.count = a_prompts.count
MML FRAME PROBLEM: Doesn't state that configuration isn't modified
CLAUDE_SUGGESTION: Add frame condition:
  ensure config_preserved: config_model |=| old config_model
         device_preserved: engine.device = old engine.device
         model_preserved: engine.is_model_loaded = old engine.is_model_loaded
         (using MML |=| for "model unchanged" on complex attributes)
RATIONALE: Caller assumes batch processing doesn't corrupt global state. Contract should guarantee this.
```

## Old-State Reasoning

**OLD-STATE-1: SCULPTOR_ENGINE lacks old-state postconditions**
```
LOCATION: SCULPTOR_ENGINE.set_device()
SEVERITY: MEDIUM (Old-State)
ISSUE: Postcondition says device_set: device.is_equal(a_device)
       But doesn't clarify relationship to old state
CLAUDE_SUGGESTION: Clarify with old expression:
  ensure device_changed: device /= old device  (if the change is observable)
         or: device_set_correctly: device.is_equal(a_device) and device /= old device
RATIONALE: Makes it explicit that state HAS changed (not idempotent).
```

**OLD-STATE-2: load_model doesn't reference old state**
```
LOCATION: SCULPTOR_ENGINE.load_model()
SEVERITY: MEDIUM (Old-State)
ISSUE: Postcondition says loaded: is_model_loaded
       But precondition requires not_already_loaded
       So this is always: False → True transition
CLAUDE_SUGGESTION: Use old expression for clarity:
  ensure model_loaded_changed: is_model_loaded and (not old is_model_loaded)
RATIONALE: Makes state transition explicit.
```

## Void Safety Patterns

**VOID-1: Proper use of attached in SCULPTOR_RESULT.summary()**
```
LOCATION: SCULPTOR_RESULT.summary()
SEVERITY: LOW (Pattern Excellence)
ISSUE: None - this is GOOD void-safe code:
  if attached mesh as m then
    Result.append ("Vertices: " + m.vertex_count.out + ...)
  end
CLAUDE_ASSESSMENT: ✓ Correct attached pattern
RECOMMENDATION: This pattern should be used throughout implementation.
```

**VOID-2: Detachable model_path without postcondition check**
```
LOCATION: SCULPTOR_ENGINE.set_model_path()
SEVERITY: MEDIUM (Void Safety)
ISSUE: model_path: detachable STRING
       Postcondition: path_set: model_path /= Void and model_path.is_equal(a_path)
       This is correct and explicit ✓
CLAUDE_ASSESSMENT: ✓ Good void-safety contract
```

## Recommendation Summary

### Contract Quality Reassessment with MML

| Aspect | Ollama | Claude | Combined |
|--------|--------|--------|----------|
| Precondition strength | 2/5 | +1 (device bounds ok) | 3/5 |
| Postcondition completeness | 2/5 | -1 (MML missing) | 1/5 |
| Frame conditions | 1/5 | -1 (critical gap) | 0/5 |
| MML completeness | N/A | 1/5 | 1/5 |
| Void safety | 4/5 | +1 (patterns good) | 5/5 |
| **OVERALL QUALITY** | **2.3/5** | **-1 (MML gaps)** | **1.3/5** |

### Priority Fixes (Claude + Ollama Combined)

**MUST FIX BEFORE PHASE 4:**
1. ✓ Add message_not_empty to make_failure (Ollama CRITICAL-2)
2. ✓ Add frame conditions to all setters (Ollama CRITICAL-3, Claude SEMANTIC-1)
3. ✓ Add mesh topology validation (Ollama CRITICAL-4)
4. ✓ Add finite coordinate validation (Ollama CRITICAL-5)
5. ✓ Fix device lifecycle (Ollama HIGH-4)
6. **Add MML model queries to POINT_CLOUD** (Claude MML-1)
7. **Add MML topological model to SCULPTOR_MESH** (Claude MML-2)
8. **Add model constraints to MESH_CONVERTER** (Claude MML-3)
9. **Strengthen XOR invariant with split conditions** (Claude SEMANTIC-2)
10. **Make success_with_mesh_constraint explicit** (Claude SEMANTIC-3)

### VERDICT: NOT READY FOR PHASE 4

Contracts have critical semantic and MML gaps:
- Frame conditions completely missing (configuration side effects unspecified)
- MML model queries needed for POINT_CLOUD and SCULPTOR_MESH
- XOR invariant semantically loose (allows nonsensical states)
- Error message semantics need strengthening

**After Fixes**: Recommend Claude review Phase 4 implementation against these MML specs.

---

**Claude Assessment:**
Phase 1 created good skeleton with proper class structure and naming. But Phase 2 reveals
that semantic correctness and mathematical rigor are missing. These gaps WILL cause
Phase 4 implementation to violate postconditions unless fixed now.

The MML patterns should be applied to ANY collection-based class to enable precise
verification. For a geometry library, this is essential.
