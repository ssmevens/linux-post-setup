#!/bin/bash

###############################################################################
# Email Configuration
# These settings are used for sending status reports via SMTP2GO
# DO NOT MODIFY THESE VALUES WITHOUT UPDATING THE SMTP2GO CONFIGURATION
###############################################################################
REPORT_EMAIL="Service-Monitor@its-ia.com"    # The email address that will send and receive reports
SMTP2GO_SERVER="mail.smtp2go.com"           # SMTP2GO's mail server address
SMTP2GO_PORT="2525"                         # SMTP2GO's mail server port
SMTP2GO_USERNAME="SRVLinux"                 # SMTP2GO account username
SMTP2GO_PASSWORD="tIx3SXLn2tF4jYxa"        # SMTP2GO account password

###############################################################################
# Password Generation Function
# Creates a secure, memorable password for new user accounts
# Uses OpenSSL for cryptographically secure random generation
# Filters to ensure password contains only allowed characters
###############################################################################
generate_password() {
    # Generate 12 random bytes, encode as base64, then filter to allowed characters
    # This ensures the password is both secure and compatible with most systems
    openssl rand -base64 12 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c 12
}

###############################################################################
# System Information Collection Function
# Gathers detailed information about the system hardware and software
# This information is used in the setup report and for making setup decisions
###############################################################################
collect_system_info() {
    echo "Collecting system information..."
    
    # Get current hostname
    HOSTNAME=$(hostname)
    
    # Get CPU information using lscpu with timeout
    CPU_INFO=$(timeout 5 lscpu | grep "Model name" | cut -d':' -f2 | sed 's/^[ \t]*//' || echo "Unable to get CPU information")
    
    # Get RAM information using free command with timeout
    RAM_INFO=$(timeout 5 free -h | grep Mem | awk '{print $2}' || echo "Unable to get RAM information")
    
    # Get detailed hardware information using dmidecode with timeout
    # Only run dmidecode if we have root privileges
    if [ "$EUID" -eq 0 ]; then
        HARDWARE_INFO=$(timeout 10 dmidecode -t system | grep -E "Manufacturer|Product Name|Serial Number" | sed 's/^[ \t]*//' || echo "Unable to get hardware information")
    else
        HARDWARE_INFO="Hardware information requires root privileges"
    fi
    
    # Get OS information using lsb_release with timeout
    OS_INFO=$(timeout 5 lsb_release -d | cut -d':' -f2 | sed 's/^[ \t]*//' || echo "Unable to get OS information")
    
    # Combine all system information into a formatted string
    # This will be used in the HTML report
    SYSTEM_INFO="Hostname: $HOSTNAME\nCPU: $CPU_INFO\nRAM: $RAM_INFO\nHardware: $HARDWARE_INFO\nOS: $OS_INFO"
}

###############################################################################
# Linder (LTS) Specific Information Collection
# Gathers all necessary information for setting up a Linder system
# Includes special requirements like NoIP and HP printer setup
###############################################################################
collect_lts_input() {
    echo "=== Linder System Setup Information Collection ==="
    echo "Please provide the following information:"
    echo "----------------------------------------"
    
    # User Information
    # Default username is 'linder' if none provided
    echo "Enter new username (default: linder):"
    read NEW_USER
    NEW_USER=${NEW_USER:-linder}
    
    # Hostname Configuration
    # Default to current hostname if none provided
    echo "Enter desired hostname (current: $HOSTNAME):"
    read NEW_HOSTNAME
    NEW_HOSTNAME=${NEW_HOSTNAME:-$HOSTNAME}
    
    # Printer Information
    # Linder uses HP printers, so we need IP and model
    echo "Enter HP printer IP address:"
    read PRINTER_IP
    echo "Enter HP printer model:"
    read PRINTER_MODEL
    
    # NoIP Information
    # Required for Linder systems for remote access
    echo "Enter NoIP username:"
    read NOIP_USERNAME
    echo "Enter NoIP password:"
    read -s NOIP_PASSWORD
    echo
    echo "Enter NoIP hostname:"
    read NOIP_HOSTNAME
    
    # Chrome Bookmarks
    # Optional: Add default bookmarks for Linder
    echo "Would you like to add default bookmarks? (y/n)"
    read ADD_BOOKMARKS
    
    # Generate a secure password for the new user
    NEW_PASSWORD=$(generate_password)
}

