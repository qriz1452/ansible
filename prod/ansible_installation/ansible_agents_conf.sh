#!/bin/bash

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
  echo -e " ///    ANSIBLE SERVER           ///"
  echo -e " ///                             ///"
  echo -e " ///  CONFIGURATION  SCRIPT      ///"
  echo -e " ///                             ///"
  echo -e " /////////////////////////////////// ${NC}"
  echo -e "${YELLOW}The Script started at: $(date +"%Y-%m-%d %H:%M:%S")${NC}"
}

# Function to check system details
sys_info() {
  echo -e "${GREEN}Fetching OS Details...${NC}"
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    echo -e "${GREEN}Found /etc/os-release. OS is: $OS${NC}"
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    echo -e "${GREEN}Found lsb_release command. OS is: $OS${NC}"
  elif [ -f /etc/lsb_release ]; then
    . /etc/lsb_release
    OS=$DISTRIB_ID
    echo -e "${GREEN}Found /etc/lsb_release. OS is: $OS${NC}"
  elif [ -f /etc/debian_version ]; then
    OS=Debian
    echo -e "${GREEN}Found /etc/debian_version. OS is: $OS${NC}"
  elif [ -f /etc/redhat-release ]; then
    OS=$(cat /etc/redhat-release | awk '{print $1}')
    echo -e "${GREEN}Found /etc/redhat-release. OS is: $OS${NC}"
  else
    OS=$(uname -s0)
    echo -e "${GREEN}OS detection fallback. OS is: $OS${NC}"
  fi
}

# Function to check python and install if not available.
py_check() {
  echo -e "${BLUE}Checking Python version...${NC}"
  if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${BLUE}Python is installed. Python version is: $PYTHON_VERSION${NC}"
  else
    echo -e "${RED}Python is not installed. Installing latest Python...${NC}"
    case $OS in
      "Ubuntu" | "Debian")
        echo -e "${BLUE}Updating package lists...${NC}"
        sudo apt update -y -vvvvv
        echo -e "${BLUE}Installing Python...${NC}"
        sudo apt install python3 -y -vvvvv
        ;;
      "CentOS" | "Red" | "Fedora" | "Amazon")
        echo -e "${BLUE}Updating package lists...${NC}"
        sudo yum update -y -vvvvv
        echo -e "${BLUE}Installing Python...${NC}"
        sudo yum install python3 -y -vvvvv
        ;;
      *)
        echo -e "${RED}Unsupported OS for automatic Python installation.${NC}"
        return
    esac
    if command -v python3 &>/dev/null; then
      PYTHON_VERSION=$(python3 --version)
      echo -e "${BLUE}Python successfully installed: $PYTHON_VERSION${NC}"
    else
      echo -e "${RED}Failed to install Python.${NC}"
    fi
  fi
}

# Function to create ansible user
ansible_user() {
  ANSIBLE_USER="ansible"
  ANSIBLE_GROUP="ansible"
  ANSIBLE_DIR="/home/ansible"

  if getent group $ANSIBLE_GROUP >/dev/null; then
    echo -e "${YELLOW}Ansible group '$ANSIBLE_GROUP' already exists.${NC}"
  else
    echo -e "${YELLOW}Ansible group '$ANSIBLE_GROUP' not found. Creating...${NC}"
    sudo groupadd $ANSIBLE_GROUP 
    echo -e "${YELLOW}Group created.${NC}"
  fi

  if id "$ANSIBLE_USER" &>/dev/null; then
    echo -e "${YELLOW}Ansible user '$ANSIBLE_USER' already exists.${NC}"
  else
    echo -e "${YELLOW}Ansible user '$ANSIBLE_USER' not found. Creating...${NC}"
    sudo useradd -m -d $ANSIBLE_DIR -g $ANSIBLE_GROUP -s /bin/bash $ANSIBLE_USER 
    echo -e "${YELLOW}User created.${NC}"
  fi

  if [ -d "$ANSIBLE_DIR" ]; then
    echo -e "${YELLOW}Ansible home directory '$ANSIBLE_DIR' already exists.${NC}"
  else
    echo -e "${YELLOW}Ansible home directory not found. Creating...${NC}"
    sudo mkdir -p $ANSIBLE_DIR -vvvvv
    echo -e "${YELLOW}Ansible home directory created.${NC}"
  fi

  echo -e "${YELLOW}Updating permissions for Ansible home directory...${NC}"
  sudo chown -R $ANSIBLE_USER:$ANSIBLE_GROUP $ANSIBLE_DIR -vvvvv
  sudo chmod 755 $ANSIBLE_DIR -vvvvv
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
  echo -e  "${RED}Usage: $0 {display_banner|sys_info|py_check|ansible_user|ansible_sec}${NC}"
  echo -e  "${RED}If you want to runn all functions i.e full script use 'all' flag.${NC}"
}

# Main script execution
if [[ $# -eq 0 ]]; then
  show_usage
  exit 1
fi

case $1 in
  display_banner)
    display_banner
    ;;
  sys_info)
    sys_info
    ;;
  py_check)
    py_check
    ;;
  ansible_user)
    ansible_user
    ;;
  ansible_sec)
    ansible_sec
    ;;
  all)
    display_banner
    sys_info
    py_check
    ansible_user
    ansible_sec
    ;;
  *)
    show_usage
    ;;
esac
