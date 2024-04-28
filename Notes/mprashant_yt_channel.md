*** YT LINK : https://www.youtube.com/watch?v=y2TSR7p3N0M  ***

Ansible Can be used for :
- Installing one application in multiple server
- Multiple application in multiple servers
- Creating users in multiple servers
- managing / updating configurations in different redhat or ubuntu distributions.

Ansible Definitaion :
- IT Automation tool built by python programming language.

Why Automation :
- Manual is time consuming
- Manual have chances of error
- Manual is repetitive task


Ansible doesnot have Master slave or Agent based architecture , it is agentless.


Advantege of Ansible : 
- Agentless architect
- simple and easy to use via YAML playbook
- Configuration management like provisioning, deployment, infra management.
- Scalability , can manage large no. of servers simlteneously using inventory
- Playbooks we can run multiple times without changing the system state.
- Open soure, large user base, community contributions
- Integrations with other tools such as Docker , K8s, AWS

How Ansible Works :
- 3 Components : Inventory , Playbook , Module
- Module : Small programs to do task, eg. shell, systemctl, package etc modules
- Inventory : Modules that need to be run on specific servers
- Playbook : anything that we are Executing or playing or running something i.e installing nginx
  - we can have multiple tasks in same playbook
  - we can have multiple modules in playbook


-------------------------------------------------------------------------------------

vmware for windows, parallel desktop for MacOS

---------------------------------------


Ansible Setup :
A1 : ansible main server
B1 : our machines.

All servers should be on the same network i.e they should be able to ping. we can check the ip using `ifconfig`

Step 1 : check if server able to acces from another machine.
B1 : `ifconfig`             (//to install use `yum install net-tools` get eth0 ip address )
A1 : `ssh username@private-ip-of-B1`
A1 : `exit`


Step 2 : Passwordless authentication :

A1 : `ssh-keygen`
A1 : `ssh-copy-id private-ip-of-B1`



 


Step 3 : Installing ansible

A1 : `sudo yum install epel-release`      (// OPTIONAL installing and updating extra packages for enterprise linux ) 
A1 : `sudo yum install ansible`           ( // dnf is latest version of yum ) 
A1 : `ansible --version`
A1 : `ansible localhost -m ping`            ( // testing whether ansible workingor not )



Step 4 : Configurations 

A1 : `cd /etc/ansible`                 ( // Ansible global configuration file is located there. )
here we will get 3 files : roles , hosts , ansible.cfg
by default this conf file will be empty , to create a blueprint or example ansible.cfg file run this command : 

A1 : `ansible-config init --disabled -t all > ansible.cfg`
A1 : ` cat ansible.cfg `


----------------------------------------------------------------

Step 5 : Ansible Playbooks  PING Module

A1 : `mkdir playbooks`   ( // just creating directory for maintaining )
NOW ALL PLAYBOOKS IN GIT  : https://github.com/qriz1452/ansible/blob/main/Playbooks/01-ping-test-connectivity.yml
A1 : `ansible-playbook your-playbook.yml`

** The execution is : play --> gather task --> tasks --> other tasks --> play recap 
** if any error in running playbook we will get the error details on the console only.
** we can use linting aswell.

A1 :  `ansible-playbook --syntax-check playbook.yml`






----------------------------------------------------------------


Step 5 : Ansible Playbooks  PING and debud Module 

Pinging localhost and printing some text.
Playbook URL :  https://github.com/qriz1452/ansible/blob/main/Playbooks/02-ping-debug-modules.yml


-----------------------------------------------------------------------------

Step 6 : Ansible playbook  yum and service  module

installing and starting the package , service
Playbook URL : https://github.com/qriz1452/ansible/blob/main/Playbooks/03-yum-service.yml

A1 : `nginx`
A1 : playbook run
A1 : `nginx`
A1 : `systemctl status nginx`  ( // it will show started and enabled )

-----------------------------------------------------------------------------------

Step 7 : Overview of Ansible Playbook


Ansible docs for modules and its parameters.




-------------------------------------------------------------


Step 8 : Playbook for remote servers :

A1 : `cd /etc/ansible` 
A1 : `cat hosts`                          ( // default inventory file for ansible inventory )
A1 : `ansible-inventory --list`           ( // we can list the servers/hosts from default inventory file )
A1 : `ansible all -m ping`                ( // pinging all ip in hosts inventory file ) 


Update the ansible playbook ( Step 5  )  and replace `localhost` with `all`


A1 :  `ansible-playbook --syntax-check playbook.yml`
A1 :  `ansible-playbook  playbook.yml`


------------------------------------------------------------------




Step 9 : Installing package on remote server : 

Update the ansible playbook ( Step 6  )  and replace `localhost` with `all`
Also add the ip of remote server on `hosts` file located at `/etc/ansible `



A1 :  `ansible-playbook --syntax-check playbook.yml`
A1 :  `ansible-playbook  playbook.yml`



-----------------------------------------------------------------------------

Step 10 : Copying files with changing owner , group and changing permission

Playbook URL : https://github.com/qriz1452/ansible/blob/main/Playbooks/04-Copying%20files%20to%20remote.yml
Apply playbook and verify on remote server copied or not.

permission and group, owner etc will be same in both server.
If we dont change the file and run the copy playbook again then it will no copy the file again.
If we made changes then copying again then it will OVERWRITE.

-------------------------------------------------------------------------------

Step 11 :  Creating Backup while copying



Playbook : https://github.com/qriz1452/ansible/blob/main/Playbooks/05-Creating%20Backup%20while%20copying.yml
If we made changes in file and copying then only backup will be created else it will not . The previous file will be renamed with adding date and timestamp.



--------------------------------------------------------------------

Step 12 : creating files and directories and deleting them

Playbook : https://github.com/qriz1452/ansible/blob/main/Playbooks/06-creating%20files%20and%20directories%20and%20deleting%20fileand%20dir.yml
If we delete  a directory all files in that dir will be deleted.



--------------------------------------------------------------------

Step 13 : Changing Permissions 
