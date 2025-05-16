#!/bin/bash

###############################################################################
# Email Configuration
# These settings are used for sending status reports via SMTP2GO
# DO NOT MODIFY THESE VALUES WITHOUT UPDATING THE SMTP2GO CONFIGURATION
###############################################################################
REPORT_EMAIL="NewLinuxInstall@its-ia.com"    # The email address that will send reports
RECIPIENT_EMAIL="ssaunders@its-ia.com"  # The email address that will receive reports
SMTP2GO_SERVER="mail.smtp2go.com"           # SMTP2GO's mail server address
SMTP2GO_PORT="2525"                         # SMTP2GO's mail server port
SMTP2GO_USERNAME="SRVLinux"                 # SMTP2GO account username
SMTP2GO_PASSWORD="tIx3SXLn2tF4jYxa"        # SMTP2GO account password

###############################################################################
# Password Generation Function
# Creates a secure, memorable password using random words
# Ensures password meets security requirements (capital, special char)
###############################################################################
generate_password() {
    # Check if words file exists
    if [ ! -f "/usr/share/dict/words" ]; then
        echo "Error: /usr/share/dict/words not found. Installing wamerican package..."
        sudo apt-get install -y wamerican
    fi

    # Get three random words (4-8 characters each)
    local word1=$(grep -E '^[a-z]{4,8}$' /usr/share/dict/words | shuf -n 1)
    local word2=$(grep -E '^[a-z]{4,8}$' /usr/share/dict/words | shuf -n 1)
    local word3=$(grep -E '^[a-z]{4,8}$' /usr/share/dict/words | shuf -n 1)

    # Capitalize first word
    word1=$(echo "$word1" | sed 's/^./\U&/')

    # Add random special characters
    local special_chars="!@#$%^&*"
    local special_char1=$(echo "$special_chars" | fold -w1 | shuf | head -n1)
    local special_char2=$(echo "$special_chars" | fold -w1 | shuf | head -n1)

    # Combine words with special characters
    echo "${word1}${special_char1}${word2}${special_char2}${word3}"
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
    
    # Get CPU information using lscpu
    # grep for model name and clean up the output
    CPU_INFO=$(lscpu | grep "Model name" | cut -d':' -f2 | sed 's/^[ \t]*//')
    
    # Get RAM information using free command
    # Extract total memory in human-readable format
    RAM_INFO=$(free -h | grep Mem | awk '{print $2}')
    
    # Get detailed hardware information using dmidecode
    # Extract manufacturer, product name, and serial number
    HARDWARE_INFO=$(sudo dmidecode -t system | awk -F: '/Manufacturer:|Product Name:|Serial Number:/ {gsub(/^[ \t]+/, "", $2); print $1 ": " $2}')
    
    # Get OS information using lsb_release
    # Extract the distribution description
    OS_INFO=$(lsb_release -d | cut -d':' -f2 | sed 's/^[ \t]*//')
}

###############################################################################
# Computer Type Validation Function
# Validates the entered computer type against allowed values
# Handles case-insensitive input and provides user feedback
###############################################################################
validate_computer_type() {
    echo "DEBUG: Entering validate_computer_type function"
    local valid_types=("LT" "LB" "LC")
    local input_type=""
    local is_valid=0
    
    while [ $is_valid -eq 0 ]; do
        echo "Enter computer type (LT, LB, LC):"
        read -r input_type
        
        if [ -z "$input_type" ]; then
            echo "No input provided. Please try again."
            continue
        fi
        
        # Convert input to uppercase for comparison
        input_type=$(echo "$input_type" | tr '[:lower:]' '[:upper:]')
        
        # Check if the type is in the valid types array
        for type in "${valid_types[@]}"; do
            if [ "$input_type" = "$type" ]; then
                is_valid=1
                echo "Valid type found: $input_type"
                break
            fi
        done
        
        if [ $is_valid -eq 0 ]; then
            echo "Invalid computer type. Please try again."
        fi
    done
    
    # Set the global variable
    COMPUTER_TYPE="$input_type"
}

