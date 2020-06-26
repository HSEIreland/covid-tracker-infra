# Disaster Recovery Plan - Data loss

This disaster recovery plan (drp) covers the actions to take in case of data loss. The plan is focused on **RDS Aurora** failure scenarios.

RDS is currently configured to automatically take snapshots. In the case you need to rebuild the cluster you can always restore the dataset from the most recent snapshot (or take one manually before destroying/rebuilding the cluster).

Once you have a snapshot you can use it to restore the cluster. Copy the snapshot id and use it in the variable `snapshot_identifier`. The cluster will then be recreated with the same dataset from the snapshot.