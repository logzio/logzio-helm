# replace upstream server details in nginx conf with env vars 

$PROXY_HOSTIP=$env:PROXY_HOSTIP
$PROXY_PORT=$env:PROXY_PORT

$conf1=Get-Content C:\nginx-1.21.3\shell\edit-nginx.conf `
    | % { $_ -replace "PROXY_HOSTIP","$PROXY_HOSTIP"} `
    | % { $_ -replace "PROXY_PORT","$PROXY_PORT"} `

$conf1 | Out-File  -Encoding Default  C:\nginx-1.21.3\shell\nginx.conf

Move-Item C:\nginx-1.21.3\conf\nginx.conf C:\nginx-1.21.3
Move-Item C:\nginx-1.21.3\shell\nginx.conf C:\nginx-1.21.3\conf\nginx.conf

CMD /C /nginx-1.21.3/nginx.exe