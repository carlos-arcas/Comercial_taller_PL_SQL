@echo off
setlocal EnableExtensions

echo =====================================
echo INICIALIZANDO REPOSITORIO GIT
echo =====================================

REM Comprobar si ya es repo git
git rev-parse --is-inside-work-tree >nul 2>&1
if %errorlevel%==0 (
    echo Este directorio ya es un repositorio Git.
    pause
    exit /b 0
)

REM Inicializar git
echo.
echo Inicializando git...
git init
if not %errorlevel%==0 (
    echo ERROR: git init ha fallado. ¿Tienes Git instalado y en el PATH?
    pause
    exit /b 1
)

REM Crear rama main
git branch -M main >nul 2>&1

REM Crear .gitignore si no existe
if not exist .gitignore (
    echo Creando .gitignore...
    (
        echo .env
        echo wallet/
        echo __pycache__/
        echo *.pyc
        echo .venv/
        echo .pytest_cache/
        echo dist/
        echo build/
        echo .idea/
        echo .vscode/
    ) > .gitignore
)

REM Primer commit
echo.
echo Añadiendo archivos...
git add .
git commit -m "Initial commit"

echo.
echo =====================================
echo REPOSITORIO INICIALIZADO
echo =====================================
echo.
echo Ahora enlaza con GitHub (si aun no lo has hecho):
echo   git remote add origin https://github.com/carlos-arcas/Comercial_taller_PL_SQL.git
echo   git push -u origin main
echo.
pause
exit /b 0