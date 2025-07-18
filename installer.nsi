!include MUI2.nsh
!include LogicLib.nsh
!include nsDialogs.nsh
!include Integration.nsh

!define PRODUCT "garyttierney\me3"
!define PRODUCT_URL "https://github.com/Syswisen/steamless-me3"

!define MUI_ICON "distribution/assets/me3.ico"


; https://gist.github.com/nikku/281d0ef126dbc215dd58bfd5b3a5cd5b
!macro APP_ASSOCIATE EXT FILECLASS DESCRIPTION ICON COMMANDTEXT COMMAND
  ; Backup the previously associated file class
  ReadRegStr $R0 SHELL_CONTEXT "Software\Classes\.${EXT}" ""
  WriteRegStr SHELL_CONTEXT "Software\Classes\.${EXT}" "${FILECLASS}_backup" "$R0"

  WriteRegStr SHELL_CONTEXT "Software\Classes\.${EXT}" "" "${FILECLASS}"

  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}" "" `${DESCRIPTION}`
  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}\DefaultIcon" "" `${ICON}`
  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}\shell" "" "open"
  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}\shell\open" "" `${COMMANDTEXT}`
  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}\shell\open\command" "" `${COMMAND}`
!macroend

!macro APP_ASSOCIATE_EX EXT FILECLASS DESCRIPTION ICON VERB DEFAULTVERB SHELLNEW COMMANDTEXT COMMAND
  ; Backup the previously associated file class
  ReadRegStr $R0 SHELL_CONTEXT "Software\Classes\.${EXT}" ""
  WriteRegStr SHELL_CONTEXT "Software\Classes\.${EXT}" "${FILECLASS}_backup" "$R0"

  WriteRegStr SHELL_CONTEXT "Software\Classes\.${EXT}" "" "${FILECLASS}"
  StrCmp "${SHELLNEW}" "0" +2
  WriteRegStr SHELL_CONTEXT "Software\Classes\.${EXT}\ShellNew" "NullFile" ""

  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}" "" `${DESCRIPTION}`
  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}\DefaultIcon" "" `${ICON}`
  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}\shell" "" `${DEFAULTVERB}`
  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}\shell\${VERB}" "" `${COMMANDTEXT}`
  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}\shell\${VERB}\command" "" `${COMMAND}`
!macroend

!macro APP_ASSOCIATE_ADDVERB FILECLASS VERB COMMANDTEXT COMMAND
  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}\shell\${VERB}" "" `${COMMANDTEXT}`
  WriteRegStr SHELL_CONTEXT "Software\Classes\${FILECLASS}\shell\${VERB}\command" "" `${COMMAND}`
!macroend

!macro APP_ASSOCIATE_REMOVEVERB FILECLASS VERB
  DeleteRegKey SHELL_CONTEXT `Software\Classes\${FILECLASS}\shell\${VERB}`
!macroend


!macro APP_UNASSOCIATE EXT FILECLASS
  ; Backup the previously associated file class
  ReadRegStr $R0 SHELL_CONTEXT "Software\Classes\.${EXT}" `${FILECLASS}_backup`
  WriteRegStr SHELL_CONTEXT "Software\Classes\.${EXT}" "" "$R0"

  DeleteRegKey SHELL_CONTEXT `Software\Classes\${FILECLASS}`
!macroend

!macro APP_ASSOCIATE_GETFILECLASS OUTPUT EXT
  ReadRegStr ${OUTPUT} SHELL_CONTEXT "Software\Classes\.${EXT}" ""
!macroend


; !defines for use with SHChangeNotify
!ifdef SHCNE_ASSOCCHANGED
!undef SHCNE_ASSOCCHANGED
!endif
!define SHCNE_ASSOCCHANGED 0x08000000
!ifdef SHCNF_FLUSH
!undef SHCNF_FLUSH
!endif
!define SHCNF_FLUSH        0x1000

!macro UPDATEFILEASSOC
; Using the system.dll plugin to call the SHChangeNotify Win32 API function so we
; can update the shell.
  System::Call "shell32::SHChangeNotify(i,i,i,i) (${SHCNE_ASSOCCHANGED}, ${SHCNF_FLUSH}, 0, 0)"
!macroend

!ifndef TARGET_DIR
  !define TARGET_DIR "target/x86_64-pc-windows-msvc/release/"
!endif

!ifndef VERSION
  !define VERSION unknown
!endif

!define MUI_ABORTWARNING

Unicode true

Name "me3"

RequestExecutionLevel user

InstallDir "$LOCALAPPDATA\Programs\${PRODUCT}"
InstallDirRegKey HKCU "Software\${PRODUCT}" "Install_Dir"

ShowInstDetails "show"
ShowUninstDetails "show"

Var UNINSTALL_REG_KEY


Function .onInit
    ; Set the uninstall registry key path here
    StrCpy $UNINSTALL_REG_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\me3"
FunctionEnd

Function onFinish
  ExecShell "open" "$LOCALAPPDATA\garyttierney\me3\config\profiles"
