[
  {
    "name": "push",
    "image": "${image_uri}",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": ${listening_port}
      }
    ],
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
