add-content -path C:/Users/Probook/.ssh/config -value @'

Host ${hostname}
    HostName ${hostname}
    User ${user}
    Identityfile ${identityfile}
'@