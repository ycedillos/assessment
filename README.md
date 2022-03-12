# Installation

You should have the following environment variables to setup the authentication:
- AWS_ACCESS_KEY_ID 
- AWS_SECRET_ACCESS_KEY
- AWS_DEFAULT_REGION=us-west-1
- AWS_SESSION_TOKEN (Optional, if you have MFA enabled)

> **Note:** This example is based on the oficial tutorial [Packer](https://learn.hashicorp.com/tutorials/terraform/packer?in=terraform/provision).

## Step 1: Create SSH keys to customize your access

    cd packer
    ssh-keygen -t rsa -C "your_email@example.com" -f ./tf-packer

## Build a Packer Image

    cd images
    packer build image.pkr.hcl

## Review cloud-init file

> **Note:** In this example, we are using cloud-init to load the wp-config.php in the AWS autoscaling template. For production environment, it is recommended to use an script to download that file using a script in Packer, that file could be located in any Secret Management tool like Vault.

The Cloud-Init file will send the host, database, username and password as parameters to the template located in scripts/configure-cloudinit.yaml. You can find the resource template in the ec2.tf file.

- You should update the value of **image_id** varible in terraform.tfvars file

## Run terraform files

Note: For this example, we are not using the S3 backend. But in real environments, we should setup the DynamoDB and restricted policies in the S3 bucket. For more information go to: [S3](https://www.terraform.io/language/settings/backends/s3)


    terraform init
    terraform plan -out=tfplan
    terraform apply tfplan

## Review the Load Balancer 

You should be able to see the init page to setup wordpress!

## Important things!

### Setup Internet facing Load Balancer

> We should use 200-302 in the health check to be able to start the configuration of Wordpress in the wizard.

### Change the Database tier

> You can change the value of db_instance_class in terraform.tfvars file to adjust the database tier
