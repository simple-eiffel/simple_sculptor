note
	description: "3D point with x, y, z coordinates"
	author: "Larry Rix"

class
	SCULPTOR_POINT_3D

create
	make, make_from_array

feature {NONE} -- Initialization

	make (a_x, a_y, a_z: REAL_32)
			-- Create point with coordinates.
		do
			x := a_x
			y := a_y
			z := a_z
		ensure
			x_set: x = a_x
			y_set: y = a_y
			z_set: z = a_z
		end

	make_from_array (a_coords: ARRAY [REAL_32])
			-- Create point from array [x, y, z].
		require
			coords_not_void: a_coords /= Void
			coords_size: a_coords.count >= 3
		do
			x := a_coords [a_coords.lower]
			y := a_coords [a_coords.lower + 1]
			z := a_coords [a_coords.lower + 2]
		ensure
			x_set: x = a_coords [a_coords.lower]
			y_set: y = a_coords [a_coords.lower + 1]
			z_set: z = a_coords [a_coords.lower + 2]
		end

feature -- Access

	x: REAL_32
			-- X coordinate.

	y: REAL_32
			-- Y coordinate.

	z: REAL_32
			-- Z coordinate.

feature -- Queries

	distance_to (a_other: SCULPTOR_POINT_3D): REAL_32
			-- Euclidean distance to `a_other` point.
		require
			other_not_void: a_other /= Void
		do
			Result := ((x - a_other.x) ^ 2.0 + (y - a_other.y) ^ 2.0 + (z - a_other.z) ^ 2.0).sqrt
		ensure
			result_non_negative: Result >= 0.0
		end

	to_array: ARRAY [REAL_32]
			-- Export point as [x, y, z] array.
		do
			create Result.make_filled (0.0, 1, 3)
			Result [1] := x
			Result [2] := y
			Result [3] := z
		ensure
			result_not_void: Result /= Void
			result_size: Result.count = 3
		end

invariant
	coordinates_finite: x.is_finite and y.is_finite and z.is_finite
	x_valid: x = x  -- NaN is never equal to itself
	y_valid: y = y  -- NaN is never equal to itself
	z_valid: z = z  -- NaN is never equal to itself

end
