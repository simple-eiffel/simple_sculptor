note
	description: "Unit tests for SCULPTOR_ENGINE"
	author: "Larry Rix"

class
	TEST_SCULPTOR_ENGINE

inherit
	EQA_TEST_SET

feature -- Tests

	test_make_creates_engine
			-- Test engine creation.
		local
			l_engine: SCULPTOR_ENGINE
		do
			create l_engine.make
			assert ("engine created", l_engine /= Void)
		end

	test_set_model_path
			-- Test setting model path.
		local
			l_engine: SCULPTOR_ENGINE
		do
			create l_engine.make
			l_engine.set_model_path ("models/point-e.onnx")
			assert ("path set", l_engine.model_path /= Void)
			assert ("path value", attached l_engine.model_path as p implies p.is_equal ("models/point-e.onnx"))
		end

	test_set_device
			-- Test device selection.
		local
			l_engine: SCULPTOR_ENGINE
		do
			create l_engine.make
			l_engine.set_device ("CUDA")
			assert ("device set", l_engine.device.is_equal ("CUDA"))
		end

	test_estimated_inference_time_cpu
			-- Test CPU inference time estimate.
		local
			l_engine: SCULPTOR_ENGINE
		do
			create l_engine.make
			l_engine.set_device ("CPU")
			l_engine.set_model_path ("model.onnx")
			l_engine.load_model
			assert ("cpu time 60s", l_engine.estimated_inference_time = 60.0)
		end

	test_estimated_inference_time_cuda
			-- Test CUDA inference time estimate.
		local
			l_engine: SCULPTOR_ENGINE
		do
			create l_engine.make
			l_engine.set_device ("CUDA")
			l_engine.set_model_path ("model.onnx")
			l_engine.load_model
			assert ("cuda time 15s", l_engine.estimated_inference_time = 15.0)
		end

	test_estimated_inference_time_tensorrt
			-- Test TensorRT inference time estimate.
		local
			l_engine: SCULPTOR_ENGINE
		do
			create l_engine.make
			l_engine.set_device ("TensorRT")
			l_engine.set_model_path ("model.onnx")
			l_engine.load_model
			assert ("tensorrt time 10s", l_engine.estimated_inference_time = 10.0)
		end

	test_model_lifecycle
			-- Test model loading and unloading.
		local
			l_engine: SCULPTOR_ENGINE
		do
			create l_engine.make
			assert ("initially not loaded", not l_engine.is_model_loaded)
			l_engine.set_model_path ("model.onnx")
			l_engine.load_model
			assert ("loaded after load_model", l_engine.is_model_loaded)
			l_engine.unload_model
			assert ("unloaded after unload_model", not l_engine.is_model_loaded)
		end

	test_execute_inference
			-- Test ONNX inference execution.
		local
			l_engine: SCULPTOR_ENGINE
			l_result: SCULPTOR_INFERENCE_RESULT
		do
			create l_engine.make
			l_engine.set_model_path ("model.onnx")
			l_engine.load_model
			l_result := l_engine.execute ("a red cube", 42)
			assert ("result not void", l_result /= Void)
			assert ("result is success", l_result.is_success)
			assert ("has point cloud", attached l_result.points)
		end

end
