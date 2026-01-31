note
	description: "Test application for simple_sculptor"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature -- Execution

	make
			-- Run tests.
		local
			l_test: TEST_SCULPTOR
		do
			create l_test
			l_test.run_all
		end

end
