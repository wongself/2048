.386
.model flat, stdcall
option casemap: none

include 2048.inc

.data
hInstance		dd		?       ; 主程序句柄
hGuide			dd		?       ; 引导文字句柄
hScore			dd		?       ; 成绩框句柄
hScoreText      dd		?       ; 成绩文本句柄
hMenu			dd		?       ; 菜单句柄
hIcon			dd		?       ; 图标句柄
hAcce			dd		?       ; 热键句柄
hStage			dd		?       ; 矩形外部句柄
hDialogBrush    dd      ?       ; 对话框背景笔刷
hStageBrush     dd      ?       ; 矩形外部背景笔刷

iScore          dd		0                       ; 0
cScore          db		MAX_LEN dup(0)          ; 0

hRec            dd      REC_LEN dup(?)          ; 方块矩阵
hText           dw      REC_LEN dup(0)          ; 数字矩阵
hBack           dd      BRUSH_LEN dup(?)        ; 背景句柄数组
hBrush          dd      BRUSH_LEN dup(?)        ; 笔刷数组

ProgramName		db		"Game", 0               ; 程序名称
GameName		db		"2048", 0               ; 程序名称
Author			db		"Wongself", 0           ; 作者
FontName        db		"Microsoft Sans Serif", 0           ; 作者
cGuide          db		"Join the numbers and get to the 2048 tile!", 0     ; 引导信息
cWin            db		"You win! Please click the button to restart", 0    ; 成功信息
cLose           db		"You lose! Please click the button to restart", 0   ; 失败信息

isWin			db		0                       ; 判断是否成功
isLose			db		0                       ; 判断是否失败

cPow0           db		"0", 0					; 0
cPow1           db		"2", 0					; 2
cPow2           db		"4", 0					; 4
cPow3           db		"8", 0					; 8
cPow4           db		"16", 0					; 16
cPow5           db		"32", 0					; 32
cPow6           db		"64", 0					; 64
cPow7           db		"128", 0                ; 128
cPow8           db		"256", 0                ; 256
cPow9           db		"512", 0                ; 512
cPow10          db		"1024", 0               ; 1024
cPow11          db		"2048", 0               ; 2048


.code
WinMain proc hInst:dword, hPrevInst:dword, cmdLine:dword, cmdShow:dword
    local wc:WNDCLASSEX	;窗口类
    local msg:MSG		;消息
    local hWnd:HWND		;对话框句柄

    invoke RtlZeroMemory, addr wc, sizeof WNDCLASSEX

    mov wc.cbSize, sizeof WNDCLASSEX			; 窗口类的大小
    mov wc.style, CS_HREDRAW or CS_VREDRAW		; 窗口风格
    mov wc.lpfnWndProc, offset Calculate		; 窗口消息处理函数地址
    mov wc.cbClsExtra, 0						; 在窗口类结构后的附加字节数，共享内存
    mov wc.cbWndExtra, DLGWINDOWEXTRA			; 在窗口实例后的附加字节数
    
    push hInst
    pop wc.hInstance							; 窗口所属程序句柄
    
    mov wc.hbrBackground, COLOR_WINDOW			; 背景画刷句柄
    mov wc.lpszMenuName, NULL					; 菜单名称指针
    mov wc.lpszClassName, offset ProgramName    ; 类名称指针

	; 加载图标句柄
    invoke LoadIcon, hInst, IDI_ICON
    mov wc.hIcon, eax

	; 加载光标句柄
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
    
    mov wc.hIconSm, 0							; 窗口小图标句柄
     
    invoke RegisterClassEx, addr wc				; 注册窗口类

	; 加载对话框窗口
    invoke CreateDialogParam, hInst, IDD_DIALOG, 0, offset Calculate, 0
    mov hWnd, eax
    invoke ShowWindow, hWnd, cmdShow    ; 显示窗口
    invoke UpdateWindow, hWnd           ; 更新窗口

    .while TRUE
        invoke GetMessage, addr msg, NULL, 0, 0                 ; 获取消息
        .break .if eax == 0
        invoke TranslateAccelerator, hWnd, hAcce, addr msg    ; 转换快捷键消息
        .if eax == 0
            invoke TranslateMessage, addr msg   ; 转换键盘消息
            invoke DispatchMessage, addr msg    ; 分发消息
        .endif
    .endw

	mov eax, msg.wParam
	ret
