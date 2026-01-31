note
	description: "Unit tests for simple_sculptor"
	author: "Larry Rix"

class
	TEST_SCULPTOR

feature -- Tests

	run_all
			-- Run all tests.
		do
			test_point_creation
			test_vector_magnitude
			test_bounding_box
		end

	test_point_creation
			-- Test SCULPTOR_POINT_3D creation.
		local
			l_point: SCULPTOR_POINT_3D
		do
			create l_point.make (1.0, 2.0, 3.0)
			assert (l_point.x = 1.0, "X coordinate")
			assert (l_point.y = 2.0, "Y coordinate")
			assert (l_point.z = 3.0, "Z coordinate")
		end

	test_vector_magnitude
			-- Test SCULPTOR_VECTOR_3D magnitude.
		local
			l_vec: SCULPTOR_VECTOR_3D
		do
			create l_vec.make (3.0, 4.0, 0.0)
			-- Magnitude of (3,4,0) should be 5
			assert (l_vec.magnitude > 4.9 and l_vec.magnitude < 5.1, "Magnitude")
		end

	test_bounding_box
			-- Test BOUNDING_BOX_3D.
		local
			l_box: BOUNDING_BOX_3D
		do
			create l_box.make (0.0, 0.0, 0.0, 10.0, 10.0, 10.0)
			assert (l_box.width = 10.0, "Width")
			assert (l_box.height = 10.0, "Height")
			assert (l_box.depth = 10.0, "Depth")
			assert (l_box.volume = 1000.0, "Volume")
		end

	assert (condition: BOOLEAN; message: STRING)
			-- Assert condition is true.
		do
			if not condition then
				print ("FAIL: " + message + "%N")
			else
				print ("PASS: " + message + "%N")
			end
		end

end
