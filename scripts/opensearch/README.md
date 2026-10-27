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

# Legal hold: defer deletion of cold indices

`hot-warm-cold-delete` deletes cold indices at 366 days. To keep them, move them onto `legal-hold-retain` (`terraform/aws-accounts/cloud-platform-aws/account/app-opensearch-legal-hold.tf`). New indices are unaffected.

Add to your ticket:

- [ ] Re-run `apply` and `verify` weekly while the hold is needed (new cold indices are not held).
- [ ] Agree an end date. Held indices keep costing cold storage.
- [ ] Lift the hold when done (see below).

The "Cold index count above expected" alert will fire while the hold is active.

From `scripts/opensearch`:

```bash
    ./legal-hold/change_policy_cold.sh false plan                 # read-only
    ./legal-hold/change_policy_cold.sh false apply <one-index>    # test one
    ./legal-hold/change_policy_cold.sh false apply
    ./legal-hold/change_policy_cold.sh false verify
```

The script works per index, writes a TSV report and exits non-zero if anything needs attention. `apply` refuses to run if any index is already being deleted (`AT_RISK_DELETE`).

## Lifting the hold

Do not set `legal_hold_delete_transition` straight back to `366d`. Every held index older than the new value is deleted on the next ISM run, and deleted cold indices are only recoverable for 14 days.

1. Preview: `./legal-hold/change_policy_cold.sh false preview-lift <days>`.
2. Lower the value in steps, oldest first.
3. After each terraform apply, run `apply` then `verify`.
