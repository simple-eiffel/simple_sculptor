note
	description: "Report of mesh validation results"
	author: "Larry Rix"

class
	MESH_VALIDATION_REPORT

create
	make

feature {NONE} -- Initialization

	make
			-- Create empty validation report.
		do
			vertex_count := 0
			face_count := 0
			is_valid := True
			error_messages := create {ARRAYED_LIST [STRING]}.make (0)
		ensure
			is_valid_set: is_valid
			error_count_zero: error_count = 0
		end

feature -- Access

	vertex_count: INTEGER
			-- Number of vertices in mesh.

	face_count: INTEGER
			-- Number of faces in mesh.

	is_valid: BOOLEAN
			-- Is mesh valid?

	error_messages: LIST [STRING]
			-- Validation error messages.

feature -- Queries

	error_count: INTEGER
			-- Number of validation errors.
		do
			Result := error_messages.count
		ensure
			non_negative: Result >= 0
		end

	has_errors: BOOLEAN
			-- Are there validation errors?
		do
			Result := error_count > 0
		end

feature -- Modification

	add_error (a_message: STRING)
			-- Add validation error message.
		require
			message_not_void: a_message /= Void
			message_not_empty: not a_message.is_empty
		do
			error_messages.extend (a_message.twin)
			is_valid := False
		ensure
			error_added: error_count = old error_count + 1
			not_valid: not is_valid
		end

	set_mesh_stats (a_vertex_count, a_face_count: INTEGER)
			-- Set mesh statistics.
		require
			counts_non_negative: a_vertex_count >= 0 and a_face_count >= 0
		do
			vertex_count := a_vertex_count
			face_count := a_face_count
		ensure
			vertex_count_set: vertex_count = a_vertex_count
			face_count_set: face_count = a_face_count
		end

invariant
	error_messages_not_void: error_messages /= Void
	error_count_matches: error_messages.count = error_count
	valid_xor_errors: is_valid xor has_errors

end
