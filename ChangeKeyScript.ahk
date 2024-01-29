;実装したい機能
; 無変換+oを受け取ったときに、Ctrlの状態を確認して、押されていた場合にIMEの状態に応じて、Ctrl+Zまたは、Ctrl+backspaceを送るようにする。押されていないときはBackspaceを送る

; メモ
; ; vkBB
; : vkBA
; , vkBC
; ^ Ctrl
; + Shift
; ! Alt
; # Win
; vk1D 無変換
; vk1C 変換

; 別アプリによる設定
; ChgKeyでCapsLockをCtrlに変更済

; a::msgbox % "Your AHK version is " A_AhkVersion

; >>>事前準備関連
;#InstallKeybdHook
#UseHook
; -----------------------------------------------------------
; 関数の定義
; >>>IME関連
;IMEのON/OFF に関する関数の定義 ;0:英語入力 1:日本語入力
IME_SET(SetSts, WinTitle="A") {
    ControlGet,hwnd,HWND,,,%WinTitle%
    if	(WinActive(WinTitle))	{
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
        NumPut(cbSize, stGTI, 0, "UInt") ;	DWORD   cbSize;
        hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
        ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
    }

    return DllCall("SendMessage"
    , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
    , UInt, 0x0283 ;Message : WM_IME_CONTROL
    , Int, 0x006 ;wParam  : IMC_SETOPENSTATUS
    , Int, SetSts) ;lParam  : 0 or 1
}
;IMEの状態を取得する関数の定義 0:英語入力 1:日本語入力
IME_GET(WinTitle="A") {
    ControlGet,hwnd,HWND,,,%WinTitle%
    if (WinActive(WinTitle)) {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
        NumPut(cbSize, stGTI, 0, "UInt") ; DWORD cbSize;
        hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
        ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
    }
    return DllCall("SendMessage"
    , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
    , UInt, 0x0283 ;Message : WM_IME_CONTROL
    , Int, 0x0005 ;wParam  : IMC_GETOPENSTATUS
    , Int, 0) ;lParam  : 0
}
; IMEreset関数を作成
IMEreset() {
    ;60秒以上操作がされていない場合、IMEをOffにする
    if (A_TimeIdleKeyboard > 90000) {
        if (IME_GET()) {
            IME_SET(0)
        }
    }
}
; -----------------------------------------------------------

; -----------------------------------------------------------
; 定期実行の設定
; -----------------------------------------------------------
#Persistent
;IMEresetを10秒ごとに実行
SetTimer, IMEreset, 100000
Return
; -----------------------------------------------------------

