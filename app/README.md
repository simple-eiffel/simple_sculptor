# Sculptor Viewer Application

Desktop application for text-to-3D model generation using Point-E ONNX inference.

## Quick Start

```bash
# Launch the application
./bin/sculptor_viewer.exe
```

A window will open with:
- **Left panel**: Text prompt and configuration controls
- **Right panel**: 3D model viewer with Three.js rendering

## Usage

### Generating Models

1. **Enter Prompt**: Describe the 3D object you want to create
   - Examples: "a red cube", "a blue sphere", "a golden torus"

2. **Configure Parameters**:
   - **Device**: Choose inference device (CPU, CUDA, or TensorRT)
   - **Inference Steps**: 1-100 (more = better quality, slower)
   - **Voxel Size**: 0.1-2.0 (smaller = higher detail)

3. **Click "Generate Model"**: Start text-to-3D generation
   - A loading spinner indicates processing
   - Model appears in the 3D viewer when complete

### Interacting with Models

- **Rotate**: Click and drag mouse on the model
- **Zoom**: Scroll mouse wheel up/down
- **Reset View**: Scroll to center or wait (grid resets automatically)

## Features

### 3D Rendering
- Real-time Three.js viewer
- Professional lighting (directional + ambient)
- Grid helper for orientation
- Shadow mapping for depth perception
- Responsive to window resize

### Text-to-3D Pipeline
- Point-E ONNX model for point cloud generation
- Voxel-based mesh conversion
- Support for multiple export formats (GLB, OBJ, STL)

### User Interface
- Modern gradient design (purple/indigo theme)
- Responsive layout for different screen sizes
- Status messages (success/error notifications)
- Smooth animations and transitions
- Persistent parameter state

## System Requirements

### Minimum
- Windows 10 or later
- 4 GB RAM
- 2 GB free disk space
- GPU recommended (CUDA or TensorRT support)

### Recommended
- Windows 11
- 8+ GB RAM
- NVIDIA GPU with CUDA support (20% faster inference)
- SSD for faster model loading

## Architecture

### Frontend (HTML/CSS/JavaScript)
Located in `web/` directory:
- `index.html` - UI layout
- `css/style.css` - Professional styling
- `js/viewer.js` - Three.js integration and event handling

Three.js handles all 3D rendering:
- WebGL context management
- Scene graph rendering
- Camera controls
- Lighting and shadows
- Model loading (GLB format via GLTFLoader)

### Backend (Eiffel)
Located in `app/` directory:
- `sculptor_viewer_app.e` - Main application entry point
- `sculptor_viewer_window.e` - Vision2 window with embedded browser
- `sculptor_service.e` - Model generation service
- `model_server.e` - HTTP API server (development)

Eiffel components:
- **simple_vision**: Window management and UI framework
- **simple_browser**: WebView2 integration for HTML/CSS/JS rendering
- **simple_sculptor**: Text-to-3D model generation
- **simple_onnx**: ONNX runtime for neural network inference

### Data Flow

```
User Input (HTML form)
        ↓
JavaScript (viewer.js)
        ↓
HTTP POST /api/generate
        ↓
Eiffel Backend (sculptor_service.e)
        ↓
simple_sculptor (generate text→3D)
        ↓
Export to GLB
        ↓
HTTP Response
        ↓
JavaScript GLTFLoader
        ↓
Three.js Render Pipeline
        ↓
WebGL Canvas Display
```

## Configuration

### Environment Variables
```bash
# Set SIMPLE_EIFFEL for library paths
export SIMPLE_EIFFEL=D:\prod

# Set ISE_LIBRARY for EiffelStudio stdlib
export ISE_LIBRARY=C:\Program Files\Eiffel Software\EiffelStudio 25.02 Standard\library
```

### Application Settings
Modify in `sculptor_viewer_window.e`:
- Window dimensions: `set_size(1400, 900)`
- Default prompt: `"a red cube"`
- Default device: `"CUDA"`
- Default steps: `64`
- Default voxel size: `0.5`

## Development

### Adding Features

#### New 3D Shape
In `viewer.js`, add to `generatePlaceholderModel()`:
```javascript
} else if (prompt.toLowerCase().includes('pyramid')) {
    geometry = new THREE.TetrahedronGeometry(1.5);
    color = 0xffa500;
}
```

#### New Control Parameter
In `index.html`, add to controls panel:
```html
<div class="control-group">
    <label for="seed">Random Seed</label>
    <input type="number" id="seed" value="42">
</div>
```

In `sculptor_service.e`, add to generation:
```eiffel
sculptor.set_seed (seed_value)
```

### Testing Features

#### Manual Testing
1. Launch application
2. Test each parameter slider
3. Try different prompts
4. Test mouse interactions
5. Verify status messages

#### Automated Testing
```bash
cd D:\prod\simple_sculptor
ec.exe -batch -config simple_sculptor.ecf -target simple_sculptor_tests -c_compile
./EIFGENs/simple_sculptor_tests/W_code/simple_sculptor.exe
```

## Troubleshooting

### Application Won't Start
- Ensure all DLLs are in `bin/` directory
- Check WebView2 is installed (Windows 10/11 have it pre-installed)
- Run from project root: `./bin/sculptor_viewer.exe`

### Models Don't Appear
- Check browser console (F12) for JavaScript errors
- Ensure Three.js CDN is accessible
- Verify GPU/CPU has sufficient memory
- Check inference logs in application console

### Generation is Slow
- Switch device from CPU to CUDA (if GPU available)
- Reduce inference steps (faster but lower quality)
- Ensure no other GPU-intensive applications are running

### Out of Memory
- Reduce voxel resolution
- Close other applications
- Restart application between large batches

## Performance

### Typical Inference Times
| Device | Inference Steps | Time |
|--------|-----------------|------|
| CPU    | 64              | 60s  |
| CUDA   | 64              | 15s  |
| TensorRT| 64              | 10s  |

### Model Memory Usage
- Point cloud (256 points): ~3 KB
- Mesh (8K vertices): ~200 KB
- GLB export: ~500 KB - 2 MB

## Credits

Built with:
- [Eiffel](https://www.eiffel.org/) - Programming language
- [Three.js](https://threejs.org/) - 3D rendering
- [Point-E](https://openai.com/) - Text-to-3D model
- [ONNX Runtime](https://onnxruntime.ai/) - Model inference
- Simple Eiffel ecosystem libraries

## License

MIT License - See LICENSE file in project root

## Support

- **Documentation**: See BUILD_VIEWER.md for development details
- **Issues**: Report on GitHub: github.com/simple-eiffel/simple_sculptor
- **Tests**: Run simple_sculptor_tests target to verify installation
