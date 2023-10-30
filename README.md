# terraform-aws

Course Contents ⭐️
⌨️ Welcome and Setup (0:00)
⌨️ What We're Going to Build
⌨️ AWS IAM Setup
⌨️ Local Environment Setup
⌨️ Let's Build! (7:22)
⌨️ AWS Provider and Terraform Init
⌨️ A VPC and Terraform Apply
⌨️ The Terraform State
⌨️ Terraform Destroy
⌨️ A Subnet and Referencing
⌨️ An IGW and Terraform fmt
⌨️ A Route Table
⌨️ A Route Table Association
⌨️ A Security Group
⌨️ An AMI Datasource
⌨️ A Key Pair
⌨️ An EC2 Instance
⌨️ Userdata and the File Function
⌨️ SSH Config Scripts
⌨️ The Provisioner and Templatefile
⌨️ The Deployment and Replace
⌨️ Variables
⌨️ Variable Precedence
⌨️ Conditional Expressions
⌨️ Outputs
⌨️ Conclusion

https://www.youtube.com/watch?v=iRaai1IBlB0

Terraform and AWS Building a dev environment
1.	Creation of AWS EC2 VPC (allows you to create a private network in the AWS cloud)
There is Provide.tf file to add the AWS provide
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                   =  "us-east-1" 
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "vscode"
}

Then main.tf to add the resources for set up the AWS VPC
resource "aws_vpc" "mtc_vpc" {
    cidr_block = "10.123.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "dev"
    }
}

Major command to run for setting up the Amazon Virtual private cloud
Terraform init
Terraform plan
Terraform apply
Terraform destroy -auto-approve   (to delete the vpc)
Terraform apply -auto-approve   (to recreate the vpc)

2.	Deploy a Subnet (To which we can deploy our EC2 instance)
Add the resource to create subnet in the main.tf file as below
resource "aws_subnet" "mtc_public_subnet" {
    vpc_id = aws_vpc.mtc_vpc.id
    cidr_block = "10.123.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"

    tags = {
        Name = "dev-public"
    }
}

Terraform plan
Terraform apply -auto-approve

3.	Create Internet Gateway and Terraform Fmt 
Add resource in the main.tf file to create a internet gateway 
resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

Terraform plan
Terraform apply -auto-approve
 	Formatting the files
Terraform fmt – This command automatically corrects the code formatting issue in the main.tf and providers.tf file 

You can see as below in the VS Code terminal after running the above command
PS C:\Users\Probook\Documents\Projects\terraform> terraform fmt
main.tf
providers.tf
PS C:\Users\Probook\Documents\Projects\terraform>

4.	Create a Route Table (Going to route traffic from our subnet to the Internet gateway) 
resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-public-rt"
  }
}

Terraform plan
Terraform apply -auto-approve

5.	Route Table Association (Going to route traffic from our subnet to the Internet gateway) 
resource "aws_route_table_association" "mtc_public_assoc" {
  subnet_id      = aws_subnet.mtc_public_subnet.id
  route_table_id = aws_route_table.mtc_public_rt.id
}

Terraform plan
Terraform apply -auto-approve

6.	Security Group (Going to route traffic from our subnet to the Internet gateway) 

Security Group is a fundamental component of network security. It acts as a virtual firewall for your Amazon Elastic Compute Cloud (EC2) instances to control inbound and outbound traffic.
resource "aws_security_group" "mtc_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

7.	The AMI Data source  
Use this data source to get the ID of a registered AMI for use in other resources.
Create datasources.tf file and add the data sources as below

data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

}

8.	The Key Pair
Provides an EC2 key pair resource. A key pair is used to control login access to EC2 instances.
Add the aws_key_pair resources to main.tf file 
resource "aws_key_pair" "mtc_auth" {
  key_name   = "mtckey"
  public_key = file("~/.ssh/id_ed25519.pub")
}

Terraform plan
Terraform apply -auto-approve

9.	Deploy the EC2 instance
resource "aws_instance" "dev_node" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.server_ami.id

  tags = {
    Name = "dev-node"
  }

  key_name               = aws_key_pair.mtc_auth.id
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  subnet_id              = aws_subnet.mtc_public_subnet.id

  root_block_device {
    volume_size = 10
  }
}