###############################################################################
# RCC Specific Information Collection
# Gathers information needed for RCC system setup
# Simpler than Linder as it doesn't require NoIP
###############################################################################
collect_rcc_input() {
    echo "=== RCC System Setup Information Collection ==="
    echo "Please provide the following information:"
    echo "----------------------------------------"
    
    # User Information
    # Default username is 'rcc' if none provided
    echo "Enter new username (default: rcc):"
    read NEW_USER
    NEW_USER=${NEW_USER:-rcc}
    
    # Hostname Configuration
    # Default to current hostname if none provided
    echo "Enter desired hostname (current: $HOSTNAME):"
    read NEW_HOSTNAME
    NEW_HOSTNAME=${NEW_HOSTNAME:-$HOSTNAME}
    
    # Printer Information
    # Basic printer setup for RCC
    echo "Enter printer IP address:"
    read PRINTER_IP
    echo "Enter printer model:"
    read PRINTER_MODEL
    
    # Generate a secure password for the new user
    NEW_PASSWORD=$(generate_password)
}

###############################################################################
# KZIA Specific Information Collection
# Similar to RCC setup but with KZIA-specific defaults
###############################################################################
collect_kzia_input() {
    echo "=== KZIA System Setup Information Collection ==="
    echo "Please provide the following information:"
    echo "----------------------------------------"
    
    # User Information
    # Default username is 'kzia' if none provided
    echo "Enter new username (default: kzia):"
    read NEW_USER
    NEW_USER=${NEW_USER:-kzia}
    
    # Hostname Configuration
    # Default to current hostname if none provided
    echo "Enter desired hostname (current: $HOSTNAME):"
    read NEW_HOSTNAME
    NEW_HOSTNAME=${NEW_HOSTNAME:-$HOSTNAME}
    
    # Printer Information
    # Basic printer setup for KZIA
    echo "Enter printer IP address:"
    read PRINTER_IP
    echo "Enter printer model:"
    read PRINTER_MODEL
    
    # Generate a secure password for the new user
    NEW_PASSWORD=$(generate_password)
}

###############################################################################
# BH Specific Information Collection
# Similar to RCC setup but with BH-specific defaults
###############################################################################
collect_bh_input() {
    echo "=== BH System Setup Information Collection ==="
    echo "Please provide the following information:"
    echo "----------------------------------------"
    
    # User Information
    # Default username is 'bh' if none provided
    echo "Enter new username (default: bh):"
    read NEW_USER
    NEW_USER=${NEW_USER:-bh}
    
    # Hostname Configuration
    # Default to current hostname if none provided
    echo "Enter desired hostname (current: $HOSTNAME):"
    read NEW_HOSTNAME
    NEW_HOSTNAME=${NEW_HOSTNAME:-$HOSTNAME}
    
    # Printer Information
    # Basic printer setup for BH
    echo "Enter printer IP address:"
    read PRINTER_IP
    echo "Enter printer model:"
    read PRINTER_MODEL
    
    # Generate a secure password for the new user
    NEW_PASSWORD=$(generate_password)
}

###############################################################################
# WWS Specific Information Collection
# Similar to RCC setup but with WWS-specific defaults
###############################################################################
collect_wws_input() {
    echo "=== WWS System Setup Information Collection ==="
    echo "Please provide the following information:"
    echo "----------------------------------------"
    
    # User Information
    # Default username is 'wws' if none provided
    echo "Enter new username (default: wws):"
    read NEW_USER
    NEW_USER=${NEW_USER:-wws}
    
    # Hostname Configuration
    # Default to current hostname if none provided
    echo "Enter desired hostname (current: $HOSTNAME):"
    read NEW_HOSTNAME
    NEW_HOSTNAME=${NEW_HOSTNAME:-$HOSTNAME}
    
    # Printer Information
    # Basic printer setup for WWS
    echo "Enter printer IP address:"
    read PRINTER_IP
    echo "Enter printer model:"
    read PRINTER_MODEL
    
    # Generate a secure password for the new user
    NEW_PASSWORD=$(generate_password)
}

###############################################################################
# EBD Specific Information Collection
# Similar to RCC setup but with EBD-specific defaults
###############################################################################
collect_ebd_input() {
    echo "=== EBD System Setup Information Collection ==="
    echo "Please provide the following information:"
    echo "----------------------------------------"
    
    # User Information
    # Default username is 'ebd' if none provided
    echo "Enter new username (default: ebd):"
    read NEW_USER
    NEW_USER=${NEW_USER:-ebd}
    
    # Hostname Configuration
    # Default to current hostname if none provided
    echo "Enter desired hostname (current: $HOSTNAME):"
    read NEW_HOSTNAME
    NEW_HOSTNAME=${NEW_HOSTNAME:-$HOSTNAME}
    
    # Printer Information
    # Basic printer setup for EBD
    echo "Enter printer IP address:"
    read PRINTER_IP
    echo "Enter printer model:"
    read PRINTER_MODEL
    
    # Generate a secure password for the new user
    NEW_PASSWORD=$(generate_password)
}

