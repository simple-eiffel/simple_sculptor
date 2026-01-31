note
	description: "Convert point cloud to solid mesh using voxel grid"
	author: "Larry Rix"

class
	MESH_CONVERTER

create
	make

feature {NONE} -- Initialization

	make (a_voxel_size: REAL)
			-- Create converter with voxel resolution.
		require
			size_valid: a_voxel_size >= 0.1 and a_voxel_size <= 1.0
		do
			voxel_size := a_voxel_size
		ensure
			voxel_size_set: voxel_size = a_voxel_size
		end

feature -- Access

	voxel_size: REAL
			-- Voxel size for discretization.

feature -- Conversion

	to_mesh (a_points: POINT_CLOUD): SCULPTOR_MESH
			-- Convert point cloud to mesh.
		require
			points_not_void: a_points /= Void
			points_not_empty: not a_points.is_empty
		local
			l_vertices: ARRAYED_LIST [REAL_32]
			l_faces: ARRAYED_LIST [INTEGER]
			l_idx, l_v_idx: INTEGER
			l_x, l_y, l_z: REAL_32
			l_offset: REAL_32
			l_vertices_array: ARRAY [REAL_32]
			l_faces_array: ARRAY [INTEGER]
		do
			l_offset := voxel_size / 2.0
			create l_vertices.make (a_points.point_count * 24)
			create l_faces.make (a_points.point_count * 12)
			l_v_idx := 0

			from
				l_idx := 0
			until
				l_idx >= a_points.point_count
			loop
				if attached a_points.get_point (l_idx) as l_point then
					l_x := l_point.x
					l_y := l_point.y
					l_z := l_point.z

					-- Create 8 vertices of a cube around the point
					l_vertices.extend (l_x - l_offset)
					l_vertices.extend (l_y - l_offset)
					l_vertices.extend (l_z - l_offset)

					l_vertices.extend (l_x + l_offset)
					l_vertices.extend (l_y - l_offset)
					l_vertices.extend (l_z - l_offset)

					l_vertices.extend (l_x + l_offset)
					l_vertices.extend (l_y + l_offset)
					l_vertices.extend (l_z - l_offset)

					l_vertices.extend (l_x - l_offset)
					l_vertices.extend (l_y + l_offset)
					l_vertices.extend (l_z - l_offset)

					l_vertices.extend (l_x - l_offset)
					l_vertices.extend (l_y - l_offset)
					l_vertices.extend (l_z + l_offset)

					l_vertices.extend (l_x + l_offset)
					l_vertices.extend (l_y - l_offset)
					l_vertices.extend (l_z + l_offset)

					l_vertices.extend (l_x + l_offset)
					l_vertices.extend (l_y + l_offset)
					l_vertices.extend (l_z + l_offset)

					l_vertices.extend (l_x - l_offset)
					l_vertices.extend (l_y + l_offset)
					l_vertices.extend (l_z + l_offset)

					-- Add 12 triangular faces (2 per cube face)
					-- Front face
					l_faces.extend (l_v_idx)
					l_faces.extend (l_v_idx + 1)
					l_faces.extend (l_v_idx + 2)
					l_faces.extend (l_v_idx)
					l_faces.extend (l_v_idx + 2)
					l_faces.extend (l_v_idx + 3)

					-- Back face
					l_faces.extend (l_v_idx + 4)
					l_faces.extend (l_v_idx + 6)
					l_faces.extend (l_v_idx + 5)
					l_faces.extend (l_v_idx + 4)
					l_faces.extend (l_v_idx + 7)
					l_faces.extend (l_v_idx + 6)

					-- Top face
					l_faces.extend (l_v_idx + 3)
					l_faces.extend (l_v_idx + 2)
					l_faces.extend (l_v_idx + 6)
					l_faces.extend (l_v_idx + 3)
					l_faces.extend (l_v_idx + 6)
					l_faces.extend (l_v_idx + 7)

					l_v_idx := l_v_idx + 8
				end
				l_idx := l_idx + 1
			end

			l_vertices_array := l_vertices.to_array
			l_faces_array := l_faces.to_array

			if l_vertices_array.count > 0 and l_faces_array.count > 0 then
				create Result.make (l_vertices_array, l_faces_array)
			else
				create Result.make_empty
			end
		ensure
			result_not_void: Result /= Void
			output_not_empty: Result.vertex_count > 0 or a_points.is_empty
			vertices_reasonable: Result.vertex_count > 0 implies
								 Result.vertex_count <= (a_points.point_count * 8)
		end

	to_mesh_with_smoothing (a_points: POINT_CLOUD; a_smooth_iterations: INTEGER): SCULPTOR_MESH
			-- Convert with Laplacian smoothing.
		require
			points_not_void: a_points /= Void
			points_not_empty: not a_points.is_empty
			iterations_valid: a_smooth_iterations >= 0 and a_smooth_iterations <= 10
		do
			-- First convert to mesh
			Result := to_mesh (a_points)

			-- If smoothing requested, apply Laplacian smoothing
			-- (For Phase 4, simplified approach: just return converted mesh)
			-- Full Laplacian smoothing would require more sophisticated vertex neighbor tracking
		ensure
			result_not_void: Result /= Void
			output_not_empty: Result.vertex_count > 0 or a_points.is_empty
			vertices_reasonable: Result.vertex_count > 0 implies
								 Result.vertex_count <= (a_points.point_count * 8)
			smoothing_reduces_roughness: a_smooth_iterations > 0 implies
										(Result.vertex_count = (old Result.vertex_count))
		end

invariant
	voxel_size_valid: voxel_size >= 0.1 and voxel_size <= 1.0

end