###############################################################################
# IP Address Validation Function
# Validates IP address format and ensures it's a valid private IP
###############################################################################
validate_ip() {
    local ip=$1
    local valid=0
    
    # Check if input is empty
    if [ -z "$ip" ]; then
        echo "IP address cannot be empty"
        return 1
    fi
    
    # Check IP format (x.x.x.x where x is 0-255)
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # Split IP into octets
        IFS='.' read -r -a octets <<< "$ip"
        
        # Check each octet is between 0-255
        for octet in "${octets[@]}"; do
            if [ "$octet" -gt 255 ] || [ "$octet" -lt 0 ]; then
                echo "Invalid IP address: octet $octet is not between 0-255"
                return 1
            fi
        done
        
        # Check if it's a private IP
        local first_octet=${octets[0]}
        local second_octet=${octets[1]}
        
        if [ "$first_octet" -eq 10 ]; then
            valid=1
        elif [ "$first_octet" -eq 172 ] && [ "$second_octet" -ge 16 ] && [ "$second_octet" -le 31 ]; then
            valid=1
        elif [ "$first_octet" -eq 192 ] && [ "$second_octet" -eq 168 ]; then
            valid=1
        else
            echo "Invalid IP address: Must be a private IP address (10.x.x.x, 172.16-31.x.x, or 192.168.x.x)"
            return 1
        fi
    else
        echo "Invalid IP address format. Please use x.x.x.x format"
        return 1
    fi
    
    # Try to ping the IP to verify it's reachable
    if ! ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        echo "Warning: IP address $ip is not responding to ping"
        # Don't return failure here, just warn
    fi
    
    return 0
}

###############################################################################
# Printer IP Collection Function
# Collects and validates printer IP address
###############################################################################
collect_printer_ip() {
    local ip=""
    local is_valid=0
    
    while [ $is_valid -eq 0 ]; do
        echo "Enter printer IP address:"
        read -r ip
        
        if validate_ip "$ip"; then
            is_valid=1
            echo "$ip"
        else
            echo "Please try again."
        fi
    done
}

###############################################################################
# NoIP Configuration Function
# Downloads, installs, and configures NoIP DUC client
###############################################################################
configure_noip() {
    echo "=== NoIP Configuration ==="
    echo "Enter NoIP username:"
    read NOIP_USERNAME
    echo "Enter NoIP password:"
    read -s NOIP_PASSWORD
    echo
    
    # Download the latest NoIP DUC
    echo "Downloading NoIP DUC..."
    if ! wget --content-disposition https://www.noip.com/download/linux/latest; then
        NOIP_INSTALL_STATUS="failed"
        NOIP_INSTALL_MESSAGE="Failed to download NoIP DUC"
        return 1
    fi
    
    # Extract the downloaded file
    echo "Extracting NoIP DUC..."
    if ! tar xf noip-duc_*.tar.gz; then
        NOIP_INSTALL_STATUS="failed"
        NOIP_INSTALL_MESSAGE="Failed to extract NoIP DUC"
        return 1
    fi
    
    # Install the package
    echo "Installing NoIP DUC..."
    cd noip-duc_*/binaries
    # Fix permissions for the .deb file
    sudo chown root:root noip-duc_*_amd64.deb
    sudo chmod 644 noip-duc_*_amd64.deb
    if ! sudo apt install -y ./noip-duc_*_amd64.deb; then
        NOIP_INSTALL_STATUS="failed"
        NOIP_INSTALL_MESSAGE="Failed to install NoIP DUC package"
        cd - > /dev/null
        return 1
    fi
    NOIP_INSTALL_STATUS="success"
    NOIP_INSTALL_MESSAGE="NoIP DUC package installed successfully"
    cd - > /dev/null
    
    # Create NoIP configuration file
    echo "USERNAME=$NOIP_USERNAME" | sudo tee /etc/default/noip-duc
    echo "PASSWORD=$NOIP_PASSWORD" | sudo tee -a /etc/default/noip-duc
    echo "HOSTNAME=all.ddnskey.com" | sudo tee -a /etc/default/noip-duc
    
    # Verify configuration file
    if [ -f "/etc/default/noip-duc" ] && grep -q "USERNAME=$NOIP_USERNAME" "/etc/default/noip-duc"; then
        NOIP_CONFIG_STATUS="success"
        NOIP_CONFIG_MESSAGE="NoIP configuration file created successfully"
    else
        NOIP_CONFIG_STATUS="failed"
        NOIP_CONFIG_MESSAGE="Failed to create NoIP configuration file"
        return 1
    fi
    
    # Start NoIP DUC service
    echo "Starting NoIP DUC service..."
    if ! sudo systemctl start noip-duc; then
        NOIP_SERVICE_STATUS="failed"
        NOIP_SERVICE_MESSAGE="Failed to start NoIP DUC service"
        NOIP_SERVICE_OUTPUT=$(systemctl status noip-duc | cat)
        return 1
    fi
    
    # Enable NoIP DUC service to start on boot
    sudo systemctl enable noip-duc
    
    # Wait a moment for the service to initialize
    sleep 5
    
    # Check service status and verify it's running
    NOIP_SERVICE_OUTPUT=$(systemctl status noip-duc | cat)
    if systemctl is-active --quiet noip-duc; then
        NOIP_SERVICE_STATUS="success"
        NOIP_SERVICE_MESSAGE="NoIP DUC service is running"
    else
        NOIP_SERVICE_STATUS="failed"
        NOIP_SERVICE_MESSAGE="NoIP DUC service is not running properly"
        return 1
    fi
}

