@ECHO OFF
setlocal enabledelayedexpansion
for %%f in (src\*.d) do (
  set /p val=<%%f
  REM echo "fullname: %%f"
  set data="%%~nf%%~xf"
  echo "%data%"

  REM echo "contents: !val!"
)