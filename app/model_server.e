note
	description: "[
		MODEL_SERVER - HTTP server for model generation API.

		Embedded HTTP server that handles requests from the browser
		for model generation and file serving.
	]"
	author: "Larry Rix"

class
	MODEL_SERVER

create
	make

feature {NONE} -- Initialization

	make
			-- Create HTTP server.
		do
			create service.make
		ensure
			service_created: attached service
		end

feature -- Operations

	start_server (a_port: INTEGER)
			-- Start HTTP server on specified port.
		require
			valid_port: a_port > 0 and a_port <= 65535
		do
			-- TODO: Implement HTTP server
			-- This would use simple_web to create an HTTP server
			-- that listens for /api/generate requests
		end

	stop_server
			-- Stop HTTP server.
		do
			-- TODO: Implement server shutdown
		end

feature {NONE} -- Implementation

	service: SCULPTOR_SERVICE
			-- Model generation service.

end
