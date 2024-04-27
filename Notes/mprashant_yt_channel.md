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


Step 5 : Ansible Playbooks 

A1 : `mkdir playbooks`   ( // just creating directory for maintaining )


NOW ALL PLAYBOOKS IN GIT 









