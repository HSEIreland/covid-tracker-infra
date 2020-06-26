[
  {
    "name": "api",
    "image": "${api_image_uri}",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": ${listening_port}
      }
    ],
    "dependsOn": [{
      "containerName": "migrations",
      "condition": "SUCCESS"
    }],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${logs_service_name}",
        "awslogs-region": "${log_group_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "environment" : [
      {"name": "AWS_REGION", "value": "${aws_region}"},
      {"name": "CONFIG_VAR_PREFIX", "value": "${config_var_prefix}"},
      {"name": "NODE_ENV", "value": "${node_env}"}
    ]
  },
  {
    "name": "migrations",
    "image": "${migrations_image_uri}",
    "essential": false,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${logs_service_name}",
        "awslogs-region": "${log_group_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "environment" : [
      {"name": "AWS_REGION", "value": "${aws_region}"},
      {"name": "CONFIG_VAR_PREFIX", "value": "${config_var_prefix}"},
      {"name": "NODE_ENV", "value": "${node_env}"}
    ]
  }
]
