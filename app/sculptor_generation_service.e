note
	description: "Service to generate 3D models from text prompts"
	author: "Larry Rix"

class
	SCULPTOR_GENERATION_SERVICE

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize generation service.
		do
			create engine.make
			create converter.make
			create serializer
		ensure
			engine_created: engine /= Void
			converter_created: converter /= Void
		end

feature -- Generation

	generate (a_prompt: STRING; a_device: STRING; a_steps: INTEGER; a_voxel_size: REAL_64): STRING
			-- Generate model from prompt and return mesh as JSON.
		require
			prompt_not_void: a_prompt /= Void
			prompt_not_empty: not a_prompt.is_empty
			device_valid: a_device.is_equal ("CPU") or a_device.is_equal ("CUDA") or a_device.is_equal ("TensorRT")
			steps_positive: a_steps > 0
			voxel_size_positive: a_voxel_size > 0.0
		local
			l_inference_result: SCULPTOR_INFERENCE_RESULT
			l_mesh: SCULPTOR_MESH
			l_seed: INTEGER
		do
			-- Configure engine
			engine.set_device (a_device).do_nothing

			-- Run inference with seed based on prompt
			l_seed := hash_prompt (a_prompt)
			l_inference_result := engine.execute (a_prompt, l_seed)

			-- Convert result to mesh
			if l_inference_result.is_success then
				l_mesh := converter.convert (l_inference_result.point_cloud, a_voxel_size)

				-- Serialize to JSON
				Result := serializer.mesh_to_json (l_mesh)
			else
				Result := "{%"error%": %"Generation failed%"}"
			end
		ensure
			result_not_void: Result /= Void
			result_not_empty: not Result.is_empty
		end

feature {NONE} -- Implementation

	engine: SCULPTOR_ENGINE
			-- ONNX inference engine.

	converter: MESH_CONVERTER
			-- Point cloud to mesh converter.

	serializer: SCULPTOR_MESH_SERIALIZER
			-- Mesh JSON serializer.

	hash_prompt (a_prompt: STRING): INTEGER
			-- Generate seed from prompt text.
		require
			prompt_not_void: a_prompt /= Void
		local
			l_hash: INTEGER
			l_idx: INTEGER
		do
			l_hash := 5381
			from
				l_idx := 1
			until
				l_idx > a_prompt.count
			loop
				l_hash := ((l_hash |<< 5) + l_hash) + a_prompt [l_idx].code
				l_idx := l_idx + 1
			end
			Result := l_hash
		end

end
