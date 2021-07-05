# Connect EC2 with DynamoDB using Terraform

This repository contains a basic example of how to use Terraform to create and connect an EC2 instance
with DynamoDB in AWS.

## Set local environment

The `main.tf` script expects to connect to a Localstack instance running in the localhost. To set up
the Localstack server run the following:

```shell
python -m venv venv
source venv/bin/activate
pip install localstack
localstack start
```

## Create infrastructure

The usual workflow to manage infrastructure with Terraform includes validating the definition,
generating a plan to move from the current state to the desired one, and applying the plan.

```shell
terraform validate               # Check that the syntax is correct
terraform plan -out=create.plan  # Calculate the resources to create, modify or delete
terraform apply create.plan      # Apply the planned changes
```

## Destroy infrastructure

In order to tear down the infrastructure, just create a plan using the `-destroy` flag and apply it.

```shell
terraform plan -destroy -out=destroy.plan
terraform apply destroy.plan
```

## Infrastructure components

The basic idea is using `main.tf` to create an EC2 instance that will host a server and a DynamoDB table 
which will act as backend. 

This is achieved by defining a `aws_instance` and a `aws_dynamodb_table` from
the AWS official Terraform provider. The `user_data` field of the instance is then used to inform 
the server about the ARN of the database by setting an environmental variable.

However, by default it is not possible to interact with a DynamoDB table. To do it, it is necessary to create
a role with the needed permissions (in this case, an [official managed one](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/using-identity-based-policies.html#access-policy-examples-aws-managed)
) and [map it to the instance using an Instance Profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html).
This way, the server will be able to access a set of credentials inside the VM with the needed privileges to
connect to DynamoDB.

## Moving to production

- Later in the development flow, the provider usually changes from Localstack to the
  actual AWS. At that point Terraform needs to have access to a set of valid AWS account credentials. This
  credential must **NEVER** be the ones of a root AWS account; instead, a restricted IAM user and roles should
  be created and used to minimize the dangers of mistakes and credentials compromise.
- Terraform uses a file to keep track of the state of the infrastructure and plan the changes to
  execute. This file needs to be accessible to every person or CI/CD system that wants to work on that
  environment. The team needs to choose and implement one of the several alternatives to store and access
  concurrently the state file safely. For example, Terraform offers the [S3 backend](https://www.terraform.io/docs/language/settings/backends/s3.html),
  that keeps the state in a S3 bucket.
- In this example, the EC2 instance uses a generic official Ubuntu 20.10 AMI. The CI/CD could use Ansible 
  or a similar solution to install the server code once the instance has been provisioned. However, a
  better approach is to use tools like Packer to build custom AMIs that contain everything, so that they
  can be passed as variables to the Terraform definition and rollout immutable deployments.
- The example uses an official managed policy for DynamoDB that grants full access to the API. A safer 
  approach is to create a custom policy that grants exactly the permissions needed by the app.
- The user used by Terraform needs to have a minimum set of permissions to be able to assign a role to an
  EC2 instance. See [this](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html#roles-usingrole-ec2instance-permissions).
