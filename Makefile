# We assume you have an AWS profile with the the PROJECT-ENVIRONMENT i.e. cti-dev
# 	This is the same profile that should exist in the env-vars file

.ONESHELL:
.SHELL := /bin/bash


# #########################################
# Shell swag
# #########################################
GREEN = \033[1;32m
RESET = \033[0m
WHITE = \033[1;38;5;231m


# #########################################
# Environment variables defaults
# #########################################
ENVIRONMENT ?=
PROJECT_KEY ?=


# #########################################
# Make target aliases
# #########################################
MAKE_TF_INIT = $(MAKE) --no-print-directory internal-init
MAKE_TF_PLAN = $(MAKE) --no-print-directory internal-plan
MAKE_TF_APPLY = $(MAKE) --no-print-directory internal-apply


# #########################################
# Commands args
# #########################################
PROJECT_ENVIRONMENT_KEY = $(PROJECT_KEY)-$(ENVIRONMENT)
PROJECT_TFVAR_FILE = env-vars/$(PROJECT_KEY).tfvars
PROJECT_ENVIRONMENT_TFVAR_FILE = env-vars/$(PROJECT_ENVIRONMENT_KEY).tfvars
TERRAFORM_PLAN_FILE = terraform-$(PROJECT_ENVIRONMENT_KEY).tfplan

# Lets use profiles that use this convention - could have got from the project-env tf var file like the AWS region below
AWS_PROFILE = $(PROJECT_ENVIRONMENT_KEY)

# Determine from tf vars file(s) - will use the first match
AWS_REGION = $(shell grep '^aws_region' $(PROJECT_ENVIRONMENT_TFVAR_FILE) $(PROJECT_TFVAR_FILE) | head -n 1 | cut -d '"' -f 2)

# NOTE: We cannot always derive these as we do not have a consistent scheme currently, see the cti-ENV-init targets
TERRAFORM_BACKEND_BUCKET ?= $(PROJECT_ENVIRONMENT_KEY)-terraform-store
TERRAFORM_BACKEND_KEY ?= $(PROJECT_KEY)
TERRAFORM_BACKEND_TABLE ?= $(PROJECT_ENVIRONMENT_KEY)-terraform-lock


# #########################################
# cti targets - HSE
# This is the one that is non conformant re backends
# #########################################
# DEV
.PHONY: cti-dev-init cti-dev-plan cti-dev-apply
cti-dev-init:
	@$(MAKE_TF_INIT) ENVIRONMENT=dev PROJECT_KEY=cti \
		TERRAFORM_BACKEND_BUCKET=fight-together-terraform-store-dev \
		TERRAFORM_BACKEND_TABLE=fight-together-terraform-lock \
		TERRAFORM_BACKEND_KEY=fight-together-dev-eu-west-1
cti-dev-plan:
	@$(MAKE_TF_PLAN) ENVIRONMENT=dev PROJECT_KEY=cti
cti-dev-apply:
	@$(MAKE_TF_APPLY) ENVIRONMENT=dev PROJECT_KEY=cti

# QA
.PHONY: cti-qa-init cti-qa-plan cti-qa-apply
cti-qa-init:
	@$(MAKE_TF_INIT) ENVIRONMENT=qa PROJECT_KEY=cti \
		TERRAFORM_BACKEND_BUCKET=fight-together-terraform-store-qa \
		TERRAFORM_BACKEND_TABLE=fight-together-terraform-lock \
		TERRAFORM_BACKEND_KEY=fight-together-qa-eu-west-1
cti-qa-plan:
	@$(MAKE_TF_PLAN) ENVIRONMENT=qa PROJECT_KEY=cti
cti-qa-apply:
	@$(MAKE_TF_APPLY) ENVIRONMENT=qa PROJECT_KEY=cti

# TRIAL
.PHONY: cti-trial-init cti-trial-plan cti-trial-apply
cti-trial-init:
	@$(MAKE_TF_INIT) ENVIRONMENT=trial PROJECT_KEY=cti \
		TERRAFORM_BACKEND_BUCKET=cti-terraform-store-trial \
		TERRAFORM_BACKEND_TABLE=cti-terraform-lock-trial \
		TERRAFORM_BACKEND_KEY=cti
cti-trial-plan:
	@$(MAKE_TF_PLAN) ENVIRONMENT=trial PROJECT_KEY=cti
cti-trial-apply:
	@$(MAKE_TF_APPLY) ENVIRONMENT=trial PROJECT_KEY=cti

# PROD
.PHONY: cti-prod-init cti-prod-plan cti-prod-apply
cti-prod-init:
	@$(MAKE_TF_INIT) ENVIRONMENT=prod PROJECT_KEY=cti \
		TERRAFORM_BACKEND_BUCKET=cti-terraform-store \
		TERRAFORM_BACKEND_TABLE=cti-terraform-lock \
		TERRAFORM_BACKEND_KEY=cti
cti-prod-plan:
	@$(MAKE_TF_PLAN) ENVIRONMENT=prod PROJECT_KEY=cti
cti-prod-apply:
	@$(MAKE_TF_APPLY) ENVIRONMENT=prod PROJECT_KEY=cti


# #########################################
# Generic targets - not dependant on a project
# #########################################
.PHONY: update validate format
update:
	@echo "$(WHITE)==> Updating modules - $(GREEN)terraform get$(RESET)"
	terraform get -update

validate:
	@echo "$(WHITE)==> Validate terraform code - $(GREEN)terraform validate$(RESET)"
	terraform validate

format:
	@echo "$(WHITE)==> Format terraform code - $(GREEN)terraform fmt$(RESET)"
	terraform fmt -recursive


# #########################################
# internal targets - don't expect these to be invoked directly
# #########################################
.PHONY: internal-init internal-plan internal-apply
internal-init:
	@echo "$(WHITE)==> Setting up environment - $(GREEN)$(PROJECT_ENVIRONMENT_KEY)$(WHITE) in $(GREEN)$(AWS_REGION)$(RESET) using AWS profile $(GREEN)$(AWS_PROFILE)$(RESET), S3 bucket $(GREEN)$(TERRAFORM_BACKEND_BUCKET)$(RESET) and DynamoDB table $(GREEN)$(TERRAFORM_BACKEND_TABLE)$(RESET)"
	terraform init -get=true \
		-upgrade=true \
		-input=false \
		-lock=true \
		-reconfigure \
		-backend=true \
		-backend-config="region=$(AWS_REGION)" \
		-backend-config="dynamodb_table=$(TERRAFORM_BACKEND_TABLE)" \
		-backend-config="bucket=$(TERRAFORM_BACKEND_BUCKET)" \
		-backend-config="key=$(TERRAFORM_BACKEND_KEY)" \
		-backend-config="profile=$(AWS_PROFILE)"

internal-plan:
	@echo "$(WHITE)==> Planning changes - $(GREEN)$(PROJECT_ENVIRONMENT_KEY) - terraform plan$(RESET)"
	terraform plan -out $(TERRAFORM_PLAN_FILE) -var-file $(PROJECT_TFVAR_FILE) -var-file $(PROJECT_ENVIRONMENT_TFVAR_FILE)

internal-apply:
	@echo "$(WHITE)==> Applying changes - $(GREEN)$(PROJECT_ENVIRONMENT_KEY) - terraform apply$(RESET)"
	terraform apply -parallelism=10 $(TERRAFORM_PLAN_FILE)
