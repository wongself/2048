include windows.inc
include user32.inc
include kernel32.inc
include comctl32.inc
include masm32.inc
include shell32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib
includelib masm32.lib
includelib gdi32.lib

WinMain             PROTO :DWORD, :DWORD, :DWORD, :DWORD	; 窗口主程序
Calculate           PROTO :DWORD, :DWORD, :DWORD, :DWORD	; 消息处理程序
InitRec             PROTO :DWORD							; 初始化方格矩阵
InitBack            PROTO       							; 初始化颜色数组
InitBrush           PROTO       							; 初始化笔刷数组
ShowNumber	        PROTO                                   ; 显示数字
RefreshRec	        PROTO                                   ; 刷新方格
UpMerge             PROTO                                   ; 上方向键子程序
DownMerge	        PROTO                                   ; 下方向键子程序
LeftMerge	        PROTO                                   ; 左方向键子程序
RightMerge	        PROTO                                   ; 右方向键子程序
RandomNumber        PROTO                                   ; 随机添加数字
JudgeLose           PROTO                                   ; 检查游戏当前状态
JudgeWin            PROTO                                   ; 检查游戏当前状态
GetScore            PROTO                                   ; 检查游戏当前状态
ProcessGame         PROTO :DWORD                            ; 根据游戏当前状态处理信息

MAX_LEN         EQU 16
WIN_POW         EQU 11

REC_LEN         EQU 16
RecBack         EQU 00b4c1cdh
TextColor       EQU 00656e77h
StageBack       EQU 00a0adbbh
StageColor      EQU 00a0adbbh
DialogBack      EQU 00eff8fah
ButtonColor     EQU 00ffffffh
ButtonBack      EQU 0000ee00h

BRUSH_LEN       EQU 12
Number0         EQU 00b4c1cdh
Number1         EQU 008cfeffh
Number2         EQU 0097d0e8h
Number3         EQU 0091d2ffh
Number4         EQU 007999e8h
Number5         EQU 00918fffh
Number6         EQU 00f594ffh
Number7         EQU 00e880b8h
Number8         EQU 00ff999ch
Number9         EQU 00e8b080h
Number10        EQU 00fff985h
Number11        EQU 0085ff88h

IDD_DIALOG		EQU 101
IDR_MENU		EQU 103
IDI_ICON		EQU 104
IDR_ACC         EQU 107
IDC_REC1		EQU 1003
IDC_REC2		EQU 1004
IDC_REC3		EQU 1005
IDC_REC4		EQU 1006
IDC_REC5		EQU 1007
IDC_REC6		EQU 1008
IDC_REC7		EQU 1009
IDC_REC8		EQU 1010
IDC_REC9		EQU 1011
IDC_REC10		EQU 1012
IDC_REC11		EQU 1013
IDC_REC12		EQU 1014
IDC_REC13		EQU 1015
IDC_REC14		EQU 1016
IDC_REC15		EQU 1017
IDC_REC16		EQU 1018
IDC_NEW		    EQU 1022
IDC_STAGE		EQU 1024
IDC_UP          EQU 1025
IDC_DOWN		EQU 1026
IDC_LEFT		EQU 1027
IDC_RIGHT		EQU 1028
IDC_NEWGAME		EQU 1030
IDC_SCORE		EQU 1033
IDC_SCORETEXT   EQU 1034
ID_40001		EQU 40001
ID_40002		EQU 40002
ID_40003		EQU 40003
ID_NEW          EQU 40004
ID_EXIT         EQU 40005
ID_ABOUT		EQU 40006
