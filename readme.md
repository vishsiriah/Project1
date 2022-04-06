Projet overview:
This project is to deploy Virtual nmachines, fontended by a load balancer. Below steps would walk you through creating this infrastructure. Please follow the steps bellow to deploy the project:

1. Create a desired folder structure on your machine
2. Create packer tempelete "server.json"
Note: If you need to delete the packer image use "az image delete -g <resource-group> -n <image name>" command
3. run az login command to authenticate to Azure. This commands authenticates you to Azure and enables you to do the needed infrastrusture deployment using terraform
4. Create recource group "az group create -l <location> -n <name of the resource group>". This command creates resource group when the infrastructure is going to be deployed
5. Build packer image use command "packer build server.json". This image is further going to be used in the code to build Virtual machines
6. Create main.tf & var.tf, main.tf contains the code need to deploy the needed infrastructure. var.tf includes the variables like counter that helps define number of VM to be created.
7. run command terraform validate. Terraform validate command validates the configuration files in a directory.
8. run command terraform plan. The terraform plan command creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure.
9. Debug all the errors
10. Run command terraform apply. This command build the needed infrastructure in the specified region
11. login to the azure portal and validate the desired infrastructure is created.
Note: The count for the VM's & nic name is set to 2 by setting a default value of counter variable in vars.tf. This is set to stay with in the free limits set for the deployment region, nic_name is set using a variable in name as "my-nic${count.index}" And VM name is being set using the following variable in name "Udacity-vspg${count.index}"
Below is out put of terraform plan for your review

