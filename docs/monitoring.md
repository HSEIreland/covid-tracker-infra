# Monitoring & Logging

The application uses **CloudWatch** for monitoring and logging. The current setup includes alarming to the slcak channel **#covid-tracker-alarms** via SNS+Lambda.

## Monitoring

The following alarms are in place right now:

- 5xx errors > 25 for 1 datapoint within 1 minute
- 4XX errors > 25 for 1 datapoint within 1 minute
- p95 api latency > 500ms for 1 datapoint within 1 minute

Alarms are enabled just for `production`.

## Logs

Multiple log groups can be queried via `Logs Insights` slecting the proper log groups.

* *Find all responses with specific status code*

```
# API and PUSH service
# searching for all 5xx responses
fields @timestamp, @message
| filter res.statusCode like /5\d{2}/
| sort @timestamp desc
| limit 20
```

```
# API Gateway Access Logs
# searching for all 5xx responses
fields @timestamp, @message
| filter @message like /\"\s5\d{2}\s/
| sort @timestamp desc
| limit 20
```