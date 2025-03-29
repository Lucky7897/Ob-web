# OB-Web

OB-Web is the ultimate web automation tool for remote access, file management, and secure web operations. Created by Lucky7897, this tool offers a comprehensive set of features to streamline your web automation tasks.

## Features

- **Remote Access Capabilities:**
  - Accessible web interface for managing tasks remotely.
  - Secure login system using JWT tokens.

- **File Management:**
  - File upload functionality.
  - File download functionality.
  - File deletion.

- **Database Integration:**
  - PostgreSQL database setup.
  - User management and authentication.

- **Web Server Configuration:**
  - NGINX setup for web server and reverse proxy.
  - SSL/TLS setup using Let's Encrypt or self-signed certificates.

- **Backup System:**
  - Automated daily backups.
  - Configuration and data backups.
  - 7-day retention policy for backups.

- **Monitoring & Logging:**
  - Supervisor configuration for process management.
  - Log rotation and storage.

- **Firewall and Security:**
  - UFW or firewalld setup for firewall rules.
  - Secure file permissions.

## Installation

### Prerequisites

- Minimum 2 CPU cores.
- Minimum 2GB RAM.
- Minimum 10GB free disk space.
- Supported OS: Ubuntu, Debian, CentOS, or any Linux distribution with `apt-get` or `yum`.

### Installation Steps

1. **Download the Installation Script:**

    ```bash
    wget https://raw.githubusercontent.com/Lucky7897/Ob-web/main/install.sh
    ```

2. **Run the Installation Script:**

    ```bash
    sudo bash install.sh
    ```

3. **Follow the On-Screen Instructions:**

    - Enter your domain name for SSL setup (leave empty for self-signed certificate).

### Installation Modes

- **GitHub Codespace:**
  The installation script is designed to detect if it is running in a GitHub Codespace and will adjust configurations accordingly.

- **Other Servers:**
  The script automatically detects the hardware and configures the installation to suit the server environment.

## Usage

### Accessing the Web Interface

- **URL:** `https://your-domain`
- **Default Username:** `admin`
- **Default Password:** `admin`

> **IMPORTANT:** Change the default password after your first login.

### File Management

1. **Upload Files:**
    - Navigate to the upload section on the dashboard.
    - Select the file to upload and click the upload button.

2. **Download Files:**
    - Navigate to the files section on the dashboard.
    - Click the download button next to the desired file.

3. **Delete Files:**
    - Navigate to the files section on the dashboard.
    - Click the delete button next to the file you wish to remove.

### Backup System

- Backups are automated and run daily.
- Backups are stored in `/var/backup/ob-web` with a 7-day retention policy.

### Monitoring & Logging

- Logs are stored in `/var/log/ob-web`.
- Supervisor manages the web application process for reliability.

## Contributing

We welcome contributions from the community! Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes and commit them (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature-branch`).
5. Open a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For support and inquiries, please visit the [GitHub Repository](https://github.com/Lucky7897/Ob-web).

---

Thank you for using OB-Web! 🎉
