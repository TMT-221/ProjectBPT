@echo off
setlocal EnableExtensions
chcp 65001 >nul
title UniLab - Quan ly phong thi nghiem
cd /d "%~dp0" || exit /b 1

rem Cho phep truyen --no-browser neu chi muon chay may chu khong tu mo trinh duyet
set "NO_BROWSER=0"
for %%A in (%*) do (
  if /i "%%~A"=="--no-browser" set "NO_BROWSER=1"
)

rem 1. Kiem tra du tep sau khi giai nen ZIP tu GitHub
if not exist "UniLab\server.mjs" goto incomplete
if not exist "UniLab\package.json" goto incomplete
if not exist "UniLab\public\index.html" goto incomplete
if not exist "UniLab\sql\02_dataset_1200.sql" goto incomplete

rem 2. Tim Node.js va kiem tra phien ban >= 22
set "NODE_EXE="
if exist "UniLab\runtime\node.exe" set "NODE_EXE=%~dp0UniLab\runtime\node.exe"
if not defined NODE_EXE (
  for /f "delims=" %%N in ('where node 2^>nul') do (
    if not defined NODE_EXE set "NODE_EXE=%%N"
  )
)
if not defined NODE_EXE goto no_node

set "NODE_VER="
for /f "delims=" %%V in ('"%NODE_EXE%" -v 2^>nul') do set "NODE_VER=%%V"
set "NODE_MAJOR="
for /f "tokens=1 delims=v." %%M in ("%NODE_VER%") do set "NODE_MAJOR=%%M"
if not defined NODE_MAJOR goto no_node
if %NODE_MAJOR% LSS 22 goto old_node

echo.
echo   UniLab · Quản lý phòng thí nghiệm
echo   Node.js: %NODE_VER%

rem 3. Tu dong cai dat thu vien PGlite trong lan chay dau tien
if exist "UniLab\node_modules\@electric-sql\pglite\package.json" goto deps_ok
where npm >nul 2>nul
if errorlevel 1 goto no_npm
echo   Lần chạy đầu tiên: đang cài đặt thư viện PGlite (cần kết nối mạng)...
echo.
if exist "UniLab\package-lock.json" (
  call npm --prefix "UniLab" ci --no-audit --no-fund
) else (
  call npm --prefix "UniLab" install --no-audit --no-fund
)
if errorlevel 1 goto install_failed
if not exist "UniLab\node_modules\@electric-sql\pglite\package.json" goto install_failed
echo.
echo   Cài đặt thư viện hoàn tất.

:deps_ok
set "PORT=4173"
if defined LABTRACK_PORT set "PORT=%LABTRACK_PORT%"
set "PROTO=http"
if defined LABTRACK_TLS_CERT if defined LABTRACK_TLS_KEY set "PROTO=https"
set "UNILAB_URL=%PROTO%://127.0.0.1:%PORT%/"
if not defined LABTRACK_DATASET set "LABTRACK_DATASET=1200"

rem 4. Kiem tra xem UniLab da chay san hay cong dang ban
"%NODE_EXE%" -e "const u=process.argv[1],p=Number(process.argv[2]);(async()=>{try{const r=await fetch(u+'api/v1/preview',{signal:AbortSignal.timeout(1200)});if(r.ok){const j=await r.json();if(j&&j.data&&j.request_id)process.exit(2);}}catch{}const{createServer}=await import('node:net');const s=createServer();s.once('error',()=>process.exit(3));s.listen(p,'127.0.0.1',()=>s.close(()=>process.exit(0)));})();" "%UNILAB_URL%" "%PORT%" >nul 2>nul
set "PRECHECK=%errorlevel%"
if "%PRECHECK%"=="2" goto already_running
if "%PRECHECK%"=="3" goto port_busy

echo   Đang khởi tạo dữ liệu cục bộ (lần đầu có thể mất vài giây)...
echo   Địa chỉ: %UNILAB_URL%
echo   Giữ cửa sổ này mở khi sử dụng; nhấn Ctrl+C để dừng máy chủ.
echo.

