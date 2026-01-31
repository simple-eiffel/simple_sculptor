note
	description: "[
		SCULPTOR_VIEWER_WINDOW - Main viewer window with embedded browser.

		Manages the browser widget and coordinates between HTML UI and
		Eiffel backend for model generation and display.
	]"
	author: "Larry Rix"

class
	SCULPTOR_VIEWER_WINDOW

create
	make

feature {NONE} -- Initialization

	make
			-- Create viewer window with browser widget.
		do
			create browser_widget.make
			create service.make
			load_ui
		end

feature -- Access

	widget: SV_WIDGET
			-- Main widget for window.
		do
			Result := browser_widget.ev_widget
		end

feature {NONE} -- Implementation

	browser_widget: SB_WIDGET
			-- Embedded browser widget.

	service: SCULPTOR_SERVICE
			-- Backend generation service.

	load_ui
			-- Load HTML UI into browser.
		local
			l_html: STRING
		do
			l_html := ui_html
			browser_widget.set_html (l_html)
		end

	ui_html: STRING
			-- HTML content for viewer UI.
		once
			Result := "[
				<!DOCTYPE html>
				<html lang="en">
				<head>
					<meta charset="UTF-8">
					<meta name="viewport" content="width=device-width, initial-scale=1.0">
					<title>Sculptor Viewer</title>
					<style>
						* {
							margin: 0;
							padding: 0;
							box-sizing: border-box;
						}

						body {
							font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
							background: #f5f5f5;
							display: flex;
							flex-direction: column;
							height: 100vh;
							overflow: hidden;
						}

						.header {
							background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
							color: white;
							padding: 20px;
							box-shadow: 0 2px 8px rgba(0,0,0,0.1);
						}

						.header h1 {
							font-size: 24px;
							margin-bottom: 5px;
						}

						.header p {
							font-size: 13px;
							opacity: 0.9;
						}

						.container {
							display: flex;
							flex: 1;
							gap: 20px;
							padding: 20px;
							overflow: hidden;
						}

						.panel {
							background: white;
							border-radius: 8px;
							box-shadow: 0 2px 8px rgba(0,0,0,0.1);
							padding: 20px;
							display: flex;
							flex-direction: column;
						}

						.controls {
							width: 300px;
							flex-shrink: 0;
						}

						.viewer {
							flex: 1;
							position: relative;
						}

						.control-group {
							margin-bottom: 20px;
						}

						.control-group label {
							display: block;
							font-weight: 600;
							margin-bottom: 8px;
							color: #333;
						}

						.control-group input,
						.control-group textarea,
						.control-group select {
							width: 100%;
							padding: 10px;
							border: 1px solid #ddd;
							border-radius: 4px;
							font-family: inherit;
							font-size: 13px;
						}

						.control-group textarea {
							resize: vertical;
							min-height: 80px;
						}

						.control-group button {
							width: 100%;
							padding: 12px;
							background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
							color: white;
							border: none;
							border-radius: 4px;
							font-weight: 600;
							cursor: pointer;
							transition: opacity 0.2s;
						}

						.control-group button:hover {
							opacity: 0.9;
						}

						.control-group button:disabled {
							opacity: 0.5;
							cursor: not-allowed;
						}

						.status {
							margin-top: 15px;
							padding: 10px;
							background: #f9f9f9;
							border-left: 3px solid #667eea;
							border-radius: 4px;
							font-size: 12px;
							color: #666;
						}

						.status.success {
							border-left-color: #4caf50;
							background: #f1f8f4;
							color: #2e7d32;
						}

						.status.error {
							border-left-color: #f44336;
							background: #fef5f5;
							color: #c62828;
						}

						#canvas {
							width: 100%;
							height: 100%;
							background: linear-gradient(135deg, #fafafa 0%, #e8e8e8 100%);
							border-radius: 4px;
						}

						.loading {
							display: none;
							position: absolute;
							top: 50%;
							left: 50%;
							transform: translate(-50%, -50%);
							text-align: center;
							color: #667eea;
						}

						.loading.active {
							display: block;
						}

						.spinner {
							border: 4px solid #f3f3f3;
							border-top: 4px solid #667eea;
							border-radius: 50%;
							width: 40px;
							height: 40px;
							animation: spin 1s linear infinite;
							margin: 0 auto 10px;
						}

						@keyframes spin {
							0% { transform: rotate(0deg); }
							100% { transform: rotate(360deg); }
						}
					</style>
				</head>
				<body>
					<div class="header">
						<h1>🎨 Sculptor Viewer</h1>
						<p>Text-to-3D generation powered by Point-E ONNX</p>
					</div>

					<div class="container">
						<div class="panel controls">
							<div class="control-group">
								<label for="prompt">Prompt</label>
								<textarea id="prompt" placeholder="Describe the object you want to create...">a red cube</textarea>
							</div>

							<div class="control-group">
								<label for="device">Device</label>
								<select id="device">
									<option value="CPU">CPU</option>
									<option value="CUDA" selected>CUDA</option>
									<option value="TensorRT">TensorRT</option>
								</select>
							</div>

							<div class="control-group">
								<label for="steps">Inference Steps</label>
								<input type="range" id="steps" min="1" max="100" value="64">
								<span id="stepsValue">64</span>
							</div>

							<div class="control-group">
								<label for="voxelSize">Voxel Size</label>
								<input type="range" id="voxelSize" min="0.1" max="2.0" step="0.1" value="0.5">
								<span id="voxelSizeValue">0.5</span>
							</div>

							<div class="control-group">
								<button id="generateBtn">Generate Model</button>
							</div>

							<div id="status" class="status" style="display:none;"></div>
						</div>

						<div class="panel viewer">
							<canvas id="canvas"></canvas>
							<div id="loading" class="loading">
								<div class="spinner"></div>
								<p>Generating model...</p>
							</div>
						</div>
					</div>

					<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
					<script>
						// Application state
						const app = {
							scene: null,
							camera: null,
							renderer: null,
							model: null,

							init() {
								this.setupThree();
								this.attachEvents();
							},

							setupThree() {
								const canvas = document.getElementById('canvas');
								const width = canvas.clientWidth;
								const height = canvas.clientHeight;

								// Scene setup
								this.scene = new THREE.Scene();
								this.scene.background = new THREE.Color(0xeeeeee);

								// Camera setup
								this.camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 1000);
								this.camera.position.set(0, 2, 3);
								this.camera.lookAt(0, 0, 0);

								// Renderer setup
								this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
								this.renderer.setSize(width, height);
								this.renderer.setPixelRatio(window.devicePixelRatio);

								// Lighting
								const light1 = new THREE.DirectionalLight(0xffffff, 0.8);
								light1.position.set(5, 10, 5);
								this.scene.add(light1);

								const light2 = new THREE.DirectionalLight(0xffffff, 0.4);
								light2.position.set(-5, -10, -5);
								this.scene.add(light2);

								const ambientLight = new THREE.AmbientLight(0xffffff, 0.4);
								this.scene.add(ambientLight);

								// Add grid
								const gridHelper = new THREE.GridHelper(10, 10, 0xcccccc, 0xeeeeee);
								this.scene.add(gridHelper);

								// Controls (mouse rotation)
								let isDragging = false;
								let previousMousePosition = { x: 0, y: 0 };

								canvas.addEventListener('mousedown', (e) => {
									isDragging = true;
									previousMousePosition = { x: e.clientX, y: e.clientY };
								});

								canvas.addEventListener('mousemove', (e) => {
									if (isDragging && this.model) {
										const deltaX = e.clientX - previousMousePosition.x;
										const deltaY = e.clientY - previousMousePosition.y;
										this.model.rotation.y += deltaX * 0.01;
										this.model.rotation.x += deltaY * 0.01;
										previousMousePosition = { x: e.clientX, y: e.clientY };
									}
								});

								canvas.addEventListener('mouseup', () => {
									isDragging = false;
								});

								// Zoom with scroll
								canvas.addEventListener('wheel', (e) => {
									e.preventDefault();
									this.camera.position.z += e.deltaY * 0.01;
									this.camera.position.z = Math.max(1, Math.min(10, this.camera.position.z));
								});

								// Start render loop
								this.animate();
							},

							animate() {
								requestAnimationFrame(() => this.animate());
								this.renderer.render(this.scene, this.camera);
							},

							attachEvents() {
								document.getElementById('generateBtn').addEventListener('click', () => this.generate());
								document.getElementById('steps').addEventListener('input', (e) => {
									document.getElementById('stepsValue').textContent = e.target.value;
								});
								document.getElementById('voxelSize').addEventListener('input', (e) => {
									document.getElementById('voxelSizeValue').textContent = e.target.value;
								});
							},

							async generate() {
								const prompt = document.getElementById('prompt').value.trim();
								if (!prompt) {
									this.showStatus('Please enter a prompt', 'error');
									return;
								}

								const device = document.getElementById('device').value;
								const steps = parseInt(document.getElementById('steps').value);
								const voxelSize = parseFloat(document.getElementById('voxelSize').value);

								this.setLoading(true);
								this.showStatus('', 'normal');

								try {
									const response = await fetch('/api/generate', {
										method: 'POST',
										headers: { 'Content-Type': 'application/json' },
										body: JSON.stringify({
											prompt,
											device,
											steps,
											voxelSize
										})
									});

									if (!response.ok) {
										throw new Error('Generation failed');
									}

									const data = await response.json();

									if (data.success) {
										await this.loadModel(data.modelPath);
										this.showStatus('Model generated successfully', 'success');
									} else {
										this.showStatus('Error: ' + data.error, 'error');
									}
								} catch (error) {
									this.showStatus('Error: ' + error.message, 'error');
								} finally {
									this.setLoading(false);
								}
							},

							async loadModel(path) {
								// Clear existing model
								if (this.model) {
									this.scene.remove(this.model);
									this.model = null;
								}

								// Load GLB model using Three.js loader
								const loader = new THREE.GLTFLoader();
								loader.load(path, (gltf) => {
									this.model = gltf.scene;
									this.scene.add(this.model);

									// Center and scale model
									const box = new THREE.Box3().setFromObject(this.model);
									const center = box.getCenter(new THREE.Vector3());
									this.model.position.sub(center);

									const size = box.getSize(new THREE.Vector3());
									const maxDim = Math.max(size.x, size.y, size.z);
									const scale = 4 / maxDim;
									this.model.scale.multiplyScalar(scale);
								});
							},

							setLoading(active) {
								document.getElementById('loading').classList.toggle('active', active);
								document.getElementById('generateBtn').disabled = active;
							},

							showStatus(message, type = 'normal') {
								const statusEl = document.getElementById('status');
								if (message) {
									statusEl.textContent = message;
									statusEl.className = 'status ' + type;
									statusEl.style.display = 'block';
								} else {
									statusEl.style.display = 'none';
								}
							}
						};

						// Initialize on load
						document.addEventListener('DOMContentLoaded', () => app.init());
					</script>
				</body>
				</html>
			]"
		end

end
