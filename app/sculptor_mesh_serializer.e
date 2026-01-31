note
	description: "Serialize 3D mesh to JSON format for web rendering"
	author: "Larry Rix"

class
	SCULPTOR_MESH_SERIALIZER

feature -- Serialization

	mesh_to_json (a_mesh: SCULPTOR_MESH): STRING
			-- Convert mesh to JSON format.
		require
			mesh_not_void: a_mesh /= Void
		local
			l_result: STRING
			l_idx: INTEGER
			l_vertex: REAL_64
		do
			create l_result.make (10000)

			-- Start JSON object
			l_result.append ("{%N%T%"vertices%": [")

			-- Add vertices
			if a_mesh.vertices.count > 0 then
				from
					l_idx := a_mesh.vertices.lower
				until
					l_idx > a_mesh.vertices.upper
				loop
					l_vertex := a_mesh.vertices [l_idx]

					-- Add commas between vertices (every 3 coordinates = 1 point)
					if l_idx > a_mesh.vertices.lower then
						if (l_idx - a_mesh.vertices.lower) \\ 3 = 0 then
							l_result.append (",%N%T%T")
						else
							l_result.append (", ")
						end
					end

					-- Format float with reasonable precision
					l_result.append (format_real (l_vertex))

					l_idx := l_idx + 1
				end
			end

			l_result.append ("%N%T],%N%T%"faces%": [")

			-- Add faces (indices)
			if a_mesh.faces.count > 0 then
				from
					l_idx := a_mesh.faces.lower
				until
					l_idx > a_mesh.faces.upper
				loop
					if l_idx > a_mesh.faces.lower then
						if (l_idx - a_mesh.faces.lower) \\ 3 = 0 then
							l_result.append (",%N%T%T")
						else
							l_result.append (", ")
						end
					end

					l_result.append (a_mesh.faces [l_idx].out)

					l_idx := l_idx + 1
				end
			end

			l_result.append ("%N%T]%N}")

			Result := l_result
		ensure
			result_not_empty: not Result.is_empty
		end

	format_real (a_value: REAL_64): STRING
			-- Format real number for JSON (max 4 decimal places).
		local
			l_rounded: REAL_64
		do
			-- Round to 4 decimal places to reduce JSON size
			l_rounded := (a_value * 10000.0).rounded / 10000.0
			Result := l_rounded.out
		end

end