; -----------------------------------------------------------
; テスト実装(test)
; -----------------------------------------------------------
; t::Send, {#}
;     If IME_GET() {
;         Send, 1
;     } Else {
;         Send, 0
;     }

+3::
    If IME_GET() {
        ; 日本語入力の場合
        bk = %ClipboardAll%
        Clipboard = #
        Send, ^v
        Clipboard = %bk%
        return
    } Else {
        Send, {#}
        Return
    }

-::
    ; もしclipboadの中身が"-"だったら、そのまま貼り付ける
    If IME_GET() {
        ; 日本語入力の場合
        bk = %ClipboardAll%
        Clipboard = -
        Send, ^v
        Clipboard = %bk%
        Return
    } Else {
        Send, {-}
        Return
    }

    ; ------------------------------ ;
    ; うまく行かない
    ; ; windowsキーを送信
    ; vkF2::Send, {Blind}{LWinDown}
    ; vkF2 up::Send, {Blind}{LWinUp}
    ; ------------------------------ ;


; 変換キー+8で"()"を入力
; (vk1C & 8::Send, {Blind}(){Left})
; ; 変換キー+9で現在選択しているテキストを切り取り、"()"を入力、その後に切り取ったテキストを貼り付け
; vk1C & 9::Send, {Blind}^x(){Tab}{Enter}{Left}^v

; ; メニューの作成
; ;Menu, メニューのID, Add, メニュ―のテキスト, 発動するコマンド名
; Menu, kakko, Add, 【】を挿入, Command1
; Menu, kakko, Add, 「」を挿入, Command2
; Menu, kakko, Add, 『』を挿入, Command3
; Menu, kakko, Add ;スペーサーの追加
; Menu, kakko, Add, 【】で挟む, Command4
; Menu, kakko, Add, 「」で挟む, Command5
; Menu, kakko, Add, 『』で挟む, Command6
; Menu, kakko, Add, []で挟む, Command7
; Menu, kakko, Add, ()で挟む, Command8
; Menu, kakko, Add, ""で挟む, Command9
; return
; ;-----------------------------
; ;各メニューアイテムが選択された際の動作
; Command1:
; Send 【】{left 1}
; return

; Command2:
; Send 「」{left 1}
; return

; Command3:
; Send 『』{left 1}
; return

; Command4:
; clipboard =
; Send ^c
; ClipWait
; Send 【%clipboard%】
; clipboard =
; Return

; Command5:
; clipboard =
; Send ^c
; ClipWait
; Send 「%clipboard%」
; clipboard =
; Return

; Command6:
; clipboard =
; Send ^c
; ClipWait
; Send 『%clipboard%』
; clipboard =
; Return

; Command7:
; clipboard =
; Send ^c
; ClipWait
; Send [%clipboard%]
; clipboard =
; Return

; Command8:
; clipboard =
; Send ^c
; ClipWait
; Send (%clipboard%)
; clipboard =
; Return

; Command9:
; clipboard =
; Send ^c
; ClipWait
; Send "%clipboard%"
; clipboard =
; Return
; ;-----------------------------
; ;メニューの表示: 無変換キー　＆　[
; vk1C & 8::Menu, kakko, Show

WrapBracket(x,y){
    Backup := ClipboardAll
    Clipboard =
    Send, ^c
    Sleep,50
    IfInString, Clipboard, `r`n
    {
        Clipboard = 
        ClipStatus := 0 ;からっぽのカッコが送られるので0
    }Else if (Clipboard = ""){
        ClipStatus := 0
    }else{
        ClipStatus := 1 ;中身があるので1
        #if
        }
    ;  StringReplace, Clipboard, Clipboard, `r`n, , All
    Sleep,50
    Clipboard = %x%%Clipboard%%y%
    Sleep, 50
    Send,^v
    Sleep,50
    if (ClipStatus = 0){
        send,{Left}
    }Else{
        #If
        }
    Clipboard := Backup
    ClipStatus = 
}
; 変換キー+8
vk1C & 8::WrapBracket("(",")")

; -----------------------------------------------------------

; -----------------------------------------------------------
; AHKの設定
; -----------------------------------------------------------
;頻繁にスクリプトを変える場合に便利
vk1D & 0::Reload		;このスクリプトをリロードして適用
vk1D & 8::Edit		;このスクリプトを編集
; -----------------------------------------------------------

; -----------------------------------------------------------
; Hotstringの設定
; -----------------------------------------------------------
#Hotstring *
#Hotstring O
::m@@::vgnrieee@gmail.com
::m//::vgnrieee@gmail.com
::m@s::s2310970@u.tsukuba.ac.jp
::m/s::s2310970@u.tsukuba.ac.jp
::m@u::s2310970@u.tsukuba.ac.jp
::m/u::s2310970@u.tsukuba.ac.jp
::t@@::08021311283
::t//::08021311283
::i@@::202310970
::i//::202310970
::n//::五十嵐尊人
::d//::
    FormatTime, dateStr, , yyyy/MM/dd
    Send, %dateStr%
Return ;日付を入力 ex)2000/01/01
::d--::
    FormatTime, dateStr, , yyyy-MM-dd
    Send, %dateStr%
Return ;日付を入力 ex)2000-01-01
::t,,::
    FormatTime, dateStr, , HH:mm
    Send, %dateStr%
Return ;時刻を入力 ex)00:00
; -----------------------------------------------------------

; -----------------------------------------------------------
; ウィンドウの移動系
; -----------------------------------------------------------
; Alt+j,kでアクティブウィンドウの最大化・最小化
!j::WinMinimize, A
!k::WinMaximize, A
!h::Send, #{Left}
!l::Send, #{Right}
; -----------------------------------------------------------

