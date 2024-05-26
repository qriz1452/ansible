#!/bin/bash



# Ask for password
read -sp "Enter password for ansible at remote server ( You may need this password to copy SSH key for passwordless authentication): " SSH_PASSWORD

# Function to display ASCII art for ANSIBLE


display_banner() {
  echo " ///////////////////////////////////"
  echo " ///                             ///"
  echo " ///    ANSIBLE HOST             ///"
  echo " ///                             ///"
  echo " ///    INSTALLATION SCRIPT      ///"
  echo " ///                             ///"
  echo " /////////////////////////////////// "

  echo " "
  echo "The Script started at  : $(date +"%Y-%m-%d %H:%M:%S")"

}


# Function to check system details

sys_info() {

  echo "Fetching OS Details......"
  # For most modern Linux Distributions
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
  # For older versions of ubuntu
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
  # For older version of ubuntu without lsb_release command
  elif [ -f /etc/lsb_release ]; then
    . /etc/lsb_release
    OS=$DISTRIB_ID
  # For Debian
  elif [ -f /etc/debian_version ]; then
    OS=Debian
  # For RHEL - CentOS, Fedora, Amazon Linux
  elif [ -f /etc/redhat-release ]; then
    OS=$(cat /etc/redhat-release | awk '{print $1}')
  # Fallback to uname
  else
    OS=$(uname -s0)
  fi

  echo "Detected OS  is  : $OS"
}




# Function to check python and install if not available.
py_check(){
  echo "Checking Python version..."
  if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "Python is installed. Python version is  : $PYTHON_VERSION"
  else
    echo "Python is not installed. Installing latest Python..."
    case $OS in
      "Ubuntu" | "Debian")
        sudo apt update -y
        sudo apt install python3 -y
        ;;

      "CentOS" | "Red Hat Enterprise Linux" | "Fedora" | "Amazon Linux")
        sudo yum  update -y
        sudo yum install python3 -y
        ;;
      *)
        echo "Unsupported OS for automatic Python installation."
    esac
    if command -v python3 &>/dev/null; then
      PYTHON_VERSION=$(python3 --version)
      echo "Python successfully installed: $PYTHON_VERSION"
    else
      echo "Failed to install Python."
    fi
  fi

}


# Installing ansible
ansible_install(){

  echo "Starting Ansible installation in $OS..."
  case $OS in
    "Ubuntu" | "Debian")
      echo "Updating system repository libraries."
      sudo apt update
      echo "Installing latest version of ansible."
      sudo apt install ansible -y

      ;;
    "CentOS" | "Red Hat Enterprise Linux" | "Fedora" | "Amazon Linux")
      sudo yum update
      sudo yum install ansible -y
      ;;
    *)
      echo "Unsupported OS for automatic Ansible Installation."
      ;;
  esac

  if command -v ansible &>/dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n1)
    ANSIBLE_COMMUNITY_VERSION=$(ansible-community --version)
    echo "Ansible Successfully installed."
    echo "Ansible Core Version is : $ANSIBLE_VERSION"
    echo "Ansible Community Version is : $ANSIBLE_COMMUNITY_VERSION"
  else
    echo "Failed to install Ansible."
  fi

}


