note
	description: "Text prompt for 3D generation"
	author: "Larry Rix"

class
	TEXT_PROMPT

create
	make

feature {NONE} -- Initialization

	make (a_text: STRING)
			-- Create prompt from text description.
		require
			text_not_void: a_text /= Void
			text_not_empty: not a_text.is_empty
		do
			text := a_text.twin
		ensure
			text_set: text.same_string (a_text)
		end

feature -- Access

	text: STRING
			-- Prompt text.

feature -- Queries

	length: INTEGER
			-- Length of prompt text.
		do
			Result := text.count
		ensure
			positive: Result > 0
		end

	is_valid: BOOLEAN
			-- Is this a valid prompt?
		do
			Result := not text.is_empty and text.count <= 1000
		end

invariant
	text_not_void: text /= Void
	text_not_empty: not text.is_empty

end
