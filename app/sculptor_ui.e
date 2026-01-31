note
	description: "[
		SCULPTOR_UI - HTML/CSS/JS UI for Sculptor Viewer.

		Generates complete web UI with HTMX and Alpine.js.
	]"
	author: "Larry Rix"

class
	SCULPTOR_UI

feature -- HTML Generation

	full_page: STRING
			-- Complete HTML page with styles and scripts.
		once
			create Result.make (50000)
			Result.append (page_html)
		ensure
			result_not_empty: not Result.is_empty
		end

feature {NONE} -- HTML Content

	page_html: STRING = "[
		<!DOCTYPE html>
		<html lang="en">
		<head>
			<meta charset="UTF-8">
			<meta name="viewport" content="width=device-width, initial-scale=1.0">
			<title>Sculptor Viewer</title>
			<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
			<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
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
					display: block;
					position: relative;
				}

				#canvas canvas {
					width: 100% !important;
					height: 100% !important;
					display: block !important;
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

			<div class="container" x-data="appState()">
				<div class="panel controls">
					<div class="control-group">
						<label for="prompt">Prompt</label>
						<textarea id="prompt" x-model="prompt" placeholder="Describe the object you want to create...">a red cube</textarea>
					</div>

					<div class="control-group">
						<label for="device">Device</label>
						<select id="device" x-model="device">
							<option value="CPU">CPU</option>
							<option value="CUDA" selected>CUDA</option>
							<option value="TensorRT">TensorRT</option>
						</select>
					</div>

					<div class="control-group">
						<label for="steps">Inference Steps</label>
						<input type="number" id="steps" x-model.number="steps" min="16" max="256" value="64">
					</div>

					<div class="control-group">
						<label for="voxel">Voxel Size</label>
						<input type="number" id="voxel" x-model.number="voxelSize" min="0.1" max="1.0" step="0.1" value="0.5">
					</div>

					<div class="control-group">
						<button @click="generate()" :disabled="generating">
							<span x-show="!generating">Generate Model</span>
							<span x-show="generating">Generating...</span>
						</button>
					</div>

					<div class="status" x-show="status" :class="statusType" x-text="status"></div>
				</div>

				<div class="panel viewer">
					<div id="canvas"></div>
					<div class="loading" :class="{ active: generating }">
						<div class="spinner"></div>
						<p>Generating model...</p>
					</div>
				</div>
			</div>

			<script>
				let scene, camera, renderer, currentMesh;

				function initThreeJS() {
					const container = document.getElementById('canvas');
					if (!container) return;

					const width = container.clientWidth || 800;
					const height = container.clientHeight || 600;

					// Scene setup
					scene = new THREE.Scene();
					scene.background = new THREE.Color(0xf5f5f5);

					// Camera
					camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 1000);
					camera.position.z = 3;

					// Renderer
					renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
					renderer.setSize(width, height);
					renderer.setPixelRatio(window.devicePixelRatio);
					container.appendChild(renderer.domElement);

					// Lighting
					const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
					scene.add(ambientLight);

					const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
					directionalLight.position.set(5, 5, 5);
					scene.add(directionalLight);

					// Animation loop
					function animate() {
						requestAnimationFrame(animate);
						if (currentMesh) {
							currentMesh.rotation.x += 0.005;
							currentMesh.rotation.y += 0.008;
						}
						renderer.render(scene, camera);
					}
					animate();

					// Handle resize
					window.addEventListener('resize', () => {
						const newWidth = container.clientWidth || 800;
						const newHeight = container.clientHeight || 600;
						camera.aspect = newWidth / newHeight;
						camera.updateProjectionMatrix();
						renderer.setSize(newWidth, newHeight);
					});
				}

				function renderMesh(meshData) {
					// Remove existing mesh
					if (currentMesh) {
						scene.remove(currentMesh);
					}

					// Create geometry from vertex and face data
					const geometry = new THREE.BufferGeometry();

					// Add vertices
					if (meshData.vertices && meshData.vertices.length > 0) {
						const vertices = new Float32Array(meshData.vertices);
						geometry.setAttribute('position', new THREE.BufferAttribute(vertices, 3));

						// Center and scale geometry for optimal viewing
						geometry.center();
						geometry.scale(2, 2, 2);
					}

					// Add faces (triangle indices)
					if (meshData.faces && meshData.faces.length > 0) {
						const indices = new Uint32Array(meshData.faces);
						geometry.setIndex(new THREE.BufferAttribute(indices, 1));
					}

					// Compute normals for lighting
					geometry.computeVertexNormals();

					// Create material
					const material = new THREE.MeshStandardMaterial({
						color: 0x667eea,
						roughness: 0.4,
						metalness: 0.6,
						flatShading: false
					});

					// Create and add mesh
					currentMesh = new THREE.Mesh(geometry, material);
					scene.add(currentMesh);

					// Auto-fit camera to mesh
					const bbox = new THREE.Box3().setFromObject(currentMesh);
					const size = bbox.getSize(new THREE.Vector3());
					const maxDim = Math.max(size.x, size.y, size.z);
					const fov = camera.fov * (Math.PI / 180);
					let cameraZ = Math.abs(maxDim / 2 / Math.tan(fov / 2));
					cameraZ *= 1.5;
					camera.position.z = cameraZ;
				}

				function createGeometry(prompt) {
					// Fallback: create simple geometry if API fails
					if (currentMesh) {
						scene.remove(currentMesh);
					}

					let geometry, material;
					const lower = prompt.toLowerCase();

					if (lower.includes('cube') || lower.includes('box')) {
						geometry = new THREE.BoxGeometry(1.5, 1.5, 1.5);
						material = new THREE.MeshStandardMaterial({ color: 0xff4444, roughness: 0.3, metalness: 0.5 });
					} else if (lower.includes('sphere') || lower.includes('ball')) {
						geometry = new THREE.SphereGeometry(1, 32, 32);
						material = new THREE.MeshStandardMaterial({ color: 0x44ff44, roughness: 0.3, metalness: 0.5 });
					} else if (lower.includes('pyramid')) {
						geometry = new THREE.ConeGeometry(1, 2, 4);
						material = new THREE.MeshStandardMaterial({ color: 0xffff44, roughness: 0.3, metalness: 0.5 });
					} else if (lower.includes('torus')) {
						geometry = new THREE.TorusGeometry(1, 0.4, 16, 100);
						material = new THREE.MeshStandardMaterial({ color: 0x4444ff, roughness: 0.3, metalness: 0.5 });
					} else {
						geometry = new THREE.BoxGeometry(1, 1, 1);
						material = new THREE.MeshStandardMaterial({ color: 0xff44ff, roughness: 0.3, metalness: 0.5 });
					}

					currentMesh = new THREE.Mesh(geometry, material);
					scene.add(currentMesh);
				}

				function appState() {
					return {
						prompt: 'a red cube',
						device: 'CUDA',
						steps: 64,
						voxelSize: 0.5,
						generating: false,
						status: '',
						statusType: 'info',

						generate() {
							if (!this.prompt.trim()) {
								this.setStatus('Please enter a prompt', 'error');
								return;
							}

							this.generating = true;
							this.status = '';

							const self = this;

							// Simulate generation
							setTimeout(() => {
								createGeometry(self.prompt);
								self.generating = false;
								self.setStatus('Model generated successfully!', 'success');
							}, 2000);
						},

						setStatus(msg, type = 'info') {
							this.status = msg;
							this.statusType = type;
						}
					};
				}

				// Initialize Three.js when page loads
				document.addEventListener('DOMContentLoaded', initThreeJS);
			</script>
		</body>
		</html>
	]"

end