rem 5. Cho may chu san sang roi tu dong mo trinh duyet
if "%NO_BROWSER%"=="1" goto start_server
start /b "" "%NODE_EXE%" -e "const u=process.argv[1];(async()=>{for(let i=0;i<120;i++){try{const r=await fetch(u+'api/v1/preview',{signal:AbortSignal.timeout(1000)});if(r.ok){const j=await r.json();if(j&&j.data&&j.request_id){const{spawn}=await import('node:child_process');spawn('rundll32.exe',['url.dll,FileProtocolHandler',u],{windowsHide:true,stdio:'ignore'}).unref();console.log('\n  Sẵn sàng — đang mở trình duyệt: '+u);return;}}}catch{}await new Promise(r=>setTimeout(r,500));}})();" "%UNILAB_URL%"

:start_server
"%NODE_EXE%" "UniLab\server.mjs"
set "EXIT_CODE=%errorlevel%"
echo.
if "%EXIT_CODE%"=="0" goto stopped_ok
echo   UniLab đã dừng do lỗi (mã %EXIT_CODE%). Xem thông báo phía trên.
pause
exit /b %EXIT_CODE%

:stopped_ok
echo   UniLab đã dừng.
exit /b 0

:already_running
echo   UniLab đang chạy sẵn tại: %UNILAB_URL%
if "%NO_BROWSER%"=="0" (
  echo   Đang mở trình duyệt...
  rundll32.exe url.dll,FileProtocolHandler "%UNILAB_URL%"
)
"%NODE_EXE%" -e "setTimeout(()=>{},1500)" >nul 2>nul
exit /b 0

:port_busy
echo.
echo   Cổng %PORT% đang được chương trình khác sử dụng.
echo   Hãy đóng chương trình đó hoặc đặt LABTRACK_PORT sang cổng khác (vd: set LABTRACK_PORT=4174) rồi chạy lại.
echo.
pause
exit /b 1

:incomplete
echo.
echo   Không tìm thấy đủ tệp nguồn của UniLab.
echo   Hãy giải nén toàn bộ tệp ZIP tải từ GitHub trước khi chạy (không mở trực tiếp bên trong ZIP).
echo   Giữ tệp Mo-UniLab.cmd ở cùng thư mục chứa thư mục UniLab.
echo.
pause
exit /b 1

:no_node
echo.
echo   Chưa tìm thấy Node.js trên máy tính này.
echo   UniLab yêu cầu Node.js phiên bản 22 trở lên (https://nodejs.org).
echo   Sau khi cài Node.js, hãy đóng cửa sổ này và mở lại Mo-UniLab.cmd.
echo.
choice /c YN /n /m "  Nhấn Y để mở trang tải Node.js (nodejs.org), hoặc N để thoát: "
if errorlevel 2 exit /b 1
rundll32.exe url.dll,FileProtocolHandler "https://nodejs.org/"
exit /b 1

:old_node
echo.
echo   Phiên bản Node.js hiện tại là %NODE_VER%, nhưng UniLab yêu cầu Node.js 22 trở lên.
echo   Vui lòng cập nhật tại https://nodejs.org rồi mở lại Mo-UniLab.cmd.
echo.
pause
exit /b 1

:no_npm
echo.
echo   Không tìm thấy lệnh npm để cài đặt thư viện cho lần chạy đầu tiên.
echo   Vui lòng cài lại Node.js 22 trở lên (kèm npm) từ https://nodejs.org.
echo.
pause
exit /b 1

:install_failed
echo.
echo   Không thể cài đặt thư viện @electric-sql/pglite.
echo   Hãy kiểm tra kết nối mạng (chỉ cần cho lần chạy đầu tiên) rồi mở lại Mo-UniLab.cmd.
echo.
pause
exit /b 1
