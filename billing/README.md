To run this into an AWS account, use the AWS cli via the below command:

```
aws budgets create-budget --cli-input-json file://[file location]/cloudplatform-budget.json --account-id=[account number to create budget in] --profile=[AWS cli profile]
```

You'll need to run this for every account you want to create a budget for.

```
You can delete this budget with the below command:
aws budgets delete-budget --account-id=[account number to delete budget from] --profile=[AWS cli profile] --budget-name 'Monthly AWS Budget'
```
