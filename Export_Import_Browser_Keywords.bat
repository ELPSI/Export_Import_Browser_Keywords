@ECHO OFF
CHCP 65001 >NUL
CD /D %~DP0
SETLOCAL ENABLEDELAYEDEXPANSION
SET CURRENT_PATH=%~DP0
IF "%1"=="" (
	SET "sqlPath=%~DP0Output\keywords.sql"
) ELSE (
	SET "sqlPath=%~F1"
)
SET "sqlPath=%sqlPath:\=/%"
SET "scriptPath=%~DP0Output\ExportEdgeSqlScript"
IF EXIST "BrowserPath.ini" (
	FOR /F "TOKENS=1,2 DELIMS==" %%i IN (BrowserPath.ini) DO (
		SET "%%i=%%j"
		IF ERRORLEVEL 1 (
			ECHO;&ECHO Can not read BrowserPath.ini.
			PAUSE && EXIT
		)	
	)
) ELSE (
	ECHO;&ECHO BrowserPath.ini not exist.
	PAUSE && EXIT
)

IF NOT EXIST "%oldPath%\Web Data" (
	ECHO;&ECHO Web Data on oldPath not existed, please modify BrowserPath.ini.
	PAUSE && EXIT
)
IF NOT EXIST "%newPath%\Web Data" (
	ECHO;&ECHO Web Data on newPath not existed, please modify BrowserPath.ini.
	PAUSE && EXIT
)
IF NOT EXIST "%~DP0Output" md "%~DP0Output"

ECHO;&CHOICE /C EI /M "Do you want to export or import edge keywords?"
IF %ERRORLEVEL%==1 (
	CALL :EXPORT_KEYWORDS
) ELSE (
	CALL :IMPORT_KEYWORDS
)
PAUSE
EXIT


:EXPORT_KEYWORDS
ECHO;&ECHO Exporting edge keywords now ...
PUSHD
CD /D "%oldPath%"
ECHO .output "%sqlPath%" > "%scriptPath%"
ECHO .dump keywords >> "%scriptPath%"
"%CURRENT_PATH%sqlite3.exe" -init "%scriptPath%" "Web Data" .exit
"%CURRENT_PATH%sqlite3.exe" -csv "Web Data" "SELECT short_name, keyword, url FROM keywords;" > "%CURRENT_PATH%Output\keywords.csv"
POPD
DEL %scriptPath%
ECHO;&ECHO Finish exporting.
GOTO :EOF

:IMPORT_KEYWORDS
TASKLIST /FI "IMAGENAME EQ msedge.exe" 2>NUL | FIND /I /N "msedge.exe">NUL
IF %ERRORLEVEL%==0 (
	ECHO;&ECHO Edge is running, do you want to force close it?	
) ELSE (
	ECHO;&ECHO Edge is not running.
	GOTO DO_IMPORT
)
ECHO;&CHOICE /M "Please input Y or N: "
	IF %ERRORLEVEL%==1 (
		TASKKILL/IM msedge.exe /F >NUL 2>NUL 
	) ELSE (
		GOTO IMPORT_KEYWORDS
	)

:DO_IMPORT
ECHO;&ECHO Importing edge keywords now ...
PUSHD
CD /D "%newPath%"
ECHO DROP TABLE IF EXISTS keywords;> "%scriptPath%"
ECHO .read "%sqlPath%">> "%scriptPath%"
COPY "Web Data" "Web Data.backup"
"%CURRENT_PATH%sqlite3.exe" -init "%scriptPath%" "Web Data" .exit
POPD
DEL %scriptPath%
ECHO;&ECHO Finish importing.
GOTO :EOF
