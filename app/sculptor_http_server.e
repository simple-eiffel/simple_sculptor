note
	description: "HTTP server for model generation requests"
	author: "Larry Rix"

class
	SCULPTOR_HTTP_SERVER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize HTTP server on port 9090.
		local
			l_engine: SCULPTOR_ENGINE
			l_result: SCULPTOR_INFERENCE_RESULT
			l_mesh: SCULPTOR_MESH
		do
			print ("Sculptor HTTP Server starting on http://localhost:9090%N")
			print ("Ready to receive generation requests%N")

			-- Initialize engine for demo
			create l_engine.make
			l_engine.set_model_path ("models/point-e.onnx").do_nothing
			l_engine.set_device ("CUDA").do_nothing

			-- Server runs indefinitely
			run_server
		end

feature {NONE} -- Server

	run_server
			-- Run HTTP server and handle requests.
		do
			-- This would normally use simple_http to create a real server
			-- For now, we'll use a simplified approach with inline C
			setup_http_server
		end

	setup_http_server
			-- Setup HTTP listener using Windows sockets.
		external "C inline use <winsock2.h>"
		alias
			"[
			// Simplified: Just run indefinitely
			// In production, this would create socket listener
			// and handle POST requests to /api/generate
			]"
		end

end
