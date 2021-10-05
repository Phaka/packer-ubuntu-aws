# Ubuntu AMI Base Images

## Overview 

If you're on an infrastructure team, you often have to provide other teams
with a base image which is up-to-date, and configured according to policies.
For example, you may want to install additional agents for monitoring, 
security or asset tracking on the image, or harden it according to one of
the CIS benchmarks. 

This repository allows you to create temporary AWS infrastructure using
terraform, and then use that in Packer to create AMIs, and then proceed
to destroy that infrastructure. After all, infrastructure that doesn't exist
cannot be compromised. 

## Usage

Before proceeding, you probably want to create a fork of the repository so 
you can change it to your hearts content.

### Requirements

- You'll need an AWS account and access id and secret key
- Your network should permit SSH access to AWS
- Packer v1.7.x installed
- Terraform v1.x installed

### Process 

At a high level the process is something like this:

* create a network using Terraform
* export variables using 
* run Packer to create and export AMI
* cleanup
* Using AMIs

#### Connect to AWS

Before you can connect, you'll need to connect to AWS, whether it's running
`gimme-aws-creds`, exporting some keys to `~/.aws` or setting some 
environment variables. The method to expose credentials to Terraform
or Packer is a bit outside of the scope of this README.

#### Create Infrastructure

First we'll need to create some AWS infrastructure that is isolated from
everything else. The reason for this is that should your infrastructure
be compromised, you do not want the AMIs we're creating to be impacted.

```
terraform init
terraform plan
terraform apply
```

#### Exporting Variables

Once the infrastructure was created, we need to export outputs so Packer
can use them. What makes this possible is that the variables required by 
packer are also Terraform outputs. 

```
terraform output > ../variables.pkrvars.hcl
```

By default Packer creates a security group that allows all internet traffic.
While there is a very slim chance of it being exploited, there's still a
chance. For the paranoid amongst us, you may want to get the IP address 
you're coming from. 

```
export PUBLIC_IP=`curl checkip.amazonaws.com`/32
```

#### Running Packer

We can now run packer to create the AMI.

```
packer init .
packer build -var-file=variables.pkrvars.hcl -var source_ip=$PUBLIC_IP .
```

#### Cleaning up

Once packer is complete, we can then proceed to destroy the AWS 
infrastructure, and save some beers.

```
cd vpc
terraform apply -destroy 
```

You should be able to login to AWS and verify that each region has AMIs. 

#### Additonal Considerations

If you're using a multi-account setup, Packer can also copy it to all of 
those accounts. It accepts a parameter for `account_ids` which is an array
of ids. 

You can also limit the regions where AMIs are copied to by passing in the
regions as the `regions` variable.

#### Using AMIs

The default prefix for AMIs are `phaka`, and as a result, the AMI for Ubuntu
20.04 would look something like this:

```
phaka-base-focal-20.04-amd64-20211005005947
```

So in terraform we can find the AMI as follows:

```
data "aws_ami" "main" {
  most_recent = true
  filter {
    name   = "name"
    values = ["phaka-base-focal-20.04-amd64-*"]
  }
  owners = ["self"]
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.main.id
  // other properties
}
```

### CI/CD

#### Jenkins

Let's demonstrate how to create AMIs as part of a CI/CD process. If you 
already have Jenkins infrastructure, then you can skip the steps to start 
your own local Jenkins server. You may want to peek at [Jenkinsfile](./jenkins/Jenkinsfile).

##### Running Local Jenkins

The following is in scope for Jenkins

* `Dockerfile` to build a container for a Jenkins server
* `docker-compose.yml` to build the docker container
* `Jenkinsfile` demonstrating how to use CI/CD to build the AMIs

Strictly speaking `docker-compose.yml` isn't necessary. However I find it 
rather convenient to manage multi-agent systems.

First we need to build the container:

```
docker-compose build
```

and then we need to bring the environment up

```
docker-compose up
```

We can then connect to Jenkins server at http://localhost:8080 and configure
it as usual. The next step is to configure credentials which Terraform and 
Packer will use.


Secret Name | Type | Comments
---------|----------|---------
 aws-secret-key-id | Text | the access key id
 aws-secret-access-key | Text | the secret access key

You also want to configure Jenkins so it can clone and build the repo from
GitHub.


