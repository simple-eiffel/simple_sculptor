/**
 * Sculptor Viewer - 3D Model Viewer
 * Handles Three.js rendering and communication with Eiffel backend
 */

class SculptorViewer {
	constructor() {
		this.scene = null;
		this.camera = null;
		this.renderer = null;
		this.model = null;
		this.controls = {
			isDragging: false,
			previousMousePosition: { x: 0, y: 0 }
		};
	}

	/**
	 * Initialize Three.js scene, camera, and renderer
	 */
	init() {
		const canvas = document.getElementById('canvas');
		const width = canvas.clientWidth;
		const height = canvas.clientHeight;

		// Scene setup
		this.scene = new THREE.Scene();
		this.scene.background = new THREE.Color(0xfafafa);

		// Camera setup
		this.camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 1000);
		this.camera.position.set(0, 2, 3);
		this.camera.lookAt(0, 0, 0);

		// Renderer setup
		this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
		this.renderer.setSize(width, height);
		this.renderer.setPixelRatio(window.devicePixelRatio);
		this.renderer.shadowMap.enabled = true;

		// Lighting
		const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
		directionalLight.position.set(5, 10, 7);
		directionalLight.castShadow = true;
		directionalLight.shadow.mapSize.width = 2048;
		directionalLight.shadow.mapSize.height = 2048;
		this.scene.add(directionalLight);

		const backLight = new THREE.DirectionalLight(0xffffff, 0.3);
		backLight.position.set(-5, 5, -7);
		this.scene.add(backLight);

		const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
		this.scene.add(ambientLight);

		// Add grid
		const gridHelper = new THREE.GridHelper(10, 10, 0xcccccc, 0xeeeeee);
		gridHelper.position.y = -1;
		this.scene.add(gridHelper);

		// Create default cube
		this.createDefaultModel();

		// Setup event listeners
		this.setupEventListeners();

		// Start render loop
		this.animate();

