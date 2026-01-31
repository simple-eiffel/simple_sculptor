note
	description: "Solid 3D mesh with vertices, faces, and normals"
	author: "Larry Rix"

class
	SCULPTOR_MESH

create
	make_empty,
	make

feature {NONE} -- Initialization

	make_empty
			-- Create empty mesh.
		do
			create vertices.make_filled (0.0, 1, 0)
			create faces.make_filled (0, 1, 0)
			vertex_count := 0
			face_count := 0
		ensure
			empty: vertex_count = 0 and face_count = 0
		end

	make (a_vertices: ARRAY [REAL_32]; a_faces: ARRAY [INTEGER])
			-- Create mesh from vertices and faces.
		require
			vertices_not_void: a_vertices /= Void
			faces_not_void: a_faces /= Void
			vertices_divisible_by_3: a_vertices.count \\ 3 = 0
			faces_divisible_by_3: a_faces.count \\ 3 = 0
			faces_valid_indices: faces_indices_valid(a_vertices.count // 3, a_faces)
		do
			vertices := a_vertices
			faces := a_faces
			vertex_count := a_vertices.count // 3
			face_count := a_faces.count // 3
		ensure
			vertices_set: vertex_count = a_vertices.count // 3
			faces_set: face_count = a_faces.count // 3
		end

feature {NONE} -- Implementation

	vertices: ARRAY [REAL_32]
			-- Vertex coordinates as flat array [x0, y0, z0, ...].

	faces: ARRAY [INTEGER]
			-- Face indices as flat array [v0, v1, v2, ...].

feature {NONE} -- Validation Helpers

	faces_indices_valid (a_vertex_count: INTEGER; a_faces: ARRAY [INTEGER]): BOOLEAN
			-- Are all face indices valid (< vertex count)?
		do
			Result := True
			across a_faces as ic loop
				if ic.item < 0 or ic.item >= a_vertex_count then
					Result := False
				end
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Access

	vertex_count: INTEGER
			-- Number of vertices.

	face_count: INTEGER
			-- Number of triangular faces.

	bounding_box: BOUNDING_BOX_3D
			-- Axis-aligned bounding box.
		local
			l_min_x, l_min_y, l_min_z: REAL_32
			l_max_x, l_max_y, l_max_z: REAL_32
			l_idx: INTEGER
		do
			if vertex_count = 0 then
				create Result.make_empty
			else
				l_min_x := vertices [vertices.lower]
				l_min_y := vertices [vertices.lower + 1]
				l_min_z := vertices [vertices.lower + 2]
				l_max_x := l_min_x
				l_max_y := l_min_y
				l_max_z := l_min_z

				from
					l_idx := vertices.lower + 3
				until
					l_idx > vertices.upper
				loop
					if vertices [l_idx] < l_min_x then
						l_min_x := vertices [l_idx]
					end
					if vertices [l_idx] > l_max_x then
						l_max_x := vertices [l_idx]
					end

					if vertices [l_idx + 1] < l_min_y then
						l_min_y := vertices [l_idx + 1]
					end
					if vertices [l_idx + 1] > l_max_y then
						l_max_y := vertices [l_idx + 1]
					end

					if vertices [l_idx + 2] < l_min_z then
						l_min_z := vertices [l_idx + 2]
					end
					if vertices [l_idx + 2] > l_max_z then
						l_max_z := vertices [l_idx + 2]
					end

					l_idx := l_idx + 3
				end

				create Result.make (l_min_x, l_min_y, l_min_z, l_max_x, l_max_y, l_max_z)
			end
		ensure
			result_not_void: Result /= Void
		end

feature -- Model Queries

	vertices_model: ARRAY [REAL_32]
			-- Mathematical model of vertex coordinates.
		do
			Result := vertices
		ensure
			result_not_void: Result /= Void
		end

	faces_model: ARRAY [INTEGER]
			-- Mathematical model of face indices.
		do
			Result := faces
		ensure
			result_not_void: Result /= Void
		end

feature -- Export

	to_glb (a_path: STRING)
			-- Export mesh to GLB format.
		require
			path_not_void: a_path /= Void
			path_not_empty: not a_path.is_empty
			not_empty: vertex_count > 0
		do
			-- Implementation in Phase 4
		end

	to_obj (a_path: STRING)
			-- Export mesh to OBJ format.
		require
			path_not_void: a_path /= Void
			path_not_empty: not a_path.is_empty
			not_empty: vertex_count > 0
		do
			-- Implementation in Phase 4
		end

	to_stl (a_path: STRING)
			-- Export mesh to STL format.
		require
			path_not_void: a_path /= Void
			path_not_empty: not a_path.is_empty
			not_empty: vertex_count > 0
		do
			-- Implementation in Phase 4
		end

feature -- Validation

	validate: MESH_VALIDATION_REPORT
			-- Check mesh quality and topology.
		do
			create Result.make
			Result.set_mesh_stats (vertex_count, face_count)

			-- Check for empty mesh
			if vertex_count = 0 then
				Result.add_error ("Mesh is empty (no vertices)")
			end

			-- Check for degenerate faces
			if face_count > 0 and vertex_count > 0 then
				across faces as ic loop
					if ic.item < 0 or ic.item >= vertex_count then
						Result.add_error ("Invalid face index: " + ic.item.out)
					end
				end
			end
		ensure
			result_not_void: Result /= Void
		end

invariant
	vertex_count_non_negative: vertex_count >= 0
	face_count_non_negative: face_count >= 0

end