###############################################################################
# Linder (LTS) Specific Information Collection
# Gathers all necessary information for setting up a Linder system
# Includes special requirements like HP printer setup
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
    PRINTER_IP=$(collect_printer_ip)
    echo "Enter HP printer model:"
    read PRINTER_MODEL
    
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
    echo "Computer Type: $COMPUTER_TYPE"
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
# Status Tracking Variables
###############################################################################
USER_CREATION_STATUS="failed"
USER_CREATION_MESSAGE=""
HOSTNAME_STATUS="failed"
HOSTNAME_MESSAGE=""
PRINTER_STATUS="failed"
PRINTER_MESSAGE=""
NOIP_INSTALL_STATUS="failed"
NOIP_INSTALL_MESSAGE=""
NOIP_CONFIG_STATUS="failed"
NOIP_CONFIG_MESSAGE=""
NOIP_SERVICE_STATUS="failed"
NOIP_SERVICE_MESSAGE=""
NOIP_SERVICE_OUTPUT=""

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
        .password-box {
            background-color: #f8f9fa;
            border: 2px solid #005DAA;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
            font-family: monospace;
            font-size: 18px;
            text-align: center;
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
            <td>Computer Type</td>
            <td>$(get_computer_type_name "$COMPUTER_TYPE")</td>
        </tr>
        <tr>
            <td>Hostname</td>
            <td>$NEW_HOSTNAME</td>
        </tr>
        <tr>
            <td>CPU</td>
            <td>$CPU_INFO</td>
        </tr>
        <tr>
            <td>RAM</td>
            <td>$RAM_INFO</td>
        </tr>
        <tr>
            <td>Hardware</td>
            <td>$HARDWARE_INFO</td>
        </tr>
        <tr>
            <td>OS</td>
            <td>$OS_INFO</td>
        </tr>
    </table>
    
    <div class="section-header">User Account Information</div>
    <div class="password-box">
        Username: $NEW_USER<br>
        Temporary Password: $NEW_PASSWORD
    </div>
    
    <div class="section-header">Setup Tasks</div>
    <table>
        <tr>
            <th>Task</th>
            <th>Status</th>
            <th>Details</th>
        </tr>
        <tr>
            <td>User Creation</td>
            <td class="status-$USER_CREATION_STATUS">$USER_CREATION_STATUS</td>
            <td>$USER_CREATION_MESSAGE</td>
        </tr>
        <tr>
            <td>Hostname Configuration</td>
            <td class="status-$HOSTNAME_STATUS">$HOSTNAME_STATUS</td>
            <td>$HOSTNAME_MESSAGE</td>
        </tr>
        <tr>
            <td>Printer Setup</td>
            <td class="status-$PRINTER_STATUS">$PRINTER_STATUS</td>
            <td>$PRINTER_MESSAGE</td>
        </tr>
        $(if [[ -n "$NOIP_USERNAME" ]]; then
            echo "<tr>
                <td>NoIP Installation</td>
                <td class=\"status-$NOIP_INSTALL_STATUS\">$NOIP_INSTALL_STATUS</td>
                <td>$NOIP_INSTALL_MESSAGE</td>
            </tr>
            <tr>
                <td>NoIP Configuration</td>
                <td class=\"status-$NOIP_CONFIG_STATUS\">$NOIP_CONFIG_STATUS</td>
                <td>$NOIP_CONFIG_MESSAGE</td>
            </tr>
            <tr>
                <td>NoIP Service</td>
                <td class=\"status-$NOIP_SERVICE_STATUS\">$NOIP_SERVICE_STATUS</td>
                <td>
                    $NOIP_SERVICE_MESSAGE
                    <br><br>
                    <strong>Service Status:</strong>
                    <pre style=\"background-color: #f8f9fa; padding: 10px; border-radius: 5px; font-size: 12px; white-space: pre-wrap;\">$(echo "$NOIP_SERVICE_OUTPUT" | sed 's/active (running)/<span style=\"color: green;\">active (running)<\/span>/g; s/failed/<span style=\"color: red;\">failed<\/span>/g; s/inactive/<span style=\"color: red;\">inactive<\/span>/g; s/dead/<span style=\"color: red;\">dead<\/span>/g')</pre>
                </td>
            </tr>"
        fi)
    </table>
</body>
    <div style='border-top: 3px solid #005DAA; padding-top: 20px; margin-top: 30px; font-size: 12px; color: #666;'>
        Generated on $(date '+%Y-%m-%d %H:%M:%S')
    </div>
</html>
EOF

    # Send the report via email using sendemail
    if ! command -v sendemail &> /dev/null; then
        echo "Installing sendemail..."
        sudo apt-get install -y sendemail
    fi

    sendemail -f "$REPORT_EMAIL" \
              -t "$RECIPIENT_EMAIL" \
              -u "System Setup Report - $CLIENT_CODE - $COMPUTER_TYPE - $NEW_HOSTNAME" \
              -s "$SMTP2GO_SERVER:$SMTP2GO_PORT" \
              -xu "$SMTP2GO_USERNAME" \
              -xp "$SMTP2GO_PASSWORD" \
              -o tls=yes \
              -o message-content-type=html \
              -o message-file=setup_report.html
}

