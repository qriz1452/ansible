#!/bin/bash

# Define color variables
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
NC='\e[0m' # No Color


# Ask for password
read -sp "Enter password for ansible at remote server ( You may need this password to copy SSH key for passwordless authentication): " SSH_PASSWORD

# Function to display ASCII art for ANSIBLE


display_banner() {
  echo "${CYAN}  ///////////////////////////////////"
  echo " ///                             ///"
  echo " ///    ANSIBLE HOST             ///"
  echo " ///                             ///"
  echo " ///    INSTALLATION SCRIPT      ///"
  echo " ///                             ///"
  echo " /////////////////////////////////// ${NC}"

  echo " "
  echo "${YELLOW}The Script started at  : $(date +"%Y-%m-%d %H:%M:%S") ${NC}"

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
        sudo apt update -y -vvv
        echo -e "${BLUE}Installing Python...${NC}"
        sudo apt install python3 -y -vvv
        ;;
      "CentOS" | "Red" | "Fedora" | "Amazon")
        echo -e "${BLUE}Updating package lists...${NC}"
        sudo yum update -y -vvv
        echo -e "${BLUE}Installing Python...${NC}"
        sudo yum install python3 -y -vvv
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




# Installing ansible
ansible_install(){

  echo -e "${GREEN}Starting Ansible installation in $OS...${NC}"
  case $OS in
    "Ubuntu" | "Debian")
      echo -e "${YELLOW}Updating system repository libraries.${NC}"
      sudo apt update
      echo -e "${YELLOW}Installing the latest version of ansible.${NC}"
      sudo apt install ansible -y

      ;;
    "CentOS" | "Red Hat Enterprise Linux" | "Fedora" | "Amazon Linux")
      sudo yum update
      sudo yum install ansible -y
      ;;
    *)
      echo -e "${RED}Unsupported OS for automatic Ansible Installation.${NC}"
      ;;
  esac

  if command -v ansible &>/dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n1)
    ANSIBLE_COMMUNITY_VERSION=$(ansible-community --version)
    echo -e "${GREEN}Ansible Successfully installed.${NC}"
    echo -e "${CYAN}Ansible Core Version is : $ANSIBLE_VERSION${NC}"
    echo -e "${CYAN}Ansible Community Version is : $ANSIBLE_COMMUNITY_VERSION${NC}"
  else
    echo -e "${RED}Failed to install Ansible.${NC}"
  fi

}

# Ansible User creation
ansible_user(){

  ANSIBLE_USER="ansible"
  ANSIBLE_GROUP="ansible"
  ANSIBLE_DIR="/home/ansible"

  if grep -q "^$ANSIBLE_GROUP:" /etc/group; then
    echo -e "${YELLOW}Ansible group --> $ANSIBLE_GROUP <-- already exists.${NC}"
  else
    echo -e "${YELLOW}Ansible group --> $ANSIBLE_GROUP <-- Not Found.${NC}"
    echo -e "${YELLOW}Creating Ansible group --> $ANSIBLE_GROUP <-- ...${NC}"
    sudo groupadd $ANSIBLE_GROUP
    echo -e "${GREEN}Group Created.${NC}"
  fi

  if id "$ANSIBLE_USER" &>/dev/null; then
    echo -e "${YELLOW}Ansible user --> $ANSIBLE_USER <-- already exists.${NC}"
  else
    echo -e "${YELLOW}Ansible user --> $ANSIBLE_USER <-- Not Found.${NC}"
    echo -e "${YELLOW}Creating Ansible user --> $ANSIBLE_USER <-- ...${NC}"
    sudo useradd -m -d $ANSIBLE_DIR -g $ANSIBLE_GROUP -s /bin/bash $ANSIBLE_USER
    echo -e "${GREEN}User created.${NC}"
  fi

  if [ -d "$ANSIBLE_DIR" ]; then
    echo -e "${YELLOW}Ansible directory --> $ANSIBLE_DIR <-- already exists.${NC}"
  else
    echo -e "${YELLOW}Ansible home directory not found.${NC}"
    echo -e "${YELLOW}Creating Ansible home directory --> $ANSIBLE_DIR <--  ...${NC}"
    sudo mkdir -p $ANSIBLE_DIR
    echo -e "${GREEN}Ansible Home directory created.${NC}"
  fi

  sudo chown -R $ANSIBLE_USER:$ANSIBLE_GROUP $ANSIBLE_DIR
  echo -e "${YELLOW}Ansible home directory permissions updated.${NC}"
  sudo chmod 755 $ANSIBLE_DIR
  echo -e "${YELLOW}Ansible chmod done to 755.${NC}"

  echo -e "${GREEN}Ansible user, group, and directory configurations Completed.${NC}"

}



