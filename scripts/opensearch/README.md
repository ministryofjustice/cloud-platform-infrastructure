# Migrate stuck indices scripts

The are a couple of common ways that indices can get stuck and break their flow through their lifecycle.

1. Hot to warm -- these migrations tend to get stuck because shards exceed the maximum size of 100gb eg. "Rejecting migration request for index [live_kubernetes_cluster-2024.05.13] because the shard size [105 GiB] exceeds the warm migration shard size limit of [100 GiB]. To avoid migration failures, reindex your data to reduce shard sizes, then migrate it to UltraWarm storage."
2. Warm to cold -- these fail when there is an issue moving the index and only the metadata is moved leading to a failure where the index can't be moved to cold because it is considered to already exist eg. "Failed to migrate index [live_eventrouter-2025.05.09] to cold storage because another index with the same name already exists in cold storage."

The solutions are different depending on the stage of the migration lifecycle:

## Hot to warm strategy

The strategy is to reindex the problematic index into a new index with an increased number of shards which reduces the maximum shard size, this new index will then be adopted by the ism policy and then moved through it's lifecycle.

## Warm to cold strategy

Here we need to delete the metadata duplicated index and retry the lifecycle policy.

# Steps for handling stuck indices

Each script takes a single boolean arg `IS_PIPELINE` eg. ./run_my_script false.

Run each script from the same dir level as this README file `/cloud-platform-infrastructure/scripts/opensearch/stuck-indicies`.

## Hot to warm steps

1. ./hot/fix.sh (handles shard resizing for indices stuck moving from hot to warm)

## Warm to cold steps

1. ./warm/get_all_cold_and_warm_indices.sh (paginates through all the cold indices and produces "collated_cold_indices")
2. ./warm/get_failed_cold_indices.sh (produces "compacted_failed_cold" needed to be read in the retrigger script)
3. ./warm/retrigger_stuck_warm.sh (handles the failed to move from warm to cold due to index with the same name already existing)

or you can just run:

```bash
    ./warm/fix.sh false
```

# Fix index policy script

This script ensures that all indices have the `hot-warm-cold-delete` ism lifecycle policy attached. Sometimes an index might find itself with out a policy attached and will hang about until somebody notices eg. when restored from cold. This script runs through all hot and warm indices and makes sure that they are all managed by a policy. The script takes a single boolean arg `IS_PIPELINE` eg. ./run_my_script false

From the `/cloud-platform-infrastructure/scripts/opensearch` dir, run the following:

```bash
    ./policies/fix.sh false
```
