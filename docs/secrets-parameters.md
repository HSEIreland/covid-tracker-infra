### AWS Secrets Manager Secrets
Secrets are not managed by the Terraform content.

Secrets use a prefix ENV-NAMESPACE- in their names.

- Some secrets are used by all projects
	- device-check
	- encrypt
	- exposures
	- header-x-secret
	- jwt
	- rds
- Some are optional
	- cct
	- cso
	- twilio

Optional secrets need to be added to the option_secrets variable.

You can use the [aws-secrets.sh](../scripts/aws-secrets.sh) script to create secrets.

i.e. For **dev** env and **ni** project namespace
```
./scripts/aws-secrets.sh create dev-cti-device-check 'SOME-VALUE'
```


### AWS Systems Manager Parameters
Parameters are managed by the Terraform content.

- Some are optional
	- arcgis_url
