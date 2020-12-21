:: BATCH CONFIG
@echo off
cd /d "%~dp0"
color 3f
setlocal EnableDelayedExpansion
setlocal EnableExtensions
set app_version=0.1.0
set window_title=-SSL Certificate Auto Download Tool for pfSense/ACME v!app_version!  - by aaronater10
title !window_title!
cls
goto :pre_process



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Pre-Process
:pre_process
echo:Running pre-processing...
echo:

:: Default Variables

        :: User Settings
        set user_settings=settings.config

        :: pfSense Settings
        set cfg_remote_dir=/conf/config.xml
        set acme_remote_dir=/conf/acme

        :: PuTTY Registry Store Settings
        set putty_reg=HKEY_CURRENT_USER\SoftWare\SimonTatham\PuTTY\SshHostKeys
        set valid_svr_key=n
        set svr_key_asked=n

        :: PATH Variable Locations and Settings
        set putty_path=C:\Program Files\PuTTY
        set tmp_path_update=n

        :: Key and Cert Default Values
        set "output_key="
        set "output_cert="

        :: SSH Key Phrase Default Values
        set "key_phrase="
        set "key_phrase_param="

        :: Default Download Folder
        set downloaded_items="downloaded_items"

        :: Function Variables
        set ctrl_obj=n
        set /a sw_key=0
        set /a sw_cert=0
        set /a exit_ctrl=0

        :: Error Reporting Variables
        set /a auth_mode_selected=0
        set /a download_mode_selected=0

        set send_error="error_codes\err.cmd"
        set app_report="app_report.log"
        set err_report="error_codes\err_report.log"

        :: File Dependencies
        set putty_dep="dependencies\putty-64bit-0.73-installer.msi"
        set svr_key_tool_dep="dependencies\svr-key-chk.bat"        

        :: Install Checks
        set putty_install="C:\Program Files\PuTTY\putty.exe"

        :: Main App Title
        set app_title=### SSL Certificate Auto Download Tool for pfSense/ACME v!app_version! ###

        :: Main App and Sub Instance Files
        set main_app="ssl-pfs-acme.bat"
        set run_file="run_file.bat"



:: Verify Error Code System
echo:Checking for error code system...
call :error_system_check
echo:

:: Run Install/Dependencies Checklist Verification
echo:Verifying dependencies...
call :verify_install_dependencies
echo:

:: Check for User Settings
if not exist "!user_settings!" (
    set cfg_first_time=y
    call :write_new_user_cfg
)

:: Import User Settings
echo:Importing user settings...
call :import_user_cfg
timeout 0 >nul
echo:

:: Validate Settings Configuration file integrity
call :validate_cfg_integrity

:: Validate if user added configuration in Settings File
call :validate_user_cfg !cfg_first_time!

:: Validate user configuration input integrity in Settings File
call :validate_user_cfg_input

:: Verify if any modes were selected in Settings File. Otherwise send error
call :verify_if_modes_selected

:: Verify if Server's Key is cached in PuTTY
call :verify_svr_key_cached !putty_reg! !port! !host!
goto :run_program



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Run Program
:run_program
cls
echo:!app_title!
echo:


