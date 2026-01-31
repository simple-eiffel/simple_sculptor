note
	description: "3D vector with magnitude and direction operations"
	author: "Larry Rix"

class
	SCULPTOR_VECTOR_3D

create
	make, make_zero, make_from_points

feature {NONE} -- Initialization

	make (a_x, a_y, a_z: REAL_32)
			-- Create vector with components.
		do
			x := a_x
			y := a_y
			z := a_z
		ensure
			x_set: x = a_x
			y_set: y = a_y
			z_set: z = a_z
		end

	make_zero
			-- Create zero vector.
		do
			x := 0.0
			y := 0.0
			z := 0.0
		ensure
			is_zero: x = 0.0 and y = 0.0 and z = 0.0
		end

	make_from_points (a_start, a_end: SCULPTOR_POINT_3D)
			-- Create vector from `a_start` to `a_end`.
		require
			start_not_void: a_start /= Void
			end_not_void: a_end /= Void
		do
			x := a_end.x - a_start.x
			y := a_end.y - a_start.y
			z := a_end.z - a_start.z
		ensure
			x_set: x = a_end.x - a_start.x
			y_set: y = a_end.y - a_start.y
			z_set: z = a_end.z - a_start.z
		end

feature -- Access

	x: REAL_32
			-- X component.

	y: REAL_32
			-- Y component.

	z: REAL_32
			-- Z component.

feature -- Queries

	magnitude: REAL_32
			-- Length of vector.
		do
			Result := ((x ^ 2.0) + (y ^ 2.0) + (z ^ 2.0)).sqrt
		ensure
			result_non_negative: Result >= 0.0
		end

	dot_product (a_other: SCULPTOR_VECTOR_3D): REAL_32
			-- Dot product with `a_other`.
		require
			other_not_void: a_other /= Void
		do
			Result := x * a_other.x + y * a_other.y + z * a_other.z
		end

	is_zero: BOOLEAN
			-- Is this a zero vector?
		do
			Result := x = 0.0 and y = 0.0 and z = 0.0
		end

feature -- Transformations

	scale (a_factor: REAL_32)
			-- Scale vector by `a_factor`.
		do
			x := x * a_factor
			y := y * a_factor
			z := z * a_factor
		ensure
			x_scaled: x = old x * a_factor
			y_scaled: y = old y * a_factor
			z_scaled: z = old z * a_factor
		end

	normalize
			-- Scale to unit length if non-zero.
		local
			l_mag: REAL_32
		do
			l_mag := magnitude
			if l_mag > 0.0 then
				scale (1.0 / l_mag)
			end
		ensure
			normalized: is_zero or (magnitude - 1.0).abs < 0.001
		end

invariant
	components_finite: x.is_finite and y.is_finite and z.is_finite
	x_valid: x = x  -- NaN is never equal to itself
	y_valid: y = y  -- NaN is never equal to itself
	z_valid: z = z  -- NaN is never equal to itself

end
