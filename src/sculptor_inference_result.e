note
	description: "Result of Point-E ONNX inference"
	author: "Larry Rix"

class
	SCULPTOR_INFERENCE_RESULT

create
	make_success,
	make_failure

feature {NONE} -- Initialization

	make_success (a_points: POINT_CLOUD)
			-- Create successful inference result.
		require
			points_not_void: a_points /= Void
		do
			points := a_points
			is_success := True
			error_message := ""
		ensure
			is_success_set: is_success
			points_set: points = a_points
		end

	make_failure (a_message: STRING)
			-- Create failed inference result.
		require
			message_not_void: a_message /= Void
			message_not_empty: not a_message.is_empty
		do
			is_success := False
			error_message := a_message.twin
			points := Void
		ensure
			is_failure: not is_success
			error_set: error_message.same_string (a_message)
		end

feature -- Access

	is_success: BOOLEAN
			-- Did inference succeed?

	points: detachable POINT_CLOUD
			-- Generated point cloud (only if successful).

	error_message: STRING
			-- Error message (only if failed).

invariant
	success_xor_error: is_success xor (error_message.count > 0)
	success_implies_no_error: is_success implies error_message.is_empty
	failure_implies_error: (not is_success) implies (not error_message.is_empty)
	success_has_points: is_success implies points /= Void

end
