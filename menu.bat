@echo off
setlocal enabledelayedexpansion

:: === 설정 파일 ===
set "SETTINGS_FILE=settings.txt"

:: settings.txt 읽어서 환경변수로 등록
for /f "usebackq delims=" %%A in ("%SETTINGS_FILE%") do (
    set "%%A"
)

:: === 기본값(설정 누락 대비) ===
if not defined EDITOR_NAME set "EDITOR_NAME=CURSOR"
if not defined EDITOR_OPEN_COMMAND set "EDITOR_OPEN_COMMAND=code"

:: === 확인 ===
echo CODE_BASE = %CODE_BASE%
echo SSH_BASE    = %SSH_BASE%
echo EDITOR_NAME = %EDITOR_NAME%
echo EDITOR_CMD  = %EDITOR_OPEN_COMMAND%
timeout /t 1 >nul

:main_menu
cls
echo 1. %EDITOR_NAME%
echo 2. SSH
echo cmd      - Open CMD (user)
echo cmd a    - Open CMD (admin)
echo ps       - Open PowerShell (user)
echo ps a     - Open PowerShell (admin)
echo x. Exit terminal
set /p choice="Please enter the number or command: "

:: ---- 공백 분리: 첫 토큰=명령, 두번째 토큰=플래그(a) ----
set "tcmd="
set "tflag="
for /f "tokens=1,2 delims= " %%i in ("%choice%") do (
    set "tcmd=%%i"
    set "tflag=%%j"
)

if /i "%tcmd%"=="cmd" (
    if /i "%tflag%"=="a" goto open_cmd_admin
    goto open_cmd_user
)
if /i "%tcmd%"=="ps" (
    if /i "%tflag%"=="a" goto open_ps_admin
    goto open_ps_user
)

if /i "%choice%"=="1" goto editor_menu
if /i "%choice%"=="2" goto ssh_menu
if /i "%choice%"=="x" exit
echo Invalid input.
pause
goto main_menu

:: ================== EDITOR 메뉴 ==================
:editor_menu
cls
call :print_editor_list
set /p csel="Enter the number to run (or 'cmd', 'ps', 'cmd a', 'ps a'): "

:: ---- 공백 분리 처리 (EDITOR 메뉴 내에서도 동일 동작) ----
set "tcmd="
set "tflag="
for /f "tokens=1,2 delims= " %%i in ("%csel%") do (
    set "tcmd=%%i"
    set "tflag=%%j"
)
if /i "%tcmd%"=="cmd" (
    if /i "%tflag%"=="a" goto open_cmd_admin
    goto open_cmd_user
)
if /i "%tcmd%"=="ps" (
    if /i "%tflag%"=="a" goto open_ps_admin
    goto open_ps_user
)

if /i "%csel%"=="f" goto main_menu
if /i "%csel%"=="x" exit
if /i "%csel%"=="r" goto rename_alias
if /i "%csel%"=="l" goto reload_map
if /i "%csel%"=="s" goto search_mode

set "selAlias=!alias[%csel%]!"
set "selPath=!path[%csel%]!"
if not defined selPath (
    echo Invalid number.
    pause
    goto editor_menu
)

:: 에디터를 동적으로 실행
call :open_editor "!selPath!"
goto main_menu

:rename_alias
set /p ridx="Enter the number to rename: "
set "rname=!alias[%ridx%]!"
if not defined rname (
    echo Invalid number.
    pause
    goto editor_menu
)
set /p newname="Enter the string to rename: "

break > tmp_map.txt
for /f "tokens=1* delims==" %%a in (%MAP_FILE%) do (
    if "%%a"=="!rname!" (
        echo %newname%=%%b>> tmp_map.txt
    ) else (
        echo %%a=%%b>> tmp_map.txt
    )
)
move /y tmp_map.txt %MAP_FILE% >nul
goto editor_menu

:: ================== dir_map.txt 최신화 ==================
:reload_map
setlocal enabledelayedexpansion

:: 기존 매핑 읽기
set count=0
for /f "tokens=1* delims==" %%a in (%MAP_FILE%) do (
    set /a count+=1
    set "alias[!count!]=%%a"
    set "path[!count!]=%%b"
)

break > tmp_map.txt

:: 실제 디렉터리 스캔
for /d %%D in (%CODE_BASE%\*) do (
    set "found="
    set "dpath=%%~fD"

    :: 기존 path 매칭 확인 → 별칭 유지
    for /l %%i in (1,1,!count!) do (
        if /i "!path[%%i]!"=="%%~fD" (
            call echo %%alias[%%i]%%=%%~fD>>tmp_map.txt
            set "found=1"
        )
    )

    :: 새 디렉터리라면 디렉터리명=경로 추가
    if not defined found (
        call echo %%~nxD=%%~fD>>tmp_map.txt
    )
)

