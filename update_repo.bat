@echo off
echo ================================
echo ACTUALIZANDO REPOSITORIO GIT
echo ================================

REM Comprobar si estamos en repo git
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo ERROR: Esta carpeta no es un repositorio git.
    pause
    exit /b
)

REM Añadir todos los cambios
echo.
echo Añadiendo archivos...
git add .

REM Pedir mensaje de commit
echo.
set /p mensaje="Escribe el mensaje del commit: "

REM Si no se escribe nada, usar mensaje automático
if "%mensaje%"=="" (
    set mensaje=Update automatico
)

REM Hacer commit
git commit -m "%mensaje%"

REM Hacer push a la rama actual
echo.
echo Haciendo push...
git push

echo.
echo ================================
echo REPOSITORIO ACTUALIZADO
echo ================================
pause