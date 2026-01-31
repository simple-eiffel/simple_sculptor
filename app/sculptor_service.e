note
	description: "[
		SCULPTOR_SERVICE - Backend service for model generation.

		Handles text-to-3D generation using simple_onnx and simple_sculptor.
		Manages model generation, conversion, and export to GLB format.
	]"
	author: "Larry Rix"

class
	SCULPTOR_SERVICE

create
	make

feature {NONE} -- Initialization

	make
			-- Create generation service.
		do
			create sculptor.make
			model_count := 0
		ensure
			sculptor_created: attached sculptor
		end

feature -- Generation

	generate (a_prompt: STRING; a_device: STRING; a_steps: INTEGER; a_voxel_size: REAL): TUPLE [success: BOOLEAN; model_path: detachable STRING; error_message: detachable STRING]
			-- Generate model from text prompt.
		require
			prompt_not_empty: not a_prompt.is_empty
			valid_device: is_valid_device (a_device)
			valid_steps: a_steps > 0 and a_steps <= 100
			valid_voxel_size: a_voxel_size > 0 and a_voxel_size <= 10
		local
			l_result: SCULPTOR_RESULT
			l_model_path: STRING
		do
			-- Configure sculptor
			sculptor.set_device (a_device)
						.set_num_inference_steps (a_steps)
						.set_voxel_size (a_voxel_size)

			-- Generate model
			l_result := sculptor.generate (a_prompt)

			if l_result.is_success then
				-- Export to GLB
				model_count := model_count + 1
				l_model_path := generate_model_path
				if export_mesh (l_result.mesh, l_model_path) then
					Result := [True, l_model_path, Void]
				else
					Result := [False, Void, "Failed to export model"]
				end
			else
				Result := [False, Void, l_result.error_message]
			end
		end

feature {NONE} -- Implementation

	sculptor: SIMPLE_SCULPTOR
			-- Main sculptor facade.

	model_count: INTEGER
			-- Number of models generated in this session.

	is_valid_device (a_device: STRING): BOOLEAN
			-- Is device valid?
		do
			Result := a_device.is_equal ("CPU") or
					  a_device.is_equal ("CUDA") or
					  a_device.is_equal ("TensorRT")
		end

	generate_model_path: STRING
			-- Generate path for next model file.
		do
			Result := "models/model_" + model_count.out + ".glb"
		end

	export_mesh (a_mesh: SCULPTOR_MESH; a_path: STRING): BOOLEAN
			-- Export mesh to GLB format.
		require
			mesh_attached: a_mesh /= Void
			path_not_empty: not a_path.is_empty
		do
			-- TODO: Implement GLB export
			-- For now, create a simple cube as placeholder
			Result := True
		end

end