WinMain endp


Calculate proc hWnd:dword, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    local hdc:HDC
    local ps:PAINTSTRUCT
    local hf:dword

    .if uMsg == WM_INITDIALOG
        ; 获取菜单的句柄并显示菜单
        invoke LoadMenu, hInstance, IDR_MENU
        mov hMenu, eax
        invoke SetMenu, hWnd, hMenu

        ; 获取图标的句柄
        invoke LoadIcon, hInstance, IDI_ICON
        mov hIcon, eax
        invoke SendMessage, hWnd, WM_SETICON, ICON_SMALL, eax 

        ; 获取加速的句柄并显示菜单
        invoke LoadAccelerators, hInstance, IDR_ACC
        mov hAcce, eax

        ; 初始化数组和矩阵
        invoke InitRec, hWnd
        invoke InitBack
        invoke InitBrush

		; 生成字体
		invoke CreateFont, 26, 0, 0, 0, FW_DONTCARE, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_OUTLINE_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, VARIABLE_PITCH, offset FontName
        mov hf, eax

		; 初始化方格及其字体
        xor ebx, ebx
        .while ebx < REC_LEN
            invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, NULL
			invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETFONT, hf, NULL
            inc ebx
        .endw

		; 随机生成两个方格
        invoke RandomNumber
        invoke RandomNumber

    .elseif uMsg == WM_PAINT
        ; 绘制对话框背景
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        invoke FillRect, hdc, addr ps.rcPaint, hDialogBrush
        invoke EndPaint, hWnd, addr ps
    
	.elseif uMsg == WM_CTLCOLORSTATIC
        ; 绘制静态文本框
        mov ecx, lParam
        .if hStage == ecx
            invoke SetTextColor, wParam, StageBack
            invoke SetBkColor, wParam, StageBack
            mov eax, hStageBrush

            ret
        .elseif hGuide == ecx || hScore == ecx
            invoke SetTextColor, wParam, TextColor
            invoke SetBkColor, wParam, DialogBack
            mov eax, hDialogBrush

            ret
        .elseif hScoreText == ecx
            invoke SetTextColor, wParam, ButtonColor
            invoke SetBkColor, wParam, StageBack
            mov eax, hStageBrush

            ret
        .endif

        ; 获得当前操作的方格句柄
        xor ebx, ebx
        .while (dword ptr hRec[ebx * 4] != ecx) && (ebx < REC_LEN)
            inc ebx
        .endw

        invoke ShowNumber

        invoke SetTextColor, wParam, TextColor              ; 绘制文本颜色
        movzx esi, word ptr hText[ebx * 2]                  ; 根据数字大小选择笔刷
        invoke SetBkColor, wParam, dword ptr hBack[esi * 4] ; 绘制背景颜色
        mov eax, dword ptr hBrush[esi * 4]                  ; 返回笔刷以便绘图

        ret
		
	.elseif uMsg == WM_COMMAND
        mov eax, wParam
        movzx eax, ax       ; 获得命令

		; 开始新游戏
        .if eax == IDC_NEW || eax == ID_NEW
            invoke RtlZeroMemory, offset hText, sizeof hText
            invoke RandomNumber
            invoke RandomNumber
            invoke RefreshRec
            invoke SendMessage, hScoreText, WM_SETTEXT, 0, offset cPow0
            and isWin, 0
            and isLose, 0
            and iScore, 0
		
		; 上方向键
        .elseif eax == IDC_UP
            .if (isWin == 0) && (isLose == 0)
                invoke UpMerge      ; 生成新数字矩阵
                invoke RefreshRec   ; 刷新方格以便重新绘制背景
                invoke JudgeWin     ; 判断是否成功
                invoke dwtoa, iScore, offset cScore                             ; 将成绩转换为文本
                invoke SendMessage, hScoreText, WM_SETTEXT, 0, offset cScore    ; 显示当前成绩
            .endif

            invoke ProcessGame, hWnd
        
		; 下方向键
        .elseif eax == IDC_DOWN
            .if (isWin == 0) && (isLose == 0)
                invoke DownMerge    ; 生成新数字矩阵
                invoke RefreshRec   ; 刷新方格以便重新绘制背景
                invoke JudgeWin     ; 判断是否成功
                invoke dwtoa, iScore, offset cScore                             ; 将成绩转换为文本
                invoke SendMessage, hScoreText, WM_SETTEXT, 0, offset cScore    ; 显示当前成绩
            .endif

            invoke ProcessGame, hWnd
        
		; 左方向键
        .elseif eax == IDC_LEFT
            .if (isWin == 0) && (isLose == 0)
                invoke LeftMerge    ; 生成新数字矩阵
                invoke RefreshRec   ; 刷新方格以便重新绘制背景
                invoke JudgeWin     ; 判断是否成功
                invoke dwtoa, iScore, offset cScore                             ; 将成绩转换为文本
                invoke SendMessage, hScoreText, WM_SETTEXT, 0, offset cScore    ; 显示当前成绩
            .endif

            invoke ProcessGame, hWnd
        
		; 右方向键
        .elseif eax == IDC_RIGHT
            .if (isWin == 0) && (isLose == 0)
                invoke RightMerge   ; 生成新数字矩阵
                invoke RefreshRec   ; 刷新方格以便重新绘制背景
                invoke JudgeWin     ; 判断是否成功
                invoke dwtoa, iScore, offset cScore                             ; 将成绩转换为文本
                invoke SendMessage, hScoreText, WM_SETTEXT, 0, offset cScore    ; 显示当前成绩
            .endif

            invoke ProcessGame, hWnd    ; 处理标志位
        
        ; 关于
        .elseif eax == ID_ABOUT
            invoke ShellAbout, hWnd, offset ProgramName, offset Author, hIcon
        
        ; 退出
        .elseif eax == ID_EXIT
            invoke Calculate, hWnd, WM_CLOSE, wParam, lParam

        .endif

    ; 退出
	.elseif uMsg == WM_CLOSE
        invoke DestroyIcon, hIcon
        invoke DestroyMenu, hMenu
        invoke DeleteObject, hStageBrush
        invoke DeleteObject, hDialogBrush

        ; 删除笔刷
        xor ebx, ebx
        .while ebx < REC_LEN
            invoke DeleteObject, dword ptr hBrush[ebx * 4]
            inc ebx
        .endw

        invoke DestroyWindow, hWnd
        invoke PostQuitMessage, NULL
    
    .else
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    
    .endif

    xor eax, eax

    ret
