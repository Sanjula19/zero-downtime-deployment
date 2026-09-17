# Stage 0 — Infrastructure Environment

## Objective

Prepare the Linux-based deployment environment required for the
Zero-Downtime Container Deployment System.

## Environment

- Host OS: Windows
- Virtualization: VirtualBox
- Guest OS: Ubuntu 24.04.2 LTS
- Network Mode: Bridged Adapter
- Ubuntu VM IP: 192.168.8.110
- VM Disk: 30 GB
- VM RAM: 4 GB

## Installed Tools

| Tool | Version / Status |
|---|---|
| Git | 2.43.0 |
| Python | 3.12.3 |
| pip | 24.0 |
| Java | OpenJDK 21.0.12 |
| Docker Engine | 29.8.1 |
| Docker Compose | v5.5.1 |
| Jenkins | 2.568.3 |
| Nginx | Active |
| UFW | Active |

## Network Verification

The Ubuntu VM uses a bridged network connection.

IPv4:

    192.168.8.110/24

Default gateway:

    192.168.8.1

Internet connectivity was verified using:

    ping -c 4 8.8.8.8

Result:

    0% packet loss

## Service Verification

Docker:

    active

Jenkins:

    active

Nginx:

    active

Docker Compose:

    Docker Compose version v5.5.1

## Firewall

UFW is enabled and configured to allow:

- TCP 22 — SSH
- TCP 80 — HTTP / Nginx
- TCP 8080 — Jenkins

## Browser Verification

Jenkins was successfully accessed from the Windows host using:

    http://192.168.8.110:8080

Nginx was successfully accessed from the Windows host using:

    http://192.168.8.110

The default Nginx welcome page was displayed successfully.

## Stage 0 Result

Infrastructure environment successfully prepared.

Docker, Jenkins, Nginx, networking, and firewall configuration
have been verified.

Stage 0 is complete.