:: Check/Run Specified Configuration & Modes from "!user_settings!"

    :: Remove Old Certificate Files Downloaded from Destination Dir in "!user_settings!"
    if "!remove_old_certs!" == "y" (
        echo:Removing old certs...
        echo:
        del /q "!dest_dir!\*" >nul 2>nul
    )

    :: Run ICMP Check from specified Host in "!user_settings!"
    if "!icmp_check!" == "y" (
        call :icmp_test !host! !icmp_numof_checks!
    )    

    :: Check to Run SSHkey or Password Mode Selected from "!user_settings!"

        :: Check if SSH Key Mode Selected
        if "!user_sshkey_mode!" == "y" (

            if "!key_pass!" == "y" (
                set key_phrase_param=-pw
                set key_phrase=!pass!
            )

            if "!acme_all_mode!" == "y" (
                call :download_certs_sshkey !putty_sessname! !port! !user! !host! !acme_remote_dir!/* !dest_dir! !key_phrase_param! !key_phrase!
                goto :end_of_program
            )
            if "!acme_specify_mode!" == "y" (
                call :download_certs_sshkey !putty_sessname! !port! !user! !host! !acme_remote_dir!/!name_obj! !dest_dir! !key_phrase_param! !key_phrase!
                goto :end_of_program
            )
            if "!cfg_specify_mode!" == "y" (
                call :download_certs_sshkey !putty_sessname! !port! !user! !host! !cfg_remote_dir! !dest_dir! !key_phrase_param! !key_phrase!
                call :parse_config !dest_dir! !name_obj!
                call :convert_b64 !dest_dir! !name_obj!
                goto :end_of_program
            )
        )

        :: Check if Password Mode Selected
        if "!user_pass_mode!" == "y" (            

            if "!acme_all_mode!" == "y" (                
                call :download_certs_pass !pass! !port! !user! !host! !acme_remote_dir!/* !dest_dir!                
                goto :end_of_program
            )
            if "!acme_specify_mode!" == "y" (
                call :download_certs_pass !pass! !port! !user! !host! !acme_remote_dir!/!name_obj! !dest_dir!
                goto :end_of_program
            )
            if "!cfg_specify_mode!" == "y" (
                call :download_certs_pass !pass! !port! !user! !host! !cfg_remote_dir! !dest_dir!
                call :parse_config !dest_dir! !name_obj!
                call :convert_b64 !dest_dir! !name_obj!
                goto :end_of_program
            )
        )       



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: End of Program
:end_of_program

:: Check if a file should be executed before exiting
if "!launch_file!" == "y" (
    echo:
    echo:Executing your file before exiting...
    echo:
    call :launch_a_file "!file_to_launch!"
    timeout 1 >nul
)

:: Exiting
cls
echo:!app_title!
echo:
echo:Process complete. Closing now...
timeout 4 >nul
exit
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: END OF PROGRAM
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: INTERNAL PROGRAM FUNCTIONS BEYOND THIS POINT!!!
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Program Functions
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Download Certs with SSH Key
:download_certs_sshkey

    :: %1 = PuTTY Session Name, %2 = Port, %3 = User, %4 = Host, %5 = Remote Source Directory, %6 = Destination Directory
    :: For SSH Key Phrase - %7 pscp password command, %8 User Password
    echo:Downloading cert files...
    echo:
    pscp -batch %7 %8 -load %1 -P %2 %3@%4:%5 %6 || (
        
        :: Send Error if Download Fails
        call !send_error! 109 "FAILED TO DOWNLOAD CERTS" "Cert Name: !name_obj!" ""

        :: Report Message to CLI
        set problem_title=*** FAILED TO DOWNLOAD CERTS ***
        set problem_subject=PLEASE CHECK YOUR SETTINGS IN THIS FILE
        set problem_item=!user_settings!
        set problem_msgbody1=Cannot authenticate or reach server, or the
        set problem_msgbody2=certificate specified is not found.
        
        call :report_err_cli "!problem_title!" "!problem_subject!" "!problem_item!" "!problem_msgbody1!" "!problem_msgbody2!"
    )
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Download Certs with Password
:download_certs_pass

    :: %1 = Password, %2 = Port, %3 = User, %4 = Host, %5 = Remote Source Directory, %6 = Destination Directory
    echo:Downloading cert files...
    echo:
    pscp -batch -pw %1 -P %2 %3@%4:%5 %6 || (

        :: Send Error if Download Fails
        call !send_error! 109 "FAILED TO DOWNLOAD CERTS" "Cert Name: !name_obj!" ""

        :: Report Message to CLI
        set problem_title=*** FAILED TO DOWNLOAD CERTS ***
        set problem_subject=PLEASE CHECK YOUR SETTINGS IN THIS FILE
        set problem_item=!user_settings!
        set problem_msgbody1=Cannot authenticate or reach server, or the
        set problem_msgbody2=certificate specified is not found.
        
        call :report_err_cli "!problem_title!" "!problem_subject!" "!problem_item!" "!problem_msgbody1!" "!problem_msgbody2!"
    )
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Dependency Verification
:verify_install_dependencies
    for /f "tokens=1-7 eol=#" %%g in (check.list) do (
        if not exist %%g (
            echo: & echo:%%j
            call %%h %%i %%j "" ""
            set "tmp_path_update=y"
        )
        if not exist %%g (
            call %%k %%l %%m "" ""
            call :cannot_run !err_report!
        ) else (            
            if "!tmp_path_update!" == "y" (
                set PATH=!PATH!;!putty_path!
                timeout 1 >nul
            )
            echo:FOUND %%g
        )
    )
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Import User Settings Config
:import_user_cfg
    for /f "eol=# delims=" %%I in (!user_settings!) do (
        set %%I
    )
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Verify if any Modes were Selected in '!user_settings!'
:verify_if_modes_selected
if "!user_sshkey_mode!" == "y" set /a auth_mode_selected=!auth_mode_selected!+1
if "!user_pass_mode!" == "y" set /a auth_mode_selected=!auth_mode_selected!+1

if "!acme_all_mode!" == "y" set /a download_mode_selected=!auth_mode_selected!+1
if "!acme_specify_mode!" == "y" set /a download_mode_selected=!auth_mode_selected!+1
if "!cfg_specify_mode!" == "y" set /a download_mode_selected=!auth_mode_selected!+1

:: Authentication Modes Check
    if not !auth_mode_selected! gtr 0 (
        call !send_error! 107 "NO AUTHENTICATION MODE SELECTED" "user_sshkey_mode, user_pass_mode" "Please pick one of theses modes:"
        
        :: Report Message to CLI
        set problem_title=*** NO AUTHENTICATION MODE SELECTED FROM '!user_settings!' FILE ***
        set problem_subject=PLEASE PICK ONE OF THESE AUTHENTICATION MODES
        set problem_item=user_sshkey_mode, user_pass_mode
        set "problem_msgbody1="
        set "problem_msgbody2="

        call :report_err_cli "!problem_title!" "!problem_subject!" "!problem_item!" "!problem_msgbody1!" "!problem_msgbody2!"
        goto :eof
    )

:: Download Modes Check
    if not !download_mode_selected! gtr 0 (
        call !send_error! 108 "NO DOWNLOAD MODE SELECTED" "acme_all_mode, acme_specify_mode, cfg_specify_mode" "Please pick one of theses modes:"

        :: Report Message to CLI
        set problem_title=*** NO DOWNLOAD MODE SELECTED FROM '!user_settings!' FILE ***
        set problem_subject=PLEASE PICK ONE OF THESE DOWNLOAD MODES
        set problem_item=acme_all_mode, acme_specify_mode, cfg_specify_mode
        set "problem_msgbody1="
        set "problem_msgbody2="

        call :report_err_cli "!problem_title!" "!problem_subject!" "!problem_item!" "!problem_msgbody1!" "!problem_msgbody2!"
        goto :eof
    )
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Verify if Server Key Cached in PuTTY Registry Location
:verify_svr_key_cached

:recheck_svr_key

reg query %1 /v /f %2:%3 >nul && set "valid_svr_key=y" || (
    
    if "!svr_key_asked!" == "y" (
    
    :: Send Error
    call !send_error! 110 "CANNOT FIND REMOTE SERVER KEY" "" ""

    :: Report Message to CLI
    set problem_title=*** THE REMOTE SERVER KEY WAS NOT SAVE OR COUND NOT BE FOUND IN REGISTRY ***
    set problem_subject=IF YOU DO NOT TRUST THE REMOTE SERVER THEN SELECT
    set problem_item='CANCEL' or 'NO' AND CLOSE PuTTY WINDOW
    set problem_msgbody1=PLEASE SAVE REMOTE SERVER KEY WHEN PROMPTED FROM PuTTY AND SELECT 'YES'
    set problem_msgbody2=PuTTY will prompt you with a window titled 'PuTTY Security Alert' to save the key.

    call :report_err_cli "!problem_title!" "!problem_subject!" "!problem_item!" "!problem_msgbody1!" "!problem_msgbody2!"
    )

    start /min "" "!svr_key_tool_dep!" %1 %2 %3
    putty -P !port! !host!

    type nul>"dependencies\instance.close"
    taskkill /F /T /IM "putty.exe" 2>nul >nul

    set "svr_key_asked=y"
    )

timeout 0 >nul

if not "!valid_svr_key!" == "y" (   
    goto :recheck_svr_key
)
goto:eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Configuration File Integrity Check
:validate_cfg_integrity
set /a cfg_checksum=0
set /a checksum_loop=0

    :: Verify pre-defined list of required configuration setting parameters
    for /f "eol=# delims==" %%I in (!user_settings!) do (

        if "%%I" == "user_sshkey_mode" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "key_pass" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "user_pass_mode" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "acme_all_mode" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "acme_specify_mode" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "cfg_specify_mode" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "name_obj" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "putty_sessname" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "host" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "port" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "user" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "pass" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "dest_dir" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "launch_file" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "file_to_launch" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "icmp_check" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "icmp_numof_checks" set /a cfg_checksum=!cfg_checksum! + 1
        if "%%I" == "remove_old_certs" set /a cfg_checksum=!cfg_checksum! + 1
        
        set /a checksum_loop=!checksum_loop! + 1

        if not !cfg_checksum! equ !checksum_loop! (
            set bad_syntax_items=!bad_syntax_items!%%I,
            set /a checksum_loop=!checksum_loop! - 1
        )
    )

:: Report Message if Checksum Bad
if not !cfg_checksum! equ 18 (

    :: Send Error
    call !send_error! 104 "BAD SYNTAX ITEMS" !bad_syntax_items! ""

    :: Report Message to CLI
    set problem_title=*** THE '!user_settings!' FILE SYNTAX IS FLAWED ***
    set problem_subject=ITEMS WITH BAD SYNTAX
    set problem_item=!bad_syntax_items!
    set problem_msgbody1=-Please fix the "!user_settings!" file before continuing, or
    set problem_msgbody2=generate a new file by deleting it and re-launching the tool.

    call :report_err_cli "!problem_title!" "!problem_subject!" "!problem_item!" "!problem_msgbody1!" "!problem_msgbody2!"
)
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Validate User Settings Contains Configuration
:validate_user_cfg
    for /f "tokens=1 eol=# delims==" %%I in (!user_settings!) do (

        if "!%%I!" == "" (
            set bad_cfg_list=!bad_cfg_list!%%I,
            set bad_cfg_found=y
        )
    )

:: Report Message if No Configuration Found
if "!bad_cfg_found!" == "y" (

    :: Send Error if Not First Time Creating User CFG
    if not "%1" == "y" (
    call !send_error! 105 "NO INPUT IN ITEMS" "!bad_cfg_list!" ""
    )

    :: Report Message to CLI
    set problem_title=*** PLEASE ENTER YOUR SETTINGS IN THE "!user_settings!" FILE FIRST BEFORE CONTINUING ***
    set problem_subject=ITEMS WITH NO CONFIGURATION
    set problem_item=!bad_cfg_list!
    set "problem_msgbody1="
    set "problem_msgbody2="

    call :report_err_cli "!problem_title!" "!problem_subject!" "!problem_item!" "!problem_msgbody1!" "!problem_msgbody2!"
)
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Validate User Settings Does Not Contain Bad Input
:validate_user_cfg_input

    :: Check for Spaces at Front and End of Setting's Input
        for /f "tokens=1-2 eol=# delims==" %%I in (!user_settings!) do (

            set cfg_input=%%J

            if "!cfg_input:~0,1!" == " " (
                set bad_cfg_list=!bad_cfg_list!%%I,
                set bad_cfg_input=y
                set bad_input_spaces_front=y
            ) else (

                if "!cfg_input:~-1!" == " " (
                    set bad_cfg_list=!bad_cfg_list!%%I,
                    set bad_cfg_input=y
                    set bad_input_spaces_end=y
                )
            )
        )

:: Check Message Type
if "!bad_input_spaces_front!" == "y" set bad_input_msg=ITEMS CONTAIN A SETTING THAT HAS "SPACES" IN FRONT OF IT
if "!bad_input_spaces_end!" == "y" set bad_input_msg=ITEMS CONTAIN A SETTING THAT HAS "SPACES" AT END OF IT

:: Report Message if CFG Input was Bad
if "!bad_cfg_input!" == "y" (

    :: Send Error
    call !send_error! 106 "INVALID INPUT IN ITEMS" "!bad_cfg_list!" "!bad_input_msg!"

    :: Report Message to CLI
    set problem_title=*** PLEASE FIX YOUR SETTINGS IN THE "!user_settings!" FILE FIRST BEFORE CONTINUING ***
    set problem_subject=!bad_input_msg!
    set problem_item=!bad_cfg_list!
    set "problem_msgbody1="
    set "problem_msgbody2="

    call :report_err_cli "!problem_title!" "!problem_subject!" "!problem_item!" "!problem_msgbody1!" "!problem_msgbody2!"
)
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Generate New Directory
:gen_new_dir
md %1
timeout 0 >nul
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Write New User Config
:write_new_user_cfg
cls
echo:Generating "!user_settings!" file because none found...
type nul>!user_settings!
timeout 4 >nul

(
echo:###################################
echo:# Authentication Mode - Default is "user_sshkey_mode"
echo:
echo:user_sshkey_mode=y
echo:key_pass=n
echo:
echo:user_pass_mode=n
echo:
echo:
echo:###################################
echo:# Download Mode - Default is "acme_all_mode"
echo:
echo:acme_all_mode=y
echo:acme_specify_mode=n
echo:cfg_specify_mode=n
echo:
echo:
echo:###################################
echo:# Cert/Key Name - Only needed if using "acme_specify_mode" or "cfg_specify_mode"
echo:
echo:name_obj=certname
echo:
echo:
echo:###################################
echo:# Gateway/Download Configuration Settings - 'dest_dir=".\downloaded_items"' default download directory
echo:# To change directory they're downloaded to, change 'dest_dir=".\downloaded_items"' to 'dest_dir="your folder path"'
echo:
echo:putty_sessname=
echo:
echo:host=
echo:port=
echo:user=
echo:pass=your-ssh-or-key-password
echo:dest_dir=".\downloaded_items"
echo:
echo:
echo:###################################
echo:# Launch a File at End of Script - Default is OFF
echo:
echo:launch_file=n
echo:file_to_launch=filename
echo:
echo:
echo:###################################
echo:# Ping Test Host till X Successful Checks before Running Script - Default is YES, 10 times
echo:
echo:icmp_check=y
echo:icmp_numof_checks=10
echo:
echo:
echo:###################################
echo:# Clean Old Downloaded Files Each Time Script Runs - Default is YES
echo:
echo:remove_old_certs=y
)>>!user_settings!
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Install Program
:install_program
        call %1
        timeout 1 >nul
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Tool Cannot Continue
:cannot_run
cls
echo:
echo:Error report was generated in %1 file.
echo:TOOL CANNOT CONTINUE. Program will now exit...
timeout 20
exit


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Error Code System Check
:error_system_check
    if not exist !send_error! (
        
        type nul>"error_prompt.vbs"
        timeout 0 >nul

        if not exist "!app_report!" type nul>!app_report!
        timeout 0 >nul

        (
        echo:ERROR CODE 100: Error Checking System Not Found - !date! - !time!
        echo:App-SECTION:Pre_Process
        echo:
        )>>!app_report!

        (
        echo:msgbox "ERROR CODE 100: Error Checking System Not Found - App-SECTION:Pre_Process",16,"ERROR CODE 100: Error Checking System Not Found"
        )>>"error_prompt.vbs"
        timeout 0 >nul

        "error_prompt.vbs"
        timeout 0 >nul        
        del /q "error_prompt.vbs"

        call :cannot_run !app_report!
    ) else echo:FOUND: Error Code System
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Pull Base64 Cert and Key Data from "config.xml"
:: %1 = Destination Directory, %2 = Name Object
:parse_config
echo:
echo:Converting data...
echo:

    for /f "tokens=1" %%g in ('type "%1\config.xml"') do (

        if "%%g"=="<descr><[CDATA[%2]]></descr>" (
            set ctrl_obj=y
        )

            if "!ctrl_obj!"=="y" (
                
                if !sw_key! equ 1 set output_key=%%g
                if !sw_cert! equ 2 set output_cert=%%g
            
            set /a sw_key=!sw_key!+1
            set /a sw_cert=!sw_cert!+1
            set /a exit_ctrl=!exit_ctrl!+1
            )
        
        if !exit_ctrl! equ 3 goto :parse_output

    )

:parse_output

    :: Parse Cert & Key variables
        set output_key=!output_key:~5,-6!
        set output_cert=!output_cert:~5,-6!
    
    :: Dump to Base64 files
        echo:!output_key!>"%1\key.b64"
        echo:!output_cert!>"%1\cert.b64"
        timeout 3 >nul
        del /q "%1\config.xml"
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Convert Base64 to Key and Cert files
:: %1 = Destination Directory, %2 = Name Object
:convert_b64
    certutil -decode "%1\key.b64" "%1\%2.key"
    certutil -decode "%1\cert.b64" "%1\%2.crt"

    timeout 3 >nul

    del /q "%1\key.b64" "%1\cert.b64"
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: ICMP Check
:icmp_test
echo:Waiting on %2 successful connection checks to host...

set /a icmp_loop_inc=0

:icmp_loop

    timeout 1 >nul & :: 1s Loop Delay
    
    ping %1 -n 1 >nul 2>nul && (
        set /a icmp_loop_inc=!icmp_loop_inc! + 1
        echo:CONNECTION CHECK !icmp_loop_inc!/%2
    ) || (
        set /a icmp_loop_inc=0
        echo:NO CONNECTION TO HOST RETRYING...
    )

    if not !icmp_loop_inc! geq %2 (
        goto :icmp_loop
    ) else (
        echo:
        goto :eof
    )
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Execute a File to Launch from settings.config
:launch_a_file

:: Create new sub instance to run file
type nul>"run_file.bat"
timeout 0 >nul

:: Write File Launcher
(
echo:@echo off
echo:cd /d "%%~dp0"
echo:setlocal EnableDelayedExpansion
echo:setlocal EnableExtensions
echo:title Loading file %1
echo:cmd /c %1 ^>nul 2^>nul ^|^| ^(
echo:echo:Could not find "!file_to_launch!" to launch - on !date! at !time! ^>^>"failed_file_launch.log"
echo:^)
echo:del /q "run_file.bat" ^& timeout 0 ^>nul ^& exit
)>>run_file.bat

:: Run File Launcher
timeout 0 >nul
start "" "run_file.bat"
goto :eof


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Error Reporting in CLI Window
:: %1 = Problem Title, %2 = Problem Subject, %3 = Problem Item, %4 = Optional Message Body Line 1, %5 = Optional Message Body Line 2
:report_err_cli
cls
echo:
echo:%1
echo:
echo:
if not %4 == "" (
    echo:%4
    echo:%5
    echo:
    echo:
)
echo:%2: %3
echo:
echo:
echo:Program will now exit...
timeout 20
exit
:: CODE FORMAT TO USE FOR SENDING TO THIS FUNCTION
::
::  :: Report Message to CLI
::  set problem_title=*** THE '!user_settings!' FILE SYNTAX IS FLAWED ***
::  set problem_subject=ITEMS WITH BAD SYNTAX
::  set problem_item=!bad_syntax_items!
::  set problem_msgbody1=-Please fix the "!user_settings!" file before continuing, or
::  set problem_msgbody2=generate a new file by deleting it and re-launching the tool.
::
::  call :report_err_cli "!problem_title!" "!problem_subject!" "!problem_item!" "!problem_msgbody1!" "!problem_msgbody2!"