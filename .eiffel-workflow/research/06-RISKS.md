# RISKS: Threat Analysis & Mitigation Plans

## Risk Assessment Methodology

Each risk evaluated on:
- **Probability:** How likely is this to occur? (HIGH/MEDIUM/LOW)
- **Impact:** If it happens, how bad? (CRITICAL/HIGH/MEDIUM/LOW)
- **Overall Severity:** P × I = Risk Score
- **Detection:** How do we find out?
- **Mitigation:** What can we do about it?
- **Contingency:** If it happens, what's our backup plan?

---

## RISK-001: ONNX Runtime Point-E Model Stability

**Severity:** MEDIUM (P: MEDIUM, I: MEDIUM)

**Threat:**
- Point-E ONNX export may have bugs or performance issues
- Model may not work as expected on various prompts
- Inference may fail silently, returning garbage geometry
- Version mismatches between ONNX Runtime and exported model

**Detection:**
- Run comprehensive test suite with diverse prompts (Week 1)
- Measure inference success rate across 50+ test prompts
- Validate output point clouds against known-good geometry
- Monitor VRAM usage and timing variance

**Probability Factors:**
- Point-E released Dec 2022 (proven stable)
- ONNX export well-documented on Hugging Face
- Community has validated workflows
- BUT: ONNX conversion introduces potential issues

**Mitigation (in order of implementation):**

1. **Early Validation (Week 1):**
   - Download official Point-E ONNX models from Hugging Face
   - Test basic inference with sample prompts
   - Document expected output ranges
   - Validate against reference implementation (PyTorch)

2. **Robust Error Handling:**
   - Wrap ONNX inference in try/catch blocks
   - Detect invalid outputs (NaN, Inf, out-of-range values)
   - Return detailed error codes (vs generic "inference failed")

3. **Fallback Models:**
   - If Point-E ONNX broken, pivot to LGM (ECCV 2024, proven)
   - LGM also has ONNX export available
   - Can run both in parallel for first release

4. **Version Pinning:**
   - Lock ONNX Runtime version in build config
   - Document exact CUDA/cuDNN versions
   - Provide pre-built Docker image with validated versions

**Contingency Plan:**
- If Point-E ONNX completely broken:
  1. Switch to LGM for Phase 1 MVP
  2. Implement Point-E support in Phase 2 (after investigation)
  3. Offer both as CLI options: `--model point-e` vs `--model lgm`

**Monitoring:**
- Track inference success rate in production (count errors per 1000 runs)
- Alert if > 5% of inferences fail
- Gather user feedback on output quality

---

## RISK-002: Mesh Conversion Quality & Artifacts

**Severity:** MEDIUM-HIGH (P: MEDIUM, I: MEDIUM)

**Threat:**
- Point clouds from diffusion models are noisy
- Mesh conversion (OpenVDB) may produce:
  - Topological errors (holes, non-manifold edges)
  - Visual artifacts (spikes, disconnected pieces)
  - Missing geometric details
  - Asymmetric geometry when input symmetric
- User frustration: "The mesh looks nothing like the prompt"

**Detection:**
- Automated mesh validation (every generated mesh)
  - Manifold check (all edges shared by 2 triangles)
  - Self-intersection test
  - Watertight verification
- Visual inspection of generated models
- User feedback ("mesh quality" issue tracker)
- Comparison with reference Shap-E output (Phase 2)

**Probability:**
- OpenVDB mature & proven (DreamWorks VFX standard)
- But: Point cloud quality varies with prompt complexity
- Simple prompts ("ball") → clean mesh
- Complex prompts ("intricate gear mechanism") → messy point cloud → bad mesh

**Mitigation:**

1. **Parameter Tuning (Implementation):**
   - Expose voxel size parameter: `--voxel-size 0.01`
   - Larger voxels → simpler mesh, fewer artifacts
   - Smaller voxels → more detail, but noisier

