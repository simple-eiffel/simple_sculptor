note
	description: "Unit tests for SIMPLE_SCULPTOR facade"
	author: "Larry Rix"

class
	TEST_SIMPLE_SCULPTOR

inherit
	EQA_TEST_SET

feature -- Tests

	test_make_creates_unloaded_instance
			-- Test that make creates an unloaded instance.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			assert ("not loaded initially", not l_sculptor.is_model_loaded)
		end

	test_set_model_path
			-- Test setting model path configuration.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_model_path ("model.onnx")
			assert ("path set", l_sculptor.engine.model_path /= Void)
			assert ("path correct", attached l_sculptor.engine.model_path as p implies p.is_equal ("model.onnx"))
		end

	test_set_device
			-- Test device selection (CPU/CUDA/TensorRT).
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_device ("CUDA")
			assert ("device set to CUDA", l_sculptor.engine.device.is_equal ("CUDA"))
		end

	test_set_voxel_size
			-- Test voxel size configuration.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_voxel_size (0.1)
			assert ("voxel size set", l_sculptor.config.voxel_size = 0.1)
		end

	test_builder_chaining
			-- Test fluent builder pattern.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_device ("CPU")
				.set_voxel_size (0.5)
				.set_seed (123)
				.set_num_inference_steps (64)
			assert ("device set", l_sculptor.engine.device.is_equal ("CPU"))
			assert ("voxel_size set", l_sculptor.config.voxel_size = 0.5)
			assert ("seed set", l_sculptor.config.seed = 123)
			assert ("steps set", l_sculptor.config.num_inference_steps = 64)
		end

	test_estimated_inference_time_cpu
			-- Test inference time estimation for CPU device.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_device ("CPU")
			l_sculptor.set_model_path ("model.onnx")
			l_sculptor.load_model
			assert ("model loaded", l_sculptor.is_model_loaded)
			assert ("cpu time 60s", l_sculptor.estimated_inference_time = 60.0)
		end

	test_estimated_inference_time_cuda
			-- Test inference time estimation for CUDA device.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_device ("CUDA")
			l_sculptor.set_model_path ("model.onnx")
			l_sculptor.load_model
			assert ("model loaded", l_sculptor.is_model_loaded)
			assert ("cuda time 15s", l_sculptor.estimated_inference_time = 15.0)
		end

	test_frame_conditions_set_device
			-- Test that set_device preserves other config.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_voxel_size (0.3)
			l_sculptor.set_seed (99)
			l_sculptor.set_num_inference_steps (100)
			l_sculptor.set_device ("CUDA")
			assert ("voxel_size unchanged", l_sculptor.config.voxel_size = 0.3)
			assert ("seed unchanged", l_sculptor.config.seed = 99)
			assert ("steps unchanged", l_sculptor.config.num_inference_steps = 100)
		end

	test_voxel_size_min_boundary
			-- Test minimum voxel size boundary.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_voxel_size (0.1)
			assert ("min size 0.1", l_sculptor.config.voxel_size = 0.1)
		end

	test_voxel_size_max_boundary
			-- Test maximum voxel size boundary.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_voxel_size (1.0)
			assert ("max size 1.0", l_sculptor.config.voxel_size = 1.0)
		end

	test_inference_steps_min_boundary
			-- Test minimum inference steps.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_num_inference_steps (16)
			assert ("min steps 16", l_sculptor.config.num_inference_steps = 16)
		end

	test_inference_steps_max_boundary
			-- Test maximum inference steps.
		local
			l_sculptor: SIMPLE_SCULPTOR
		do
			create l_sculptor.make
			l_sculptor.set_num_inference_steps (256)
			assert ("max steps 256", l_sculptor.config.num_inference_steps = 256)
		end

end
