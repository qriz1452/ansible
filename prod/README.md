### Ansible Managed Nodes Configuration

To configure your Ansible managed nodes, follow these steps:

#### Step 1: Run the `ansible_agents_conf.sh` Script as Sudo

Before executing the script, ensure you have appropriate permissions. Run the script as sudo:

```bash
sudo ./ansible_agents_conf.sh
```

This ensures that the script has the necessary privileges to perform system-level operations.

#### Step 2: Important Note

**Run the Script First on Nodes to be Managed by Ansible Controller**

Ensure that you run the `ansible_agents_conf.sh` script on the nodes that you intend to manage using your Ansible controller. This script sets up the necessary configurations and dependencies on the managed nodes for effective management by Ansible.

#### Step 3: Understanding the Script

The `ansible_agents_conf.sh` script automates the setup and configuration of the Ansible server environment. Below is an overview of its functionalities:

1. **Color Variables**: Defines color codes for text output in the terminal.
   
2. **display_banner Function**: Displays an ASCII art banner for an Ansible server and prints the current timestamp.

3. **sys_info Function**: Fetches details about the operating system (OS) running on the server. It detects the OS from various locations such as `/etc/os-release`, `/etc/debian_version`, and `/etc/redhat-release`.

4. **py_check Function**: Checks whether Python 3 is installed on the system. If Python 3 is not found, it installs it using package managers like `apt` or `yum`, depending on the detected OS.

5. **ansible_user Function**: Creates an Ansible user and group if they don't already exist. It also creates a home directory for the Ansible user and sets appropriate permissions.

6. **ansible_sec Function**: Configures security settings for the Ansible user, including setting a password (though it's recommended to use SSH keys), creating an `.ssh` directory with appropriate permissions, updating SSH server configuration (`sshd_config`) for key-based authentication, and restarting the SSH service. Additionally, it grants the Ansible user sudo privileges without requiring a password.

7. **update_sshd_config Function**: Helper function used by `ansible_sec` to update SSH server configuration (`sshd_config`) with specific settings.

8. **show_usage Function**: Displays usage instructions for the script.

9. **Main Script Execution**: The script checks the arguments passed to it. If no arguments are provided, it displays usage instructions. Otherwise, it executes the corresponding function based on the provided argument. The script supports individual execution of functions (`display_banner`, `sys_info`, `py_check`, `ansible_user`, `ansible_sec`) or executing all functions at once using the `all` flag.

#### Step 4: Post-Execution Steps

Once the script execution is complete, your Ansible managed nodes should be configured according to the specified settings.



--------------------------------------------------




Certainly! Here's a full documentation for your Ansible setup script:

---

# Ansible Controller Setup Script

This script automates the setup and configuration of an Ansible controller environment. It includes functionalities such as installing Ansible, creating Ansible user, generating SSH keys, distributing SSH keys to managed nodes, and configuring Ansible settings.

## Prerequisites

Before running this script, ensure the following:

- **SSH Password**: You should have the password for the Ansible user on remote servers ready. This password will be used for copying SSH keys for passwordless authentication default password is 'password".

- **Managed Nodes List**: Create a `server.txt` file containing the IP addresses or hostnames of all managed nodes. This file is required for distributing SSH keys to managed nodes.

## Usage

1. **Run the Script**

   Run the script as a sudo user:

   ```bash
   sudo ./ansible_controller_setup.sh
   ```

2. **Follow On-Screen Prompts**

   The script will prompt you to enter the SSH password for the Ansible user on remote servers. Enter the password when prompted.

3. **Post-Execution Steps**

   After the script completes execution, perform the following steps if necessary:

   - **Switch to Ansible User**: If you encounter SSH errors after running the script, switch to the Ansible user and execute the following commands in the Ansible home directory ( ansible user default password is 'password" ):
     ```bash
     su ansible
     cd
     ```
     ```bash
     eval $(ssh-agent)
     ssh-add /home/ansible/.ssh/ansible_server_id_rsa
     ```

## Script Components

### 1. Color Variables

Defines color codes for text output in the terminal.

### 2. Ask for Password

Requests the user to enter the password for the Ansible user on remote servers.

### 3. display_banner Function

Displays an ASCII art banner for the Ansible host and prints the current timestamp.

### 4. sys_info Function

Fetches details about the operating system (OS) running on the host.

### 5. py_check Function

Checks whether Python 3 is installed on the system and installs it if not found.

### 6. ansible_install Function

Installs Ansible on the host depending on the detected OS.

### 7. ansible_user Function

Creates an Ansible user and group if they don't already exist. It also creates a home directory for the Ansible user and sets appropriate permissions.

### 8. ansible_conf Function

Generates the Ansible configuration file (`/etc/ansible/ansible.cfg`) if it doesn't already exist.

### 9. ansible_sec Function

Sets the Ansible user's password and generates an SSH key pair for passwordless authentication.

### 10. ssh_copy Function

Copies the generated SSH public key to all the servers listed in the `server.txt` file. It uses `sshpass` to automate the password entry for SSH key copying. After copying, it adds the private key to the SSH agent for the Ansible user.

---

