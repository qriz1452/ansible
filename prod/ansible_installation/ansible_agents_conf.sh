#!/bin/bash
# This Script Configures ansible on managed servers.
# This Script is tested on Ubuntu 22 , Will update <<--->> here if it is working on other linux flavors.



# Define color variables
RED='\e[31m'            
GREEN='\e[32m'          
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
NC='\e[0m' # No Color

# Function to display ASCII art for ANSIBLE
display_banner() {
  echo -e "${CYAN} ///////////////////////////////////"
  echo -e " ///                             ///"
  echo -e " ///  ANSIBLE Managed VMs        ///"
  echo -e " ///                             ///"
  echo -e " ///  CONFIGURATION  SCRIPT      ///"
  echo -e " ///                             ///"
  echo -e " /////////////////////////////////// ${NC}"
  echo -e "${GREEN}This Script Configures ansible on managed servers.${NC}"
  echo -e "${YELLOW}The Script started at: $(date +"%Y-%m-%d %H:%M:%S")${NC}"
}


# Function to check system details
sys_info() {
  echo -e "${GREEN}Fetching OS Details...${NC}"
  
  # Checking if /etc/os-release file exists
  if [ -f /etc/os-release ]; then           
    . /etc/os-release  # Sourcing the file to get OS details
    OS=$NAME
    echo -e "${GREEN}Found /etc/os-release. OS is: $OS${NC}"

  # Checking if the lsb_release command is available
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)  # Getting the Linux distribution name
    echo -e "${GREEN}Found lsb_release command. OS is: $OS${NC}"

  # Checking if /etc/lsb_release file exists
  elif [ -f /etc/lsb_release ]; then        
    . /etc/lsb_release  # Sourcing the file to get OS details
    OS=$DISTRIB_ID
    echo -e "${GREEN}Found /etc/lsb_release. OS is: $OS${NC}"

  # Checking if /etc/debian_version file exists
  elif [ -f /etc/debian_version ]; then         
    OS=Debian  # Setting OS as Debian
    echo -e "${GREEN}Found /etc/debian_version. OS is: $OS${NC}"

  # Checking if /etc/redhat-release file exists
  elif [ -f /etc/redhat-release ]; then         
    OS=$(cat /etc/redhat-release | awk '{print $1}')  # Extracting the first word, usually the OS name
    echo -e "${GREEN}Found /etc/redhat-release. OS is: $OS${NC}"

  # Fallback: using uname to get the OS kernel name
  else
    OS=$(uname -s)  # Getting the kernel name
    echo -e "${GREEN}OS detection fallback. OS is: $OS${NC}"
  fi
}



# Function to check Python and install if not available
py_check() {
  echo -e "${BLUE}Checking Python version...${NC}"
  
  # Check if Python 3 is installed
  if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version)  # Get the installed Python version
    echo -e "${BLUE}Python is installed. Python version is: $PYTHON_VERSION${NC}"
  else
    echo -e "${RED}Python is not installed. Installing the latest Python...${NC}"
    
    # Determine the package manager and install Python based on the OS
    case $OS in
      "Ubuntu" | "Debian")
        echo -e "${BLUE}Updating package lists...${NC}"
        sudo apt update -y -vvvvv  # Update the package lists for APT
        echo -e "${BLUE}Installing Python...${NC}"
        sudo apt install python3 -y -vvvvv  # Install Python 3 using APT
        ;;
      "CentOS" | "Red" | "Fedora" | "Amazon")
        echo -e "${BLUE}Updating package lists...${NC}"
        sudo yum update -y -vvvvv  # Update the package lists for YUM
        echo -e "${BLUE}Installing Python...${NC}"
        sudo yum install python3 -y -vvvvv  # Install Python 3 using YUM
        ;;
      *)
        echo -e "${RED}Unsupported OS for automatic Python installation.${NC}"
        return  # Exit the function if the OS is not supported
    esac

    # Verify if Python 3 was successfully installed
    if command -v python3 &>/dev/null; then
      PYTHON_VERSION=$(python3 --version)  # Get the installed Python version
      echo -e "${BLUE}Python successfully installed: $PYTHON_VERSION${NC}"
    else
      echo -e "${RED}Failed to install Python.${NC}"
    fi
  fi
}