; -----------------------------------------------------------
; アプリ切り替え関連
; -----------------------------------------------------------
; 変換キーとmでVScodeを起動、またはアクティブにする
vk1C & m::
    if WinExist("ahk_exe Code.exe")
        ; VScodeがアクティブになっている場合は、最小化する
        if WinActive("ahk_exe Code.exe")
            WinMinimize, ahk_exe Code.exe
        else
            WinActivate, ahk_exe Code.exe
    else
        Run, C:\Users\vgnri\AppData\Local\Programs\Microsoft VS Code\Code.exe
Return

; 変換キーとnでCursorを起動、またはアクティブにする
vk1C & n::
    if WinExist("ahk_exe Cursor.exe")
        ; Cursorがアクティブになっている場合は、最小化する
        if WinActive("ahk_exe Cursor.exe")
            WinMinimize, ahk_exe Cursor.exe
        else
            WinActivate, ahk_exe Cursor.exe
    else
        Run, C:\Users\vgnri\AppData\Local\Programs\Cursor\Cursor.exe
Return

vk1C & o::
    if WinExist("ahk_exe Obsidian.exe")
        ; Obsidianがアクティブになっている場合は、最小化する
        if WinActive("ahk_exe Obsidian.exe")
            WinMinimize, ahk_exe Obsidian.exe
        else
            WinActivate, ahk_exe Obsidian.exe
    else
        Run, C:\Users\vgnri\AppData\Local\Programs\obsidian\Obsidian.exe
Return

; 変換キー+vで#3を送信。ただし、変換キーが押されている間は、windowsキーを押し続ける
; vk1C & v::
;     While (GetKeyState("vk1C", "P"))			;式を評価した結果が真である間、一連の処理を繰り返し実行する
;     {
;         Send, {Blind}{LWinDown}
;         Sleep, 0 				;負荷が高い場合は設定を変更 設定できる値は-1、0、10～m秒 詳細はSleep
;         if (GetKeyState("v", "P"))
;         {
;             Send, {Blind}{LWinUp}
;             Send, {Blind}#3
;             return
;         }
;     }
;     Send, {Blind}{LWinUp}
; Return

vk1C & v::Send, #3 ; Vivaldi
vk1C & l::Send, #4 ; LINE

; カタカナひらがなローマ字キー2連打でAltTabMenuキーのタスク切り替えとして割当
IsAltTabMenu := false
vkF2 & RAlt::
    Send !^{Tab}
    IsAltTabMenu := true
return
vk1C & vkF2::
    Send, !^{Tab}
    IsAltTabMenu := true
return



; vkF2::
;     If (A_PriorHotKey == A_ThisHotKey and A_TimeSincePriorHotkey < 500){
;         Send !^{Tab}
;         IsAltTabMenu := true
;         ; } else {
;         ;     ; vkF2が単独でクリックされた場合の動作
;         ;     Send, {Blind}{Ctrl}
;         ; } Else {
;         ;     ; VScodeを起動、またはアクティブにする
;         ;     if WinExist("ahk_exe Code.exe")
;         ;         WinActivate, ahk_exe Code.exe
;         ;     else
;         ;         Run, C:\Users\vgnri\AppData\Local\Programs\Microsoft VS Code\Code.exe
;     }
; return
; vkF2 & j::
;     if WinExist("ahk_exe Code.exe")
;         WinActivate, ahk_exe Code.exe
;     else
;         Run, C:\Users\vgnri\AppData\Local\Programs\Microsoft VS Code\Code.exe
; return

; vkF2::
; key := "vkF2"
; KeyWait, %key%, T0.3
; If(ErrorLevel){          ;長押しした場合
;     ; VScodeを起動、またはアクティブにする
;     if WinExist("ahk_exe Code.exe")
;         WinActivate, ahk_exe Code.exe
;     else
;         Run, C:\Users\vgnri\AppData\Local\Programs\Microsoft VS Code\Code.exe
;     KeyWait, %key%
;     ; Run, C:\Users\vgnri\AppData\Local\Programs\Microsoft VS Code\Code.exe
;     ; WinActivate, ahk_exe Code.exe
;     return
; }
; KeyWait, %key%, D, T0.2
; If(!ErrorLevel){         ;2度押しした場合
;     Send !^{Tab}
;     IsAltTabMenu := true
; }else{                   ;短押しした場合
;     Send, {Esc}
;     return
; }
; return

