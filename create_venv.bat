@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

REM Проверяем, что прийдут аргументы
if "%~1"=="" (
    echo Usage: create_venv.bat ProjectName PythonVersion(3.8^|3.10^|3.12)
    goto :eof
)
if "%~2"=="" (
    echo Usage: create_venv.bat ProjectName PythonVersion(3.8^|3.10^|3.12)
    goto :eof
)

set PROJECT_NAME=%1
set PYTHON_VER=%2

REM Определяем путь к папке со скриптом
set SCRIPT_DIR=%~dp0

REM Путь к ini файлу с настройками
set CONFIG_FILE=%SCRIPT_DIR%config.ini

REM Проверяем наличие config.ini
if not exist "%CONFIG_FILE%" (
    echo ERROR: Configuration file config.ini not found in %SCRIPT_DIR%
    echo Please create config.ini with proper settings. See example below:
    echo [Paths]
    echo BASE_VENV_DIR=%%USERPROFILE%%\Envs
    echo PYTHON38=%%USERPROFILE%%\AppData\Local\Programs\Python\Python38\python.exe
    echo PYTHON310=%%USERPROFILE%%\AppData\Local\Programs\Python\Python310\python.exe
    echo PYTHON312=%%USERPROFILE%%\AppData\Local\Programs\Python\Python312\python.exe
    goto :eof
)

REM Функция для чтения из ini файла (разбор строки в секции [Paths])
for /f "usebackq tokens=1,* delims==" %%A in (`findstr /i "^%PYTHON_VER%" "%CONFIG_FILE%"`) do (
    set "PYTHON_PATH=%%B"
)

REM Читаем BASE_VENV_DIR
for /f "usebackq tokens=1,* delims==" %%A in (`findstr /i "^BASE_VENV_DIR" "%CONFIG_FILE%"`) do (
    set "BASE_VENV_DIR=%%B"
)

REM Проверяем, что прочитались нужные переменные
if "%PYTHON_PATH%"=="" (
    echo Error: Python path for version %PYTHON_VER% not found in config.ini
    goto :eof
)
if "%BASE_VENV_DIR%"=="" (
    echo Error: BASE_VENV_DIR not found in config.ini
    goto :eof
)

REM Expand environment variables in paths (like %USERPROFILE%)
call set "PYTHON_EXE=%PYTHON_PATH%"
call set "BASE_VENV_DIR=%BASE_VENV_DIR%"

REM Проверка существования python
if not exist "%PYTHON_EXE%" (
    echo Python executable not found: %PYTHON_EXE%
    goto :eof
)

REM Полный путь для виртуального окружения
set VENV_PATH=%BASE_VENV_DIR%\%PROJECT_NAME%_%PYTHON_VER%

echo Creating virtual environment at: %VENV_PATH% using %PYTHON_EXE%

REM Создаём папку для виртуального окружения, если её нет
if not exist "%BASE_VENV_DIR%" (
    mkdir "%BASE_VENV_DIR%"
)

REM Создаём виртуальное окружение
"%PYTHON_EXE%" -m venv "%VENV_PATH%"

if ERRORLEVEL 1 (
    echo Failed to create virtual environment.
    goto :eof
)

echo Virtual environment created successfully!

REM Создаём файл с инструкциями для PyCharm
set INSTR_FILE=%SCRIPT_DIR%pycharm_venv_instructions_%PROJECT_NAME%.txt

(
echo Instructions to configure PyCharm with virtual environment:
echo.
echo 1. Open PyCharm settings (File → Settings → Project: %PROJECT_NAME% → Python Interpreter).
echo 2. Click on the gear icon ⚙️ → Add.
echo 3. Choose “Existing environment”.
echo 4. Click “...” and select the interpreter:
echo    %VENV_PATH%\Scripts\python.exe
echo 5. Click OK and apply the changes.
echo.
echo Note:
echo - Your virtual environment is located at:
echo    %VENV_PATH%
echo - To activate manually in cmd, run:
echo    %VENV_PATH%\Scripts\activate.bat
) > "%INSTR_FILE%"

REM Открываем файл инструкций
start notepad "%INSTR_FILE%"

ENDLOCAL
