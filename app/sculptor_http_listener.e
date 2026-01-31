note
	description: "HTTP server for generation requests (simplified demo version)"
	author: "Larry Rix"

class
	SCULPTOR_HTTP_LISTENER

create
	make

feature {NONE} -- Initialization

	make
			-- Start HTTP listener (demo version - just generates sample meshes).
		do
			create service.make
			print ("Generation service initialized%N")
			print ("Ready to process model generation requests%N")
		end

feature {NONE} -- Service

	service: SCULPTOR_GENERATION_SERVICE
			-- Generation service.

	generate_mesh_json (a_prompt: STRING): STRING
			-- Generate mesh and return as JSON (demo implementation).
		require
			prompt_not_void: a_prompt /= Void
		local
			l_result: STRING
		do
			-- For demo: return simple cube mesh
			create l_result.make (1000)

			l_result.append ("{%N%T%"vertices%": [")
			l_result.append ("-1, -1, -1, 1, -1, -1, 1, 1, -1, -1, 1, -1,")
			l_result.append ("-1, -1, 1, 1, -1, 1, 1, 1, 1, -1, 1, 1")
			l_result.append ("],%N%T%"faces%": [")
			l_result.append ("0, 1, 2, 0, 2, 3,")
			l_result.append ("4, 6, 5, 4, 7, 6,")
			l_result.append ("0, 4, 5, 0, 5, 1,")
			l_result.append ("2, 6, 7, 2, 7, 3,")
			l_result.append ("0, 3, 7, 0, 7, 4,")
			l_result.append ("1, 5, 6, 1, 6, 2")
			l_result.append ("]%N}")

			Result := l_result
		ensure
			result_not_empty: not Result.is_empty
		end

end
