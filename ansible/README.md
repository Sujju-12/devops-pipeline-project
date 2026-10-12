# Ansible: build dependency setup

This playbook installs Java 17, Maven, Git, and curl on Debian/Ubuntu build hosts. It is intended to prepare a host for building the Spring Boot application; it does not install Jenkins, configure a CI server, or install Docker.

## Prerequisites

- Ansible installed on the control machine.
- SSH access and sudo privileges for remote hosts, or a local inventory entry.
- A Debian/Ubuntu target.

## Run against localhost

From the repository root:

```bash
ansible --version
ansible-playbook -i ansible/inventory.ini ansible/install-build-dependencies.yml --ask-become-pass
```

For localhost, Ansible may not need a become password if passwordless sudo is configured. Omit `--ask-become-pass` only when privilege escalation is already configured.

## Build the application

After dependencies are installed:

```bash
cd app/employee-api
mvn clean verify
```

## Remote host

Add a real host and user to the inventory, configure SSH key access, then run the playbook with the appropriate inventory. Do not commit private keys, passwords, or other secrets.

The playbook uses apt and is designed for Debian/Ubuntu; adapt the package tasks before using it on another Linux distribution.
