
solution "LivingWallpaper"
	location				(_ACTION)
	language				"C++"
	configurations			{ "Debug", "Release" }
	platforms				{ "x32", "x64" }
	objdir					("../Intermediate/".._ACTION)

	project "LivingWallpaper"
		uuid				"4A4C0573-DC2B-4899-92E5-61DF02FCA6FE"
		kind				"WindowedApp"
		targetdir			"../Output/"
		
		links				{ "opengl32", "glu32", "glew32" }
		files {
							"../LivingWallpaper/**.cpp",
							"../LivingWallpaper/**.h",
		}

		includedirs {
							"../Externals/glew-2.0.0/include"
		}

		platforms			"x32"
			libdirs {
							"../Externals/glew-2.0.0/lib/Release/Win32"
			}
			
		platforms			"x64"
			libdirs {
							"../Externals/glew-2.0.0/lib/Release/x64"
			}

		configuration		"Debug"
			targetsuffix	"_d"
			flags			{ "Symbols" }
			
		configuration		"Release"
			targetsuffix	"_r"
			flags			{ "Optimize" }