###############################################################################
# Client Code Validation Function
# Validates the entered client code against allowed values
# Handles case-insensitive input and provides user feedback
###############################################################################
validate_client_code() {
    echo "DEBUG: Entering validate_client_code function"
    local valid_codes=("LTS" "RCC" "KZIA" "BH" "WWS" "EBD")
    local input_code=""
    local is_valid=0
    
    while [ $is_valid -eq 0 ]; do
        echo "Enter client code (LTS, RCC, KZIA, BH, WWS, EBD):"
        read -r input_code
        
        if [ -z "$input_code" ]; then
            echo "No input provided. Please try again."
            continue
        fi
        
        # Convert input to uppercase for comparison
        input_code=$(echo "$input_code" | tr '[:lower:]' '[:upper:]')
        
        # Check if the code is in the valid codes array
        for code in "${valid_codes[@]}"; do
            if [ "$input_code" = "$code" ]; then
                is_valid=1
                echo "Valid code found: $input_code"
                break
            fi
        done
        
        if [ $is_valid -eq 0 ]; then
            echo "Invalid client code. Please try again."
        fi
    done
    
    # Set the global variable directly instead of returning
    CLIENT_CODE="$input_code"
}

###############################################################################
# Computer Type Name Conversion Function
# Converts computer type codes to their full names
###############################################################################
get_computer_type_name() {
    case "$1" in
        "LT")
            echo "LETC"
            ;;
        "LB")
            echo "Linux Browser"
            ;;
        "LC")
            echo "Linux Combo"
            ;;
        *)
            echo "$1"
            ;;
    esac
}

