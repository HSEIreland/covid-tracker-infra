#!/bin/bash
# This is pretty dump and assumes all the keys are scalar values
set -eou pipefail

keys=${1:-api_ecs_autoscale_max_instances api_ecs_autoscale_min_instances api_service_desired_count push_ecs_autoscale_max_instances push_ecs_autoscale_min_instances push_service_desired_count rds_backup_retention rds_cluster_family rds_cluster_size rds_instance_type}

script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
env_vars_directory=${script_directory}/../env-vars
variables_file=${script_directory}/../variables.tf

project_envs=$(find ${env_vars_directory}/ -name '*-*.tfvars' -exec basename {} .tfvars \; | sort)
declare -A default_key_values

echo "Project-Env,$(echo ${keys} | sed 's/ /,/g')"
for project_env in default ${project_envs}; do
	project=${project_env%-*}
	project_tfvars_file=${env_vars_directory}/${project}.tfvars
	project_env_tfvars_file=${env_vars_directory}/${project_env}.tfvars

	row=${project_env},
	for key in ${keys}; do
		# Cater for "default" case row which we will populate from the variables.tf file
		if [[ "${project_env}" == "default" ]]; then
			value=$(grep -r "${key}" -A 1 ${variables_file} | grep 'default = ' | cut -d ' ' -f 5 || echo '')
			default_key_values[${key}]=${value}
		else
			value=$(grep "^${key}[[:blank:]]\+=" ${project_env_tfvars_file} ${project_tfvars_file} | head -n 1 | cut -d '=' -f 2 | sed 's/"//g; s/^ //' || echo '')
			# Fall back to default value if we have no value
			if [[ ${value} == '' ]]; then value=${default_key_values[${key}]}; fi
		fi
		row+=${value},
	done

	echo ${row%,}
done
