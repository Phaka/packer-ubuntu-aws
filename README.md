# Ubuntu AMI Base Images

## Overview 

## Usaage

### Requirements

- You'll need an AWS account and access id and secret key
- Your network should permit SSH access to AWS

### Process 

First we'll need to create some AWS infrastructure that is isolated from
everything else. The reason for this is that should your infrastructure
be compromised, you do not want the AMIs we're creating to be impacted.

```
cd vpc
terraform init
terraform plan
terraform apply
terraform output > ../variables.pkrvars.hcl
cd ..
```

The apply step will export the vpc id and subnet id. 

We also need to determine which IP address we're coming from. 

```
export PUBLIC_IP=`curl checkip.amazonaws.com`/32
```

We can now run packer to create the AMI.

```
packer init .
packer build -var-file=variables.pkrvars.hcl -var source_ip=$PUBLIC_IP .
```

Once packer is complete, we can then proceed to destroy the AWS 
infrastructure, and save some beers.

```
cd vpc
terraform apply -destroy 
```





