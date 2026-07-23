@echo off
setlocal

set JAVA_HOME=C:\Program Files\Java\jdk-17
set BUILD_DIR=D:\FPT\SWP\Swp_ProjectOfTeam4-main\build\web\WEB-INF
set SRC_DIR=D:\FPT\SWP\Swp_ProjectOfTeam4-main\src\java\com\diabetes\monitoring

echo [1/2] Compiling DoctorLabServlet...
set TOMCAT_LIB=C:\Users\asus\Downloads\apache-tomcat-10.1.40\apache-tomcat-10.1.40\lib

setlocal enabledelayedexpansion
set CP=%BUILD_DIR%\classes;%TOMCAT_LIB%\servlet-api.jar
for %%f in (%BUILD_DIR%\lib\*.jar) do set CP=!CP!;%%f

"%JAVA_HOME%\bin\javac.exe" -encoding UTF-8 ^
  -cp "%CP%" ^
  -d "%BUILD_DIR%\classes" ^
  "%SRC_DIR%\servlet\DoctorLabServlet.java"

if %ERRORLEVEL% NEQ 0 (
    echo ERROR compiling DoctorLabServlet
    exit /b 1
)

echo OK

echo [2/2] Copying dashboard.jsp...
copy /Y "D:\FPT\SWP\Swp_ProjectOfTeam4-main\web\WEB-INF\views\doctor-lab\dashboard.jsp" ^
        "D:\FPT\SWP\Swp_ProjectOfTeam4-main\build\web\WEB-INF\views\doctor-lab\dashboard.jsp"
echo OK

echo.
echo === ALL DONE ===
