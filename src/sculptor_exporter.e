note
	description: "Export mesh to various file formats"
	author: "Larry Rix"

class
	SCULPTOR_EXPORTER

create
	make

feature {NONE} -- Initialization

	make
			-- Create exporter.
		do
			is_initialized := True
		ensure
			initialized: is_initialized
		end

feature -- Access

	is_initialized: BOOLEAN
			-- Is exporter initialized?

feature -- Export Operations

	export_to_glb (a_mesh: SCULPTOR_MESH; a_path: STRING): SCULPTOR_RESULT
			-- Export mesh to GLB (binary glTF) format.
		require
			mesh_not_void: a_mesh /= Void
			path_not_void: a_path /= Void
			path_not_empty: not a_path.is_empty
			mesh_not_empty: a_mesh.vertex_count > 0
		do
			-- Implementation in Phase 4
			create {SCULPTOR_RESULT} Result.make_success (a_mesh)
		ensure
			result_not_void: Result /= Void
		end

	export_to_obj (a_mesh: SCULPTOR_MESH; a_path: STRING): SCULPTOR_RESULT
			-- Export mesh to OBJ (Wavefront) format.
		require
			mesh_not_void: a_mesh /= Void
			path_not_void: a_path /= Void
			path_not_empty: not a_path.is_empty
			mesh_not_empty: a_mesh.vertex_count > 0
		do
			-- Implementation in Phase 4
			create {SCULPTOR_RESULT} Result.make_success (a_mesh)
		ensure
			result_not_void: Result /= Void
		end

	export_to_stl (a_mesh: SCULPTOR_MESH; a_path: STRING): SCULPTOR_RESULT
			-- Export mesh to STL (stereolithography) format.
		require
			mesh_not_void: a_mesh /= Void
			path_not_void: a_path /= Void
			path_not_empty: not a_path.is_empty
			mesh_not_empty: a_mesh.vertex_count > 0
		do
			-- Implementation in Phase 4
			create {SCULPTOR_RESULT} Result.make_success (a_mesh)
		ensure
			result_not_void: Result /= Void
		end

invariant
	initialized: is_initialized

end
