# Checklist
Using a project with key **cti** and a **dev** environment.


## Create an AWS profile
Add a cti-dev profile to ~/.aws/credentials


## Create the Terraform state backend
See [../scripts/create-tf-state-backend.sh] script.

```
# Set your AWS_PROFILE
export AWS_PROFILE=cti-dev

# Create
./scripts/create-tf-state-backend.sh eu-west-1 cti-dev-terraform-store cti-dev-terraform-lock
```

## Import TLS certificates
In some cases we need to use certificates that are supplied
- PENDING Import certicates script

In some cases we need to use certificates that we manage but we do NOT manage the DNS
- Will require the DNS domain owner to create CNAMEs to complete the AWS ACM certificate request


## DNS
In some cases where we manage the DNS we may need to help with additional DNS record creation i.e. Naked domain config.


## Create the AWS SecretsManager secrets
We need to create the secrets outside of Terraform, see the [secrets/parameters](./secrets-parameters.md) doc.


## Create the env-vars files

| File                    | Content                                                    |
| ------------------------| -----------------------------------------------------------|
| env-vars/cti.tfvars     | Contains the CTI values that are the same across all envs  |
| env-vars/cti-dev.tfvars | Contains the CTI values that are specific to the dev env   |

With these we need to decide on some optionals
- Enable DNS where we manage the DNS, in some cases we do not manage the DNS
- Enable TLS certificates where we manage the certificates, in some cases we need to import certificates
- Some lambdas are optional
- Some secrets/parameters are optional


## Slack channel/application
May need to create a slack application/channel - usually for the prod env only at this time.
- Application will be PROJECT-bot i.e. cti-bot
- Channel name will be PROJECT-contact-tracing-alarms i.e ctii-contact-tracing-alarms


## Create the Makefile targets
Will need to create the following targets.

| Target        | Description                                                                        |
| --------------| -----------------------------------------------------------------------------------|
| cti-dev-init  | Does the Terraform module pulls and backend config                                 |
| cti-dev-plan  | Runs a Terraform plan, creating a local TF plan file i.e. terraform-cti-dev.tfplan |
| cti-dev-apply | Does a Terraform apply using the created TF plan file                              |
