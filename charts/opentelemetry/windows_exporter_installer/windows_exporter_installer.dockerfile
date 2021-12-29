FROM python:latest

# Download and install kubectl
# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
RUN apt-get update \  
    && apt-get -y install curl

WORKDIR /etc/kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

COPY windows_exporter_installer.py etc/windows_exporter_installer.py

# Python package that handles ssh connections
RUN pip install paramiko
ENTRYPOINT [ "python","./etc/windows_exporter_installer.py"]











