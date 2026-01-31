note
	description: "[
		SCULPTOR_VIEWER_APP - Text-to-3D viewer using SIMPLE_BROWSER.

		Simple direct integration with SIMPLE_BROWSER facade.
		No Vision2 wrapping needed.
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
			l_browser: SIMPLE_BROWSER
		do
			print ("Sculptor Viewer v1.0.0%N")
			print ("======================%N%N")
			print ("Launching 3D viewer...%N%N")

			-- Create and configure browser
			create l_browser.make

			if l_browser.is_valid then
				l_browser.set_title ("Sculptor Viewer - Text to 3D")
				l_browser.set_size (1400, 900)
				l_browser.load_htmx_page (ui.full_page)
				l_browser.run
			else
				print ("ERROR: Failed to initialize browser%N")
			end
		end

feature {NONE} -- UI

	ui: SCULPTOR_UI
			-- UI generator.
		once
			create Result
		end

end
