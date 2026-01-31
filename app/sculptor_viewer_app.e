note
	description: "[
		SCULPTOR_VIEWER_APP - Text-to-3D viewer application.

		Main application class for the sculptor viewer. Creates a Vision2
		window with embedded WebView2 browser displaying a 3D model viewer.

		Features:
		- HTML/CSS/JS UI with Three.js 3D rendering
		- Text-to-3D generation via Point-E ONNX
		- Real-time model generation from prompts
		- GLB model export and visualization
	]"
	author: "Larry Rix"

class
	SCULPTOR_VIEWER_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Launch the viewer application.
		local
			l_app: SV_APPLICATION
		do
			print ("Sculptor Viewer v1.0.0%N")
			print ("======================%N%N")

			create l_app.make
			prepare_main_window (l_app)
			l_app.launch
		end

feature {NONE} -- UI Setup

	prepare_main_window (a_app: SV_APPLICATION)
			-- Set up main application window.
		local
			l_window: SV_WINDOW
			l_main_widget: SCULPTOR_VIEWER_WINDOW
			l_discard: SV_WIDGET
		do
			-- Create main window
			create l_window.make_with_title ("Sculptor Viewer - Text to 3D")
			l_discard := l_window.set_size (1400, 900)

			-- Create viewer widget
			create l_main_widget.make
			l_discard := l_window.add (l_main_widget.widget)

			-- Register and show window
			a_app.add_window (l_window)
			l_window.show_now
		end

end
