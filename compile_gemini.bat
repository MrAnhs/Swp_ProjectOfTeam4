@echo off
set CLASSES=D:\FPT\SWP\Swp_ProjectOfTeam4-main\build\web\WEB-INF\classes
set LIB=D:\FPT\SWP\Swp_ProjectOfTeam4-main\build\web\WEB-INF\lib
set TOMCAT_LIB=C:\Users\asus\Downloads\apache-tomcat-10.1.40\apache-tomcat-10.1.40\lib
set SRC=D:\FPT\SWP\Swp_ProjectOfTeam4-main\src\java

echo [1/3] Compiling util GeminiIntegration...
javac -encoding UTF-8 -cp "%CLASSES%;%LIB%\*;%TOMCAT_LIB%\*" -d "%CLASSES%" "%SRC%\com\diabetes\monitoring\util\GeminiIntegration.java"
if %ERRORLEVEL% NEQ 0 (echo ERROR compiling util GeminiIntegration & goto :end) else (echo OK)

echo [2/3] Compiling doctor util GeminiIntegration...
javac -encoding UTF-8 -cp "%CLASSES%;%LIB%\*;%TOMCAT_LIB%\*" -d "%CLASSES%" "%SRC%\com\diabetes\monitoring\doctor\util\GeminiIntegration.java"
if %ERRORLEVEL% NEQ 0 (echo ERROR compiling doctor GeminiIntegration & goto :end) else (echo OK)

echo [3/3] Compiling AIChatServlet...
javac -encoding UTF-8 -cp "%CLASSES%;%LIB%\*;%TOMCAT_LIB%\*" -d "%CLASSES%" "%SRC%\com\diabetes\monitoring\servlet\AIChatServlet.java"
if %ERRORLEVEL% NEQ 0 (echo ERROR compiling AIChatServlet & goto :end) else (echo OK)

echo.
echo === ALL COMPILED SUCCESSFULLY ===

:end
