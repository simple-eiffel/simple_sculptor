note
	description: "Configuration builder for 3D generation"
	author: "Larry Rix"

class
	SCULPTOR_CONFIG

create
	make

feature {NONE} -- Initialization

	make
			-- Create default configuration.
		do
			voxel_size := 0.5
			seed := 42
			num_inference_steps := 64
		ensure
			voxel_size_set: voxel_size = 0.5
			seed_set: seed = 42
			steps_set: num_inference_steps = 64
		end

feature -- Access

	voxel_size: REAL
			-- Voxel resolution for mesh conversion.

	seed: INTEGER
			-- Random seed for reproducibility.

	num_inference_steps: INTEGER
			-- Number of diffusion inference steps.

feature -- Configuration (Builder Pattern)

	set_voxel_size (a_size: REAL): like Current
			-- Set voxel size (0.1 to 1.0).
		require
			size_valid: a_size >= 0.1 and a_size <= 1.0
		do
			voxel_size := a_size
			Result := Current
		ensure
			result_is_current: Result = Current
			size_set: voxel_size = a_size
		end

	set_seed (a_seed: INTEGER): like Current
			-- Set random seed.
		do
			seed := a_seed
			Result := Current
		ensure
			result_is_current: Result = Current
			seed_set: seed = a_seed
		end

	set_num_inference_steps (a_steps: INTEGER): like Current
			-- Set inference steps (16 to 256).
		require
			steps_valid: a_steps >= 16 and a_steps <= 256
		do
			num_inference_steps := a_steps
			Result := Current
		ensure
			result_is_current: Result = Current
			steps_set: num_inference_steps = a_steps
		end

invariant
	voxel_size_valid: voxel_size >= 0.1 and voxel_size <= 1.0
	steps_valid: num_inference_steps >= 16 and num_inference_steps <= 256

end
