note
	description: "Axis-aligned bounding box in 3D space"
	author: "Larry Rix"

class
	BOUNDING_BOX_3D

create
	make, make_empty

feature {NONE} -- Initialization

	make (a_min_x, a_min_y, a_min_z, a_max_x, a_max_y, a_max_z: REAL_32)
			-- Create bounding box with min and max coordinates.
		require
			min_max_x: a_min_x <= a_max_x
			min_max_y: a_min_y <= a_max_y
			min_max_z: a_min_z <= a_max_z
		do
			min_x := a_min_x
			min_y := a_min_y
			min_z := a_min_z
			max_x := a_max_x
			max_y := a_max_y
			max_z := a_max_z
		ensure
			min_x_set: min_x = a_min_x
			min_y_set: min_y = a_min_y
			min_z_set: min_z = a_min_z
			max_x_set: max_x = a_max_x
			max_y_set: max_y = a_max_y
			max_z_set: max_z = a_max_z
		end

	make_empty
			-- Create empty bounding box.
		do
			min_x := 0.0
			min_y := 0.0
			min_z := 0.0
			max_x := 0.0
			max_y := 0.0
			max_z := 0.0
		ensure
			is_empty: width = 0.0 and height = 0.0 and depth = 0.0
		end

feature -- Access

	min_x: REAL_32
			-- Minimum x coordinate.

	min_y: REAL_32
			-- Minimum y coordinate.

	min_z: REAL_32
			-- Minimum z coordinate.

	max_x: REAL_32
			-- Maximum x coordinate.

	max_y: REAL_32
			-- Maximum y coordinate.

	max_z: REAL_32
			-- Maximum z coordinate.

feature -- Queries

	width: REAL_32
			-- Extent along x-axis.
		do
			Result := max_x - min_x
		ensure
			result_non_negative: Result >= 0.0
		end

	height: REAL_32
			-- Extent along y-axis.
		do
			Result := max_y - min_y
		ensure
			result_non_negative: Result >= 0.0
		end

	depth: REAL_32
			-- Extent along z-axis.
		do
			Result := max_z - min_z
		ensure
			result_non_negative: Result >= 0.0
		end

	volume: REAL_32
			-- Volume of bounding box.
		do
			Result := width * height * depth
		ensure
			result_non_negative: Result >= 0.0
		end

	contains_point (a_point: SCULPTOR_POINT_3D): BOOLEAN
			-- Does this bounding box contain `a_point`?
		require
			point_not_void: a_point /= Void
		do
			Result := a_point.x >= min_x and a_point.x <= max_x and
					  a_point.y >= min_y and a_point.y <= max_y and
					  a_point.z >= min_z and a_point.z <= max_z
		end

	center: SCULPTOR_POINT_3D
			-- Center point of bounding box.
		do
			create Result.make (
				min_x + width / 2.0,
				min_y + height / 2.0,
				min_z + depth / 2.0
			)
		ensure
			result_not_void: Result /= Void
		end

invariant
	bounds_consistent: min_x <= max_x and min_y <= max_y and min_z <= max_z
	min_x_valid: min_x = min_x
	max_x_valid: max_x = max_x
	min_y_valid: min_y = min_y
	max_y_valid: max_y = max_y
	min_z_valid: min_z = min_z
	max_z_valid: max_z = max_z

end
