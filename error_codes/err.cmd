::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Format Parameters
set p1=%1
set p2=%2
set p3=%3
set p4=%4
set p5=%5
set p6=%6
set p7=%7
set p8=%8
set p9=%9

:: Strip Quotes Out
for /l %%l in (1,1,9) do (
    set p%%l=!p%%l:"=!
)


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: DB of Error Codes and Messages
:db_check
(
if !p1! equ 101 set err_msg=ERROR CODE 101: Putty Installer Not Found& set match_chk=1
if !p1! equ 102 set err_msg=ERROR CODE 102: Cached Server Key Check Tool Not Found& set match_chk=1
if !p1! equ 103 set err_msg=ERROR CODE 103: Putty App Failed to Install& set match_chk=1
if !p1! equ 104 set err_msg=ERROR CODE 104: 'settings.config' File syntax is flawed& set match_chk=1
if !p1! equ 105 set err_msg=ERROR CODE 105: 'settings.config' Has missing settings& set match_chk=1
if !p1! equ 106 set err_msg=ERROR CODE 106: 'settings.config' Has invalid input& set match_chk=1
if !p1! equ 107 set err_msg=ERROR CODE 107: No authentication mode selected in 'settings.config'& set match_chk=1
if !p1! equ 108 set err_msg=ERROR CODE 108: No download mode selected in 'settings.config'& set match_chk=1
if !p1! equ 109 set err_msg=ERROR CODE 109: Failed to download certs. Cannot authenticate or reach server, or specified cert is not found& set match_chk=1
if !p1! equ 110 set err_msg=ERROR CODE 110: Remote Server Key was not saved or could not be located in Registry Cache& set match_chk=1
)


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Check if Error Code Match Found

if not !match_chk! equ 1 (
    set /a recheck=!recheck!+1
    if !recheck! equ 5 cls & echo:ERROR CODE: "!p1!" NOT FOUND IN DB^^! & echo:Program Location: !p2! & goto :eof
    goto :db_check
)


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Report Error Message

:: Create Files

    :: Create Error Log File
    if not exist "error_codes\err_report.log" type nul>"error_codes\err_report.log"

    :: Create Error Prompt File
    type nul>"error_codes\error_prompt.vbs"

    timeout 0 >nul & :: DELAY TIMER for File Creation


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Dump to Log & Prompt

    :: Dump to Log
    echo:!p2!: !date! - !time!>>error_codes\err_report.log
    echo:Details: !err_msg! - !p4! '!p3!'>>error_codes\err_report.log
    echo:>>error_codes\err_report.log

    :: Dump to VBS Prompt
    (
    echo:msgbox "Details: !err_msg!: !p4! -!p3!",16,"!err_msg:~0,15! !p2!"
    )>>"error_codes\error_prompt.vbs"

    timeout 0 >nul & :: DELAY TIMER for Writing Error to File

    :: Launch VBS Error Prompt File
    "error_codes\error_prompt.vbs"
    timeout 0 >nul

    :: Remove VBS Error Prompt File
    del /q "error_codes\error_prompt.vbs"