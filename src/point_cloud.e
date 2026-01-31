note
	description: "Sparse 3D point cloud from ONNX inference"
	author: "Larry Rix"

class
	POINT_CLOUD

create
	make

feature {NONE} -- Initialization

	make (a_points: ARRAY [REAL_64])
			-- Create point cloud from flat array (xyz triplets).
		require
			points_not_void: a_points /= Void
			count_divisible_by_3: a_points.count \\ 3 = 0
		do
			points := a_points
		ensure
			points_set: points = a_points
		end

feature -- Access

	points: ARRAY [REAL_64]
			-- Point data as flat array [x0, y0, z0, x1, y1, z1, ...].

	point_count: INTEGER
			-- Number of points.
		do
			Result := points.count // 3
		ensure
			positive: Result >= 0
		end

feature -- Model Queries

	points_model: ARRAY [REAL_64]
			-- Mathematical model of points (for postcondition verification).
		local
			l_idx: INTEGER
		do
			create Result.make_filled (0.0, 1, points.count)
			from
				l_idx := points.lower
			until
				l_idx > points.upper
			loop
				Result [l_idx] := points [l_idx]
				l_idx := l_idx + 1
			end
		ensure
			result_not_void: Result /= Void
			result_size: Result.count = points.count
		end

	get_point (a_index: INTEGER): detachable SCULPTOR_POINT_3D
			-- Get point at 0-based index.
		require
			valid_index: a_index >= 0 and a_index < point_count
		local
			l_base_idx: INTEGER
		do
			l_base_idx := a_index * 3 + points.lower
			create Result.make (
				points [l_base_idx],
				points [l_base_idx + 1],
				points [l_base_idx + 2]
			)
		end

feature -- Queries

	bounding_box: BOUNDING_BOX_3D
			-- Axis-aligned bounding box of all points.
		local
			l_min_x, l_min_y, l_min_z: REAL_64
			l_max_x, l_max_y, l_max_z: REAL_64
			l_idx: INTEGER
		do
			if is_empty then
				create Result.make_empty
			else
				l_min_x := points [points.lower]
				l_min_y := points [points.lower + 1]
				l_min_z := points [points.lower + 2]
				l_max_x := l_min_x
				l_max_y := l_min_y
				l_max_z := l_min_z

				from
					l_idx := points.lower + 3
				until
					l_idx > points.upper
				loop
					if points [l_idx] < l_min_x then
						l_min_x := points [l_idx]
					end
					if points [l_idx] > l_max_x then
						l_max_x := points [l_idx]
					end

					if points [l_idx + 1] < l_min_y then
						l_min_y := points [l_idx + 1]
					end
					if points [l_idx + 1] > l_max_y then
						l_max_y := points [l_idx + 1]
					end

					if points [l_idx + 2] < l_min_z then
						l_min_z := points [l_idx + 2]
					end
					if points [l_idx + 2] > l_max_z then
						l_max_z := points [l_idx + 2]
					end

					l_idx := l_idx + 3
				end

				create Result.make (l_min_x, l_min_y, l_min_z, l_max_x, l_max_y, l_max_z)
			end
		ensure
			result_not_void: Result /= Void
		end

	is_empty: BOOLEAN
			-- Are there any points?
		do
			Result := point_count = 0
		end

invariant
	points_not_void: points /= Void
	count_valid: points.count \\ 3 = 0

end
