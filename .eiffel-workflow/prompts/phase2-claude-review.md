# Eiffel Contract Review - Claude

You are reviewing Eiffel contracts and MML (Mathematical Modeling Language) specifications for a text-to-3D generation library. Focus on:

1. **Semantic correctness** of contracts (do they mean what the author intended?)
2. **MML completeness** (are model queries sufficient for verification?)
3. **Frame conditions** (what didn't change? Is it stated?)
4. **Old-state reasoning** (do postconditions properly reference `old` state?)
5. **Void safety** (are all detachable attributes handled?)

## Contracts Under Review

[Same contracts as Ollama - embedded above]

See prompts/phase2-ollama-review.md for full contract specifications.

## Ollama's Review (Previous AI - paste here)

```
[PASTE OLLAMA'S RESPONSE HERE - this section will be populated by the user]
```

## Claude-Specific MML Review Checklist

For this library, MML (Mathematical Modeling Language) is relevant for:

- **POINT_CLOUD**: Represents a mathematical sequence of 3D points
  - Current: `points: ARRAY [REAL_32]` (flat array)
  - Should have: `points_model: MML_SEQUENCE [SCULPTOR_POINT_3D]` for postconditions
  - Frame condition: `points_model.removed(index) |=| old points_model.removed(index)`

- **SCULPTOR_MESH**: Represents topological structure (vertices + faces)
  - Current: Simple count tracking
  - Should have: `vertices_model: MML_SEQUENCE [SCULPTOR_POINT_3D]` and `faces_model: MML_SEQUENCE [INTEGER]`
  - Invariant: Face indices must be valid (< vertex_count)

- **MESH_CONVERTER**: Transformation function
  - Current: `convert(points): mesh` with no model tracking
  - Should have: Postcondition relating input points to output mesh geometry
  - Example: "each output vertex is within voxel_size of some input point"

### MML Questions

1. **POINT_CLOUD.get_point(index)**:
   - Current postcondition: none
   - Should be: `points_model.at(index) |=| Result`?
   - Or just verify coordinate access?

2. **MESH_CONVERTER.convert(points)**:
   - Current postcondition: `result_not_void`
   - Should verify: Output mesh vertex count is <= input point count * (1/voxel_size)³?
   - Or just: Result geometry spans input points' bounding box?

3. **SCULPTOR_MESH.make(vertices, faces)**:
   - Should validate: All face indices < vertex_count in postcondition?
   - Or leave for invariant check only?

## Key Issues to Address

1. **Frame Conditions**: Configuration changes (set_device, set_voxel_size) should specify what does NOT change
   - Example: `set_voxel_size` changes voxel_size but what about seed, num_inference_steps?

2. **Detachable Handling**:
   - SCULPTOR_ENGINE.model_path is detachable
   - SCULPTOR_RESULT.mesh is detachable
   - Are all uses properly checked?

3. **State Consistency**:
   - After `load_model`, engine.is_model_loaded should be True
   - After `unload_model`, engine.is_model_loaded should be False
   - Currently correct, but should `batch_generate` maintain this across multiple calls?

4. **Builder Pattern Postconditions**:
   - All set_* methods return `like Current`
   - Postcondition: `result_is_current: Result = Current` ✓
   - But should they also verify what they SET? (e.g., `voxel_size_set: config.voxel_size = a_size`)

5. **Error Message Semantics**:
   - `error_message` is STRING (never void) - good for XOR pattern
   - But is empty string ("") same as no error?
   - Consider: `error_message.is_empty` vs `error_message /= Void`

## Review Output Format

For each issue, provide:

```
CLAUDE_ISSUE: [brief description]
LOCATION: [class.feature or class.invariant]
SEVERITY: [CRITICAL/HIGH/MEDIUM/LOW]
MML_RELEVANT: [yes/no]
SUGGESTION: [how to fix]
RATIONALE: [why this matters]
```

## Questions for Claude Reviewer

1. Do the XOR invariants properly prevent invalid states?
2. Should POINT_CLOUD have MML model queries for precise frame conditions?
3. Are detachable attributes (model_path, mesh) handled consistently?
4. What frame conditions are missing from configuration setters?
5. Should postconditions verify state changes via model queries instead of direct field checks?
6. Is the void-safety approach (empty string for no error) semantically correct?

---

**After reviewing contracts and considering Ollama's findings, provide your assessment.**