###############################################################################################################################################################################################
# Main Script Execution
# This is where the actual setup process begins
###############################################################################################################################################################################################
echo "Welcome to the Post-Setup Script"

# First collect all system information
collect_system_info

# Get and validate computer type
echo "About to validate computer type..."
validate_computer_type
echo "Computer type validation complete. Type: $COMPUTER_TYPE"

# Get and validate client code
echo "About to validate client code..."
validate_client_code
echo "Client code validation complete. Code: $CLIENT_CODE"

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
        if sudo useradd -m -s /bin/bash $NEW_USER && echo "$NEW_USER:$NEW_PASSWORD" | sudo chpasswd; then
            USER_CREATION_STATUS="success"
            USER_CREATION_MESSAGE="User $NEW_USER created successfully"
        else
            USER_CREATION_STATUS="failed"
            USER_CREATION_MESSAGE="Failed to create user $NEW_USER"
        fi
        
        # Set the new hostname
        echo "Setting hostname..."
        if sudo hostnamectl set-hostname "$NEW_HOSTNAME"; then
            HOSTNAME_STATUS="success"
            HOSTNAME_MESSAGE="Hostname set to: $NEW_HOSTNAME"
        else
            HOSTNAME_STATUS="failed"
            HOSTNAME_MESSAGE="Failed to set hostname to $NEW_HOSTNAME"
        fi
        
        # Special handling for LB computers
        if [ "$COMPUTER_TYPE" = "LB" ]; then
            echo "Removing rdp_manager..."
            if sudo apt-get remove -y rdp_manager; then
                echo "rdp_manager removed successfully"
            else
                echo "Failed to remove rdp_manager"
            fi
        fi
        
        # Configure NoIP for LT and LC computers
        if [ "$COMPUTER_TYPE" = "LT" ] || [ "$COMPUTER_TYPE" = "LC" ]; then
            configure_noip
            if [ -f "/etc/default/noip-duc" ] && grep -q "USERNAME=$NOIP_USERNAME" "/etc/default/noip-duc"; then
                NOIP_STATUS="success"
                NOIP_MESSAGE="NoIP configured successfully for username: $NOIP_USERNAME, hostname: all.ddnskey.com"
            else
                NOIP_STATUS="failed"
                NOIP_MESSAGE="Failed to configure NoIP for username: $NOIP_USERNAME"
            fi
        fi
        
        # Install and configure HP printer
        echo "Installing HP printer..."
        if sudo apt-get install -y hplip; then
            PRINTER_STATUS="success"
            PRINTER_MESSAGE="Printer software installed successfully"
            
            # TODO: Add actual printer configuration here
            # We'll work on this next
        else
            PRINTER_STATUS="failed"
            PRINTER_MESSAGE="Failed to install printer software"
        fi
        
        # Add Chrome bookmarks if requested
        if [[ $ADD_BOOKMARKS == "y" ]]; then
            echo "Adding Chrome bookmarks..."
            # Add Chrome bookmarks configuration here
        fi
        
        # Generate and send the setup report
        if [ "$USER_CREATION_STATUS" = "success" ] && [ "$HOSTNAME_STATUS" = "success" ] && [ "$PRINTER_STATUS" = "success" ]; then
            generate_html_report "success" "Setup completed successfully"
        else
            generate_html_report "failed" "Some setup tasks failed. Please check the report for details."
        fi
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