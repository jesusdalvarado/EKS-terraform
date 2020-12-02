# EKS-terraform
Example app using Amazon EKS and Terraform

<h1>What is this?</h1>

This is an example app built using Terraform to create the infrstructure resources in AWS.

<h2>Technologies implemented</h2>

- Terraform
- Amazon EKS
- Rancher
- Docker
- Amazon S3
- Amazon VPC (required by EKS)
- Redis
- Flask

<h2>Requirements</h2>

- Make sure you have already installed both Docker Engine and Docker Compose.
- Install aws client and configure it (e.g. using the command aws configure)
- You need to create an S3 bucket called "eks-remote-terraform-state" in the region "us-west-2" before running terraform init , this is to use terraform remote state. This bucket has to be created manually in AWS because Terraform can't create it.
- You also need to create a Dynamodb table (the name for primary partition key could be "LockID"). Make sure the region for this resource is also "us-west-2" otherwise you will see the error "Requested resource not found" during terraform init.
- Terraform can read directly from the configured credentials using aws configure, or you can use an .env file like this

        APPLICATION_NAME=app
        AWS_ACCESS_KEY_ID=some_access_key
        AWS_SECRET_ACCESS_KEY=some_secret_key
        AWS_REGION=us-west-2


<h1>Getting Started</h1>

<h2>Terraform useful commands to create resources</h2>

1. `docker-compose run terraform sh`
1. Run `terraform init`
2. Run `terraform plan`
3. Run `terraform apply`
