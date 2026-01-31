note
	description: "Unit tests for MESH_CONVERTER"
	author: "Larry Rix"

class
	TEST_MESH_CONVERTER

inherit
	EQA_TEST_SET

feature -- Tests

	test_make_creates_converter
			-- Test creating converter with valid voxel size.
		local
			l_converter: MESH_CONVERTER
		do
			create l_converter.make (0.1)
			assert ("voxel size set", l_converter.voxel_size = 0.1)
		end

	test_voxel_size_bounds
			-- Test voxel size must be in valid range.
		local
			l_converter: MESH_CONVERTER
		do
			create l_converter.make (0.1)
			assert ("min size valid", l_converter.voxel_size = 0.1)
			create l_converter.make (1.0)
			assert ("max size valid", l_converter.voxel_size = 1.0)
			create l_converter.make (0.5)
			assert ("mid size valid", l_converter.voxel_size = 0.5)
		end

	test_convert_returns_mesh
			-- Test conversion produces mesh object.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_converter: MESH_CONVERTER
			l_mesh: SCULPTOR_MESH
		do
			create l_points.make_filled (0.0, 1, 3)
			l_points [1] := 0.0
			l_points [2] := 1.0
			l_points [3] := 2.0
			create l_cloud.make (l_points)
			create l_converter.make (0.1)
			l_mesh := l_converter.convert (l_cloud)
			assert ("mesh not void", l_mesh /= Void)
			assert ("mesh has vertices", l_mesh.vertex_count > 0)
			assert ("mesh has faces", l_mesh.face_count > 0)
		end

	test_convert_with_smoothing
			-- Test conversion with Laplacian smoothing.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_converter: MESH_CONVERTER
			l_mesh: SCULPTOR_MESH
		do
			create l_points.make_filled (0.0, 1, 3)
			l_points [1] := 1.0
			l_points [2] := 2.0
			l_points [3] := 3.0
			create l_cloud.make (l_points)
			create l_converter.make (0.1)
			l_mesh := l_converter.convert_with_smoothing (l_cloud, 5)
			assert ("smoothed mesh not void", l_mesh /= Void)
			assert ("vertex count bounded", l_mesh.vertex_count <= l_cloud.point_count * 8)
		end

	test_voxel_grid_topology
			-- Test that converted mesh has valid topology.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_converter: MESH_CONVERTER
			l_mesh: SCULPTOR_MESH
		do
			create l_points.make_filled (0.0, 1, 6)
			l_points [1] := 0.0
			l_points [2] := 0.0
			l_points [3] := 0.0
			l_points [4] := 1.0
			l_points [5] := 1.0
			l_points [6] := 1.0
			create l_cloud.make (l_points)
			create l_converter.make (0.5)
			l_mesh := l_converter.convert (l_cloud)
			-- Each point becomes 8 vertices, faces should be valid
			assert ("vertex count matches points", l_mesh.vertex_count = l_cloud.point_count * 8)
		end

	test_single_point
			-- Test converting single point to mesh.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_converter: MESH_CONVERTER
			l_mesh: SCULPTOR_MESH
		do
			create l_points.make_filled (0.0, 1, 3)
			l_points [1] := 0.5
			l_points [2] := 0.5
			l_points [3] := 0.5
			create l_cloud.make (l_points)
			create l_converter.make (0.1)
			l_mesh := l_converter.convert (l_cloud)
			assert ("single point creates 8 verts", l_mesh.vertex_count = 8)
			assert ("single point creates faces", l_mesh.face_count > 0)
		end

	test_min_voxel_size_creates_mesh
			-- Test conversion with minimum voxel size.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_converter: MESH_CONVERTER
			l_mesh: SCULPTOR_MESH
		do
			create l_points.make_filled (0.0, 1, 3)
			create l_cloud.make (l_points)
			create l_converter.make (0.1)  -- minimum
			l_mesh := l_converter.convert (l_cloud)
			assert ("min voxel creates mesh", l_mesh.vertex_count > 0)
		end

	test_max_voxel_size_creates_mesh
			-- Test conversion with maximum voxel size.
		local
			l_points: ARRAY [REAL_32]
			l_cloud: POINT_CLOUD
			l_converter: MESH_CONVERTER
			l_mesh: SCULPTOR_MESH
		do
			create l_points.make_filled (0.0, 1, 3)
			create l_cloud.make (l_points)
			create l_converter.make (1.0)  -- maximum
			l_mesh := l_converter.convert (l_cloud)
			assert ("max voxel creates mesh", l_mesh.vertex_count > 0)
		end

end
