# Linux Post-Setup Script

A comprehensive post-installation setup script for Linux systems, designed to automate the final configuration steps for various client environments. This script handles system setup, user creation, printer configuration, and generates detailed setup reports.

## Features

- Client-specific setup paths (LTS, RCC, KZIA, BH, WWS, EBD)
- Computer type validation (LT, LB, LC)
- Automated user creation with secure, memorable password generation
- Comprehensive system information collection and reporting
- Printer configuration with HP printer support
- NoIP DUC setup and configuration (for Linder systems)
- Chrome bookmark management (optional)
- Professional HTML email reporting via SMTP2GO
- Detailed setup status tracking and reporting

## Directory Structure

```
linux-post-setup/
├── scripts/
│   └── post-setup.sh    # Main setup script
└── README.md            # This file
```

## Prerequisites

- Linux system (tested on Ubuntu, Linux Mint)
- sudo privileges
- Internet connection
- SMTP2GO account configured
- wamerican package (for password generation)

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

4. Follow the interactive prompts to enter:
   - Computer type (LT, LB, LC)
   - Client code (LTS, RCC, KZIA, BH, WWS, EBD)
   - Username (defaults provided based on client)
   - Hostname
   - Printer information
   - NoIP credentials (for Linder systems)
   - Other client-specific details

## Client-Specific Features

### Linder (LTS)
- HP printer configuration with HPLIP
- NoIP DUC setup and configuration
- Optional Chrome bookmark management
- RDP manager removal (for Linux Browser systems)
- Special handling for different computer types (LT, LB, LC)

### RCC, KZIA, BH, WWS, EBD
- Basic printer setup with CUPS
- User creation with secure password
- Hostname configuration
- System information collection

## Computer Types

- **LT (LETC)**: Full Linux system with NoIP support
- **LB (Linux Browser)**: Browser-focused system with RDP manager removal
- **LC (Linux Combo)**: Combination system with NoIP support

## Email Reporting

The script generates and sends professional HTML reports via SMTP2GO. Reports include:
- System hardware information (CPU, RAM, OS)
- Setup task status and details
- User account information
- Printer configuration status
- NoIP setup status (for Linder systems)
- Service status information

## Security Features

- Secure password generation using random words
- Password requirements enforcement (capital letters, special characters)
- Secure handling of NoIP credentials
- SMTP2GO integration for secure email reporting

## Error Handling

- Comprehensive error checking for all setup tasks
- Detailed status tracking for each operation
- Automatic rollback of failed operations
- Clear error messages and reporting

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

## Support

For support or questions, please contact [your contact information] 