Calculate endp


ProcessGame proc hWnd:dword

    ; 若成功，则显示成功对话框
    .if isWin == 1
        invoke MessageBox, hWnd, offset cWin, offset GameName, MB_OK
        ret
    .endif

    invoke RandomNumber

    ; 若失败，则显示失败对话框
    invoke JudgeLose
    .if isLose == 1
        invoke MessageBox, hWnd, offset cLose, offset GameName, MB_OK
        ret
    .endif

    ret
ProcessGame endp


; 判断游戏是否成功
JudgeWin proc

    ; 若出现2048，则游戏成功
    .while ebx < REC_LEN
        .if word ptr hText[ebx * 2] == WIN_POW
            or isWin, 1
        .endif
        inc ebx
    .endw

    ret
JudgeWin endp


; 判断游戏是否失败
JudgeLose proc

	or isLose, 1
    xor ebx, ebx
    .while ebx < 32
        xor ecx, ecx
        .while ecx < 8
            ; 若有空位，则游戏尚未失败
            mov esi, ebx
            add esi, ecx
            mov ax, word ptr hText[esi]
            .if ax == 0
                and isLose, 0
                .break
            .endif

            ; 若上邻位可合并，则游戏尚未失败
            .if ebx != 0
                .if ax == word ptr hText[esi - 8]
                    and isLose, 0
                    .break
                .endif
            .endif

            ; 若下邻位可合并，则游戏尚未失败
            .if ebx != 24
                .if ax == word ptr hText[esi + 8]
                    and isLose, 0
                    .break
                .endif
            .endif

            ; 若左邻位可合并，则游戏尚未失败
            .if ecx != 0
                .if ax == word ptr hText[esi - 2]
                    and isLose, 0
                    .break
                .endif
            .endif

            ; 若右邻位可合并，则游戏尚未失败
            .if ecx != 6
                .if ax == word ptr hText[esi + 2]
                    and isLose, 0
                    .break
                .endif
            .endif

            add ecx, 2
        .endw
        
        .break .if isLose == 0
        add ebx, 8
    .endw

	ret
