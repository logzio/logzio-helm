import subprocess
import json
import paramiko
import logging
import sys

from paramiko.client import AutoAddPolicy
from paramiko.ssh_exception import AuthenticationException

KUBECTL_WINDOWS_NODES_QUERY = ["kubectl", "get", "nodes", "--selector=kubernetes.io/os=windows", "--output=json"]


def close_connection(ssh_stdin, ssh_stderr, ssh_stdout, ssh_client):
    ssh_stdin.close()
    ssh_stdout.close()
    ssh_stderr.close()
    ssh_client.exec_command("exit")


def install_windows_exporter(ssh_client, win_node_hostname):
    logging.debug("Installing windows exporter client as a service.")
    ssh_client.exec_command(
        "curl -L -o windows-exporter.msi https://github.com/prometheus-community/windows_exporter/releases"
        "/download/v0.16.0/windows_exporter-0.16.0-amd64.msi")
    ssh_client.exec_command(
        "msiexec /i %cd%\\windows-exporter.msi LISTEN_PORT=9100 ENABLED_COLLECTORS=cpu,cs,container,"
        "logical_disk,"
        "memory,net,os,service,system,tcp")
    logging.debug(f"Finished installing windows exporter on {win_node_hostname}")


def main(win_node_username, win_node_password):
    windows_nodes = subprocess.check_output(
        KUBECTL_WINDOWS_NODES_QUERY).decode('utf-8')
    windows_nodes = json.loads(windows_nodes)
    ssh_client = paramiko.SSHClient()
    ssh_client.set_missing_host_key_policy(AutoAddPolicy())

    if len(windows_nodes['items']) == 0:
        logging.debug("No windows nodes found, skipping job")
        return
    for win_node in windows_nodes['items']:
        win_node_hostname = win_node['status']['addresses'][1]['address']
        try:
            ssh_client.connect(win_node_hostname, username=win_node_username, password=win_node_password)
        except AuthenticationException:
            logging.error(f"SSH connection to node {win_node_hostname} failed, please check username and password")
            continue
        logging.debug(f"Connected to windows node {win_node_hostname}")
        ssh_stdin, ssh_stdout, ssh_stderr = ssh_client.exec_command('net start')
        running_services = ssh_stdout.read()
        if running_services.decode("utf-8").find("windows_exporter") != -1:
            logging.debug(f"Node {win_node_hostname} already running windows_exporter, closing connection.")
            close_connection(ssh_stdin, ssh_stderr, ssh_stdout, ssh_client)
            continue
        install_windows_exporter(ssh_client, win_node_hostname)
        close_connection(ssh_stdin, ssh_stderr, ssh_stdout, ssh_client)


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
    args = sys.argv[1:]
    win_username = args[0]
    win_password = args[1]
    if not win_username or win_username.isspace():
        logging.debug("No windows node username provided, skipping job")
    else:
        main(win_username, win_password)