# Function to create ansible user
ansible_user() {
  ANSIBLE_USER="ansible"       # Define the Ansible username
  ANSIBLE_GROUP="ansible"      # Define the Ansible group
  ANSIBLE_DIR="/home/ansible"  # Define the home directory for the Ansible user

  # Check if the Ansible group exists
  if getent group $ANSIBLE_GROUP >/dev/null; then
    echo -e "${YELLOW}Ansible group '$ANSIBLE_GROUP' already exists.${NC}"
  else
    echo -e "${YELLOW}Ansible group '$ANSIBLE_GROUP' not found. Creating...${NC}"
    sudo groupadd $ANSIBLE_GROUP  # Create the Ansible group
    echo -e "${YELLOW}Group created.${NC}"
  fi

  # Check if the Ansible user exists
  if id "$ANSIBLE_USER" &>/dev/null; then
    echo -e "${YELLOW}Ansible user '$ANSIBLE_USER' already exists.${NC}"
  else
    echo -e "${YELLOW}Ansible user '$ANSIBLE_USER' not found. Creating...${NC}"
    sudo useradd -m -d $ANSIBLE_DIR -g $ANSIBLE_GROUP -s /bin/bash $ANSIBLE_USER  # Create the Ansible user with specified home directory and shell
    echo -e "${YELLOW}User created.${NC}"
  fi

  # Check if the Ansible home directory exists
  if [ -d "$ANSIBLE_DIR" ]; then
    echo -e "${YELLOW}Ansible home directory '$ANSIBLE_DIR' already exists.${NC}"
  else
    echo -e "${YELLOW}Ansible home directory not found. Creating...${NC}"
    sudo mkdir -p $ANSIBLE_DIR -vvvvv  # Create the home directory
    echo -e "${YELLOW}Ansible home directory created.${NC}"
  fi

  # Update the permissions for the Ansible home directory
  echo -e "${YELLOW}Updating permissions for Ansible home directory...${NC}"
  sudo chown -R $ANSIBLE_USER:$ANSIBLE_GROUP $ANSIBLE_DIR -vvvvv  # Change ownership to the Ansible user and group
  sudo chmod 755 $ANSIBLE_DIR -vvvvv  # Set the appropriate permissions
  echo -e "${YELLOW}Permissions updated.${NC}"

  echo -e "${YELLOW}Ansible user, group, and directory configuration completed.${NC}"
}




# Function to configure ansible user security
ansible_sec() {
  ANSIBLE_USER_PASS="password"
  SSH_DIR="/home/ansible/.ssh"

  echo -e "${MAGENTA}Setting ansible user password...${NC}"
  echo "${ANSIBLE_USER}:${ANSIBLE_USER_PASS}" | sudo chpasswd 
  echo -e "${MAGENTA}Password set.${NC}"

  if [ ! -d $SSH_DIR ]; then
    echo -e "${MAGENTA}$SSH_DIR does not exist. Creating...${NC}"
    sudo mkdir -p "$SSH_DIR" -vvvvv
    echo -e "${MAGENTA}$SSH_DIR created.${NC}"
  fi

  echo -e "${MAGENTA}Setting permissions for $SSH_DIR...${NC}"
  sudo chown "$ANSIBLE_USER:$ANSIBLE_USER" "$SSH_DIR" -vvvvv
  sudo chmod 700 "$SSH_DIR" -vvvvv
  echo -e "${MAGENTA}Permissions updated.${NC}"

  echo -e "${MAGENTA}Reviewing and setting permissions for ansible home directory, ssh, and authorized keys...${NC}"
  sudo chmod 0700 $ANSIBLE_DIR -vvvvv
  sudo chmod 0700 $SSH_DIR -vvvvv
  sudo touch $SSH_DIR/authorized_keys 
  sudo chmod 0600 $SSH_DIR/authorized_keys -vvvvv
  sudo chown "$ANSIBLE_USER:$ANSIBLE_USER" $SSH_DIR/authorized_keys -vvvvv
  echo -e "${MAGENTA}Permissions for SSH directory and files updated.${NC}"

  # Path to the sshd_config file
  SSHD_CONFIG="/etc/ssh/sshd_config"

  # Function to update sshd_config
  update_sshd_config() {
    local setting="$1"
    local value="$2"
    if grep -q "^#*$setting" "$SSHD_CONFIG"; then
      echo -e "${CYAN}Updating existing setting $setting in $SSHD_CONFIG to $value...${NC}"
      sudo sed -i "s|^#*$setting.*|$setting $value|" "$SSHD_CONFIG" 
    else
      echo -e "${CYAN}Adding new setting $setting to $SSHD_CONFIG with value $value...${NC}"
      echo "$setting $value" | sudo tee -a "$SSHD_CONFIG" > /dev/null
    fi
    echo -e "${CYAN}Setting $setting updated to $value.${NC}"
  }

  echo -e "${CYAN}Updating SSH configuration...${NC}"
  update_sshd_config "PubkeyAuthentication" "yes"
  update_sshd_config "PasswordAuthentication" "yes"
  update_sshd_config "AuthorizedKeysFile" ".ssh/authorized_keys"
  update_sshd_config "PermitRootLogin" "no"
  update_sshd_config "ChallengeResponseAuthentication" "no"
  update_sshd_config "UsePAM" "yes"
  update_sshd_config "GSSAPIAuthentication" "yes"
  update_sshd_config "GSSAPICleanupCredentials" "no"
  echo -e "${CYAN}SSH configuration updated.${NC}"

  echo -e "${CYAN}Restarting SSH service...${NC}"

if [[ "$OS" == "Ubuntu" || "$OS" == "Debian" ]]; then
    sudo systemctl restart ssh 
  else
    sudo systemctl restart sshd 
  fi
  echo -e "${CYAN}SSH service restarted.${NC}"

  echo -e "${GREEN}Adding ansible user to sudoers...${NC}"
  if ! sudo grep -q "^ansible ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null
    echo -e "${GREEN}Ansible user added to sudoers with NOPASSWD privileges.${NC}"
  else
    echo -e "${GREEN}Ansible user already has NOPASSWD sudo privileges.${NC}"
  fi
}