JudgeLose endp


RightMerge proc

	xor ebx, ebx
    ; 针对每一行
    .while ebx < 32
        ; 向右合并
        mov ecx, 6
        .while (ecx > 0) && (ecx < 00ffh)
            mov esi, ebx
            add esi, ecx
            mov edi, esi
            sub edi, 2
            .while (word ptr hText[edi] == 0) && (edi > ebx)
                sub edi, 2
                sub ecx, 2
            .endw
            mov ax, word ptr hText[esi]
            .if (ax == word ptr hText[edi]) && (ax != 0)
                inc eax
                mov word ptr hText[esi], ax
                and word ptr hText[edi], 0
                sub ecx, 2
                invoke GetScore                
            .endif
            sub ecx, 2
        .endw

        ; 向右移位
        xor ecx, ecx
        .while ecx < 6
            mov esi, ebx
            add esi, ecx
            add esi, 2
            .if word ptr hText[esi] == 0
                .while esi > ebx
                    mov ax, word ptr hText[esi - 2]
                    mov word ptr hText[esi], ax
                    sub esi, 2
                .endw
                and word ptr hText[ebx], 0
            .endif
            add ecx, 2
        .endw
        
        add ebx, 8
    .endw

    ret
RightMerge endp


LeftMerge proc

    xor ebx, ebx
    ; 针对每一行
    .while ebx < 32
        mov edx, ebx
        add edx, 6

        ; 向左合并
        xor ecx, ecx
        .while ecx < 6
            mov esi, ebx
            add esi, ecx
            mov edi, esi
            add edi, 2
            .while (word ptr hText[edi] == 0) && (edi < edx)
                add edi, 2
                add ecx, 2
            .endw
            mov ax, word ptr hText[esi]
            .if (ax == word ptr hText[edi]) && (ax != 0)
                inc eax
                mov word ptr hText[esi], ax
                and word ptr hText[edi], 0
                add ecx, 2
                invoke GetScore                
            .endif
            add ecx, 2
        .endw

        ; 向左移位
        mov ecx, 6
        .while ecx > 0
            mov esi, ebx
            add esi, ecx
            sub esi, 2
            .if word ptr hText[esi] == 0
                .while esi < edx
                    mov ax, word ptr hText[esi + 2]
                    mov word ptr hText[esi], ax
                    add esi, 2
                .endw
                and word ptr hText[edx], 0
            .endif
            sub ecx, 2
        .endw
        
        add ebx, 8
    .endw

    ret
LeftMerge endp


