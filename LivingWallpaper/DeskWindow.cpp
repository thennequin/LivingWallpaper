
#include "DeskWindow.h"

#include <vector>

#include <gl\gl.h>
#include <gl\glu.h>
//#include <gl\glaux.h>		// Header File For The Glaux Library

const char* const DeskWindow::c_pWindowClassName = "LivingDeskWindow";

const char* const c_pVertexShaderBase = 
"void main() {\n"
"	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;\n"
"	gl_TexCoord[0] = gl_MultiTexCoord0;\n"
"}\n"
;

const char* const c_pFragmentShaderBase0 =
"uniform vec3 iResolution;"
"uniform float iGlobalTime;"
"uniform float iTimeDelta;"
"uniform float iGlobalFrame;"
"uniform float iChannelTime[4];"
"uniform vec4 iMouse;"
"uniform vec4 iDate;"
"uniform float iSampleRate;"
"uniform vec3 iChannelResolution[4];"
"uniform sampler2D iChannel0;"
;

const char* const c_pFragmentShaderBase1 =
"void main() {\n"
"	mainImage( gl_FragColor, gl_TexCoord[0].xy * iResolution.xy );"
"}"
;



LRESULT CALLBACK DeskWindow::WinProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg)
	{

	}
	return DefWindowProc(hWnd, uMsg, wParam, lParam);
}

void DeskWindow::RegisterWindowClass()
{
	WNDCLASSEX ex;

	ex.cbSize = sizeof(WNDCLASSEX);
	ex.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
	ex.lpfnWndProc = WinProc;
	ex.cbClsExtra = 0;
	ex.cbWndExtra = 0;
	ex.hInstance = GetModuleHandle(NULL);
	ex.hIcon = LoadIcon(NULL, IDI_APPLICATION);
	//ex.hCursor = LoadCursor(NULL, IDC_ARROW);
	ex.hCursor = NULL;
	ex.hbrBackground = NULL;
	ex.lpszMenuName = NULL;
	ex.lpszClassName = c_pWindowClassName;
	ex.hIconSm = NULL;

	RegisterClassEx(&ex);
}

void DeskWindow::UnregisterWindowClass()
{
	UnregisterClass( c_pWindowClassName, GetModuleHandle(NULL) );
}

DeskWindow::DeskWindow(HMONITOR oLinkToMonitor, int iX, int iY, int iWidth, int iHeight, HWND oParent)
{
	m_pHWND = CreateWindow( c_pWindowClassName, "DeskWindow", 0, iX, iY, iWidth, iHeight, NULL, NULL, NULL, NULL );

	SetWindowLong(m_pHWND, GWL_STYLE, WS_VISIBLE );
	SetWindowLong(m_pHWND, GWL_EXSTYLE, WS_EX_TRANSPARENT );
	SetParent( m_pHWND, oParent );
	ShowWindow( m_pHWND, SW_SHOW );

	static	PIXELFORMATDESCRIPTOR pfd =				// pfd Tells Windows How We Want Things To Be
	{
		sizeof(PIXELFORMATDESCRIPTOR),				// Size Of This Pixel Format Descriptor
		1,											// Version Number
		PFD_DRAW_TO_WINDOW |						// Format Must Support Window
		PFD_SUPPORT_OPENGL |						// Format Must Support OpenGL
		PFD_DOUBLEBUFFER,							// Must Support Double Buffering
		PFD_TYPE_RGBA,								// Request An RGBA Format
		32,											// Select Our Color Depth
		0, 0, 0, 0, 0, 0,							// Color Bits Ignored
		0,											// No Alpha Buffer
		0,											// Shift Bit Ignored
		0,											// No Accumulation Buffer
		0, 0, 0, 0,									// Accumulation Bits Ignored
		16,											// 16Bit Z-Buffer (Depth Buffer)  
		0,											// No Stencil Buffer
		0,											// No Auxiliary Buffer
		PFD_MAIN_PLANE,								// Main Drawing Layer
		0,											// Reserved
		0, 0, 0										// Layer Masks Ignored
	};

	if (!(m_pDC = GetDC(m_pHWND)))							// Did We Get A Device Context?
	{
		MessageBox(NULL, "Can't Create A GL Device Context.", "ERROR", MB_OK | MB_ICONEXCLAMATION);
		return;								// Return FALSE
	}

	GLuint iPixelFormat;
	if (!(iPixelFormat = ChoosePixelFormat(m_pDC, &pfd)))	// Did Windows Find A Matching Pixel Format?
	{
		MessageBox(NULL, "Can't Find A Suitable PixelFormat.", "ERROR", MB_OK | MB_ICONEXCLAMATION);
		return;								// Return FALSE
	}

	if (!SetPixelFormat(m_pDC, iPixelFormat, &pfd))		// Are We Able To Set The Pixel Format?
	{
		MessageBox(NULL, "Can't Set The PixelFormat.", "ERROR", MB_OK | MB_ICONEXCLAMATION);
		return;								// Return FALSE
	}

	if (!(m_pGLRC = wglCreateContext(m_pDC)))				// Are We Able To Get A Rendering Context?
	{
		MessageBox(NULL, "Can't Create A GL Rendering Context.", "ERROR", MB_OK | MB_ICONEXCLAMATION);
		return;								// Return FALSE
	}

	if (!wglMakeCurrent(m_pDC, m_pGLRC))					// Try To Activate The Rendering Context
	{
		MessageBox(NULL, "Can't Activate The GL Rendering Context.", "ERROR", MB_OK | MB_ICONEXCLAMATION);
		return;								// Return FALSE
	}

	GLenum err = glewInit();
	if (GLEW_OK != err)
	{
		/* Problem: glewInit failed, something is seriously wrong. */
		fprintf(stderr, "Error: %s\n", glewGetErrorString(err));
	}
	fprintf(stdout, "Status: Using GLEW %s\n", glewGetString(GLEW_VERSION));

	glShadeModel(GL_SMOOTH);							// Enable Smooth Shading
	glClearColor(0.0f, 0.0f, 0.0f, 0.f);				// Black Background
	glClearDepth(1.0f);									// Depth Buffer Setup
	glEnable(GL_DEPTH_TEST);							// Enables Depth Testing
	glDepthFunc(GL_LEQUAL);								// The Type Of Depth Testing To Do
	glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);	// Really Nice Perspective Calculations

	Resize(iWidth, iHeight);

	std::string sFragmentShader;
	sFragmentShader += c_pFragmentShaderBase0;
	FILE* pFile = fopen("fragment.shader", "r");
	if (pFile != NULL)
	{
		fseek(pFile, 0, SEEK_END);
		size_t iSize = ftell(pFile);
		fseek(pFile, 0, SEEK_SET);
		std::vector<char> sFileContent(iSize + 1);
		fread(&sFileContent[0], iSize, 1, pFile);
		sFileContent[sFileContent.size() - 1] = 0;
		sFragmentShader += &sFileContent[0];
	}
	sFragmentShader += c_pFragmentShaderBase1;

	m_pVertexShader = new GLShader(GLShader::E_TYPE_VERTEX, c_pVertexShaderBase);
	m_pVertexShader->Compile();
	m_pFragmentShader = new GLShader(GLShader::E_TYPE_FRAGMENT, sFragmentShader.c_str());
	m_pFragmentShader->Compile();
	m_pShaderProgram = new GLShaderProgram(m_pVertexShader, m_pFragmentShader);
	m_pShaderProgram->Compile();

	m_iLastTickCount = GetTickCount64();
	m_fTime = 0.f;
}