2. **Point Cloud Preprocessing (Phase 2):**
   - Outlier removal (remove isolated points > 5σ from center)
   - Noise filtering (Laplacian smoothing)
   - Density normalization (upsample sparse regions)

3. **Mesh Cleanup (Phase 2):**
   - Remove degenerate triangles
   - Merge duplicate vertices
   - Smooth normals (laplacian smoothing)
   - Decimate to reasonable triangle count

4. **Quality Scoring:**
   - Automated metric: manifold + detail + size reasonableness
   - Rate meshes 1-5 stars
   - Flag low-quality results for user review

5. **Prompt-Specific Tuning (Phase 3):**
   - Easy prompts (animals, objects) → relaxed thresholds
   - Complex prompts (gear, structure) → aggressive cleaning

**Contingency Plan:**
- If OpenVDB produces consistently bad meshes:
  1. Switch to libigl (alternative mesh library)
  2. Implement custom Poisson reconstruction
  3. Use Shap-E instead (better direct mesh output)

**Example Failure Case:**
```
Prompt: "a gear with 20 teeth"
Point Cloud: Noisy, missing some teeth details
OpenVDB Mesh: 12 visible teeth, spiky artifacts
User Experience: "Gear looks like a hedgehog"

Mitigation:
- Detect "complex geometry" hint in prompt
- Use smaller voxel size (more triangles, more detail)
- Apply aggressive smoothing
- Result: All 20 teeth visible, smooth edges
```

---

## RISK-003: VRAM Management & Out-of-Memory Crashes

**Severity:** HIGH (P: MEDIUM, I: CRITICAL)

**Threat:**
- Point-E models require ~5GB VRAM during inference
- Mesh conversion (OpenVDB) requires ~2-4GB scratch space
- Point cloud stored in memory: 1M points × 3 floats = 12MB baseline
- Other GPU processes (desktop, background apps) consume memory
- Shap-E (Phase 2) requires even more (6-8GB)
- Result: CUDA out-of-memory crash, bad user experience

**Detection:**
- Profile VRAM usage during inference
- Monitor peak memory on various hardware (RTX 4070, 4090, 5070 Ti)
- Test with other GPU processes running
- Stress test with maximum prompt complexity

**Probability:**
- Real concern: 16GB VRAM is tight (3-4GB OS, other apps, etc.)
- Shap-E will push some systems over edge
- User error: running competing GPU workloads

**Mitigation:**

1. **VRAM Profiling (Phase 1):**
   - Measure peak memory per GPU model
   - Document requirements: "Point-E needs 6GB free VRAM"
   - Provide memory checker: `simple_sculptor check-vram`

2. **Memory Optimization:**
   - FP16 inference (half memory, OpenVDB compatible): 5GB → 2.5GB
   - Model quantization (INT8): Further 25-50% reduction
   - Batch processing: Process prompts sequentially (not parallel)
   - Stream mesh conversion (process points in chunks)

3. **Graceful Degradation:**
   - Reduce point cloud size if VRAM < 8GB: `--point-count 500000` (instead of 1M)
   - Auto-detection: Check free VRAM, warn if tight
   - Offer `--memory-safe` mode (slower, smaller batches)

4. **User Guidance:**
   - Clear error message: "CUDA Out of Memory (need 8GB, have 5GB)"
   - Suggestions: Close Chrome, Discord, other GPU apps
   - Link to FAQ: "How to free up VRAM"

5. **Streaming Architecture (Phase 2+):**
   - Don't load entire point cloud; process in tiles
   - Mesh conversion window-at-a-time
   - Reduces peak memory by 50%

**Contingency Plan:**
- If OOM unavoidable on 16GB systems:
  1. Switch to LGM (uses less VRAM than Point-E)
  2. Implement CPU fallback for mesh conversion (very slow)
  3. Reduce default point count to 500K

