
#include "DeskWindow.h"
#include <Windows.h>

#include <list>

struct Screen
{
	HMONITOR pMonitor;
	RECT oRect;
};

typedef std::list<Screen> ScreenList;

static HWND s_pWorkerHWND = NULL;
static ScreenList s_oScreenList;

BOOL CALLBACK MonitorEnumProc(HMONITOR lprcMonitorhMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData)
{
	Screen oScreen;
	oScreen.pMonitor = lprcMonitorhMonitor;
	oScreen.oRect = *lprcMonitor;
	s_oScreenList.push_back(oScreen);

	return TRUE;
}

void RefreshMonitors()
{
	s_oScreenList.clear();
	EnumDisplayMonitors(NULL, NULL, MonitorEnumProc, NULL);
}

BOOL CALLBACK EnumWindowProcFunc(HWND pTopHwnd, LPARAM pTopParam )
{
	HWND pShellHwnd = FindWindowEx(pTopHwnd,
		NULL,
		"SHELLDLL_DefView",
		NULL);

	if (pShellHwnd != NULL)
	{
		HWND pWorkerHWND = FindWindowEx(NULL,
			pTopHwnd,
			"WorkerW",
			NULL);
		if (pWorkerHWND != NULL)
		{
			(*(HWND*)pTopParam) = pWorkerHWND;
		}
	}

	return true;
}

HWND FindWorker()
{
	HWND pWorker = NULL;
	EnumWindows( EnumWindowProcFunc, (LPARAM)&pWorker );
	return pWorker;
}



int main(/*int argc, char** argv*/)
{
	DeskWindow::RegisterWindowClass();

	//Ask for second WorkerW
	{
		HWND oProgmanHWND = FindWindow("Progman", NULL);

		ULONG_PTR iResults;
		SendMessageTimeout(oProgmanHWND,
			0x052C,//user code
			NULL,
			NULL,
			SMTO_NORMAL,
			1000,
			&iResults);
	}

	DeskWindowPtrList oDeskWindowList;
	HWND oWorker = FindWorker();

	HWND pDesktopHWND = GetDesktopWindow();

	RefreshMonitors();

	// Create DeskWindows
	for (ScreenList::iterator it = s_oScreenList.begin(), itEnd = s_oScreenList.end(); it != itEnd; ++it)
	{
		DeskWindow* pDeskWindow = new DeskWindow(it->pMonitor,
			it->oRect.left,
			it->oRect.top,
			it->oRect.right - it->oRect.left,
			it->oRect.bottom - it->oRect.top,
			oWorker
		);
		oDeskWindowList.push_back(pDeskWindow);
	}
	
	bool bExit = false;

	while (!bExit)
	{
		for (DeskWindowPtrList::iterator it = oDeskWindowList.begin(), itEnd = oDeskWindowList.end(); it != itEnd; ++it)
		{
			(*it)->Refresh();
		}
	}
	
	for (DeskWindowPtrList::iterator it = oDeskWindowList.begin(), itEnd = oDeskWindowList.end(); it != itEnd; ++it)
	{
		delete *it;
	}
	//HDC const dc = GetDC(0);
	//Ellipse(dc, 10, 10, 200, 200);

	DeskWindow::UnregisterWindowClass();
	return 0;
}