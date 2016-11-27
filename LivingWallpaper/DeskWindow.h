
#ifndef __DESK_WINDOW_H__
#define __DESK_WINDOW_H__

#include "GLShader.h"
#include "GLShaderProgram.h"

#include <Windows.h>
#include <list>

class DeskWindow
{
public:
	static void RegisterWindowClass();
	static void UnregisterWindowClass();
	static const char* const c_pWindowClassName;

	DeskWindow(HMONITOR oLinkToMonitor, int iX, int iY, int iWidth, int iHeight, HWND oParent);
	~DeskWindow();

	void Refresh();

	void Resize(int iWidth, int iHeight);
	void Draw();
	void SwapBuffers();
private:
	static LRESULT CALLBACK WinProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

	HWND		m_pHWND;
	HDC			m_pDC;
	HGLRC		m_pGLRC;
	
	int					m_iWidth;
	int					m_iHeight;

	ULONGLONG			m_iLastTickCount;
	float				m_fTime;

	GLShader*			m_pVertexShader;
	GLShader*			m_pFragmentShader;
	GLShaderProgram*	m_pShaderProgram;
};

typedef std::list<DeskWindow*> DeskWindowPtrList;

#endif // __DESK_WINDOW_H__