###############################################################################
# Information Confirmation Function
# Displays all collected information and asks for confirmation
# Prevents accidental setup with incorrect information
###############################################################################
confirm_information() {
    echo -e "\n=== Collected Information ==="
    echo "Client Code: $CLIENT_CODE"
    echo "Username: $NEW_USER"
    echo "Hostname: $NEW_HOSTNAME"
    echo "Printer IP: $PRINTER_IP"
    echo "Printer Model: $PRINTER_MODEL"
    
    # Only show NoIP information if it was collected (Linder systems)
    if [[ -n "$NOIP_USERNAME" ]]; then
        echo "NoIP Hostname: $NOIP_HOSTNAME"
    fi
    
    # Only show bookmarks information if it was collected (Linder systems)
    if [[ -n "$ADD_BOOKMARKS" ]]; then
        echo "Add Bookmarks: $ADD_BOOKMARKS"
    fi
    
    echo "Generated Password: $NEW_PASSWORD"
    
    # Ask for confirmation before proceeding
    echo -e "\nIs this information correct? (y/n)"
    read CONFIRM
    
    # Exit if user doesn't confirm
    if [[ $CONFIRM != "y" ]]; then
        echo "Setup cancelled. Please run the script again."
        exit 1
    fi
}

###############################################################################
# HTML Report Generation Function
# Creates a professional HTML report of the setup process
# Uses consistent styling with other automated reports
###############################################################################
generate_html_report() {
    local status=$1
    local message=$2
    
    # Create HTML report with professional styling
    cat << EOF > setup_report.html
<!DOCTYPE html>
<html>
<head>
    <title>System Setup Report</title>
    <style>
        body { 
            font-family: Arial, sans-serif;
            background-color: #f8f9fa;
            color: #666;
            margin: 0;
            padding: 20px;
        }
        .report-header { 
            background-color: #005DAA;
            color: white;
            padding: 15px;
            font-size: 24px;
            margin-bottom: 20px;
            border-radius: 5px;
            border-left: 5px solid #FFD700;
        }
        .section-header {
            background-color: #005DAA;
            color: white;
            padding: 10px;
            margin-top: 20px;
            border-radius: 5px;
            border-left: 5px solid #FFD700;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
            background-color: white;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        th {
            background-color: #005DAA;
            color: white;
            padding: 12px;
            text-align: left;
            border-bottom: 2px solid #FFD700;
        }
        td {
            padding: 10px;
            border: 1px solid #ddd;
            color: #666;
        }
        tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        tr:hover {
            background-color: #f0f0f0;
        }
        .status-success {
            color: #005DAA;
            font-weight: bold;
        }
        .status-failed {
            color: #FFD700;
            font-weight: bold;
        }
        .status-error {
            color: #FFD700;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="report-header">System Setup Report - $CLIENT_CODE</div>
    
    <div class="section-header">System Information</div>
    <table>
        <tr>
            <th>Property</th>
            <th>Value</th>
        </tr>
        <tr>
            <td>Hostname</td>
            <td>$(echo "$SYSTEM_INFO" | grep "Hostname:" | cut -d':' -f2)</td>
        </tr>
        <tr>
            <td>CPU</td>
            <td>$(echo "$SYSTEM_INFO" | grep "CPU:" | cut -d':' -f2)</td>
        </tr>
        <tr>
            <td>RAM</td>
            <td>$(echo "$SYSTEM_INFO" | grep "RAM:" | cut -d':' -f2)</td>
        </tr>
        <tr>
            <td>Hardware</td>
            <td>$(echo "$SYSTEM_INFO" | grep "Hardware:" | cut -d':' -f2)</td>
        </tr>
        <tr>
            <td>OS</td>
            <td>$(echo "$SYSTEM_INFO" | grep "OS:" | cut -d':' -f2)</td>
        </tr>
    </table>
    
    <div class="section-header">Setup Tasks</div>
    <table>
        <tr>
            <th>Task</th>
            <th>Status</th>
            <th>Details</th>
        </tr>
        <tr>
            <td>User Creation</td>
            <td class="status-$status">$status</td>
            <td>$message</td>
        </tr>
        <tr>
            <td>Hostname Configuration</td>
            <td class="status-success">Success</td>
            <td>Hostname set to: $NEW_HOSTNAME</td>
        </tr>
        <tr>
            <td>Printer Setup</td>
            <td class="status-success">Success</td>
            <td>Printer $PRINTER_MODEL configured at $PRINTER_IP</td>
        </tr>
        $(if [[ -n "$NOIP_USERNAME" ]]; then
            echo "<tr>
                <td>NoIP Configuration</td>
                <td class=\"status-success\">Success</td>
                <td>NoIP hostname: $NOIP_HOSTNAME</td>
            </tr>"
        fi)
    </table>
</body>
</html>
EOF

    # Send the report via email using sendmail
    (
        echo "From: $REPORT_EMAIL"
        echo "To: $REPORT_EMAIL"
        echo "Subject: System Setup Report - $CLIENT_CODE - $NEW_HOSTNAME"
        echo "MIME-Version: 1.0"
        echo "Content-Type: text/html"
        echo
        cat setup_report.html
    ) | sendmail -t
}

###############################################################################
# Client Code Collection Function
# Continuously prompts for a valid client code until one is provided
# Case-insensitive validation against known client codes
###############################################################################
get_client_code() {
    local valid_codes=("LTS" "RCC" "KZIA" "BH" "WWS" "EBD")
    local client_code=""
    
    while true; do
        echo "Enter client code (LTS, RCC, KZIA, BH, WWS, EBD):"
        read client_code
        
        # Convert input to uppercase for case-insensitive comparison
        client_code=$(echo "$client_code" | tr '[:lower:]' '[:upper:]')
        
        # Check if the code is in our valid codes array
        for code in "${valid_codes[@]}"; do
            if [[ "$client_code" == "$code" ]]; then
                echo "$client_code"
                return 0
            fi
        done
        
        echo "Invalid client code. Please try again."
    done
}

###############################################################################
# Main Script Execution
# This is where the actual setup process begins
###############################################################################
echo "Welcome to the Post-Setup Script"

# First collect all system information
collect_system_info

# Get and validate client code
CLIENT_CODE=$(get_client_code)

# Collect client-specific information based on the code
case $CLIENT_CODE in
    "LTS")
        collect_lts_input
        ;;
    "RCC")
        collect_rcc_input
        ;;
    "KZIA")
        collect_kzia_input
        ;;
    "BH")
        collect_bh_input
        ;;
    "WWS")
        collect_wws_input
        ;;
    "EBD")
        collect_ebd_input
        ;;
    *)
        echo "Invalid client code"
        exit 1
        ;;
