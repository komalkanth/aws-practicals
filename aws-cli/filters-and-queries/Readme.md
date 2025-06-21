## Create a VPC for testing filters and queries

Creates a test VPC. I'm using `--region` and `--profile` options which are optional.
`--profile` is used to choose one out of multiple accounts/roles we have configured under our credentials.

```sh
aws ec2 create-vpc \
    --cidr-block 10.2.0.0/16 \
    --region us-east-1 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=aws-cli-filters-vpc}]' \
    --profile iamadmin-prod
```
_Note_: AWS CLI is not idempotent. Running the same command multiple times may result in multiple resources being created, depending on the type of resource.

---

## Fetch VPC details using a filter

Fetch the VPC ID by fetching VPCs in this region and adding a filter to only fetch the VPC with the name `aws-cli-filters-vpc` which is actually a `Name` tag.

```sh
aws ec2 describe-vpcs \
  --region us-east-1 --profile iamadmin-prod \
  --filters Name=tag:Name,Values=aws-cli-filters-vpc
```

This gives an output as shown below. This filter has been applied on the server/AWS side resulting in fetching only data that has been filtered.

```
{
    "Vpcs": [
        {
            "OwnerId": "xxxxxxxxxx",
            "InstanceTenancy": "default",
            "CidrBlockAssociationSet": [
                {
                    "AssociationId": "vpc-cidr-assoc-0ca2b9816423ac142",
                    "CidrBlock": "10.2.0.0/16",
                    "CidrBlockState": {
                        "State": "associated"
                    }
                }
            ],
            "IsDefault": false,
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "aws-cli-filters-vpc"
                }
            ],
            "BlockPublicAccessStates": {
                "InternetGatewayBlockMode": "off"
            },
            "VpcId": "vpc-093a100d0f9b5eddc",
            "State": "available",
            "CidrBlock": "10.2.0.0/16",
            "DhcpOptionsId": "dopt-0f3a26b8db7571085"
        }
    ]
}
```
---

## Filter the returned output using a query and assign the value to a variable

We can now take this filtered-at-server output and further parse it to only get the output we need, which is the VPC-Id in our case. This is generally called client-side-filtering and also called as a 'query' and there are a few ways to do it.

Example 1 using native `--query`option using [JMESPath Syntax](https://jmespath.org/)
```sh
export AWS_CLI_TEST_VPC=$(aws ec2 describe-vpcs --region us-east-1 --profile iamadmin-prod --filters Name=tag:Name,Values=aws-cli-filters-vpc --query 'Vpcs[*].VpcId | [0]' --output text)

echo $AWS_CLI_TEST_VPC
```
**Explanation:** The above command filters out all VPCs from the JSON output using `--query 'Vpcs[*]`.<br/>
Further filtering with `--query 'Vpcs[*].VpcId'` outputs only the VPCId but as a list.<br/>
To only fetch the value we pipe the first value of the list (since we only have one VPC) using `--query 'Vpcs[*].VpcId | [0]'`.<br/>
Finally we assign the output of this command to a variable called `AWS_CLI_TEST_VPC` which we can further use in other commands as seen in the example below.<br/>
The output by default is JSON and so the query result is output with double quotes. To just get the vpc-id we add the `--output text`.

## Create another using resource using the previous created variable
```sh
aws ec2 associate-vpc-cidr-block \
  --cidr-block 100.64.0.0/24 \
    --region us-east-1 --profile iamadmin-prod \
      --vpc-id $AWS_CLI_TEST_VPC
```
We can pass on the VPC ID that was assigned to the variable `AWS_CLI_TEST_VPC` as part of the input parameters to the next AWS CLI command.

---
## Verification

Here's the command to describe VPC details but this time we query for just the `CidrBlockAssociationSet` and `VpcId` details from the CLI output. Apart from JSON and text, we can also output in the YAML format if required.

```sh
aws ec2 describe-vpcs \
--region us-east-1 --profile iamadmin-prod \
--filters Name=tag:Name,Values=aws-cli-filters-vpc \
--query 'Vpcs[*].[CidrBlockAssociationSet, VpcId]' --output yaml
```

Output of the above command
```
- - - AssociationId: vpc-cidr-assoc-0ca2b9816423ac142
      CidrBlock: 10.2.0.0/16
      CidrBlockState:
        State: associated
    - AssociationId: vpc-cidr-assoc-03ba8e691e2cc209a
      CidrBlock: 100.64.0.0/24
      CidrBlockState:
        State: associated
  - vpc-093a100d0f9b5eddc
```