:: alias 기준 정렬해서 최종 저장
sort tmp_map.txt /o %MAP_FILE%
del tmp_map.txt >nul 2>&1

endlocal
echo dir_map.txt reloaded with alias preserved and sorted!
pause
goto editor_menu

:: ================== 코드에디터 목록 출력 ==================
:print_editor_list
echo Listing all mapped folders from %MAP_FILE%:
set count=0
for /f "tokens=1* delims==" %%a in (%MAP_FILE%) do (
    set /a count+=1
    set "alias[!count!]=%%a"
    set "path[!count!]=%%b"
    echo     !count!. %%a
)
echo l. reLoad
echo r. Rename
echo s. Search
echo cmd / cmd a   - Open CMD (user/admin)
echo ps  / ps a    - Open PowerShell (user/admin)
echo f. select Folder again
echo x. eXit terminal
exit /b

:: ================== SEARCH 모드 ==================
:search_mode
cls
set /p keyword="Enter keyword to search: "
if "%keyword%"=="" goto editor_menu

echo Searching for "%keyword%" ...
set scount=0
for /f "tokens=1* delims==" %%a in (%MAP_FILE%) do (
    echo %%a | findstr /i "%keyword%" >nul
    if not errorlevel 1 (
        set /a scount+=1
        set "salias[!scount!]=%%a"
        set "spath[!scount!]=%%b"
        echo     !scount!. %%a
    )
)

if %scount%==0 (
    echo No matches found.
    pause
    goto editor_menu
)

set /p snum="Enter number to run (or 'f'=back, also supports 'cmd[/ a]' or 'ps[/ a]'): "

:: ---- 공백 분리 처리 (SEARCH 모드 내에서도 동일 동작) ----
set "tcmd="
set "tflag="
for /f "tokens=1,2 delims= " %%i in ("%snum%") do (
    set "tcmd=%%i"
    set "tflag=%%j"
)
if /i "%tcmd%"=="cmd" (
    if /i "%tflag%"=="a" goto open_cmd_admin
    goto open_cmd_user
)
if /i "%tcmd%"=="ps" (
    if /i "%tflag%"=="a" goto open_ps_admin
    goto open_ps_user
)

if /i "%snum%"=="f" goto editor_menu
if not defined salias[%snum%] (
    echo Invalid number.
    pause
    goto search_mode
)

set "selAlias=!salias[%snum%]!"
set "selPath=!spath[%snum%]!"

:: 에디터를 동적으로 실행
call :open_editor "!selPath!"
goto main_menu

:: ================== SSH 메뉴 ==================
:ssh_menu
cls
echo Listing all SSH hosts from %SSH_BASE%\ssh_map.txt:

rem --- 바깥에서 사용할 최종 변수 초기화 ---
set "sshUserHost="
set "sshPort="

rem --- ssh_map.txt 를 읽는 동안은 반드시 DelayedExpansion 끔 ---
setlocal DisableDelayedExpansion

set "idx=0"
rem # 혹은 빈 줄(#)은 무시하고 목록 + 번호 출력
for /f "usebackq tokens=* delims=" %%L in ("%SSH_BASE%\ssh_map.txt") do (
    if not "%%L"=="" if /i not "%%L"=="#" (
        set /a idx+=1
        rem 여기서 idx는 %idx% 가 아니라 CALL 로 확장해야 하므로:
        call echo     %%idx%%. %%L
    )
)

if %idx%==0 (
    echo No entries found in ssh_map.txt
    pause
    endlocal
    goto main_menu
)