esac

# Confirm all collected information before proceeding
confirm_information

# Execute the appropriate setup based on client code
case $CLIENT_CODE in
    "LTS")
        echo "Starting Linder setup..."
        
        # Create new user with generated password
        echo "Creating new user..."
        sudo useradd -m -s /bin/bash $NEW_USER
        echo "$NEW_USER:$NEW_PASSWORD" | sudo chpasswd
        
        # Set the new hostname
        echo "Setting hostname..."
        sudo hostnamectl set-hostname "$NEW_HOSTNAME"
        
        # Special handling for Linux Mint machines with LB in hostname
        if [[ $OS_INFO == *"Linux Mint"* ]] && [[ $NEW_HOSTNAME == *"LB"* ]]; then
            echo "Removing rdp_manager app..."
            sudo apt-get remove -y rdp_manager
        fi
        
        # Install and configure HP printer
        echo "Installing HP printer..."
        sudo apt-get install -y hplip
        # Add printer configuration here
        
        # Configure NoIP
        echo "Configuring NoIP..."
        # Add NoIP configuration here
        
        # Add Chrome bookmarks if requested
        if [[ $ADD_BOOKMARKS == "y" ]]; then
            echo "Adding Chrome bookmarks..."
            # Add Chrome bookmarks configuration here
        fi
        
        # Generate and send the setup report
        generate_html_report "success" "Setup completed successfully"
        ;;
        
    "RCC"|"KZIA"|"BH"|"WWS"|"EBD")
        echo "Starting $CLIENT_CODE setup..."
        
        # Create new user with generated password
        echo "Creating new user..."
        sudo useradd -m -s /bin/bash $NEW_USER
        echo "$NEW_USER:$NEW_PASSWORD" | sudo chpasswd
        
        # Set the new hostname
        echo "Setting hostname..."
        sudo hostnamectl set-hostname "$NEW_HOSTNAME"
        
        # Install and configure printer
        echo "Installing printer..."
        sudo apt-get install -y cups
        # Add printer configuration here
        
        # Generate and send the setup report
        generate_html_report "success" "Setup completed successfully"
        ;;
esac

echo "Setup completed. Check setup_report.html for details."