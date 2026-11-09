# Hardened LAMP Stack on RHEL 10 bootc

A containerised LAMP infrastructure built on **Red Hat Enterprise Linux 10 bootc**, using Podman, Quadlet, systemd, MariaDB, PHP-FPM, and Apache HTTP Server.

The project explores an image-based approach to deploying and managing a Linux application stack, with an emphasis on reproducibility, service management, persistent storage, secret handling, firewall configuration, and automated container updates.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Objectives](#objectives)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Container Orchestration](#container-orchestration)
- [Security Design](#security-design)
- [Automated Updates](#automated-updates)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Building the bootc Image](#building-the-bootc-image)
- [Generating a QCOW2 Image](#generating-a-qcow2-image)
- [Deploying the Virtual Machine](#deploying-the-virtual-machine)
- [Accessing the Application](#accessing-the-application)
- [Managing Services](#managing-services)
- [Troubleshooting](#troubleshooting)
- [Current Development Status](#current-development-status)
- [Future Improvements](#future-improvements)
- [Contributing](#contributing)
- [License](#license)

---

## Project Overview

Traditional LAMP deployments commonly install Apache, PHP, and MariaDB directly onto a Linux host. This project takes a different approach.

Instead of managing application services directly on the operating system, the application stack is deployed as separate Podman containers and orchestrated through systemd using Quadlet.

The underlying operating system is based on RHEL 10 bootc, an image-based operating system model that enables system deployment and updates through container images.

The resulting architecture separates the operating system from the application services while retaining systemd integration for service lifecycle management.

The project currently includes:

- A custom RHEL 10 bootc image.
- Containerised Apache HTTP Server.
- PHP-FPM application processing.
- MariaDB database services.
- Podman Quadlet definitions.
- systemd service integration.
- Automated database secret provisioning.
- Firewalld configuration.
- Podman automatic update scheduling.
- QCOW2 image generation.
- KVM/libvirt virtual machine deployment.

## Objectives

1. Build a reproducible LAMP environment using RHEL 10 bootc.
2. Separate application services into independently managed containers.
3. Use Podman Quadlet to define container infrastructure declaratively.
4. Integrate container lifecycle management with systemd.
5. Implement persistent database storage.
6. Provision database credentials using Podman secrets.
7. Apply firewall restrictions to exposed application services.
8. Support automated container image updates.
9. Generate deployable QCOW2 virtual machine images.
10. Establish a foundation for repeatable and maintainable infrastructure deployment.

---

## Architecture

The system consists of three application containers running on a RHEL 10 bootc operating system.

```text
                  Client / Browser
                         |
                         | HTTP :8080
                         |
                  +---------------+
                  |   Firewalld   |
                  +---------------+
                         |
                  +---------------+
                  | Apache HTTPD  |
                  |   Container   |
                  +---------------+
                         |
                         | FastCGI
                         | Port 9000
                         |
                  +---------------+
                  |    PHP-FPM    |
                  |   Container   |
                  +---------------+
                         |
                         | SQL
                         |
                  +---------------+
                  |    MariaDB    |
                  |   Container   |
                  +---------------+
                         |
                  +---------------+
                  | Persistent    |
                  | Database Vol. |
                  +---------------+

              RHEL 10 bootc Operating System
                         |
                  +---------------+
                  |    systemd    |
                  +---------------+
                         |
                  +---------------+
                  | Podman /      |
                  | Quadlet       |
                  +---------------+
```

### Application request flow

1. A client sends an HTTP request to port `8080`.
2. Firewalld controls access to the exposed application port.
3. Apache receives the HTTP request.
4. Requests for PHP files are forwarded to PHP-FPM using FastCGI.
5. PHP-FPM executes the application code.
6. The PHP application communicates with MariaDB over the internal Podman network.
7. MariaDB stores application data in a persistent Podman volume.
8. The response is returned through PHP-FPM and Apache to the client.

### Container communication

The application containers communicate through a dedicated Podman network named `lamp.network`.

The intended communication paths are:

| Component | Destination | Purpose |
|---|---|---|
| Client | Apache :8080 | HTTP requests |
| Apache | PHP-FPM :9000 | PHP execution |
| PHP-FPM | MariaDB :3306 | Database operations |

MariaDB is intended to remain accessible internally rather than being exposed directly to external clients.

---

## Technology Stack

| Technology | Purpose |
|---|---|
| RHEL 10 bootc | Image-based operating system |
| Podman | Container runtime |
| Quadlet | Declarative container management |
| systemd | Service lifecycle management |
| Apache HTTP Server | Web server |
| PHP-FPM | PHP application processing |
| MariaDB | Relational database |
| Firewalld | Host firewall management |
| Podman Secrets | Database credential management |
| libvirt / KVM | Virtual machine deployment |
| QCOW2 | Virtual disk image format |
| Bash | Automation and deployment scripts |

---

## Project Structure

```text
lampdev-hardened/
│
├── app/
│   └── index.php
│
├── httpd/
│   └── proxy-php.conf
│
├── quadlets/
│   ├── lamp.network
│   ├── mariadb-data.volume
│   ├── mariadb.container
│   ├── php-fpm.container
│   └── httpd.container
│
├── systemd/
│   ├── lamp-secrets.service
│   └── podman-auto-update.timer.d/
│       └── override.conf
│
├── Containerfile.bootc
├── build-bootc.sh
├── setup-secrets.sh
├── start-lamp.sh
├── test-container.sh
├── bootc-config.sh
├── build-qcow2.sh
├── launch-vm.sh
├── .gitignore
│
├── config.toml       # Local image-builder configuration
├── user-data         # Local cloud-init configuration
└── output/           # Generated VM images
```

### Important files

| File | Responsibility |
|---|---|
| `Containerfile.bootc` | Defines the custom bootc image |
| `build-bootc.sh` | Automates bootc image building |
| `setup-secrets.sh` | Generates and provisions database credentials |
| `lamp-secrets.service` | Runs secret provisioning through systemd |
| `lamp.network` | Defines the application network |
| `mariadb.container` | Defines the MariaDB container |
| `php-fpm.container` | Defines the PHP-FPM container |
| `httpd.container` | Defines the Apache container |
| `proxy-php.conf` | Configures Apache-to-PHP-FPM forwarding |
| `bootc-config.sh` | Generates image-builder configuration |
| `build-qcow2.sh` | Generates a QCOW2 virtual disk |
| `launch-vm.sh` | Creates and starts the KVM virtual machine |
| `override.conf` | Configures the weekly Podman update schedule |

---

## How It Works

### 1. Operating system image

The project uses:

```dockerfile
FROM registry.redhat.io/rhel10/rhel-bootc:latest
```

The custom image adds the application files, Apache configuration, Quadlet definitions, secret provisioning service, and firewall configuration.

Firewalld is installed during the image build and enabled as a system service.

### 2. Apache and PHP-FPM integration

Apache handles incoming HTTP requests and forwards PHP requests to PHP-FPM.

Configuration:

```apache
DirectoryIndex index.php index.html

<FilesMatch "\.php$">
    SetHandler "proxy:fcgi://php-fpm:9000"
</FilesMatch>
```

The PHP application is shared between the Apache and PHP-FPM containers through a read-only mount for Apache and an application mount for PHP-FPM.

### 3. Database persistence

MariaDB uses a named Podman volume:

```ini
Volume=mariadb-data.volume:/var/lib/mysql:Z
```

This separates database storage from the container lifecycle.

Removing or replacing the MariaDB container should not automatically remove the persistent database volume.

### 4. Secret provisioning

The project uses Podman secrets instead of embedding database passwords directly in container definitions.

The provisioning script generates:

- A MariaDB root password.
- An application database password.

The credentials are supplied to containers through Podman secret references.

The secret provisioning service is defined in:

```text
systemd/lamp-secrets.service
```

Generated credentials are saved locally by the provisioning script at:

```text
/root/lamp-secrets-generated.txt
```

This file contains plaintext credentials and must remain protected.

---

## Container Orchestration

Quadlet provides systemd-native definitions for Podman containers.

The project defines:

```text
lamp.network
mariadb-data.volume
mariadb.container
php-fpm.container
httpd.container
```

These definitions describe the network, persistent storage, and application services.

systemd manages the resulting container services, including their dependencies and restart behaviour.

The intended startup dependency order is:

1. Secret provisioning.
2. MariaDB.
3. PHP-FPM.
4. Apache HTTP Server.

This allows the application stack to be managed using familiar systemd commands.

---

## Security Design

Security is a central design consideration.

### 1. Container separation

Apache, PHP-FPM, and MariaDB run as separate containers.

This separates their responsibilities and reduces unnecessary coupling.

### 2. Database isolation

MariaDB is designed to communicate with the other containers over the internal application network.

The database should not require a publicly exposed host port.

### 3. Secret management

Database passwords are provisioned through Podman secrets rather than hardcoded as container environment values in the Quadlet definitions.

### 4. Firewall configuration

Firewalld is installed and enabled in the bootc image.

The application HTTP port is configured as:

```bash
firewall-offline-cmd --add-port=8080/tcp
```

### 5. Read-only application access

Apache mounts the application directory read-only:

```ini
Volume=/srv/www:/var/www/html:z,ro
```

This prevents Apache from modifying application files through that mount.

### 6. SELinux considerations

Container volume definitions use SELinux labels such as `:Z`, `:z`, and `:ro` where appropriate.

These labels help ensure that container processes can access their required files under SELinux enforcement.

### 7. Image-based deployment

The bootc approach provides a reproducible operating system image that can be built, deployed, and updated as a unit.

**Security note:** This is an evolving security-focused implementation, not a formally certified or production-audited platform.

---

## Automated Updates

The project configures Podman automatic updates through systemd.

The timer override is:

```ini
[Timer]
OnCalendar=
OnCalendar=Sun *-*-* 03:00:00
```

This replaces the default timer schedule with a weekly schedule.

The timer can be enabled with:

```bash
sudo systemctl enable --now podman-auto-update.timer
```

Check its schedule:

```bash
systemctl list-timers podman-auto-update.timer
```

Inspect the timer configuration:

```bash
sudo systemctl cat podman-auto-update.timer
```

The Quadlet container definitions use:

```ini
AutoUpdate=registry
```

This allows Podman automatic updates to identify containers configured for registry-based updates.

---

## Prerequisites

The development environment used for this project includes:

- Rocky Linux 10 running under WSL2.
- Podman.
- systemd.
- Firewalld.
- libvirt.
- KVM virtualization support.
- `virt-install`.
- `virsh`.
- `virt-viewer` (optional).
- Red Hat Developer Subscription.
- Access to the required Red Hat container registries.
- Git.

The deployment environment requires sufficient resources for the virtual machine.

The current VM configuration uses:

| Resource | Configuration |
|---|---|
| vCPUs | 2 |
| RAM | 4096 MB |
| Virtual disk | QCOW2 |
| Network | libvirt default NAT |
| Application port | 8080 |

---

## Getting Started

Clone the repository:

```bash
git clone https://github.com/Movineo/lampdev-hardened.git
```

Enter the project directory:

```bash
cd lampdev-hardened
```

Make the automation scripts executable:

```bash
chmod +x build-bootc.sh
chmod +x setup-secrets.sh
chmod +x start-lamp.sh
chmod +x test-container.sh
chmod +x bootc-config.sh
chmod +x build-qcow2.sh
chmod +x launch-vm.sh
```

Before building, configure the required Red Hat registry authentication and subscription access.

Do not commit registry credentials, password hashes, private SSH keys, or generated database passwords.

---

## Building the bootc Image

Build the custom image:

```bash
./build-bootc.sh
```

The resulting image is intended to be tagged:

```text
localhost/lampdev-hardened-bootc:latest
```

Inspect the image:

```bash
podman images
```

---

## Generating a QCOW2 Image

The project includes a bootc image-builder workflow for generating a virtual machine disk image.

Run:

```bash
./build-qcow2.sh
```

The generated image is expected under:

```text
output/qcow2/disk.qcow2
```

Inspect the output:

```bash
ls -lh output/qcow2/
```

---

## Deploying the Virtual Machine

Launch the VM:

```bash
./launch-vm.sh
```

The deployment script uses libvirt and `virt-install` to create a virtual machine named:

```text
lampdev-hardened
```

The VM is configured with:

- 2 virtual CPUs.
- 4 GB RAM.
- QCOW2 virtual disk.
- libvirt default network.
- Cloud-init user configuration.

Check the VM state:

```bash
sudo virsh domstate lampdev-hardened
```

Find its IP address:

```bash
sudo virsh domifaddr lampdev-hardened
```

View the virtual machine console:

```bash
sudo virsh console lampdev-hardened
```

Stop the VM:

```bash
sudo virsh shutdown lampdev-hardened
```

Force-stop if necessary:

```bash
sudo virsh destroy lampdev-hardened
```

---

## Accessing the Application

The intended application endpoint is:

```text
http://VM_IP_ADDRESS:8080
```

For example:

```text
http://192.168.122.44:8080
```

Check HTTP connectivity:

```bash
curl -i http://192.168.122.44:8080
```

The application endpoint should become available after the container services and firewall configuration have been successfully initialized.

---

## Managing Services

Check failed systemd services:

```bash
sudo systemctl --failed
```

Inspect the application containers:

```bash
sudo podman ps -a
```

Inspect container logs:

```bash
sudo podman logs httpd
sudo podman logs php-fpm
sudo podman logs mariadb
```

Inspect service logs:

```bash
sudo journalctl -u httpd.service -b --no-pager
sudo journalctl -u php-fpm.service -b --no-pager
sudo journalctl -u mariadb.service -b --no-pager
```

Check the firewall:

```bash
sudo firewall-cmd --list-all
```

Check listening ports:

```bash
sudo ss -lntp
```

---

## Troubleshooting

### Application unavailable on port 8080

Check:

```bash
sudo podman ps -a
sudo systemctl --failed
sudo ss -lntp | grep 8080
```

Inspect Apache logs:

```bash
sudo journalctl -u httpd.service -b --no-pager
```

### Database container fails to start

Check the secrets:

```bash
sudo podman secret ls
```

Check MariaDB logs:

```bash
sudo podman logs mariadb
```

Inspect the secret provisioning service:

```bash
sudo systemctl status lamp-secrets.service
sudo journalctl -u lamp-secrets.service -b --no-pager
```

### Quadlet services fail

Reload systemd:

```bash
sudo systemctl daemon-reload
```

Check generated services:

```bash
systemctl list-units --type=service | grep -E 'mariadb|php-fpm|httpd'
```

Inspect the failed unit:

```bash
sudo systemctl status httpd.service
```

### VM network connectivity

Check:

```bash
sudo virsh net-list --all
sudo virsh domifaddr lampdev-hardened
```

From the host, test:

```bash
ping -c 4 VM_IP_ADDRESS
```

---

## Current Development Status

The project has progressed through initial image creation, container configuration, and virtual machine deployment.

| Component | Status |
|---|---|
| RHEL 10 bootc base image | Built |
| Firewalld installation | Configured in image |
| Apache configuration | Created |
| PHP-FPM configuration | Created |
| MariaDB configuration | Created |
| Quadlet definitions | Created |
| Secret provisioning script | Created |
| systemd secret service | Created |
| Podman auto-update timer | Configured |
| QCOW2 image generation | Completed |
| KVM VM creation | Completed |
| VM network connectivity | Verified |
| VM HTTP application endpoint | Pending verification |
| Guest container startup | Pending verification |
| End-to-end database integration in guest | Pending verification |

The project is under active development. The current focus is validating service startup, database secret provisioning, container networking, and application availability inside the deployed VM.

---

## Future Improvements

Planned areas of improvement include:

- Complete automated first-boot initialization.
- Verify systemd and Quadlet startup dependencies.
- Improve secret provisioning and recovery.
- Add application health checks.
- Implement HTTPS using TLS certificates.
- Add reverse-proxy security headers.
- Improve container resource limits.
- Implement centralized logging.
- Add monitoring and metrics.
- Automate image rebuilds and deployment.
- Test image updates and rollback procedures.
- Add CI/CD integration.
- Conduct security and configuration audits.
- Add automated integration tests.

---

## Contributing

Contributions, issue reports, and suggestions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Make your changes.
4. Test your changes.
5. Submit a pull request.

---

## Author

**Movine Odhiambo**

GitHub: [@Movineo](https://github.com/Movineo)

Project: [lampdev-hardened](https://github.com/Movineo/lampdev-hardened)

---

## License

A license has not yet been specified. All rights are reserved unless a license is added to this repository.