#If (IsAltTabMenu)
j::Send {Down}
k::Send {Up}
h::Send {Left}
l::Send {Right}
Enter::
    Send {Enter}
    IsAltTabMenu := false
Return
Space::
    Send {Space}
    IsAltTabMenu := false
Return
#If
    ; -----------------------------------------------------------

; -----------------------------------------------------------
; IME関連の設定
; -----------------------------------------------------------
; IMEのON/OFF
; vk1D::IME_SET(0) ;無変換キーで英語入力に
vk1C::
    If (IME_GET()) {
        IME_SET(0)
    } Else {
        IME_SET(1)
    }
return

; Ctrl+backspaceで日本語入力・英語入力どちらの場合でも打ち始めた文字を削除
Ctrl & BackSpace::
    ime := IME_GET()
    If (ime) {
        Send, ^z
    } Else {
        Send, {Blind}^{BackSpace}
    }
Return
; Ctrl+DeleteでIMEの切り替え　(∵Ctrl+BackSpaceで消去した後に、IME切り替えを迅速に行うため)
Ctrl & Delete::
    ime := IME_GET()
    If (ime) {
        IME_SET(0)
    } Else {
        IME_SET(1)
    }
Return
; -----------------------------------------------------------

; -----------------------------------------------------------
; カーソル移動関連の設定
; -----------------------------------------------------------
; 現在は別のキーの割り当てたりしている（タッチパッドを使ったほうが速いと思ったため）
; 変換キーとi,k,j,lでカーソル移動
; vk1C & i::
; vk1C & j::
; vk1C & k::
; vk1C & l::
;     While (GetKeyState("vk1C", "P"))			;式を評価した結果が真である間、一連の処理を繰り返し実行する
;     {
;         MoveX := 0, MoveY := 0
;         MoveY += GetKeyState("i", "P") ? -11 : 0	;GetKeyState() と ?:演算子(条件) (三項演算子) の組み合わせ
;         MoveX += GetKeyState("j", "P") ? -11 : 0
;         MoveY += GetKeyState("k", "P") ? 11 : 0
;         MoveX += GetKeyState("l", "P") ? 11 : 0
;         MouseMove, %MoveX%, %MoveY%, 0, R		;マウスカーソルを移動する
;         Sleep, 0 				;負荷が高い場合は設定を変更 設定できる値は-1、0、10～m秒 詳細はSleep
;     }
; Return
; -----------------------------------------------------------

; -----------------------------------------------------------
; キャレット移動関連の設定
; -----------------------------------------------------------
vk1D & H::Send,{Blind}{Left}
vk1D & J::Send,{Blind}{Down}
vk1D & K::Send,{Blind}{Up}
vk1D & L::Send,{Blind}{Right}
vk1D & s::Send, {Blind}{Home} ;Home
vk1D & f::Send, {Blind}{End} ;End
; -----------------------------------------------------------

; -----------------------------------------------------------
;vivaldi用の設定
; -----------------------------------------------------------
Ctrl & o::
    If (GetKeyState("Space", "P")) {
        Send, +^o
    } Else {
        Send, ^o
    }
Return ;サイドパネルでメモを開く用
Ctrl & i::
    If (GetKeyState("Space", "P")) {
        Send, !^q
    } Else {
        Send, ^i
    }
Return ;サイドパネルでstackeditを開く用
vk1D & w::Send, !w ;ウィンドウパネルを開く用のAlt+wに無変換+wを割り当て
vk1D & e::Send, {Blind}^e ;無変換キー+eでCtrl+e
; -----------------------------------------------------------

; -----------------------------------------------------------
; 無変換でCtrlと同様の動作をさせる設定
; -----------------------------------------------------------
vk1D & z::Send, ^z ;もとに戻す
vk1D & y::Send, ^y ;やり直す
vk1D & c::Send, ^c ;コピー
vk1D & V::Send, ^v ;貼り付け
vk1D & X::Send, ^x ;切り取り
vk1D & a::Send, ^a ;全選択
vk1D & /::Send, ^/ ;コメントアウト
; -----------------------------------------------------------