10.	User Data
Create a template file userdata.tpl and add the below script


#!/bin/bash
sudo apt-get update -y &&
sudo apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common &&
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&
sudo apt-get update -y &&
sudo apt-get install docker-ce docker-ce-cli containerd.io -y &&
sudo usermod -aG docker ubuntu

Terraform plan
Terraform apply -auto-approve

Your instance will be created and above userdata will be run inside the instance to create a docker in that instance.

11.	SSH to the instance through VS Code
Run the below command inside the terraform terminal in the VS code to get the public ip of the instance
terraform state list
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
PS C:\Users\Probook\Documents\Projects\terraform> terraform state list
data.aws_ami.server_ami
aws_instance.dev_node
aws_internet_gateway.mtc_internet_gateway
aws_key_pair.mtc_auth
aws_route.default_route
aws_route_table.mtc_public_rt
aws_route_table_association.mtc_public_assoc
aws_security_group.mtc_sg
aws_subnet.mtc_public_subnet
aws_vpc.mtc_vpc
PS C:\Users\Probook\Documents\Projects\terraform>

The run the below command to get the public ip

terraform state show aws_instance.dev_node

 

Run the below command for SSH into your instance

> ssh -i C:\Users\Probook\.ssh\id_ed25519 ubuntu@54.167.104.122  new value (54.242.82.162)

 
 

12.	SSH Config Scripts 
Create a windows-ssh-config.tpl file and add the below script
add-content -path C:/Users/Probook/.ssh/config -value @'

Host ${hostname}
    HostName ${hostname}
    User ${user}
    Identityfile ${identityfile}
'@

13.	Provisioners

Ref : https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax#how-to-use-provisioners

Add provisioner script under existing resource as below in the main.tf file
 provisioner "local-exec" {
    command = templatefile("windows-ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/id_ed25519"
    })
    interpreter = ["Powershell", "-Command"]
  }

1.	Terraform plan
2.	Then see the state list by running the below command
3.	terraform state list   and copy the instance name aws_instance.dev_node 
4.	Then run the below command 
5.	terraform apply -replace aws_instance.dev_node 
you can see the below output in the VS Code terminal that our instance is successfully created
 
You can see the config file is written successfully the host information after connection and you can run the below command to verify it 
cat ~/.ssh/config
 

You can now SSH with VS Code and see the output that is connecting to the instance Ref 1:18 in the video
 

14.	Connect your EC2 with Putty
Download and install Putty and open putty
  
 
PuTTY fatal error: No supported authentication methods available. 

The private key file format in our .ssh folder is not compatible with putty, so try below steps to convert the private key into putty native format fille with .ppk extension and then load the key as above it will connect.

1.	Download Puttygen (https://www.puttygen.com/download-putty)
2.	Open PUttyGen and then Load the private key from :C:\Users\Probook\.ssh\id_ed25519 
3.	save the new private key with a new name.
4.	Open Putty, go to Connection > SSH > Auth > and add the new private key (putty_ec2_private_key.ppk)
5.	Connect now using 127.0.0.1 and 2222

 
 

15.	Variable in Terraform
Refer 1:30 from the video
Create a file variable.tf and add the below variable definition script
variable "host_os" {
  type        = string
  default     = "windows"
  description = "description"
}

The create a terraform.tfvars to add the value to the variables
host_os = "linux"

Run the terraform console and see the output
 
Now use this variable with interpolation in the main.tf file as below
 provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/id_ed25519"
    })
    interpreter = ["Powershell", "-Command"]
  }

16.	Conditionals
Replace the interpreter line in the main.tf with conditions as below
interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash","-c"]

17.	Outputs
You can output whatever you want from the instance details in terraform console, but we can do the same in creating a separate file called outputs.tf
 
Outputs.tf
output "dev_ip" {
  value = aws_instance.dev_node.public_ip
}

Terraform plan
Terraform apply -refresh-only
See the output as below after successful creation of instance
 

Terraform output
 
