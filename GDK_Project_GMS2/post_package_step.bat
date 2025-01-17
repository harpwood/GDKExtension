@echo off
:: RK - this is useful for debugging what variables are being passed in from GMS2
:: set
:: echo #########################################################################################################################

:: ensure that YYPLATFORM_option_windows_copy_exe_to_dest is set to True
if not "%YYPLATFORM_option_windows_copy_exe_to_dest%" == "True" goto error_ensure_windows_copy_exe_to_dest

:: Check if GDK is installed
if not exist "C:\Program Files (x86)\Microsoft GDK\Command Prompts\GamingDesktopVars.cmd" goto error_install_GDK

:: Setup the GDK Environment (force version Update Oct 2021)
set GRDKEDITION=211000
call "C:\Program Files (x86)\Microsoft GDK\Command Prompts\GamingDesktopVars.cmd" GamingDesktopVS2019
if ERRORLEVEL 1 (
  goto error_wrong_GDK
)

:: Ensure the runner is called the correct thing
pushd %YYoutputFolder%

:: Resolve {project_name.exe} if used
call :getfilename "%YYPLATFORM_option_windows_executable_name%"

:: Rename the runner to the executable name (GameOptions->Windows->Executable Name)
if exist Runner.exe move Runner.exe "%filename%.exe"

:: Copy the required dll libraries from the user's GDK installation folder
if not exist "Party.dll" copy "%GameDKLatest%\GRDK\ExtensionLibraries\PlayFab.Party.Cpp\Redist\CommonConfiguration\neutral\Party.dll" "Party.dll"
if not exist "PartyXboxLive.dll" copy "%GameDKLatest%\GRDK\ExtensionLibraries\PlayFab.PartyXboxLive.Cpp\Redist\CommonConfiguration\neutral\PartyXboxLive.dll" "PartyXboxLive.dll"
if not exist "XCurl.dll" copy "%GameDKLatest%\GRDK\ExtensionLibraries\Xbox.XCurl.API\Redist\CommonConfiguration\neutral\XCurl.dll" "XCurl.dll"
popd

:: generate map
makepkg genmap /f %YYoutputFolder%\layout.xml /d %YYoutputFolder%
if ERRORLEVEL 1 goto exitError
:: generate package
mkdir %YYoutputFolder%\MSIXVC
makepkg pack /f %YYoutputFolder%\layout.xml /d %YYoutputFolder% /pd %YYoutputFolder%\MSIXVC -pc > "%YYtempFolderUnmapped%\makepkg.out"
if ERRORLEVEL 1 goto exitError
:: can be useful for debugging problems
:: type "%YYtempFolderUnmapped%\makepkg.out"
:: get the application name, this is horrible but should find the game appname to use for launching
pushd "%YYtempFolderUnmapped%"
for /f "tokens=*" %%a in (makepkg.out) do (
  (echo %%a | findstr /i /c:"Successfully created package '" >nul) && (set APPNAME=%%a) 
)
popd
set MSIXVC=%APPNAME:~30,-2%
call :getfilename "%MSIXVC%"
call :getdirectory "%YYtargetFile%"
:: It will copy the entire directory 
xcopy /s /y "%YYoutputFolder%\MSIXVC" "%directory%%filename%-pkg\"
if ERRORLEVEL 1 goto exitError
:: everything finished OK
echo.
echo "################################ Finished Creating Package ################################"
echo "Output folder: %directory%%filename%-pkg"
echo "NOTE: You will need both .MSIXVC and .EKB to upload the package to the MS Partner Center"
:: ----------------------------------------------------------------------------------------------------
:: exit /b 255
:: ----------------------------------------------------------------------------------------------------
:exit
exit /b 0
:: ----------------------------------------------------------------------------------------------------
:exitError
echo "ERROR : Unable to complete"
exit /b 1
:: ----------------------------------------------------------------------------------------------------
:: If the GDK is not installed then prompt the user to install it
:error_install_GDK
echo "Goto https://github.com/microsoft/GDK/releases/tag/October_2021_Republish to install the GDK"
exit /b 1
:: ----------------------------------------------------------------------------------------------------
:: If the required GDK verison is not installed 
:error_wrong_GDK
echo "Wrong GDK version, goto https://github.com/microsoft/GDK/releases/tag/October_2021_Republish"
exit /b 1
:: ----------------------------------------------------------------------------------------------------
:: Ensire that windows option for copy exe to dest is enabled
:error_ensure_windows_copy_exe_to_dest
echo "The Game Options -> Windows -> General -> Copy exe to output folder MUST be enabled."
exit /b 1
:: ----------------------------------------------------------------------------------------------------
:: Get the filename from the given parameter
:getfilename
set filename=%~n1
goto :eof
:: ----------------------------------------------------------------------------------------------------
:: Get the filename from the given parameter
:getfilenameext
set filenameext=%~nx1
goto :eof
:: ----------------------------------------------------------------------------------------------------
:: Get the directory and filename (no extension)from the given parameter
:getdirectoryfilename
set directoryfilename=%~dn1
goto :eof
:: ----------------------------------------------------------------------------------------------------
:: Get the filename from the given parameter
:getfilename
:: First we remove the extension (since dev could have missed it in the IDE)
set filename=%~n1
:: Resolve ${project_name} if it was used
call set filename=%%filename:${project_name}=%YYMACROS_project_name%%%
goto :eof