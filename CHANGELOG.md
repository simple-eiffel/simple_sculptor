# Changelog

## [1.0.0] - 2026-01-31

### Added
- Text-to-3D generation via Point-E ONNX model
- Multi-device support (CPU, CUDA, TensorRT)
- Efficient point cloud processing and storage
- Voxel-based mesh conversion algorithm
- Multi-format mesh export (GLB, OBJ, STL)
- Configurable inference parameters (seed, steps)
- Batch generation for multiple prompts
- 47 comprehensive unit tests (100% pass rate)
- Design by Contract throughout all 14 classes
- Complete GitHub Pages documentation site

### Technical
- Void-safe implementation (void_safety="all")
- SCOOP-compatible concurrency support
- XOR result pattern for success/error handling
- Frame conditions for state preservation
- MML model queries for verification
- Builder pattern for configuration chaining
- Facade pattern for simplified API
- 180+ acceptance criteria derived from postconditions

### Architecture
- 5-layer dependency model
- 14 core classes with full contracts
- 100+ preconditions enforcing valid inputs
- 100+ postconditions verifying correct outputs
- 50+ invariants maintaining class consistency

## Installation

```bash
<library name="simple_sculptor" location="$SIMPLE_EIFFEL/simple_sculptor/simple_sculptor.ecf"/>
```

## Status

✅ Production ready

## License

MIT License