# Define color variables
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
NC='\e[0m' # No Color

# Generating ansible configuration
ansible_conf() {
    ANSIBLE_CFG="/etc/ansible/ansible.cfg"

    if [ -f "$ANSIBLE_CFG" ]; then
        echo -e "${GREEN}Ansible configuration file --> $ANSIBLE_CFG <-- already exists.${NC}"
    else
        echo -e "${YELLOW}Ansible configuration file not found${NC}"
        echo -e "${BLUE}Creating Ansible configuration file --> $ANSIBLE_CFG <-- ...${NC}"
        sudo ansible-config init --disabled -t all > $ANSIBLE_CFG
        echo -e "${GREEN}Ansible configuration file created.${NC}"
    fi
}

# password and ssh
ansible_sec() {
    ANSIBLE_USER_PASS="password"
    SSH_DIR="$ANSIBLE_DIR/.ssh"
    KEY_NAME="ansible_server_id_rsa"

    echo -e "${BLUE}Setting ansible user password${NC}"
    #echo "$ANSIBLE_USER_PASS" | sudo passwd --stdin $ANSIBLE_USER
    echo "${ANSIBLE_USER}:${ANSIBLE_USER_PASS}" | sudo chpasswd

    if [ ! -d $SSH_DIR ]; then
        echo -e "${BLUE}${SSH_DIR} does not exist, creating...${NC}"
        mkdir -p "$SSH_DIR"
        echo -e "${GREEN}${SSH_DIR} created.${NC}"
        echo -e "${BLUE}Setting ${SSH_DIR} permission...${NC}"
        chown "$ANSIBLE_USER:$ANSIBLE_USER" "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        echo -e "${GREEN}${SSH_DIR} directory permissions updated.${NC}"
    fi
    echo -e "${BLUE}Generating key-pair for ansible servers.${NC}"
    sudo -u "$ANSIBLE_USER" ssh-keygen -t rsa -b 4096 -f "${SSH_DIR}/${KEY_NAME}" -N ""
}

# Copying SSH file to servers.
ssh_copy(){
    SERVER_FILE="server.txt"

    if [[ ! -f "$SERVER_FILE" ]]; then
        echo -e "${RED}Server file not found: $SERVER_FILE${NC}"
        exit 1
    else
        echo -e "${GREEN}Sever file found. $SERVER_FILE${NC}"
    fi

    if [[ ! -f "${SSH_DIR}/${KEY_NAME}" ]]; then
        echo -e "${RED}SSH key file not found: ${SSH_DIR}/${KEY_NAME}${NC}"
        exit 1
    else
        echo -e "${GREEN}SSH key file found : ${SSH_DIR}/${KEY_NAME}${NC}"
    fi

    while IFS= read -r server; do
        # Skip empty lines or lines that start with a comment
        [[ -z "$server" || "$server" =~ ^# ]] && continue
      
        echo -e "${BLUE}Copying SSH key to $server...${NC}"
        sshpass -p "$SSH_PASSWORD" ssh-copy-id -i "${SSH_DIR}/${KEY_NAME}" -o StrictHostKeyChecking=no "$ANSIBLE_USER@$server"

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}Successfully copied SSH key to $server${NC}"
        else
            echo -e "${RED}Failed to copy SSH key to $server${NC}"
        fi
    done < "$SERVER_FILE"

    echo -e "${GREEN}SSH key distribution complete.${NC}"
    su - ansible -c "eval \$(ssh-agent) && ssh-add ${SSH_DIR}/${KEY_NAME}"
    echo -e "${YELLOW}IF YOU ARE GETTING ERROR UNABLE TO SSH THEN EXECUTE THE COMMAND 'eval \$(ssh-agent)' and 'ssh-add ${SSH_DIR}/${KEY_NAME}' command as ansible user in ansible home directory${NC}"
}





# Display the banner
display_banner

# Display system info
sys_info

# Installing Python
py_check

# Ansible installation
ansible_install

# Ansible user creation
ansible_user

#Ansible configuration file
ansible_conf

#Ansible ssh and passwd
ansible_sec

#Copying SSH files
ssh_copy
