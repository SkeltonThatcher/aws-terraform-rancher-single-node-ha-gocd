# Single Node SSL/HA for Rancher Server and GoCD in AWS

This repo contains Terraform code with supporting scripts and advisories to deploy single node HA Rancher server and Rancher hosts in AWS, with GoCD server and GoCD auto-registered agents

The deployment is designed for use with the STCL-TECH GoCD server and agent services from the [SkeltonThatcher Rancher Build Engineering custom catalog ](https://github.com/SkeltonThatcher/rancher-buildeng-catalog)

The Terraform plan will build out and deploy the following resources.

* x1 VPC + IGW
* x2 Public subnets
* x2 Private subnets
* RDS DB subnet group
* Single-AZ or Multi-AZ RDS MySQL DB instance
* SSL enabled elastic load balancer + listeners
* Launch configuration + fixed Multi-AZ auto-scaling group of x1 instance for the Rancher server
* Launch configuration + fixed Multi-AZ auto-scaling group of a specified EC2 instance amount for the Rancher GoCD server hosts
* Launch configuration + fixed Multi-AZ auto-scaling group of a specified EC2 instance amount for the Rancher GoCD agent hosts
* EC2 IAM policy role for the Rancher server & hosts, granting full access to EC2, S3, Route 53, SNS & Cloudwatch
* RancherOS EC2 instance with active Docker running a password protected deployment of Rancher server
* RancherOS EC2 instances with active Docker as Rancher hosts to run GoCD server and GoCD agents
* Route 53 DNS alias record for the ELB

The estimated deployment time is 30 minutes.

### Prerequisites

* AWS account
* AWS IAM user account with AWS access/secret keys and permission to create specified resources
* Valid SSL certificate present in the AWS Certificate Manager
* Cygwin (or similar) installed to enable running of .sh scripts if using Windows
* Git installed and configured
* Terraform installed and configured

### How to use the Terraform plan to deploy AWS infrastructure supporting Rancher server and Rancher hosts

#### Version advisories
Tested with the following versions.

* RancherOS v1.0.0
* Rancher server v1.5.6
* Rancher agent v1.2.2
* GoCD v17.4.0

#### Rancher server

* Clone the repo
* Create an EC2 keypair in AWS
* Create an S3 bucket to hold remote state
* Update `init.sh` with the S3 bucket name and region
* Run `init.sh` to initialise remote state
* Create `terraform.tfvars` in the root of the cloned folder (see `terraform.tfvars.example`)
* Set `gocdagt_hst_max` + `gocdsrv_hst_max`, `gocdagt_hst_min` + `gocdsrv_hst_max`and `gocdagt_hst_des` + `gocdsrv_hst_max` in `terraform.tfvars` to zero (0)
* Make up a temporary reg_token in `terraform.tfvars`
* Run `terraform plan` from the root of the folder
* Run `terraform apply` from the root of the folder
* Wait until the installation has completed
* Access Rancher server at the displayed output URL
* Log in with the name and password specified in the `terraform.tfvars` file

#### Rancher hosts for GoCD server + agents

* Enable hosts registration from within Rancher and copy the token from the registration string. The token will be in the format similar to `6C8B0D1B2E95DD1AA07A:1483142400000:PKQGzShMCv3wtD02DvlU4MkBY0`
* Update `reg_token` in `terraform.tfvars` with the registration token
* Update `gocdagt_hst_max` + `gocdsrv_hst_max`, `gocdagt_hst_min` + `gocdsrv_hst_max`and `gocdagt_hst_des` + `gocdsrv_hst_max` in `terraform.tfvars` with the max, min and desired amount of GoCD server and GoCD agent host instances
* Re-run `terraform plan`
* Re-run `terraform apply`
* Launch configurations will be replaced with new versions and applied to the auto scaling groups
* The specified amount of GoCD server and GoCD agent host instances will launch and register with the Rancher server

### How to install GoCD server with GoCD auto-registered agents

#### Rancher plugins
* Within Rancher, add the Rancher EBS plugin item from the Rancher library catalog and pre-create a 10GB GP2 storage volume named `ebs`
* Add the Rancher Route 53 DNS plugin item from the Rancher library and configure, later adding a CNAME entry in R53 for the corresponding GoCD server service once it is installed. Specify a scheduling rule for host label gocdsrv_hst

#### Custom catalog with GoCD server + agents
* Add the STCL custom catalog to Rancher - https://github.com/SkeltonThatcher/rancher-buildeng-catalog
* Install the GoCD server item, specifying a scheduling rule for host label gocdsrv_hst
* Obtain the GoCD agent registration key from the GoCD server config XML
* Install the GoCD agent item, adding the agent registration key, and specifying a scheduling rule for host label gocdagt_hst

#### How to remove
* To remove all deployed resources run `terraform destroy`

### Licence

Copyright (c) 2017 Skelton Thatcher Consulting Ltd.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

### Acknowledgments

* set_access_control.sh script created by [George Cairns](https://www.linkedin.com/in/george-cairns-9624b621/) from [Automation Logic](http://www.automationlogic.com/)
