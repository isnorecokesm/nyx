.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
include \masm32\include\comdlg32.inc
include \masm32\macros\macros.asm 

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\comdlg32.lib

WndProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
CreateControls PROTO
RegisterWindowClass PROTO
BrowseFile PROTO :DWORD, :DWORD
ExportVideo PROTO

.data
    szClassName     db "NyxClass", 0
    szWindowTitle   db "Nyx", 0
    
    szVideo         db "Photo:", 0
    szAudio         db "Audio:", 0
    szOutput        db "Name:", 0
    szExport        db "EXPORT VIDEO", 0
    szBrowse        db "Browse", 0
    szReady         db "Ready to export", 0
    szDone          db "Exporting...", 0
    szComplete      db "Export complete!", 0
    szTitle         db "Done", 0
    szError1        db "Select a video file first!", 0
    szError2        db "Failed to start FFmpeg!", 0
    szErrorTitle    db "Error", 0
    szStatic        db "STATIC", 0
    szEdit          db "EDIT", 0
    szButton        db "BUTTON", 0
    
    szDefaultOut    db "output.mp4", 0
    
    szFFmpeg        db "ffmpeg.exe -y -i ", 0
    szQuote         db 22h, 0
    szSpace         db " ", 0
    szAudioFlag     db " -i ", 0
    szCodecFlags    db " -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 ", 0
    
    szFilter        db "Video Files", 0
                    db "*.mp4;*.avi;*.mkv;*.mov", 0
                    db "Audio Files", 0
                    db "*.mp3;*.wav;*.aac;*.m4a", 0
                    db "All Files", 0
                    db "*.*", 0, 0

.data?
    hInstance       dd ?
    hWnd            dd ?
    hVideoEdit      dd ?
    hAudioEdit      dd ?
    hOutputEdit     dd ?
    hExportBtn      dd ?
    hVideoBrowse    dd ?
    hAudioBrowse    dd ?
    hStatusLabel    dd ?
    
    szVideoPath     db 512 dup(?)
    szAudioPath     db 512 dup(?)
    szOutputPath    db 512 dup(?)
    szCommand       db 2048 dup(?)
    
    wc              WNDCLASSEX <>
    msg             MSG <>
    ofn             OPENFILENAME <>
    startup         STARTUPINFO <>
    procinfo        PROCESS_INFORMATION <>

.const
    ID_VIDEO_EDIT   equ 101
    ID_AUDIO_EDIT   equ 102
    ID_OUTPUT_EDIT  equ 103
    ID_EXPORT_BTN   equ 104
    ID_VIDEO_BROWSE equ 105
    ID_AUDIO_BROWSE equ 106
    ID_STATUS       equ 107

.code

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax
    
    call RegisterWindowClass
    
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, 
        addr szClassName, addr szWindowTitle,
        WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX or WS_VISIBLE,
        CW_USEDEFAULT, CW_USEDEFAULT, 650, 300,
        NULL, NULL, hInstance, NULL
    mov hWnd, eax
    
    call CreateControls
    
    .while TRUE
        invoke GetMessage, addr msg, NULL, 0, 0
        .break .if eax == 0
        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg
    .endw
    
    invoke ExitProcess, 0

RegisterWindowClass proc
    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset WndProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov eax, hInstance
    mov wc.hInstance, eax
    
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
    
    mov wc.hbrBackground, COLOR_BTNFACE + 1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, offset szClassName
    mov wc.hIconSm, 0
    
    invoke RegisterClassEx, addr wc
    ret
RegisterWindowClass endp

CreateControls proc
    invoke CreateWindowEx, 0, addr szStatic, addr szVideo,
        WS_CHILD or WS_VISIBLE or SS_LEFT,
        10, 15, 60, 20,
        hWnd, NULL, hInstance, NULL
    
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, addr szEdit, NULL,
        WS_CHILD or WS_VISIBLE or ES_AUTOHSCROLL,
        80, 12, 400, 25,
        hWnd, ID_VIDEO_EDIT, hInstance, NULL
    mov hVideoEdit, eax
    
    invoke CreateWindowEx, 0, addr szButton, addr szBrowse,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        490, 12, 80, 25,
        hWnd, ID_VIDEO_BROWSE, hInstance, NULL
    mov hVideoBrowse, eax
    
    invoke CreateWindowEx, 0, addr szStatic, addr szAudio,
        WS_CHILD or WS_VISIBLE or SS_LEFT,
        10, 55, 60, 20,
        hWnd, NULL, hInstance, NULL
    
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, addr szEdit, NULL,
        WS_CHILD or WS_VISIBLE or ES_AUTOHSCROLL,
        80, 52, 400, 25,
        hWnd, ID_AUDIO_EDIT, hInstance, NULL
    mov hAudioEdit, eax
    
    invoke CreateWindowEx, 0, addr szButton, addr szBrowse,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        490, 52, 80, 25,
        hWnd, ID_AUDIO_BROWSE, hInstance, NULL
    mov hAudioBrowse, eax
    
    invoke CreateWindowEx, 0, addr szStatic, addr szOutput,
        WS_CHILD or WS_VISIBLE or SS_LEFT,
        10, 95, 60, 20,
        hWnd, NULL, hInstance, NULL
    
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, addr szEdit, addr szDefaultOut,
        WS_CHILD or WS_VISIBLE or ES_AUTOHSCROLL,
        80, 92, 400, 25,
        hWnd, ID_OUTPUT_EDIT, hInstance, NULL
    mov hOutputEdit, eax
    
    invoke CreateWindowEx, 0, addr szButton, addr szExport,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        200, 140, 250, 40,
        hWnd, ID_EXPORT_BTN, hInstance, NULL
    mov hExportBtn, eax
    
    invoke CreateWindowEx, 0, addr szStatic, addr szReady,
        WS_CHILD or WS_VISIBLE or SS_CENTER,
        10, 200, 620, 20,
        hWnd, ID_STATUS, hInstance, NULL
    mov hStatusLabel, eax
    
    ret