FunctionEnd

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_SHOWREADME "https://me3.readthedocs.io/"
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION onFinish
!define MUI_FINISHPAGE_RUN_TEXT "Open the mod profile folder?"

!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE English


!macro CreateInternetShortcutWithIcon FILEPATH URL ICONPATH
WriteINIStr "${FILEPATH}" "InternetShortcut" "URL" "${URL}"
WriteINIStr "${FILEPATH}" "InternetShortcut" "IconFile" "${ICONPATH}"
!macroend

; Installer Section
Section "Main Application" SEC01
    SectionIn RO
    SetShellVarContext current

    CreateDirectory "$INSTDIR\config"
    CreateDirectory "$INSTDIR\bin"
    CreateDirectory "$INSTDIR\assets"

    SetOutPath "$INSTDIR"
    File /oname=bin\me3.exe "${TARGET_DIR}me3.exe"
    File /oname=bin\me3-launcher.exe "${TARGET_DIR}me3-launcher.exe"
    File /oname=bin\me3_mod_host.dll "${TARGET_DIR}me3_mod_host.dll"
    File /oname=README.txt "INSTALLER_README.txt"
    File /oname=assets\me3.ico "distribution/assets/me3.ico"

    File "LICENSE-APACHE"
    File "LICENSE-MIT"
    File "CHANGELOG.md"

    WriteRegStr HKCU "$UNINSTALL_REG_KEY" "DisplayName" "me3"
    WriteRegStr HKCU "$UNINSTALL_REG_KEY" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKCU "$UNINSTALL_REG_KEY" "InstallLocation" "$INSTDIR"
    WriteRegStr HKCU "$UNINSTALL_REG_KEY" "DisplayVersion" "${VERSION}"
    WriteRegDWORD HKCU "$UNINSTALL_REG_KEY" "NoModify" 1
    WriteRegDWORD HKCU "$UNINSTALL_REG_KEY" "NoRepair" 1

    WriteRegStr HKCU "Software\${PRODUCT}" "Install_Dir" $INSTDIR
    nsExec::Exec '"$INSTDIR\bin\me3.exe" add-to-path'
    nsExec::Exec '"$INSTDIR\bin\me3.exe" profile create -g nr nightreign-default --package nightreign-mods'
    nsExec::Exec '"$INSTDIR\bin\me3.exe" profile create -g er eldenring-default --package eldenring-mods'

    CreateDirectory "$SMPROGRAMS\me3"
    CreateShortCut "$SMPROGRAMS\me3\ELDEN RING (me3).lnk" "$INSTDIR\bin\me3.exe" \
      "launch --auto-detect -p eldenring-default" "$INSTDIR\assets\me3.ico" "" "" \
      "" "Launch ELDEN RING with the eldenring-default mod profile"

    CreateShortCut "$SMPROGRAMS\me3\NIGHTREIGN (me3).lnk" "$INSTDIR\bin\me3.exe" \
      "launch --auto-detect -p nightreign-default" "$INSTDIR\assets\me3.ico" "" "" \
      "" "Launch NIGHTREIGN with the nightreign-default mod profile"

    !insertmacro CreateInternetShortcutWithIcon "$SMPROGRAMS\me3\Documentation.URL" "https://me3.readthedocs.io" "$INSTDIR\assets\me3.ico"

    ; Generate an uninstaller executable
    WriteUninstaller "$INSTDIR\uninstall.exe"

    !insertmacro APP_ASSOCIATE "me3" "me3.mod-profile" "me3 Mod Profile" \
      "$INSTDIR\assets\me3.ico" "Open with me3" "$INSTDIR\bin\me3.exe launch --auto-detect -p $\"%1$\""

    !insertmacro APP_ASSOCIATE_ADDVERB "me3.mod-profile" "open-with-diagnostics" "Open with me3 (diagnostics)" \
      "$INSTDIR\bin\me3.exe launch --diagnostics --auto-detect -p $\"%1$\""
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\bin\me3-launcher.exe"
    Delete "$INSTDIR\bin\me3_mod_host.dll"
    Delete "$INSTDIR\bin\me3.exe"
    Delete "$INSTDIR\uninstall.exe"
    Delete "$INSTDIR\LICENSE-APACHE"
    Delete "$INSTDIR\LICENSE-MIT"
    Delete "$INSTDIR\CHANGELOG.md"
    Delete "$INSTDIR\README.txt"
    Delete "$INSTDIR\assets\me3.ico"
    Delete "$SMPROGRAMS\me3\ELDEN RING (me3).lnk"
    Delete "$SMPROGRAMS\me3\NIGHTREIGN (me3).lnk"
    Delete "$SMPROGRAMS\me3\Documentation.URL"

    RMDir "$SMPROGRAMS\me3"
    RMDir "$INSTDIR\assets"
    RMDir "$INSTDIR\bin"

    DeleteRegKey HKCU "$UNINSTALL_REG_KEY"
SectionEnd