DownMerge proc
		
    xor ecx, ecx
    ; 针对每一列
    .while ecx < 8
        mov edx, ecx
        add edx, 24

        ; 向下合并
        mov ebx, 24
        .while (ebx > 0) && (ebx < 00ffh)
            mov esi, ebx
            add esi, ecx
            mov edi, esi
            sub edi, 8
            .while (word ptr hText[edi] == 0) && (edi > ecx)
                sub edi, 8
                sub ebx, 8
            .endw
            mov ax, word ptr hText[esi]
            .if (ax == word ptr hText[edi]) && (ax != 0)
                inc eax
                mov word ptr hText[esi], ax
                and word ptr hText[edi], 0
                sub ebx, 8
                invoke GetScore                
            .endif
            sub ebx, 8
        .endw

        ; 向下移位
        xor ebx, ebx
        .while ebx < 24
            mov esi, ebx
            add esi, ecx
            add esi, 8
            .if word ptr hText[esi] == 0
                .while esi > ecx
                    mov ax, word ptr hText[esi - 8]
                    mov word ptr hText[esi], ax
                    sub esi, 8
                .endw
                and word ptr hText[ecx], 0
            .endif
            add ebx, 8
        .endw
        
        add ecx, 2
    .endw

    ret
DownMerge endp


UpMerge proc
		
    xor ecx, ecx
    ; 针对每一列
    .while ecx < 8
        mov edx, ecx
        add edx, 24

        ; 向上合并
        xor ebx, ebx
        .while ebx < 24
            mov esi, ebx
            add esi, ecx
            mov edi, esi
            add edi, 8
            .while (word ptr hText[edi] == 0) && (edi < edx)
                add edi, 8
                add ebx, 8
            .endw
            mov ax, word ptr hText[esi]
            .if (ax == word ptr hText[edi]) && (ax != 0)
                inc eax
                mov word ptr hText[esi], ax
                and word ptr hText[edi], 0
                add ebx, 8
                invoke GetScore                
            .endif
            add ebx, 8
        .endw

        ; 向上移位
        mov ebx, 24
        .while ebx > 0
            mov esi, ebx
            add esi, ecx
            sub esi, 8
            .if word ptr hText[esi] == 0
                .while esi < edx
                    mov ax, word ptr hText[esi + 8]
                    mov word ptr hText[esi], ax
                    add esi, 8
                .endw
                and word ptr hText[edx], 0
            .endif
            sub ebx, 8
        .endw
        
        add ecx, 2
    .endw

    ret
UpMerge endp


; 生成1或2并将其赋值到空的随机方格
RandomNumber proc

    local isRandom:dword
    local remain:dword
    local isPow1:dword
    and isRandom, 0

    ; 计算空方格数量
    xor edx, edx
    xor ebx, ebx
    .while ebx < 32
        xor ecx, ecx
        .while ecx < 8
            mov esi, ebx
            add esi, ecx
            mov ax, word ptr hText[esi]
            .if ax == 0
                inc edx
            .endif
            add ecx, 2
        .endw
        add ebx, 8
    .endw

    .if edx == 0
        ret
    .endif

    mov esi, edx

    ; 随机选择某一空方格
    invoke GetTickCount
    div esi
    mov remain, edx
    
    ; 随机选择生成1还是2
    mov esi, 2
    invoke GetTickCount
    div esi
    mov isPow1, edx
    
    ; 赋值到指定的方格
    xor edi, edi
    xor ebx, ebx
    .while ebx < 32
        xor ecx, ecx
        .while ecx < 8
            mov esi, ebx
            add esi, ecx
            mov ax, word ptr hText[esi]
            .if ax == 0
                .if edi == remain
                    .if isPow1 == 0
                        mov word ptr hText[esi], 1
                    .else
                        mov word ptr hText[esi], 2
                    .endif
                    or isRandom, 1
                    .break
                .endif
                inc edi
            .endif
            add ecx, 2
        .endw
        .break .if isRandom == 1
        add ebx, 8
    .endw

	ret
RandomNumber endp


; 刷新方格以便于重新绘制背景
RefreshRec proc

    xor ebx, ebx
    .while ebx < REC_LEN
        invoke InvalidateRect, dword ptr hRec[ebx * 4], NULL, TRUE
        inc ebx
    .endw

    ret
RefreshRec endp


