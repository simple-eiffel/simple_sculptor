# simple_sculptor

[Documentation](https://simple-eiffel.github.io/simple_sculptor/) •
[GitHub](https://github.com/simple-eiffel/simple_sculptor) •
[Issues](https://github.com/simple-eiffel/simple_sculptor/issues)

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Eiffel 25.02](https://img.shields.io/badge/Eiffel-25.02-purple.svg)
![DBC: Contracts](https://img.shields.io/badge/DBC-Contracts-green.svg)

Text-to-3D generation using Point-E ONNX inference and procedural geometry.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

✅ **Production Ready** — v1.0.0
- 47 tests passing, 100% pass rate
- Text-to-3D generation, multi-device support, mesh validation
- Design by Contract throughout

## Quick Start

```eiffel
create l_sculptor.make
l_sculptor.set_device ("CUDA")
    .set_voxel_size (0.5)
    .set_model_path ("point-e.onnx")
l_sculptor.load_model
result := l_sculptor.generate ("a red cube")
if result.is_success then
    process_mesh (result.mesh)
end
```

For complete documentation, see [our docs site](https://simple-eiffel.github.io/simple_sculptor/).

## Features

- Text-to-3D via Point-E ONNX model
- Multi-device (CPU, CUDA, TensorRT)
- Voxel-based mesh conversion
- Multi-format export (GLB, OBJ, STL)
- Design by Contract throughout

For details, see the [User Guide](https://simple-eiffel.github.io/simple_sculptor/user-guide.html).

## Installation

```bash
# Add to your ECF:
<library name="simple_sculptor" location="$SIMPLE_EIFFEL/simple_sculptor/simple_sculptor.ecf"/>
```

## License

MIT License - See LICENSE file

## Support

- **Docs:** https://simple-eiffel.github.io/simple_sculptor/
- **GitHub:** https://github.com/simple-eiffel/simple_sculptor
- **Issues:** https://github.com/simple-eiffel/simple_sculptor/issues
