note
	description: "Result of 3D generation (success or error)"
	author: "Larry Rix"

class
	SCULPTOR_RESULT

create
	make_success,
	make_failure

feature {NONE} -- Initialization

	make_success (a_mesh: SCULPTOR_MESH)
			-- Create successful result with generated mesh.
		require
			mesh_not_void: a_mesh /= Void
		do
			mesh := a_mesh
			is_success := True
			error_message := ""
		ensure
			is_success_set: is_success
			mesh_set: mesh = a_mesh
		end

	make_failure (a_message: STRING)
			-- Create failure result.
		require
			message_not_void: a_message /= Void
			message_not_empty: not a_message.is_empty
		do
			is_success := False
			error_message := a_message.twin
			mesh := Void
		ensure
			is_failure: not is_success
			error_set: error_message.same_string (a_message)
			no_mesh: mesh = Void
		end

feature -- Access

	is_success: BOOLEAN
			-- Did generation succeed?

	mesh: detachable SCULPTOR_MESH
			-- Generated mesh (only if successful).

	error_message: STRING
			-- Error message (only if failed).

feature -- Queries

	summary: STRING
			-- Human-readable summary.
		do
			if is_success then
				Result := "Generation succeeded. Mesh: "
				if attached mesh as m then
					Result.append ("Vertices: " + m.vertex_count.out + ", Faces: " + m.face_count.out)
				end
			else
				Result := "Generation failed: " + error_message
			end
		ensure
			result_not_empty: not Result.is_empty
		end

invariant
	success_xor_error: is_success xor (error_message.count > 0)
	success_implies_no_error: is_success implies error_message.is_empty
	failure_implies_error: (not is_success) implies (not error_message.is_empty)
	success_has_mesh: is_success implies mesh /= Void
	error_has_message: (not is_success) implies not error_message.is_empty

end
