# 🚀 Linux Post-Setup Automation Script

## Overview
This powerful automation script streamlines the post-installation setup process for various client environments. It's designed to handle multiple client configurations (LTS, RCC, KZIA, BH, WWS, EBD) with specific requirements for each.

## ✨ Key Features

### 🔐 Smart User Management
- Automated user creation with secure password generation
- Client-specific default usernames
- Secure password handling and reporting

### 🖥️ System Configuration
- Dynamic hostname configuration
- Hardware information collection
- OS-specific optimizations
- Printer setup automation

### 📧 Professional Reporting
- Beautiful HTML email reports
- Real-time setup status tracking
- Detailed system information
- Installed software inventory
- Secure credential reporting

### 🛠️ Client-Specific Features
- **LTS (Linder) Systems**
  - NoIP dynamic DNS configuration
  - HP printer setup
  - Chrome bookmark management
  - Special Linux Mint optimizations

- **RCC/KZIA/BH/WWS/EBD Systems**
  - Standard printer configuration
  - Basic system optimization
  - Client-specific defaults

## 🎯 Usage

```bash
# Make the script executable
chmod +x post-setup.sh

# Run the script
./post-setup.sh
```

The script will guide you through:
1. Client code selection
2. System information collection
3. Configuration options
4. Installation process
5. Report generation

## 📊 Report Features
- System hardware details
- Installed software inventory
- User credentials
- Setup task status
- Timestamp and tracking
- Professional HTML formatting

## 🔧 Technical Details
- Bash script implementation
- SMTP2GO email integration
- Secure password generation
- Dynamic software tracking
- Case-insensitive client code validation

## 📝 Requirements
- Linux-based operating system
- Root/sudo access
- Internet connection
- SMTP2GO account (for email reports)

## 🔐 Security Notes
- Passwords are generated using OpenSSL
- Credentials are included in email reports
- All sensitive data is handled securely

## 🎨 Customization
The script can be easily modified to:
- Add new client configurations
- Modify default settings
- Add additional software tracking
- Customize email templates

## 📈 Future Enhancements
- [ ] Web-based configuration interface
- [ ] Additional client support
- [ ] Enhanced security features
- [ ] Automated backup integration
- [ ] Remote management capabilities

## 🤝 Contributing
Feel free to submit issues and enhancement requests!

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

---
Made with ❤️ for automated Linux system management 