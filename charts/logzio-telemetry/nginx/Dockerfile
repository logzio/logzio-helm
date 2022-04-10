FROM mcr.microsoft.com/windows/servercore:ltsc2019

RUN powershell -Command \
    $ErrorActionPreference = 'Stop'; \
    Invoke-WebRequest -Method Get -Uri https://nginx.org/download/nginx-1.21.3.zip -OutFile c:\nginx-1.21.3.zip ; \
    Expand-Archive -Path c:\nginx-1.21.3.zip -DestinationPath c:\ ; \
    Remove-Item c:\nginx-1.21.3.zip -Force

WORKDIR /nginx-1.21.3

RUN mkdir shell
COPY edit-nginx.conf ./shell
COPY docker-entrypoint.ps1 ./shell

ENTRYPOINT [ "powershell.exe", "./shell/docker-entrypoint.ps1" ]