CreateControls endp

WndProc proc hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    .if uMsg == WM_COMMAND
        mov eax, wParam
        and eax, 0FFFFh
        
        .if eax == ID_EXPORT_BTN
            call ExportVideo
            
        .elseif eax == ID_VIDEO_BROWSE
            invoke BrowseFile, addr szVideoPath, hVideoEdit
            
        .elseif eax == ID_AUDIO_BROWSE
            invoke BrowseFile, addr szAudioPath, hAudioEdit
        .endif
        
    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage, 0
        
    .else
        invoke DefWindowProc, hWin, uMsg, wParam, lParam
        ret
    .endif
    
    xor eax, eax
    ret
WndProc endp

BrowseFile proc pBuffer:DWORD, hEdit:DWORD
    LOCAL buffer[512]:BYTE
    
    invoke RtlZeroMemory, addr ofn, sizeof OPENFILENAME
    
    mov ofn.lStructSize, sizeof OPENFILENAME
    mov eax, hWnd
    mov ofn.hwndOwner, eax
    mov ofn.lpstrFilter, offset szFilter
    lea eax, buffer
    mov ofn.lpstrFile, eax
    mov byte ptr [buffer], 0
    mov ofn.nMaxFile, 512
    mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
    
    invoke GetOpenFileName, addr ofn
    .if eax != 0
        invoke lstrcpy, pBuffer, addr buffer
        invoke SetWindowText, hEdit, pBuffer
    .endif
    
    ret
BrowseFile endp

ExportVideo proc
    invoke GetWindowText, hVideoEdit, addr szVideoPath, 512
    invoke GetWindowText, hAudioEdit, addr szAudioPath, 512
    invoke GetWindowText, hOutputEdit, addr szOutputPath, 512
    
    .if byte ptr [szVideoPath] == 0
        invoke MessageBox, hWnd, addr szError1, addr szErrorTitle, MB_OK or MB_ICONERROR
        ret
    .endif
    
    invoke lstrcpy, addr szCommand, addr szFFmpeg
    invoke lstrcat, addr szCommand, addr szQuote
    invoke lstrcat, addr szCommand, addr szVideoPath
    invoke lstrcat, addr szCommand, addr szQuote
    
    .if byte ptr [szAudioPath] != 0
        invoke lstrcat, addr szCommand, addr szAudioFlag
        invoke lstrcat, addr szCommand, addr szQuote
        invoke lstrcat, addr szCommand, addr szAudioPath
        invoke lstrcat, addr szCommand, addr szQuote
        invoke lstrcat, addr szCommand, addr szCodecFlags
    .else
        invoke lstrcat, addr szCommand, addr szSpace
    .endif
    
    invoke lstrcat, addr szCommand, addr szQuote
    invoke lstrcat, addr szCommand, addr szOutputPath
    invoke lstrcat, addr szCommand, addr szQuote
    
    invoke SetWindowText, hStatusLabel, addr szDone
    
    invoke RtlZeroMemory, addr startup, sizeof STARTUPINFO
    mov startup.cb, sizeof STARTUPINFO
    
    invoke CreateProcess, NULL, addr szCommand, NULL, NULL, FALSE,
        CREATE_NO_WINDOW, NULL, NULL, addr startup, addr procinfo
    
    .if eax != 0
        invoke WaitForSingleObject, procinfo.hProcess, INFINITE
        invoke CloseHandle, procinfo.hProcess
        invoke CloseHandle, procinfo.hThread
        invoke MessageBox, hWnd, addr szComplete, addr szTitle, MB_OK or MB_ICONINFORMATION
    .else
        invoke MessageBox, hWnd, addr szError2, addr szErrorTitle, MB_OK or MB_ICONERROR
    .endif
    
    invoke SetWindowText, hStatusLabel, addr szReady
    ret
ExportVideo endp

end start