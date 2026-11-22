@echo off
setlocal
cd /d "%~dp0" || exit /b 1
if not exist "server.mjs" goto incomplete
if not exist "package.json" goto incomplete
if not exist "sql\01_schema.sql" goto incomplete
if not exist "sql\02_dataset_1200.sql" goto incomplete
if not exist "public\index.html" goto incomplete
where node.exe >nul 2>&1
if errorlevel 1 (
  echo Can cai Node.js 24 de chay LabTrack.
  pause
  exit /b 1
)
if not exist "node_modules\@electric-sql\pglite\package.json" goto dependencies
if not defined LABTRACK_PORT set "LABTRACK_PORT=4173"
if not defined LABTRACK_DATASET set "LABTRACK_DATASET=1200"
set "labtrack_protocol=http"
if defined LABTRACK_TLS_CERT if defined LABTRACK_TLS_KEY set "labtrack_protocol=https"
echo LabTrack: mo %labtrack_protocol%://127.0.0.1:%LABTRACK_PORT%/ sau khi may chu khoi dong.
echo Giu cua so nay mo trong khi su dung. Bam Ctrl+C de dung.
node "%~dp0server.mjs"
set "labtrack_exit=%errorlevel%"
if not "%labtrack_exit%"=="0" pause
exit /b %labtrack_exit%

:incomplete
echo Thieu tep cua LabTrack. Khong chay truc tiep tu trong tep ZIP.
echo Nhan chuot phai vao tep ZIP, chon Extract All ^(Giai nen tat ca^),
echo roi mo Mo-LabTrack.cmd trong thu muc da giai nen.
pause
exit /b 1

:dependencies
echo Chua cai thu vien PGlite. Can mang cho lan cai dat dau tien.
echo Trong thu muc nay, chay: npm.cmd ci
echo Sau do mo lai Mo-LabTrack.cmd.
pause
exit /b 1
