!macro KNOWBASE_STOP_RUNNING_PROCESSES
  DetailPrint "Stopping running KnowBase processes..."
  nsExec::ExecToLog 'cmd /C taskkill /F /IM KnowBase.exe /T 2>NUL'
  Pop $0
  nsExec::ExecToLog 'cmd /C taskkill /F /IM KnowBaseBackend.exe /T 2>NUL'
  Pop $0
  Sleep 1000
!macroend

!macro NSIS_HOOK_PREINSTALL
  !insertmacro KNOWBASE_STOP_RUNNING_PROCESSES
!macroend

!macro NSIS_HOOK_PREUNINSTALL
  !insertmacro KNOWBASE_STOP_RUNNING_PROCESSES
!macroend
