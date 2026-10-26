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

`hot-warm-cold-delete` deletes cold indices at 366 days. To keep existing cold indices (for example for an investigation), move them onto the `legal-hold-retain` policy defined in `terraform/aws-accounts/cloud-platform-aws/account/app-opensearch-legal-hold.tf`. That policy runs no actions in its `cold` state and only deletes at `legal_hold_delete_transition`. New indices are unaffected and still follow `hot-warm-cold-delete`.

Updating `hot-warm-cold-delete` itself does not help: existing indices keep the policy version they started with, and re-entering its `cold` state would re-run `cold_migration` on indices that are already cold.

## Before you start: add these TODOs to your ticket

A legal hold is an ongoing obligation, not a one-off change. Your ticket must explicitly include:

- [ ] Re-run `apply` then `verify` at least weekly while the hold is needed. Indices that move to cold after a run are still on `hot-warm-cold-delete` and will be deleted at 366 days.
- [ ] A review/end date for the hold, agreed with whoever requested it. Held indices keep accruing cold-storage cost until the hold is lifted.
- [ ] Lifting the hold (see below) once it is no longer needed.

While the hold is active the cold index count grows, so the `opensearch-indices-health-check` "Cold index count above expected" alert will start firing. Treat it as a reminder that a hold is active rather than silencing it.

## Applying the hold

From the `/cloud-platform-infrastructure/scripts/opensearch` dir, after the terraform has been applied:

```bash
    # 1. Read-only: classify every cold index and see what would change
    ./legal-hold/change_policy_cold.sh false plan

    # 2. Test on one cold index
    ./legal-hold/change_policy_cold.sh false apply <one-cold-index>

    # 3. Apply to every eligible cold index, then verify
    ./legal-hold/change_policy_cold.sh false apply
    ./legal-hold/change_policy_cold.sh false verify
```

The script works per index (curl's SigV4 signing breaks on wildcard paths) and writes a per-index TSV report. It exits non-zero if anything needs attention:

| Class                              | Meaning                                                                                                                                                    |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CANDIDATE`                        | On `hot-warm-cold-delete` in `cold` – `apply` will move it onto the hold                                                                                   |
| `HELD`                             | Already on the current version of `legal-hold-retain`                                                                                                      |
| `HELD_STALE`                       | On `legal-hold-retain` but an older version (for example after `legal_hold_delete_transition` changed) – `apply` refreshes it, `verify` fails until it has |
| `AT_RISK_DELETE`                   | Actively in the `delete` state – the hold cannot stop it. `apply` refuses to run until these are resolved                                                  |
| `STALLED`                          | Policy disabled or action failed – not currently progressing to delete, left unchanged                                                                     |
| `STALLED_DELETE`                   | In the `delete` state but the delete failed and the policy is disabled – not deleting now, but an ISM retry would delete it. Reported, left unchanged      |
| `UNMANAGED` / `OTHER`              | No policy / a different policy – left unchanged                                                                                                            |
| `FAIL_CHANGE` / `FAIL_NOT_APPLIED` | `change_policy` was rejected / ISM did not apply it within `VERIFY_TIMEOUT_SECS`                                                                           |

`change_policy` is asynchronous, so `apply` polls `explain` until each index is confirmed on the hold policy.

## Lifting the hold – run with care

**Do not simply set `legal_hold_delete_transition` back to `366d`.** ISM measures age from index creation, so on the next ISM run (about 5 minutes) every held index older than the new value is deleted – potentially thousands of indices at once. Deleted cold indices are only recoverable for 14 days (see [AWS cold storage](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/cold-storage.html#cold-snapshot)).

1. Agree the lift with the requester and take snapshots of anything that must be kept.
2. Preview exactly what a value would delete: `./legal-hold/change_policy_cold.sh false preview-lift <days>`.
3. Lower `legal_hold_delete_transition` in reviewed steps (oldest first). After each terraform apply, held indices are `HELD_STALE` (still on the old policy version, so nothing changes yet); run `apply` to move them onto the new version – deletions happen from that point – then `verify`.