DeskWindow::~DeskWindow()
{
	DestroyWindow(m_pHWND);
}

void DeskWindow::Refresh()
{
	MSG oMsg;
	if (PeekMessage(&oMsg, m_pHWND, 0, 0, PM_REMOVE))	// Is There A Message Waiting?
	{
		TranslateMessage(&oMsg);
		DispatchMessage(&oMsg);
	}
	else
	{
		if (wglMakeCurrent(m_pDC, m_pGLRC))
		{
			Draw();
			SwapBuffers();
		}
	}
}

void DeskWindow::Resize(int iWidth, int iHeight)
{
	glViewport(0, 0, iWidth, iHeight);						// Reset The Current Viewport

	glMatrixMode(GL_PROJECTION);						// Select The Projection Matrix
	glLoadIdentity();									// Reset The Projection Matrix

														// Calculate The Aspect Ratio Of The Window
	//gluPerspective(45.0f, (GLfloat)iWidth / (GLfloat)iHeight, 0.1f, 100.0f);

	gluOrtho2D( 0.f, 1.f, 0.f, 1.f );

	glMatrixMode(GL_MODELVIEW);							// Select The Modelview Matrix
	glLoadIdentity();									// Reset The Modelview Matrix

	m_iWidth = iWidth;
	m_iHeight = iHeight;
}

void DeskWindow::Draw()
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	// Clear Screen And Depth Buffer

	glLoadIdentity();									// Reset The Current Modelview Matrix

	m_pShaderProgram->Use();
	/*
	uniform vec3 iResolution;
	uniform float iGlobalTime;
	uniform float iGlobalDelta;
	uniform float iGlobalFrame;
	uniform float iChannelTime[4];
	uniform vec4 iMouse;
	uniform vec4 iDate;
	uniform float iSampleRate;
	uniform vec3 iChannelResolution[4];
	uniform samplerXX iChanneli;
	*/

	ULONGLONG iTick = GetTickCount64();

	float fDelta = (iTick - m_iLastTickCount) / 1000.f;
	m_iLastTickCount = iTick;

	m_pShaderProgram->SetVec3("iResolution", m_iWidth, m_iHeight, 1.f);
	m_pShaderProgram->SetFloat("iGlobalTime", m_fTime);
	m_pShaderProgram->SetFloat("iTimelDelta", fDelta);

	m_fTime += fDelta;

	/*char sLog[256];
	sprintf(sLog,"Delta %f => %f\n", fDelta, fTime);
	OutputDebugString(sLog);*/

	glBegin(GL_QUADS);
		glColor3f(1.0f, 1.0f, 1.0f);
		glTexCoord2f(0.0f, 0.0f);
		glVertex2f(0.0f, 0.0f);
		glTexCoord2f(0.0f, 1.0f);
		glVertex2f(0.0f, 1.0f);
		glTexCoord2f(1.0f, 1.0f);
		glVertex2f(1.0f, 1.0f);
		glTexCoord2f(1.0f, 0.0f);
		glVertex2f(1.0f, 0.0f);
	glEnd();
}

void DeskWindow::SwapBuffers()
{
	::SwapBuffers(m_pDC);
}