# Function to show usage
show_usage() {
  echo -e "${RED}Usage: $0 [OPTION]${NC}"
  echo -e "${RED}Script to configure ansible managed nodes.${NC}"
  echo
  echo -e "${RED}Options:${NC}"
  echo -e "${RED}  --display_banner, -db    Display the banner information${NC}"
  echo -e "${RED}  --system_info, -si      Show system information${NC}"
  echo -e "${RED}  --python_check, -pc     Check Python installation and version${NC}"
  echo -e "${RED}  --ansible_user, -au     Configure ansible user${NC}"
  echo -e "${RED}  --ansible_security, -as Configure ansible security settings${NC}"
  echo -e "${RED}  --all, -a               Run all functions (full script)${NC}"
  echo -e "${RED}  -h, --help              Display this help and exit${NC}"
  echo
  echo -e "${RED}Example:${NC}"
  echo -e "${RED}  $0 --display_banner${NC}"
  echo -e "${RED}  $0 -db${NC}"
  echo -e "${RED}  $0 --all${NC}"
  echo
}


LOG_FILE="/path/to/your/logfile.log"

# Function to log and display output
log_and_display() {
  while IFS= read -r line; do
    echo "$line" | tee -a "$LOG_FILE"
  done
}

# Redirect stdout and stderr to the log_and_display function
exec > >(log_and_display)
exec 2>&1


# Main script execution
if [[ $# -eq 0 ]]; then
  show_usage
  exit 1
fi

case $1 in
  --display_banner | -db )
    echo "${RED} You are only running part of script $0 , This script is written for ansible managed node configuration.${NC}"
    display_banner
    ;;
  --system_info | -si)
    echo "${RED} You are only running part of script $0 , This script is written for ansible managed node configuration.${NC}"
    sys_info
    ;;
  --python_check | -pc)
    echo "${RED} You are only running part of script $0 , This script is written for ansible managed node configuration.${NC}"
    py_check
    ;;
  --ansible_user | -au)
    echo "${RED} You are only running part of script $0 , This script is written for ansible managed node configuration.${NC}"
    ansible_user
    ;;
  --ansible_security | -as)
    echo "${RED} You are only running part of script $0 , This script is written for ansible managed node configuration.${NC}"
    ansible_sec
    ;;
  --all | -a)
    display_banner
    sys_info
    py_check
    ansible_user
    ansible_sec
    ;;
  --help | -h)
    show_usage
    ;;
  *)
    show_usage
    ;;
esac
