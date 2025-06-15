# Purrploy

A robust deployment and management script for the Dokploy service using Docker and Docker Swarm.

## Overview

This script automates the deployment and management of the Dokploy service, handling Docker container orchestration, network configuration, and service management. It provides a simple interface for common operations while ensuring proper setup and security.

## Features

- **Docker Integration**: Seamless integration with Docker and Docker Swarm
- **Automatic Service Management**: Easy installation, updates, and service control
- **Secure Configuration**: Built-in security checks and best practices
- **Traefik Reverse Proxy**: Automatic setup with configurable IP bindings
- **Comprehensive Logging**: Detailed operation logging with color-coded output
- **Modular Codebase**: Well-organized, maintainable code structure
- **Built-in Security**: Automatic firewall configuration and security checks

## Prerequisites

- Linux-based operating system
- Root access
- Internet connection
- Available ports (80, 443)
- Docker and Docker Swarm installed

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/dokploy-deployer.git
   cd dokploy-deployer
   ```

2. Set up the directory structure:
   ```bash
   sudo mkdir -p /scripts/bytepurr/{lib,utils}
   ```

3. Set permissions:
   ```bash
   sudo chown -R $USER:$USER /scripts/bytepurr
   chmod +x deployer.sh
   ```

4. Copy the example configuration:
   ```bash
   cp config.example.yml config.yml
   ```

5. Edit the configuration file:
   ```bash
   nano config.yml
   ```

## Configuration

The `config.yml` file contains all configurable parameters. Key settings include:

### Network Configuration
```yaml
network:
  # Internal port for Dokploy service
  port: 3000
  
  # Traefik configuration
  traefik:
    port: 80      # HTTP port
    ssl_port: 443 # HTTPS port
  
  # IP binding for Traefik
  # Options:
  # - Specific IP (e.g., "70.35.199.91")
  # - All interfaces ("0.0.0.0")
  advertise_addr: "0.0.0.0"
```

### Docker Configuration
```yaml
docker:
  release_tag: "latest"
  traefik_version: "v3.1.2"
  postgres_version: "16"
  redis_version: "7"
```

### Database Configuration
```yaml
database:
  # External database URL (optional)
  url: ""
  
  # Internal database settings
  internal:
    user: "dokploy"
    name: "dokploy"
    password: "your_secure_password"
```

## Usage

### Basic Commands

```bash
# Install Dokploy
sudo ./deployer.sh install

# Update Dokploy
sudo ./deployer.sh update

# Stop Dokploy
sudo ./deployer.sh stop

# Start Dokploy
sudo ./deployer.sh start

# Restart Dokploy
sudo ./deployer.sh restart

# Clean up (remove all containers and volumes)
sudo ./deployer.sh cleanup

# Reinstall (cleanup + install)
sudo ./deployer.sh reinstall
```

### Traefik Configuration

The script supports flexible Traefik configuration:

1. **IP Binding**:
   - Bind to a specific IP (e.g., "70.35.199.91"):
     - Uses host networking mode
     - Direct port binding to the specified IP
     - Optimal for single-interface deployments
   - Bind to all interfaces ("0.0.0.0"):
     - Uses the `dokploy-network` overlay network
     - Allows access from any network interface
     - Better for multi-interface or complex network setups

2. **Port Configuration**:
   - HTTP: Port 80 (configurable via `network.traefik.port`)
   - HTTPS: Port 443 (configurable via `network.traefik.ssl_port`)

3. **Network Mode**:
   - Specific IP: Uses host networking for direct port binding
   - All Interfaces: Uses `dokploy-network` overlay network for flexible access

## Architecture

The script is organized into several components:

```
dokploy-deployer/
├── deployer.sh           # Main deployment script
├── config.yml           # Configuration file
├── config.example.yml   # Example configuration
├── LICENSE             # GNU AGPL v3.0 License
├── lib/                # Library functions
│   ├── logging.sh      # Logging functions
│   ├── docker.sh       # Docker operations
│   ├── network.sh      # Network configuration
│   ├── database.sh     # Database management
│   ├── redis.sh        # Redis management
│   └── traefik.sh      # Traefik configuration
└── utils/              # Utility functions
    ├── error.sh        # Error handling
    └── validation.sh   # Input validation
```

## Security Considerations

1. **Root Access**: The script requires root access for Docker operations
2. **Database Security**: Change default database credentials
3. **Network Security**: Configure firewall rules appropriately
4. **File Permissions**: Maintain proper file permissions
5. **Sensitive Data**: Keep configuration files secure

## Troubleshooting

Common issues and solutions:

1. **Permission Denied**:
   ```bash
   sudo chmod +x deployer.sh
   ```

2. **Docker Command Failed**:
   ```bash
   sudo systemctl restart docker
   ```

3. **Port Already in Use**:
   ```bash
   sudo lsof -i :<port>
   sudo kill -9 <PID>
   ```

## Maintenance

1. **Regular Updates**:
   ```bash
   sudo ./deployer.sh update
   ```

2. **Backup**:
   ```bash
   # Backup configuration
   cp config.yml config.yml.backup
   
   # Backup volumes
   docker volume ls | grep dokploy
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

Copyright (C) 2025 Purrquinox Technologies

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Support

For support, please open an issue in the GitHub repository or contact the maintainers.

## Contact

- GitHub: [@purrquinox](https://github.com/purrquinox)
- Email: support@purrquinox.com