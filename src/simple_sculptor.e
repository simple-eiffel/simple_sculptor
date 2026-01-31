note
	description: "Text-to-3D generation library using ONNX Runtime and procedural geometry"
	author: "Larry Rix"

class
	SIMPLE_SCULPTOR

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize ONNX environment and default configuration.
		do
			create engine.make
			create config.make
		ensure
			engine_created: engine /= Void
			config_created: config /= Void
		end

feature -- Access

	engine: SCULPTOR_ENGINE
			-- ONNX inference engine.

	config: SCULPTOR_CONFIG
			-- Current generation configuration.

	is_model_loaded: BOOLEAN
			-- Is ONNX model loaded and ready?
		do
			Result := engine.is_model_loaded
		end

	estimated_inference_time: REAL
			-- Estimated time for inference (seconds).
		require
			model_loaded: is_model_loaded
		do
			Result := engine.estimated_inference_time
		end

feature -- Configuration

	set_model_path (a_path: STRING): like Current
			-- Set path to Point-E ONNX model file.
		require
			path_not_void: a_path /= Void
			path_not_empty: not a_path.is_empty
		do
			engine.set_model_path (a_path)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_device (a_device: STRING): like Current
			-- Set device: "CPU", "CUDA", or "TensorRT".
		require
			device_not_void: a_device /= Void
			valid_device: a_device.is_equal ("CPU") or a_device.is_equal ("CUDA") or a_device.is_equal ("TensorRT")
			not_loaded: not is_model_loaded
		do
			engine.set_device (a_device)
			Result := Current
		ensure
			result_is_current: Result = Current
			device_changed: engine.device.is_equal (a_device)
			voxel_size_unchanged: config.voxel_size = old config.voxel_size
			seed_unchanged: config.seed = old config.seed
			steps_unchanged: config.num_inference_steps = old config.num_inference_steps
		end

	set_voxel_size (a_size: REAL): like Current
			-- Set voxel size for mesh conversion (0.1 to 1.0).
		require
			size_valid: a_size >= 0.1 and a_size <= 1.0
		do
			config.set_voxel_size (a_size)
			Result := Current
		ensure
			result_is_current: Result = Current
			voxel_size_set: config.voxel_size = a_size
			device_unchanged: engine.device.is_equal (old engine.device)
			seed_unchanged: config.seed = old config.seed
			steps_unchanged: config.num_inference_steps = old config.num_inference_steps
			model_state_unchanged: is_model_loaded = old is_model_loaded
		end

	set_seed (a_seed: INTEGER): like Current
			-- Set random seed for reproducibility.
		do
			config.set_seed (a_seed)
			Result := Current
		ensure
			result_is_current: Result = Current
			seed_set: config.seed = a_seed
			device_unchanged: engine.device.is_equal (old engine.device)
			voxel_size_unchanged: config.voxel_size = old config.voxel_size
			steps_unchanged: config.num_inference_steps = old config.num_inference_steps
			model_state_unchanged: is_model_loaded = old is_model_loaded
		end

	set_num_inference_steps (a_steps: INTEGER): like Current
			-- Set number of diffusion steps (16 to 256).
		require
			steps_valid: a_steps >= 16 and a_steps <= 256
		do
			config.set_num_inference_steps (a_steps)
			Result := Current
		ensure
			result_is_current: Result = Current
			steps_set: config.num_inference_steps = a_steps
			device_unchanged: engine.device.is_equal (old engine.device)
			voxel_size_unchanged: config.voxel_size = old config.voxel_size
			seed_unchanged: config.seed = old config.seed
			model_state_unchanged: is_model_loaded = old is_model_loaded
		end

feature -- Generation

	generate (a_prompt: STRING): SCULPTOR_RESULT
			-- Generate 3D mesh from text prompt.
		require
			prompt_not_void: a_prompt /= Void
			prompt_not_empty: not a_prompt.is_empty
			model_loaded: is_model_loaded
		local
			l_inference_result: SCULPTOR_INFERENCE_RESULT
			l_converter: MESH_CONVERTER
			l_mesh: SCULPTOR_MESH
		do
			-- Step 1: Run ONNX inference
			l_inference_result := engine.execute (a_prompt, config.seed)

			if l_inference_result.is_success and attached l_inference_result.points as l_points then
				-- Step 2: Convert point cloud to mesh using voxel grid
				create l_converter.make (config.voxel_size)
				l_mesh := l_converter.convert (l_points)

				-- Step 3: Return mesh result
				create Result.make_success (l_mesh)
			else
				-- Inference failed
				if attached l_inference_result.error_message as l_error then
					create Result.make_failure (l_error)
				else
					create Result.make_failure ("Unknown inference error")
				end
			end
		ensure
			result_not_void: Result /= Void
			result_valid: Result.is_success xor (not Result.error_message.is_empty)
		end

	generate_and_view (a_prompt: STRING): SCULPTOR_RESULT
			-- Generate 3D mesh and open in browser viewer.
		require
			prompt_not_void: a_prompt /= Void
			prompt_not_empty: not a_prompt.is_empty
			model_loaded: is_model_loaded
		do
			-- Generate mesh
			Result := generate (a_prompt)

			-- If successful, viewer would open here (Phase 5+)
			-- For Phase 4: just return the result
		ensure
			result_not_void: Result /= Void
		end

	batch_generate (a_prompts: LIST [STRING]): LIST [SCULPTOR_RESULT]
			-- Generate multiple 3D meshes from list of prompts.
		require
			prompts_not_void: a_prompts /= Void
			prompts_not_empty: a_prompts.count > 0
			model_loaded: is_model_loaded
		local
			l_results: ARRAYED_LIST [SCULPTOR_RESULT]
		do
			create l_results.make (a_prompts.count)

			across a_prompts as ic loop
				if attached ic.item as l_prompt then
					l_results.extend (generate (l_prompt))
				end
			end

			Result := l_results
		ensure
			result_not_void: Result /= Void
			result_count: Result.count = a_prompts.count
			each_result_valid: across Result as ic all
								  ic.item.is_success xor (not ic.item.error_message.is_empty)
								end
		end

feature -- Model Management

	load_model
			-- Load ONNX model from configured path into memory.
		require
			model_path_set: engine.model_path /= Void
		do
			engine.load_model
		ensure
			model_loaded: is_model_loaded
		end

	unload_model
			-- Unload ONNX model and free VRAM.
		require
			model_loaded: is_model_loaded
		do
			engine.unload_model
		ensure
			model_not_loaded: not is_model_loaded
		end

invariant
	engine_not_void: engine /= Void
	config_not_void: config /= Void

end
