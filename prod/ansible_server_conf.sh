#!/bin/bash

# Function to display ASCII art for ANSIBLE


display_banner() {
  echo " ///////////////////////////////////"
  echo " ///                             ///"
  echo " ///    ANSIBLE SERVER           ///"
  echo " ///                             ///"
  echo " ///  CONFIGURATION  SCRIPT      ///"
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


  # Path to the sshd_config file
  SSHD_CONFIG="/etc/ssh/sshd_config"

  # Function to update sshd_config
  update_sshd_config() {
      local setting="$1"
      local value="$2"

      if grep -q "^#*$setting" "$SSHD_CONFIG"; then
          sudo sed -i "s|^#*$setting.*|$setting $value|" "$SSHD_CONFIG"
      else
          echo "$setting $value" | sudo tee -a "$SSHD_CONFIG" > /dev/null
      fi
  }

  # Ensure PubkeyAuthentication is set to yes
  update_sshd_config "PubkeyAuthentication" "yes"

  # Ensure PasswordAuthentication is set to no
  update_sshd_config "PasswordAuthentication" "yes"

  # Ensure AuthorizedKeysFile is set to .ssh/authorized_keys
  update_sshd_config "AuthorizedKeysFile" ".ssh/authorized_keys"

  # Restart SSH service to apply changes
  sudo systemctl restart sshd

  echo "SSH configuration updated and SSH service restarted."

  # Add ansible to sudoers without password prompt
  if ! sudo grep -q "^ansible ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
      echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null
      echo "Updated sudoers to allow ansible user to run all commands without password."
  else
      echo "ansible user already has NOPASSWD sudo privileges."
  fi



}




# Display the banner
display_banner

# Display system info
sys_info

# Installing Python
py_check


# Ansible user creation
ansible_user


#Ansible ssh and passwd
ansible_sec
