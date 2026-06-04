import subprocess
import json
import paramiko
import logging
import sys

from paramiko.client import WarningPolicy
from paramiko.ssh_exception import AuthenticationException, SSHException

KUBECTL_WINDOWS_NODES_QUERY = ["kubectl", "get", "nodes", "--selector=kubernetes.io/os=windows", "--output=json"]


def run_ssh_command(ssh_client, command):
    ssh_stdin, ssh_stdout, ssh_stderr = ssh_client.exec_command(command)
    exit_code = ssh_stdout.channel.recv_exit_status()
    stdout = ssh_stdout.read().decode("utf-8")
    stderr = ssh_stderr.read().decode("utf-8")
    ssh_stdin.close()
    ssh_stdout.close()
    ssh_stderr.close()
    return stdout, stderr, exit_code


def install_windows_exporter(ssh_client, win_node_hostname):
    logging.debug(f"Downloading windows exporter on {win_node_hostname}.")
    stdout, stderr, exit_code = run_ssh_command(
        ssh_client,
        "curl -L -o windows-exporter.msi https://github.com/prometheus-community/windows_exporter/releases"
        "/download/v0.16.0/windows_exporter-0.16.0-amd64.msi")
    if exit_code != 0:
        logging.error(f"Failed to download windows exporter on {win_node_hostname}: {stderr}")
        return False

    logging.debug(f"Installing windows exporter on {win_node_hostname}.")
    stdout, stderr, exit_code = run_ssh_command(
        ssh_client,
        "msiexec /i %cd%\\windows-exporter.msi LISTEN_PORT=9100 ENABLED_COLLECTORS=cpu,cs,container,"
        "logical_disk,"
        "memory,net,os,service,system,tcp")
    if exit_code != 0:
        logging.error(f"Failed to install windows exporter on {win_node_hostname}: {stderr}")
        return False

    logging.debug(f"Finished installing windows exporter on {win_node_hostname}")
    return True


def main(win_node_username, win_node_password):
    windows_nodes = subprocess.check_output(
        KUBECTL_WINDOWS_NODES_QUERY).decode('utf-8')
    windows_nodes = json.loads(windows_nodes)

    if len(windows_nodes['items']) == 0:
        logging.debug("No windows nodes found, skipping job")
        return
    for win_node in windows_nodes['items']:
        win_node_hostname = None
        for addr in win_node['status']['addresses']:
            if addr['type'] == 'InternalIP':
                win_node_hostname = addr['address']
                break
        if win_node_hostname is None:
            logging.error(f"No InternalIP found for node {win_node['metadata']['name']}, skipping")
            continue

        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(WarningPolicy())
        try:
            ssh_client.connect(win_node_hostname, username=win_node_username, password=win_node_password)
        except (AuthenticationException, SSHException, OSError) as e:
            logging.error(f"SSH connection to node {win_node_hostname} failed: {e}")
            ssh_client.close()
            continue

        logging.debug(f"Connected to windows node {win_node_hostname}")
        try:
            stdout, stderr, exit_code = run_ssh_command(ssh_client, 'net start')
            if "windows_exporter" in stdout:
                logging.debug(f"Node {win_node_hostname} already running windows_exporter, skipping.")
                continue
            install_windows_exporter(ssh_client, win_node_hostname)
        finally:
            ssh_client.close()


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
    args = sys.argv[1:]
    win_username = args[0]
    win_password = args[1]
    if not win_username or win_username.isspace():
        logging.debug("No windows node username provided, skipping job")
    else:
        main(win_username, win_password)