**Testing Plan:**
```bash
# Week 2: VRAM profiling
nvidia-smi --query-gpu=memory.used,memory.free --format=csv -lms 100 &
simple_sculptor generate --prompt "complex mechanical object" --verbose
# Measure peak usage, validate < 14GB on 16GB system

# Week 3: Stress test on 8GB GPU (expensive, but validate)
# Use cloud GPU with 8GB limitation
```

---

## RISK-004: Model File Distribution & Download Failures

**Severity:** MEDIUM (P: MEDIUM, I: MEDIUM)

**Threat:**
- Point-E ONNX models: ~3.5GB each
- Shap-E: ~5GB
- Total ecosystem: 8-10GB for full support
- Distribution challenges:
  - Where to host? GitHub Releases (limited), Hugging Face (reliable), custom CDN (cost)
  - Network failures: Download interrupted, resumed, verified
  - Licensing: Ensure OpenAI model distribution rights
  - Disk space: Users may not have storage for multiple models
  - Download time: 3.5GB on slow internet = hours

**Detection:**
- Model download CI/CD test (weekly verify URLs alive)
- User issue tracking (download failures reported)
- Monitor hosting bandwidth costs
- Automated integrity checks (SHA256 verification)

**Probability:**
- Models must be distributed (can't embed in executable)
- Network failures are common (WiFi drops, ISP issues)
- Hosting stability depends on provider choice

**Mitigation:**

1. **Primary Hosting (Hugging Face):**
   - Hugging Face Model Hub = industry standard
   - OpenAI already hosts models there
   - Reliable, well-tested, automatic CDN
   - Free for open models
   - Plan: Upload Point-E + Shap-E to `simple-eiffel` Hugging Face organization

2. **Fallback Hosting (GitHub Releases):**
   - GitHub Releases supports up to 2GB per file
   - Split models: Part 1 (2GB), Part 2 (1.5GB), auto-join on download
   - Automatic mirror if Hugging Face down

3. **Download Management:**
   - Resume capability: Continue interrupted downloads
   - Integrity: SHA256 checksum verification
   - Caching: Cache in ~/.simple_sculptor/models/ (once downloaded, reuse)
   - Parallel chunk download (Phase 2): Download 4 chunks in parallel

4. **User Communication:**
   - Estimate download time: "Downloading 3.5GB model (~30 min on 10Mbps internet)"
   - Progress bar with ETA
   - Option to pre-download: `simple_sculptor download-models` (without generating)

5. **Licensing Compliance:**
   - Verify OpenAI Model License allows redistribution ✓ (it does)
   - Document license in downloads
   - Include in release notes

**Contingency Plan:**
- If both Hugging Face & GitHub down (unlikely):
  1. Users can manually download from alternate sources (document in FAQ)
  2. Support `--model-path /local/file/point-e.onnx` override
  3. Pivot to LGM (hosted on both platforms independently)

**Testing:**
```bash
# Implement download test in CI/CD
- Try download from Hugging Face
- Verify SHA256
- Cleanup after test
- Run on schedule (daily check)
```

---

## RISK-005: Browser Viewer Compatibility

**Severity:** LOW (P: LOW, I: LOW)

**Threat:**
- THREE.js viewer may not work on some browsers/systems
- WebGL not available (old graphics drivers, virtual machines)
- Performance issues (low-end GPUs)
- Mobile browsers may struggle with large GLB files

**Detection:**
- Test on latest Chrome, Firefox, Safari
- Test on low-end systems (Intel Iris, no dedicated GPU)
- Monitor user reports (issue tracker)
- Browser compatibility matrix (documented)

**Probability:**
- THREE.js widely supported (thousands of production sites use it)
- WebGL standard since 2011 (12+ years of support)
- Modern browsers all support it

**Mitigation:**

1. **Graceful Fallback:**
   - If WebGL unavailable: Show message "Your browser doesn't support 3D viewing"
   - Offer to download GLB file instead

2. **Performance Optimization:**
   - Draco compression for large GLBs (Phase 2)
   - Progressive loading (show low-res first, high-res streaming)
   - Throttle lighting quality on low-end systems

3. **Mobile Support (Phase 2+):**
   - Touch controls for orbit camera
   - Responsive layout
   - Reduce model complexity for mobile

**Contingency Plan:**
- If THREE.js has critical bugs:
  - Switch to Babylon.js (similar, alternative library)
  - Or fall back to OBJ/STL file generation (let user open in their viewer)

**Testing:**
- BrowserStack compatibility testing (CI/CD)
- Manual testing on: Windows (Chrome, Edge, Firefox), macOS (Safari, Chrome), Linux

---

## RISK-006: User Expectation vs Reality (Output Quality)

**Severity:** MEDIUM (P: HIGH, I: MEDIUM)

**Threat:**
- User expectation: Text → Perfect 3D model (like movie/game quality)
- Reality: Diffusion models produce "good enough" geometry with artifacts
- Specific issues:
  - Symmetric objects become asymmetric
  - Fine details missing (teeth, fingers)
  - Proportions sometimes odd
  - Topology errors (holes, disconnected parts)
- User disappointment: "I thought AI could generate perfect models"

**Detection:**
- User feedback (GitHub issues, forums: "quality not good")
- Comparison with Shap-E/TRELLIS (newer models better quality)
- Prompt-based analysis (complex prompts fail more)

**Probability:**
- HIGH: Expectations often exceed reality with generative models
- Point-E 2022 model (before recent improvements)
- Shap-E & TRELLIS better, but also more complex/slow

**Mitigation:**

1. **Set Expectations (Documentation):**
   - README: "simple_sculptor MVP uses Point-E (2022 model). Results are good but not perfect."
   - Blog post: "What Point-E does well" vs "Known limitations"
   - Examples: Show before/after (prompts + outputs)
   - Comparison chart: Point-E vs Shap-E vs TRELLIS
   - Realistic use cases: "Good for concepting, not final production assets"

2. **Quality Tiering:**
   - Communicate: "Phase 1 MVP = baseline quality. Phase 2+ will improve."
   - Offer Shap-E in Phase 2 (better quality, worth waiting)
   - Document improvement path

3. **User Guidance:**
   - Interactive tips: "Simpler prompts often work better"
   - Example prompts that work well (curated gallery)
   - Tutorial: "Prompting best practices for 3D"

4. **Iterative Refinement (Phase 2+):**
   - Allow refinement: `--refine model.glb --prompt "add more detail"`
   - Seed exploration: Try multiple seeds, pick best
   - Integration with KittyCAD: "Use AI to generate, then refine by hand"

**Contingency Plan:**
- If Phase 1 feedback consistently negative:
  - Skip Point-E, go straight to Shap-E for Phase 1
  - Costs more compute, but higher quality = better UX
  - Launch with Shap-E instead (delay but better outcome)

**Metrics:**
- "User satisfaction" survey after generation
- Star rating: Would you use this again? (1-5 stars)
- NPS-style question: Would you recommend simple_sculptor?

---

## RISK-007: ONNX Model Download at First Run

**Severity:** MEDIUM (P: MEDIUM, I: MEDIUM)

**Threat:**
- First user runs `simple_sculptor generate --prompt "..."`
- System auto-downloads 3.5GB model
- User doesn't expect this; network slow
- Download fails; bad experience
- "Why didn't the README warn me?"

**Detection:**
- First-time user feedback
- Issue tracker: "Download too slow"
- Analytics: % users complete download vs abandon

**Probability:**
- MEDIUM: Users may not read docs
- 3.5GB is substantial (30min on 10Mbps, slow for mobile)
- Network flakiness inevitable

**Mitigation:**

1. **Clear Communication:**
   - Initial error message: "First run: Downloading 3.5GB model (do this once). Continue? Y/N"
   - Show estimated time based on current bandwidth
   - Progress bar with ETA
   - Option to skip: "No, I'll download manually later"

2. **Pre-Download Option:**
   - Command: `simple_sculptor setup` (download models in advance)
   - Recommended in README: "Run this after install"
   - Faster than waiting at generation time

3. **Docker Image:**
   - Pre-build Docker image with models included
   - For cloud users or CI/CD: `docker run ... simple_sculptor generate`
   - Models baked in; no download needed

4. **Error Recovery:**
   - If download interrupted: Resume from checkpoint
   - Clear cache: `simple_sculptor clean` (frees space)
   - Manual model path: `--model-dir /custom/path`

**Contingency:**
- If download failures persist:
  - Offer split downloads (Part 1, Part 2)
  - Partner with different hosting (CloudFlare, AWS)
  - Reduce model size via quantization

---

## RISK-008: Eiffel Library Integration Complexity

**Severity:** MEDIUM (P: MEDIUM, I: MEDIUM)

**Threat:**
- Building as full Eiffel library + C++ FFI is complex
- May require extensive refactoring
- ONNX Runtime FFI may have subtle memory management issues
- DBC (Design by Contract) adds overhead
- SCOOP concurrency introduces complexity

**Detection:**
- Compilation issues during development
- Memory leaks in stress testing
- Performance profiling (DBC overhead)
- Code review from simple_* maintainers

**Probability:**
- MEDIUM: Eiffel FFI proven but not trivial
- ONNX Runtime C++ API well-documented
- But custom marshaling needed for tensors

**Mitigation:**

1. **Phased Implementation:**
   - Phase 0 (Prototype): C++ standalone (simple, fast validation)
   - Phase 1: Minimal Eiffel wrapper + FFI (get it working)
   - Phase 2: Full library + SCOOP (optimize after proving concept)

2. **FFI Reference Implementation:**
   - Study existing simple_* C++ integrations (simple_vulkan, simple_shaderc)
   - Copy proven patterns
   - Document FFI design in INNOVATION docs

3. **Testing:**
   - Memory profiling: Valgrind/ASAN (catch leaks early)
   - Load testing: Run 100+ generations, check for accumulation
   - Void-safety checking: Compile with `-void_safety all`

4. **Performance:**
   - Measure DBC overhead (preconditions, postconditions)
   - If > 5% impact, consider `-check` flag (disable in production)
   - Profile critical paths (inference wrapper)

**Contingency:**
- If FFI becomes intractable:
  - Keep as standalone C++ tool
  - Build CLI only (not library)
  - Can convert to library later

---

## Risk Summary Table

| Risk ID | Threat | P | I | Severity | Mitigation | Owner |
|---------|--------|---|---|----------|-----------|-------|
| RISK-001 | ONNX model instability | M | M | MED | Early validation, fallback LGM | AI Infra |
| RISK-002 | Mesh conversion quality | M | M | MED-HI | Parameter tuning, preprocessing | Geometry |
| RISK-003 | VRAM out-of-memory | M | C | HI | FP16, memory profiling, degradation | GPU Mgmt |
| RISK-004 | Model distribution | M | M | MED | Hugging Face + GitHub, resume | Infra |
| RISK-005 | Browser compatibility | L | L | LOW | Graceful fallback, fallback viewer | Frontend |
| RISK-006 | User expectation mismatch | H | M | MED | Clear docs, phase 2 upgrade | Product |
| RISK-007 | First-run download | M | M | MED | Pre-download option, progress bar | UX |
| RISK-008 | Eiffel FFI complexity | M | M | MED | Phased implementation, patterns | Arch |

---

## Contingency Plan Flowchart

```
Critical Issue in Phase 1?
├─ ONNX Model broken? → Switch to LGM
├─ Mesh quality poor? → Parameter tuning → Fallback to libigl
├─ VRAM insufficient? → FP16 quantization → Reduce point count
├─ Model download fails? → GitHub fallback → Manual download option
├─ FFI intractable? → Standalone C++ tool → Library in Phase 2
└─ User backlash on quality? → Shap-E phase 2 acceleration
```

---

**Document Status:** RISKS ANALYZED, ready for RECOMMENDATION phase