# Ansible User creation
ansible_user(){

ANSIBLE_USER="ansible"
ANSIBLE_GROUP="ansible"
ANSIBLE_DIR="/home/ansible"

  if grep -q "^$ANSIBLE_GROUP:" /etc/group; then
    echo "Ansible group --> $ANSIBLE_GROUP <-- already exist."
  else
    echo "Ansible group --> $ANSIBLE_GROUP <-- Not Found"
    echo "Creating Ansible group --> $ANSIBLE_GROUP <-- ..."
    sudo groupadd $ANSIBLE_GROUP
    echo "Group Created."
  fi


  if id "$ANSIBLE_USER" &>/dev/null; then
    echo "Ansible user --> $ANSIBLE_USER <-- already exist."
  else
    echo "Ansible user --> $ANSIBLE_USER <-- Not Found."
    echo "Creating Ansible user --> $ANSIBLE_USER <-- ..."
    sudo useradd -m -d $ANSIBLE_DIR -g $ANSIBLE_GROUP -s /bin/bash $ANSIBLE_USER
    echo "User created"
  fi


  if [ -d "$ANSIBLE_DIR" ]; then
    echo "Ansible directory --> $ANSIBLE_DIR <-- already exist"
  else
    echo "Ansible home directory not found"
    echo "Creating ansible home directory --> $ANSIBLE_DIR <--  ..."
    sudo mkdir -p $ANSIBLE_DIR
    echo "Ansible Home directory created."
  fi




  sudo chown -R $ANSIBLE_USER:$ANSIBLE_GROUP $ANSIBLE_DIR
  echo "Ansible home directory permissions updated"
  sudo chmod 755 $ANSIBLE_DIR
  echo "Ansible chmod done to 755"

  echo "Ansible user,group and directory configurations Completed."



}


# Generating ansible configuration

ansible_conf() {

ANSIBLE_CFG="/etc/ansible/ansible.cfg"

  if [ -f "$ANSIBLE_CFG" ]; then
    echo "Ansible configuration file --> $ANSIBLE_CFG <-- already exists."
  else
    echo "Ansible configuration file not found"
    echo "Creating Ansible configuration file --> $ANSIBLE_CFG <-- ..."
    sudo ansible-config init --disabled -t all > $ANSIBLE_CFG
    echo "Ansible configuration file created."
  fi
}

# password and ssh
ansible_sec() {

ANSIBLE_USER_PASS="password"
SSH_DIR="$ANSIBLE_DIR/.ssh"
KEY_NAME="ansible_server_id_rsa"

  echo "Setting ansible user password"
  #echo "$ANSIBLE_USER_PASS" | sudo passwd --stdin $ANSIBLE_USER
  echo "${ANSIBLE_USER}:${ANSIBLE_USER_PASS}" | sudo chpasswd


  if [ ! -d $SSH_DIR ]; then
    echo "$SSH_DIR does not exist, creating..."
    mkdir -p "$SSH_DIR"
    echo "$SSH_DIR created."
    echo "Setting $SSH_DIR permission..."
    chown "$ANSIBLE_USER:$ANSIBLE_USER" "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    echo "$SSH_DIR directory permissions updated."
  fi
  echo "Generating key-pair for ansible servers."
  sudo -u "$ANSIBLE_USER" ssh-keygen -t rsa -b 4096 -f "${SSH_DIR}/${KEY_NAME}" -N ""

}



# Copying SSH file to servers.
ssh_copy(){


  SERVER_FILE="server.txt"

  if [[ ! -f "$SERVER_FILE" ]]; then
    echo "Server file not found: $SERVER_FILE"
    exit 1
  else
    echo "Sever file found. $SERVER_FILE"
  fi

  if [[ ! -f "${SSH_DIR}/${KEY_NAME}" ]]; then
    echo "SSH key file not found: ${SSH_DIR}/${KEY_NAME}"
    exit 1
  else
    echo "SSH key file found : ${SSH_DIR}/${KEY_NAME}"
  fi

  while IFS= read -r server; do
    # Skip empty lines or lines that start with a comment
    [[ -z "$server" || "$server" =~ ^# ]] && continue
  
    echo "Copying SSH key to $server..."
    sshpass -p "$SSH_PASSWORD" ssh-copy-id -i "${SSH_DIR}/${KEY_NAME}" -o StrictHostKeyChecking=no "$ANSIBLE_USER@$server"

    if [[ $? -eq 0 ]]; then
      echo "Successfully copied SSH key to $server"
    else
      echo "Failed to copy SSH key to $server"
    fi

  done < "$SERVER_FILE"

  echo "SSH key distribution complete."
  su - ansible -c "
    eval \$(ssh-agent)
    ssh-add /home/user/.ssh/your_private_key
  "

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
