# Linux Post-Setup Script

A comprehensive post-installation setup script for Linux systems, designed to automate the final configuration steps for various client environments.

## Features

- Client-specific setup paths (LTS, RCC, KZIA, BH, WWS, EBD)
- Automated user creation with secure password generation
- System information collection and reporting
- Printer configuration
- NoIP setup (for Linder systems)
- Chrome bookmark management
- HTML email reporting via SMTP2GO

## Directory Structure

```
linux-post-setup/
├── scripts/
│   └── post-setup.sh    # Main setup script
└── docs/
    └── README.md        # This file
```

## Prerequisites

- Linux system (tested on Ubuntu, Linux Mint)
- sudo privileges
- sendmail installed
- SMTP2GO account configured

## Usage

1. Clone this repository:
   ```bash
   git clone [repository-url]
   cd linux-post-setup
   ```

2. Make the script executable:
   ```bash
   chmod +x scripts/post-setup.sh
   ```

3. Run the script with sudo:
   ```bash
   sudo ./scripts/post-setup.sh
   ```

4. Follow the prompts to enter:
   - Client code (LTS, RCC, KZIA, BH, WWS, EBD)
   - Username
   - Hostname
   - Printer information
   - Other client-specific details

## Client-Specific Features

### Linder (LTS)
- HP printer configuration
- NoIP setup
- Chrome bookmark management
- RDP manager removal (for Linux Mint LB systems)

### RCC, KZIA, BH, WWS, EBD
- Basic printer setup
- User creation
- Hostname configuration

## Email Reporting

The script generates and sends HTML reports via SMTP2GO. Reports include:
- System information
- Setup task status
- Configuration details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

[Your chosen license]

## Author

[Your name/organization] 