		// Attach UI events
		this.attachUIEvents();
	}

	/**
	 * Create a default cube model for initial display
	 */
	createDefaultModel() {
		const geometry = new THREE.BoxGeometry(2, 2, 2);
		const material = new THREE.MeshPhongMaterial({
			color: 0xff0000,
			shininess: 100
		});
		this.model = new THREE.Mesh(geometry, material);
		this.model.castShadow = true;
		this.scene.add(this.model);
	}

	/**
	 * Setup mouse and scroll event listeners for interaction
	 */
	setupEventListeners() {
		const canvas = document.getElementById('canvas');

		canvas.addEventListener('mousedown', (e) => {
			this.controls.isDragging = true;
			this.controls.previousMousePosition = { x: e.clientX, y: e.clientY };
		});

		canvas.addEventListener('mousemove', (e) => {
			if (this.controls.isDragging && this.model) {
				const deltaX = e.clientX - this.controls.previousMousePosition.x;
				const deltaY = e.clientY - this.controls.previousMousePosition.y;
				this.model.rotation.y += deltaX * 0.01;
				this.model.rotation.x += deltaY * 0.01;
				this.controls.previousMousePosition = { x: e.clientX, y: e.clientY };
			}
		});

		canvas.addEventListener('mouseup', () => {
			this.controls.isDragging = false;
		});

		canvas.addEventListener('wheel', (e) => {
			e.preventDefault();
			this.camera.position.z += e.deltaY * 0.01;
			this.camera.position.z = Math.max(0.5, Math.min(15, this.camera.position.z));
		});

		// Handle window resize
		window.addEventListener('resize', () => {
			const width = canvas.clientWidth;
			const height = canvas.clientHeight;
			this.camera.aspect = width / height;
			this.camera.updateProjectionMatrix();
			this.renderer.setSize(width, height);
		});
	}

	/**
	 * Attach UI event listeners
	 */
	attachUIEvents() {
		document.getElementById('generateBtn').addEventListener('click', () => this.generate());

		document.getElementById('steps').addEventListener('input', (e) => {
			document.getElementById('stepsValue').textContent = e.target.value;
		});

		document.getElementById('voxelSize').addEventListener('input', (e) => {
			document.getElementById('voxelSizeValue').textContent = e.target.value;
		});
	}

	/**
	 * Animation loop
	 */
	animate() {
		requestAnimationFrame(() => this.animate());
		this.renderer.render(this.scene, this.camera);
	}

	/**
	 * Generate model from user input
	 */
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
			// For demonstration, create a placeholder model
			// In production, this would call the HTTP API
			this.generatePlaceholderModel(prompt);
			this.showStatus('Model generated successfully!', 'success');
		} catch (error) {
			this.showStatus('Error: ' + error.message, 'error');
		} finally {
			this.setLoading(false);
		}
	}

	/**
	 * Generate a placeholder model for demonstration
	 */
	generatePlaceholderModel(prompt) {
		// Remove old model
		if (this.model) {
			this.scene.remove(this.model);
		}

		// Create a simple geometry based on prompt keywords
		let geometry;
		let color = 0x667eea;
		let scale = 1;

		if (prompt.toLowerCase().includes('cube')) {
			geometry = new THREE.BoxGeometry(2, 2, 2);
			color = 0xff0000;
		} else if (prompt.toLowerCase().includes('sphere') || prompt.toLowerCase().includes('ball')) {
			geometry = new THREE.SphereGeometry(1.5, 32, 32);
			color = 0x00ff00;
		} else if (prompt.toLowerCase().includes('cylinder')) {
			geometry = new THREE.CylinderGeometry(1, 1, 2.5, 32);
			color = 0x0000ff;
		} else if (prompt.toLowerCase().includes('cone')) {
			geometry = new THREE.ConeGeometry(1.5, 2.5, 32);
			color = 0xffff00;
		} else if (prompt.toLowerCase().includes('torus')) {
			geometry = new THREE.TorusGeometry(1.5, 0.5, 16, 32);
			color = 0xff00ff;
		} else {
			// Default tetrahedron
			geometry = new THREE.TetrahedronGeometry(1.5);
			color = 0x667eea;
		}

		const material = new THREE.MeshPhongMaterial({
			color: color,
			shininess: 100,
			wireframe: false
		});

		this.model = new THREE.Mesh(geometry, material);
		this.model.castShadow = true;
		this.scene.add(this.model);

		// Reset camera position
		this.camera.position.set(0, 2, 3);
		this.camera.lookAt(0, 0, 0);
	}

	/**
	 * Load a GLB model from the server
	 */
	async loadModel(path) {
		const loader = new THREE.GLTFLoader();

		return new Promise((resolve, reject) => {
			loader.load(
				path,
				(gltf) => {
					// Remove old model
					if (this.model) {
						this.scene.remove(this.model);
					}

					this.model = gltf.scene;
					this.scene.add(this.model);

					// Enable shadows
					this.model.traverse((node) => {
						if (node.isMesh) {
							node.castShadow = true;
							node.receiveShadow = true;
						}
					});

					// Center and scale model
					const box = new THREE.Box3().setFromObject(this.model);
					const center = box.getCenter(new THREE.Vector3());
					this.model.position.sub(center);

					const size = box.getSize(new THREE.Vector3());
					const maxDim = Math.max(size.x, size.y, size.z);
					const scale = 4 / maxDim;
					this.model.scale.multiplyScalar(scale);

					resolve();
				},
				undefined,
				(error) => {
					reject(error);
				}
			);
		});
	}

	/**
	 * Set loading state
	 */
	setLoading(active) {
		document.getElementById('loading').classList.toggle('active', active);
		document.getElementById('generateBtn').disabled = active;
	}

	/**
	 * Show status message
	 */
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
}

// Initialize viewer when page loads
document.addEventListener('DOMContentLoaded', () => {
	const viewer = new SculptorViewer();
	viewer.init();
});
