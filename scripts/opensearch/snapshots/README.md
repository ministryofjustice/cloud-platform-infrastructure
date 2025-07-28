# OpenSearch Snapshot & Restore Script

These two scripts work together to migrate and preserve log data from a live OpenSearch cluster to a separate cluster using snapshots stored in S3.

## Why This Is Needed

Managing OpenSearch log indices across environments requires careful handling to avoid impacting live workloads. This process is designed with the following considerations in mind:

Restoring large volume of log on the live OpenSearch cluster adds significant load, which may:

- Increases warm tier instance resource usage.
- Degrade performance for other users accessing the cluster.
- Risks cluster instability during peak usage or large restores.

### Safer Approach

To make the process safe and isolated, all restoration work is performed on a separate OpenSearch cluster, away from production.

This allows us to snapshot and restore large volumes of log data without affecting live service operations.

## Script 1: `take_snpashot_cold_incides.sh`

This script:

1. Reads a list of indices from source-index-list.txt (stored in S3).
2. Migrates each index from cold to warm tier.
3. Takes a snapshot of each index to the S3 snapshot repo.
4. Tracks completed snapshots by prefixing the index with `snapshot-taken-`.
5. Migrates the index back to cold tier after snapshot.

## Script 2: `restore_snpashot.sh`

This script:

1. Downloads the same source-index-list.txt file.
2. Filters lines with `snapshot-taken-`.
3. Skips indices already restored (snapshot-restored.txt in S3).
4. Restores each index from the S3 snapshot repository.
5. Set the replica count to `0` to save cost and improve the time.
6. Waits for full shard recovery and green index health.
7. Migrates restored index to the warm tier.

## Usage

Taking an OpenSearch snapshot can take more than 30+ minutes per index, depending on shard size and data volume. Therefore, it is recommended to follow this process:

1. Run the take-snapshot.sh script to initiate snapshot creation.
2. Wait some batch to be completed.
3. Once snapshots are expected to be complete, run the restore-snapshot.sh script to begin restoring the indices.
