note
	description: "Unit tests for SCULPTOR_MESH"
	author: "Larry Rix"

class
	TEST_SCULPTOR_MESH

inherit
	EQA_TEST_SET

feature -- Tests

	test_make_empty_mesh
			-- Test creating empty mesh.
		local
			l_mesh: SCULPTOR_MESH
		do
			create l_mesh.make_empty
			assert ("mesh is empty", l_mesh.vertex_count = 0 and l_mesh.face_count = 0)
		end

	test_make_with_vertices_and_faces
			-- Test creating mesh with vertices and faces.
		local
			l_vertices: ARRAY [REAL_32]
			l_faces: ARRAY [INTEGER]
			l_mesh: SCULPTOR_MESH
		do
			-- Create simple triangle: 3 vertices (x,y,z each)
			create l_vertices.make_filled (0.0, 1, 9)
			l_vertices [1] := 0.0
			l_vertices [2] := 0.0
			l_vertices [3] := 0.0
			l_vertices [4] := 1.0
			l_vertices [5] := 0.0
			l_vertices [6] := 0.0
			l_vertices [7] := 0.0
			l_vertices [8] := 1.0
			l_vertices [9] := 0.0

			-- Create one face (triangle with vertex indices 0,1,2)
			create l_faces.make_filled (0, 1, 3)
			l_faces [1] := 0
			l_faces [2] := 1
			l_faces [3] := 2

			create l_mesh.make (l_vertices, l_faces)
			assert ("vertex count correct", l_mesh.vertex_count = 3)
			assert ("face count correct", l_mesh.face_count = 1)
		end

	test_bounding_box
			-- Test mesh bounding box calculation.
		local
			l_vertices: ARRAY [REAL_32]
			l_faces: ARRAY [INTEGER]
			l_mesh: SCULPTOR_MESH
			l_bbox: BOUNDING_BOX_3D
		do
			create l_vertices.make_filled (0.0, 1, 9)
			l_vertices [1] := 0.0
			l_vertices [2] := 0.0
			l_vertices [3] := 0.0
			l_vertices [4] := 1.0
			l_vertices [5] := 1.0
			l_vertices [6] := 1.0
			l_vertices [7] := 2.0
			l_vertices [8] := 2.0
			l_vertices [9] := 2.0

			create l_faces.make_filled (0, 1, 3)
			l_faces [1] := 0
			l_faces [2] := 1
			l_faces [3] := 2
			create l_mesh.make (l_vertices, l_faces)

			l_bbox := l_mesh.bounding_box
			assert ("bbox not void", l_bbox /= Void)
			assert ("bbox min x", l_bbox.min_x = 0.0)
			assert ("bbox max x", l_bbox.max_x = 2.0)
			assert ("bbox min y", l_bbox.min_y = 0.0)
			assert ("bbox max y", l_bbox.max_y = 2.0)
			assert ("bbox min z", l_bbox.min_z = 0.0)
			assert ("bbox max z", l_bbox.max_z = 2.0)
		end

	test_validate_mesh
			-- Test mesh validation.
		local
			l_vertices: ARRAY [REAL_32]
			l_faces: ARRAY [INTEGER]
			l_mesh: SCULPTOR_MESH
			l_report: MESH_VALIDATION_REPORT
		do
			create l_vertices.make_filled (0.0, 1, 9)
			l_vertices [1] := 0.0
			l_vertices [2] := 0.0
			l_vertices [3] := 0.0
			l_vertices [4] := 1.0
			l_vertices [5] := 0.0
			l_vertices [6] := 0.0
			l_vertices [7] := 0.5
			l_vertices [8] := 1.0
			l_vertices [9] := 0.0

			create l_faces.make_filled (0, 1, 3)
			l_faces [1] := 0
			l_faces [2] := 1
			l_faces [3] := 2
			create l_mesh.make (l_vertices, l_faces)

			l_report := l_mesh.validate
			assert ("report not void", l_report /= Void)
			assert ("mesh is valid", l_report.is_valid)
			assert ("no errors", not l_report.has_errors)
		end

	test_model_queries
			-- Test MML model queries for postcondition verification.
		local
			l_vertices: ARRAY [REAL_32]
			l_faces: ARRAY [INTEGER]
			l_mesh: SCULPTOR_MESH
			l_v_model: ARRAY [REAL_32]
			l_f_model: ARRAY [INTEGER]
		do
			create l_vertices.make_filled (0.0, 1, 3)
			l_vertices [1] := 1.0
			l_vertices [2] := 2.0
			l_vertices [3] := 3.0
			create l_faces.make_filled (0, 1, 3)
			l_faces [1] := 0
			l_faces [2] := 0
			l_faces [3] := 0
			create l_mesh.make (l_vertices, l_faces)

			l_v_model := l_mesh.vertices_model
			l_f_model := l_mesh.faces_model

			assert ("vertices_model not void", l_v_model /= Void)
			assert ("vertices_model size", l_v_model.count = 3)
			assert ("faces_model not void", l_f_model /= Void)
			assert ("faces_model size", l_f_model.count = 3)
		end

	test_empty_mesh_bounding_box
			-- Test bounding box of empty mesh.
		local
			l_mesh: SCULPTOR_MESH
			l_bbox: BOUNDING_BOX_3D
		do
			create l_mesh.make_empty
			l_bbox := l_mesh.bounding_box
			assert ("empty mesh bbox exists", l_bbox /= Void)
			assert ("empty mesh bbox is empty", l_bbox.volume = 0.0)
		end

	test_validate_empty_mesh
			-- Test validation of empty mesh.
		local
			l_mesh: SCULPTOR_MESH
			l_report: MESH_VALIDATION_REPORT
		do
			create l_mesh.make_empty
			l_report := l_mesh.validate
			assert ("empty mesh report not valid", not l_report.is_valid)
			assert ("empty mesh has error", l_report.has_errors)
		end

	test_large_mesh
			-- Stress test with large mesh.
		local
			l_vertices: ARRAYED_LIST [REAL_32]
			l_faces: ARRAYED_LIST [INTEGER]
			l_mesh: SCULPTOR_MESH
			l_idx: INTEGER
		do
			create l_vertices.make (3000)  -- 1000 vertices (x,y,z each)
			from l_idx := 1 until l_idx > 1000 loop
				l_vertices.extend ((l_idx mod 100).to_real)
				l_vertices.extend ((l_idx mod 100).to_real)
				l_vertices.extend ((l_idx mod 100).to_real)
				l_idx := l_idx + 1
			end

			create l_faces.make (300)  -- 100 faces
			from l_idx := 0 until l_idx >= 100 loop
				l_faces.extend (l_idx mod 1000)
				l_faces.extend ((l_idx + 1) mod 1000)
				l_faces.extend ((l_idx + 2) mod 1000)
				l_idx := l_idx + 1
			end

			create l_mesh.make (l_vertices.to_array, l_faces.to_array)
			assert ("large mesh created", l_mesh.vertex_count = 1000)
			assert ("large mesh faces created", l_mesh.face_count = 100)
		end

	test_degenerate_triangle
			-- Test mesh with degenerate triangle (all same vertex).
		local
			l_vertices: ARRAY [REAL_32]
			l_faces: ARRAY [INTEGER]
			l_mesh: SCULPTOR_MESH
		do
			create l_vertices.make_filled (0.0, 1, 3)
			l_vertices [1] := 1.0
			l_vertices [2] := 1.0
			l_vertices [3] := 1.0
			create l_faces.make_filled (0, 1, 3)
			l_faces [1] := 0
			l_faces [2] := 0
			l_faces [3] := 0
			create l_mesh.make (l_vertices, l_faces)
			-- Degenerate face still valid topologically
			assert ("degenerate mesh created", l_mesh.face_count = 1)
		end

end
