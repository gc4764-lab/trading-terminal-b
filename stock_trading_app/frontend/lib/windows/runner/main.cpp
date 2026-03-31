#include <flutter/flutter.h>
#include <windows.h>
#include <shellapi.h>

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  // Enable multi-monitor DPI awareness
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  
  // Allow multiple windows
  CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  
  flutter::FlutterWindow window(800, 600);
  WindowClass window_class("FLUTTER_WINDOW_CLASS", window);
  
  if (!window_class.Register()) {
    return EXIT_FAILURE;
  }
  
  window.Create();
  window.Show();
  
  flutter::FlutterViewController view(800, 600, window.GetHandle());
  view.SetIsVisible(true);
  
  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  
  CoUninitialize();
  return EXIT_SUCCESS;
}