echo(
echo cmd / cmd a   - Open CMD (user/admin)
echo ps  / ps a    - Open PowerShell (user/admin)
echo f. select Folder again
echo x. eXit terminal
set /p "sshsel=Enter the number to connect or a command: "

rem ---- 여기서부터는 sshsel 값에 따라 분기 ----
rem 명령어 계열은 endlocal 하고 원래 라벨로 점프
if /i "%sshsel%"=="x" (
    endlocal
    exit /b
)
if /i "%sshsel%"=="f" (
    endlocal
    goto main_menu
)
if /i "%sshsel%"=="cmd" (
    endlocal
    goto open_cmd_user
)
if /i "%sshsel%"=="cmd a" (
    endlocal
    goto open_cmd_admin
)
if /i "%sshsel%"=="ps" (
    endlocal
    goto open_ps_user
)
if /i "%sshsel%"=="ps a" (
    endlocal
    goto open_ps_admin
)

rem 숫자인지 대충 체크 (정수 아니면 다시)
for /f "delims=0123456789" %%Z in ("%sshsel%") do (
    if not "%%Z"=="" (
        echo Invalid input.
        pause
        endlocal
        goto ssh_menu
    )
)

rem ---- 선택한 번호에 해당하는 라인을 다시 읽어서 user@host:port 파싱 ----
set "target=%sshsel%"
set "idx=0"
set "line="
for /f "usebackq tokens=* delims=" %%L in ("%SSH_BASE%\ssh_map.txt") do (
    if not "%%L"=="" if /i not "%%L"=="#" (
        set /a idx+=1
        call :_ssh_pick_line %%idx%% "%%L" "%target%"
    )
)

if not defined line (
    echo Invalid number.
    pause
    endlocal
    goto ssh_menu
)

rem 이제 line 은 "별칭=사용자@호스트:포트" 형태
for /f "tokens=1* delims==" %%A in ("%line%") do (
    set "alias=%%A"
    set "info=%%B"
)

rem info = "user@host:port"
for /f "tokens=1,2 delims=:" %%U in ("%info%") do (
    set "userhost=%%U"
    set "port=%%V"
)

if not defined port set "port=22"

rem DisableDelayedExpansion 영역 끝내고 바깥 환경으로 값 넘기기
endlocal & set "sshUserHost=%userhost%" & set "sshPort=%port%"

rem 실제 SSH 실행 (창 크기 200x40은 기존 로직 유지)
start "SSH Session" cmd /c "mode con: cols=200 lines=40 && ssh -p %sshPort% %sshUserHost%"
goto main_menu

rem ======================================================
rem 선택 번호(target) 와 현재 idx 를 비교해서 line 설정하는 헬퍼
rem 이 라벨은 ssh_menu 안에서만 호출됨
:_ssh_pick_line
rem %1 = 현재 idx , %2 = "별칭=사용자@호스트:포트", %3 = target
if "%~1"=="%~3" (
    set "line=%~2"
)
exit /b

:: ================== 에디터 실행(공통) ==================
:open_editor
rem %~1 = target path
set "TARGET_PATH=%~1"

cls
echo Opening %EDITOR_NAME% at "%TARGET_PATH%" ...
rem PowerShell에서 실행: 경로 이동 후 EDITOR_OPEN_COMMAND로 열기
rem - 명령어는 문자열로 쓰고, PowerShell에서 실행 가능한 형태로 호출
start "" powershell -NoProfile -Command ^
  "Set-Location -LiteralPath '%TARGET_PATH%'; & '%EDITOR_OPEN_COMMAND%' . --new-window"
exit /b

:: ================== 터미널 열기 (일반/관리자) ==================
:open_cmd_user
cls
echo Opening Windows Terminal (CMD - user) at %CODE_BASE% ...
where wt.exe >nul 2>&1
if %errorlevel%==0 (
  start "" wt.exe new-tab -d "%CODE_BASE%" cmd
) else (
  start "" cmd /k "cd /d %CODE_BASE%"
)
goto main_menu

:open_ps_user
cls
echo Opening Windows Terminal (PowerShell - user) at %CODE_BASE% ...
where wt.exe >nul 2>&1
if %errorlevel%==0 (
  start "" wt.exe new-tab -d "%CODE_BASE%" powershell
) else (
  start "" powershell -NoExit -Command "Set-Location -LiteralPath '%CODE_BASE%'"
)
goto main_menu

:open_cmd_admin
cls
echo Opening **Admin** Windows Terminal (CMD) at %CODE_BASE% ...
where wt.exe >nul 2>&1
if %errorlevel%==0 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Process wt.exe -Verb RunAs -ArgumentList 'new-tab','-d','%CODE_BASE%','cmd'"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Process cmd.exe -Verb RunAs -WorkingDirectory '%CODE_BASE%' -ArgumentList '/k','cd /d %CODE_BASE% & echo [WT not found] Fallback to classic CMD.'"
)
goto main_menu

:open_ps_admin
cls
echo Opening **Admin** Windows Terminal (PowerShell) at %CODE_BASE% ...
where wt.exe >nul 2>&1
if %errorlevel%==0 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Process wt.exe -Verb RunAs -ArgumentList 'new-tab','-d','%CODE_BASE%','powershell'"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Process powershell.exe -Verb RunAs -WorkingDirectory '%CODE_BASE%' -ArgumentList '-NoExit'"
)
goto main_menu