; 计算分数
GetScore proc

    .if eax == 0
        add iScore, 0
    .elseif eax == 1
        add iScore, 2
    .elseif eax == 2
        add iScore, 4
    .elseif eax == 3
        add iScore, 8
    .elseif eax == 4
        add iScore, 16
    .elseif eax == 5
        add iScore, 32
    .elseif eax == 6
        add iScore, 64
    .elseif eax == 7
        add iScore, 128
    .elseif eax == 8
        add iScore, 256
    .elseif eax == 9
        add iScore, 512
    .elseif eax == 10
        add iScore, 1024
    .elseif eax == 11
        add iScore, 2048
    .endif

    ret
GetScore endp


ShowNumber proc
    
    movzx eax, word ptr hText[ebx * 2]

    .if eax == 0
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, NULL
    .elseif eax == 1
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow1
    .elseif eax == 2
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow2
    .elseif eax == 3
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow3
    .elseif eax == 4
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow4
    .elseif eax == 5
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow5
    .elseif eax == 6
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow6
    .elseif eax == 7
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow7
    .elseif eax == 8
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow8
    .elseif eax == 9
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow9
    .elseif eax == 10
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow10
    .elseif eax == 11
        invoke SendMessage, dword ptr hRec[ebx * 4], WM_SETTEXT, 0, offset cPow11
    .endif

    ret
ShowNumber endp


InitBrush proc

    invoke CreateSolidBrush, DialogBack
    mov hDialogBrush, eax

    invoke CreateSolidBrush, StageBack
    mov hStageBrush, eax

    xor ebx, ebx
    invoke CreateSolidBrush, Number0
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number1
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number2
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number3
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number4
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number5
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number6
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number7
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number8
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number9
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number10
    mov dword ptr hBrush[ebx * 4], eax

    inc ebx
    invoke CreateSolidBrush, Number11
    mov dword ptr hBrush[ebx * 4], eax
    
    ret
InitBrush endp


InitBack proc

    xor ebx, ebx
    mov dword ptr hBack[ebx * 4], Number0

    inc ebx
    mov dword ptr hBack[ebx * 4], Number1

    inc ebx
    mov dword ptr hBack[ebx * 4], Number2

    inc ebx
    mov dword ptr hBack[ebx * 4], Number3

    inc ebx
    mov dword ptr hBack[ebx * 4], Number4

    inc ebx
    mov dword ptr hBack[ebx * 4], Number5

    inc ebx
    mov dword ptr hBack[ebx * 4], Number6

    inc ebx
    mov dword ptr hBack[ebx * 4], Number7

    inc ebx
    mov dword ptr hBack[ebx * 4], Number8

    inc ebx
    mov dword ptr hBack[ebx * 4], Number9

    inc ebx
    mov dword ptr hBack[ebx * 4], Number10
    
    inc ebx
    mov dword ptr hBack[ebx * 4], Number11

    ret
InitBack endp

InitRec proc hWnd:dword

    invoke GetDlgItem, hWnd, IDC_STAGE
    mov hStage, eax

    invoke GetDlgItem, hWnd, IDC_NEWGAME
    mov hGuide, eax

    invoke GetDlgItem, hWnd, IDC_SCORE
    mov hScore, eax

    invoke GetDlgItem, hWnd, IDC_SCORETEXT
    mov hScoreText, eax

    xor ebx, ebx
    invoke GetDlgItem, hWnd, IDC_REC1
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC2
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC3
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC4
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC5
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC6
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC7
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC8
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC9
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC10
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC11
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC12
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC13
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC14
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC15
    mov dword ptr hRec[ebx * 4], eax

    inc ebx
    invoke GetDlgItem, hWnd, IDC_REC16
    mov dword ptr hRec[ebx * 4], eax

    ret
InitRec endp

; 主程序
main proc

    invoke GetModuleHandle, NULL
    mov hInstance, eax
    invoke WinMain, hInstance, 0, 0, SW_SHOWNORMAL
	invoke ExitProcess, eax

main endp
end main