; -----------------------------------------------------------
;　特殊キー代替系の設定
; -----------------------------------------------------------
vk1D & Enter:: ; 行挿入(Ctrlを押している場合は、現在の行の上に、押していない場合は行の下に挿入)
    If (GetKeyState("Ctrl", "P")) {
        Send, {Up}{End}{Enter}
    } Else {
        Send, {End}{Enter}
    }
Return
; >>> 変換キー
vk1C & vkBB::Send, {Blind}{End}{Enter} ; 変換キー + ;
vk1C & @::Send, {Blind}{BackSpace}{BackSpace}{BackSpace} ; 変換キー + @でBackSpace×3
; >>> 無変換キー
vk1D & vkBB::Send, {Blind}{Enter} ; 無変換キー + ;
vk1D & vkBA::Send,{Blind}{End}{Enter} ; 無変換キー + :
vk1D & P::Send,{Blind}{Ctrl}{BackSpace} ; 無変換キー + Pで単語ごとに削除
vk1D & O::Send,{Blind}{BackSpace}
; 無変換+oを受け取ったときに、Ctrlの状態を確認して、押されていた場合にIMEの状態に応じて、Ctrl+Zまたは、Ctrl+backspaceを送るようにする。押されていないときはBackspaceを送る
; vk1D & o::
;     If (GetKeyState("Ctrl", "P")) {
;         ime := IME_GET()
;         If (ime) {
;             Send, ^z
;         } Else {
;             Send, ^{BackSpace}
;         }
;     } Else {
;         Send, {Blind}{BackSpace}
;     }
vk1D & @::Send,{Blind}{Del}
vk1D & Q::Send,{Blind}{Esc}
; -----------------------------------------------------------

; -----------------------------------------------------------
; vimもどき
; -----------------------------------------------------------
vk1D & d::Send, {Blind}{Home}+{End}		;1行選択
; -----------------------------------------------------------

; -----------------------------------------------------------
; アプリ起動系
; -----------------------------------------------------------
; vk1D & w::WinActivate, ahk_exe cmd.exe
vk1D & g::Run,C:\Users\vgnri\AppData\Local\Fit Win\fitwin\fitwin.exe
; -----------------------------------------------------------

; -----------------------------------------------------------
; 以下、未実装(実装案、等)
; -----------------------------------------------------------
; Enterキーの入力簡略化案
; vkBB::
;     If (A_PriorHotkey == Space and A_TimeSincePriorHotkey < 500){
;         Send, {Enter}
;     } Else{
;         Send, {vkBB}
;     }
; Return

; vkBA::
;     If (A_PriorHotkey == Space and A_TimeSincePriorHotkey < 500){
;         Send, {Blind}{Enter}
;     } Else {
;         Send, {vkBA}
;     }
; Return
; -----------------------------------------------------------

#UseHook off

; 参考用
; vkF2::
; key := "vkF2"
; KeyWait, %key%, T0.3
; If(ErrorLevel){          ;長押しした場合
;     TenKey := true
;     KeyWait, %key%
;     TenKey := false
;     return
; }
; KeyWait, %key%, D, T0.2
; If(!ErrorLevel){         ;2度押しした場合
;     Send !^{Tab}
;     IsAltTabMenu := true
; }else{                   ;短押しした場合
;     Send, {Esc}
;     return
; }

; Space単体にShiftキーの機能を割りあえているさんぷるこーど
; #InstallKeybdHook
; $Space::
;     if SandS_guard = True ;スペースキーガード
;         return
;     SandS_guard = True ;スペースキーにガードをかける
;     Send,{Shift Down} ;シフトキーを仮想的に押し下げる
;     ifNotEqual SandS_key ;既に入力済みの場合は抜ける
; return
; SandS_key=
; Input,SandS_key,L1 V ;1文字入力を受け付け（入力有無判定用）
; return

; $Space up:: ;スペース解放時
;     input ;既存のInputコマンドの終了
;     if SandS_guard = False ;ガードがかかってなかった場合（修飾キー＋Spaceのリリース）
;         return
;     SandS_guard = False ;スペースキーガードを外す
;     Send,{Shift Up} ;シフトキー解放
;     ifEqual SandS_key ;SandS文字入力なし
;     Send,{Space} ;スペースを発射
;     SandS_key=
; return

; Spaceキーと;でEnterキー
; Space & vkBB::Send, {Blind}{Enter
