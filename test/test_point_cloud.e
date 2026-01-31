note
	description: "Unit tests for POINT_CLOUD"
	author: "Larry Rix"

class
	TEST_POINT_CLOUD

inherit
	EQA_TEST_SET

feature -- Tests

	test_make_creates_point_cloud
			-- Test creating point cloud from array.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
		do
			create l_points.make_filled (0.0, 1, 9)  -- 3 points (x,y,z each)
			l_points [1] := 0.0
			l_points [2] := 1.0
			l_points [3] := 2.0
			l_points [4] := 3.0
			l_points [5] := 4.0
			l_points [6] := 5.0
			l_points [7] := 6.0
			l_points [8] := 7.0
			l_points [9] := 8.0
			create l_cloud.make (l_points)
			assert ("point count correct", l_cloud.point_count = 3)
		end

	test_point_count_calculation
			-- Test point count is divisible by 3.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
		do
			create l_points.make_filled (0.0, 1, 6)  -- 2 points
			create l_cloud.make (l_points)
			assert ("2 points detected", l_cloud.point_count = 2)
		end

	test_empty_point_cloud
			-- Test is_empty query.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
		do
			create l_points.make_filled (0.0, 1, 0)
			create l_cloud.make (l_points)
			assert ("cloud is empty", l_cloud.is_empty)
		end

	test_non_empty_point_cloud
			-- Test is_empty returns false for non-empty.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
		do
			create l_points.make_filled (0.0, 1, 3)  -- 1 point
			create l_cloud.make (l_points)
			assert ("cloud is not empty", not l_cloud.is_empty)
		end

	test_bounding_box
			-- Test bounding box calculation.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_bbox: BOUNDING_BOX_3D
		do
			create l_points.make_filled (0.0, 1, 9)
			l_points [1] := 1.0
			l_points [2] := 2.0
			l_points [3] := 3.0
			l_points [4] := -1.0
			l_points [5] := 4.0
			l_points [6] := 5.0
			l_points [7] := 3.0
			l_points [8] := 0.0
			l_points [9] := 2.0
			create l_cloud.make (l_points)
			l_bbox := l_cloud.bounding_box
			assert ("bbox not void", l_bbox /= Void)
			assert ("min x correct", l_bbox.min_x = -1.0)
			assert ("max x correct", l_bbox.max_x = 3.0)
			assert ("min y correct", l_bbox.min_y = 0.0)
			assert ("max y correct", l_bbox.max_y = 4.0)
			assert ("min z correct", l_bbox.min_z = 2.0)
			assert ("max z correct", l_bbox.max_z = 5.0)
		end

	test_get_point
			-- Test retrieving individual points.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_point: detachable SCULPTOR_POINT_3D
		do
			create l_points.make_filled (0.0, 1, 6)
			l_points [1] := 1.0
			l_points [2] := 2.0
			l_points [3] := 3.0
			l_points [4] := 4.0
			l_points [5] := 5.0
			l_points [6] := 6.0
			create l_cloud.make (l_points)
			l_point := l_cloud.get_point (0)
			assert ("point not void", l_point /= Void)
			assert ("x coordinate", attached l_point as p implies p.x = 1.0)
			assert ("y coordinate", attached l_point as p implies p.y = 2.0)
			assert ("z coordinate", attached l_point as p implies p.z = 3.0)
		end

	test_points_model_query
			-- Test MML model query for postcondition verification.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_model: ARRAY [REAL_32]
		do
			create l_points.make_filled (0.0, 1, 3)
			l_points [1] := 1.5
			l_points [2] := 2.5
			l_points [3] := 3.5
			create l_cloud.make (l_points)
			l_model := l_cloud.points_model
			assert ("model not void", l_model /= Void)
			assert ("model size matches", l_model.count = 3)
			assert ("model data correct", l_model [1] = 1.5)
		end

	test_negative_coordinates
			-- Test point cloud with negative coordinates.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_bbox: BOUNDING_BOX_3D
		do
			create l_points.make_filled (0.0, 1, 6)
			l_points [1] := -5.0
			l_points [2] := -10.0
			l_points [3] := -15.0
			l_points [4] := 5.0
			l_points [5] := 10.0
			l_points [6] := 15.0
			create l_cloud.make (l_points)
			l_bbox := l_cloud.bounding_box
			assert ("handles negative min", l_bbox.min_x = -5.0)
			assert ("handles positive max", l_bbox.max_x = 5.0)
		end

	test_large_point_cloud
			-- Stress test with many points.
		local
			l_points: ARRAYED_LIST [REAL_32]
			l_cloud: POINT_CLOUD
			l_idx: INTEGER
		do
			create l_points.make (3000)  -- 1000 points
			from l_idx := 1 until l_idx > 1000 loop
				l_points.extend ((l_idx mod 100).to_real)
				l_points.extend ((l_idx mod 200).to_real)
				l_points.extend ((l_idx mod 300).to_real)
				l_idx := l_idx + 1
			end
			create l_cloud.make (l_points.to_array)
			assert ("point count 1000", l_cloud.point_count = 1000)
			assert ("not empty", not l_cloud.is_empty)
		end

	test_all_same_coordinates
			-- Test point cloud where all points are identical.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_bbox: BOUNDING_BOX_3D
		do
			create l_points.make_filled (5.0, 1, 9)
			create l_cloud.make (l_points)
			l_bbox := l_cloud.bounding_box
			assert ("all points same - min=max", l_bbox.min_x = 5.0 and l_bbox.max_x = 5.0)
			assert ("width zero", l_bbox.width = 0.0)
		end

end
