
solution "LivingWallpaper"
	location				(_ACTION)
	language				"C++"
	configurations			{ "Debug", "Release" }
	platforms				{ "x32", "x64" }
	objdir					("../Intermediate/".._ACTION)

	project "LivingWallpaper"
		uuid				"4A4C0573-DC2B-4899-92E5-61DF02FCA6FE"
		--kind				"WindowedApp"
		kind				"ConsoleApp"
		targetdir			"../Output/"
		
		links				{ "opengl32", "glu32", "glew32" }
		files {
							"../LivingWallpaper/**.cpp",
							"../LivingWallpaper/**.h",
		}

		includedirs {
							"../Externals/glew-2.0.0/include"
		}
		
		configuration			"x32"
			targetdir		"../Output/x32/"
			libdirs {
							"../Externals/glew-2.0.0/lib/Release/Win32"
			}
			postbuildcommands {
							'xcopy "..\\..\\Externals\\lew-2.0.0\\bin\\Release\\Win32\\glew32.dll" "..\\..\\Output\\x32\\" /Y',
							'xcopy "..\\..\\Output\\fragment.shader" "..\\..\\Output\\x32\\" /Y',
			}

		configuration			"x64"
			targetdir		"../Output/x64/"
			libdirs {
							"../Externals/glew-2.0.0/lib/Release/x64"
			}
			postbuildcommands {
							'xcopy "..\\..\\Externals\\glew-2.0.0\\bin\\Release\\x64\\glew32.dll" "..\\..\\Output\\x64\\" /Y',
							'xcopy "..\\..\\Output\\fragment.shader" "..\\..\\Output\\x64\\" /Y',
			}

		configuration		"Debug"
			targetsuffix	"_d"
			flags			{ "Symbols" }
			
		configuration		"Release"
			targetsuffix	"_r"
			flags			{ "Optimize" }
