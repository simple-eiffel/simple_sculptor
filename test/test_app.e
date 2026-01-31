note
	description: "Test application for simple_sculptor library"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run all tests.
		do
			print ("Running simple_sculptor tests...%N%N")
			passed := 0
			failed := 0

			run_simple_sculptor_tests
			run_sculptor_engine_tests
			run_point_cloud_tests
			run_mesh_converter_tests
			run_sculptor_mesh_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_simple_sculptor_tests
			-- Run SIMPLE_SCULPTOR tests.
		do
			create simple_sculptor_tests
			run_test (agent simple_sculptor_tests.test_make_creates_unloaded_instance, "test_make_creates_unloaded_instance")
			run_test (agent simple_sculptor_tests.test_set_model_path, "test_set_model_path")
			run_test (agent simple_sculptor_tests.test_set_device, "test_set_device")
			run_test (agent simple_sculptor_tests.test_set_voxel_size, "test_set_voxel_size")
			run_test (agent simple_sculptor_tests.test_builder_chaining, "test_builder_chaining")
			run_test (agent simple_sculptor_tests.test_estimated_inference_time_cpu, "test_estimated_inference_time_cpu")
			run_test (agent simple_sculptor_tests.test_estimated_inference_time_cuda, "test_estimated_inference_time_cuda")
			run_test (agent simple_sculptor_tests.test_frame_conditions_set_device, "test_frame_conditions_set_device")
			run_test (agent simple_sculptor_tests.test_voxel_size_min_boundary, "test_voxel_size_min_boundary")
			run_test (agent simple_sculptor_tests.test_voxel_size_max_boundary, "test_voxel_size_max_boundary")
			run_test (agent simple_sculptor_tests.test_inference_steps_min_boundary, "test_inference_steps_min_boundary")
			run_test (agent simple_sculptor_tests.test_inference_steps_max_boundary, "test_inference_steps_max_boundary")
		end

	run_sculptor_engine_tests
			-- Run SCULPTOR_ENGINE tests.
		do
			create sculptor_engine_tests
			run_test (agent sculptor_engine_tests.test_make_creates_engine, "test_make_creates_engine")
			run_test (agent sculptor_engine_tests.test_set_model_path, "test_set_model_path")
			run_test (agent sculptor_engine_tests.test_set_device, "test_set_device")
			run_test (agent sculptor_engine_tests.test_estimated_inference_time_cpu, "test_estimated_inference_time_cpu")
			run_test (agent sculptor_engine_tests.test_estimated_inference_time_cuda, "test_estimated_inference_time_cuda")
			run_test (agent sculptor_engine_tests.test_estimated_inference_time_tensorrt, "test_estimated_inference_time_tensorrt")
			run_test (agent sculptor_engine_tests.test_model_lifecycle, "test_model_lifecycle")
			run_test (agent sculptor_engine_tests.test_execute_inference, "test_execute_inference")
		end

	run_point_cloud_tests
			-- Run POINT_CLOUD tests.
		do
			create point_cloud_tests
			run_test (agent point_cloud_tests.test_make_creates_point_cloud, "test_make_creates_point_cloud")
			run_test (agent point_cloud_tests.test_point_count_calculation, "test_point_count_calculation")
			run_test (agent point_cloud_tests.test_empty_point_cloud, "test_empty_point_cloud")
			run_test (agent point_cloud_tests.test_non_empty_point_cloud, "test_non_empty_point_cloud")
			run_test (agent point_cloud_tests.test_bounding_box, "test_bounding_box")
			run_test (agent point_cloud_tests.test_get_point, "test_get_point")
			run_test (agent point_cloud_tests.test_points_model_query, "test_points_model_query")
			run_test (agent point_cloud_tests.test_negative_coordinates, "test_negative_coordinates")
			run_test (agent point_cloud_tests.test_large_point_cloud, "test_large_point_cloud")
			run_test (agent point_cloud_tests.test_all_same_coordinates, "test_all_same_coordinates")
		end

	run_mesh_converter_tests
			-- Run MESH_CONVERTER tests.
		do
			create mesh_converter_tests
			run_test (agent mesh_converter_tests.test_make_creates_converter, "test_make_creates_converter")
			run_test (agent mesh_converter_tests.test_voxel_size_bounds, "test_voxel_size_bounds")
			run_test (agent mesh_converter_tests.test_convert_returns_mesh, "test_convert_returns_mesh")
			run_test (agent mesh_converter_tests.test_convert_with_smoothing, "test_convert_with_smoothing")
			run_test (agent mesh_converter_tests.test_voxel_grid_topology, "test_voxel_grid_topology")
			run_test (agent mesh_converter_tests.test_single_point, "test_single_point")
			run_test (agent mesh_converter_tests.test_min_voxel_size_creates_mesh, "test_min_voxel_size_creates_mesh")
			run_test (agent mesh_converter_tests.test_max_voxel_size_creates_mesh, "test_max_voxel_size_creates_mesh")
		end

	run_sculptor_mesh_tests
			-- Run SCULPTOR_MESH tests.
		do
			create sculptor_mesh_tests
			run_test (agent sculptor_mesh_tests.test_make_empty_mesh, "test_make_empty_mesh")
			run_test (agent sculptor_mesh_tests.test_make_with_vertices_and_faces, "test_make_with_vertices_and_faces")
			run_test (agent sculptor_mesh_tests.test_bounding_box, "test_bounding_box")
			run_test (agent sculptor_mesh_tests.test_validate_mesh, "test_validate_mesh")
			run_test (agent sculptor_mesh_tests.test_model_queries, "test_model_queries")
			run_test (agent sculptor_mesh_tests.test_empty_mesh_bounding_box, "test_empty_mesh_bounding_box")
			run_test (agent sculptor_mesh_tests.test_validate_empty_mesh, "test_validate_empty_mesh")
			run_test (agent sculptor_mesh_tests.test_large_mesh, "test_large_mesh")
			run_test (agent sculptor_mesh_tests.test_degenerate_triangle, "test_degenerate_triangle")
		end

feature {NONE} -- Implementation

	simple_sculptor_tests: TEST_SIMPLE_SCULPTOR
	sculptor_engine_tests: TEST_SCULPTOR_ENGINE
	point_cloud_tests: TEST_POINT_CLOUD
	mesh_converter_tests: TEST_MESH_CONVERTER
	sculptor_mesh_tests: TEST_SCULPTOR_MESH

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
