@echo off
setlocal
where py >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  echo Installing all-in-one-infer with the Python launcher...
  py -3 -m pip install --upgrade all-in-one-infer soundfile
  py -3 "%~dp0allin1_bridge.py" --probe
  goto :done
)
where python >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  echo Installing all-in-one-infer with python...
  python -m pip install --upgrade all-in-one-infer soundfile
  python "%~dp0allin1_bridge.py" --probe
  goto :done
)
echo Python 3.9+ was not found. Install Python, then run this file again.
:done
echo.
echo First analysis will download model checkpoints and can take a while.
pause
