# Developer Tools

## :white_check_mark: CLI

The AWS AWS CLI is an open source tool that enables you to interact with AWS services using commands in your command-line shell (like bash and zsh).

* [Overview](https://aws.amazon.com/cli/)
* [User Guide](https://docs.aws.amazon.com/cli/)
* [Github](https://github.com/aws/aws-cli)

All (IaaS) AWS administration, management, and access functions in the AWS Management Console are available in the AWS API and CLI. New features are always provided through the API and CLI within 180 days of launch.

Several AWS services provide higher-level commands (for example `aws s3`) that simplify using the more complex low-level API (`aws s3api`).

Ways to perform tasks against AWS:
* AWS CLI on local computer
* AWS CLI on EC2 instance
* AWS SDK on local computer
* AWS SDK on EC2 instance
* AWS Instance Metadata Service for EC2

### Configuring the CLI

To give an AWS user access to the CLI
* go to `IAM > Users > username > Security credentials`
* click on "create an access key"
* store the Access Key ID and Secret Key somewhere

Next, configure the CLI:
```
$ aws configure
AWS Access Key ID [None]: ABC6EUYHJJ8MX
AWS Secret Access Key [None]: LBe+RhkCgFKN45Pd/s9Dfmzm0BbyGrG
Default region name [None]: eu-west-1 
Default output format [None]:
```

This will generate files `config` and `credentials` in folder `~/.aws`.

### Example: S3 CLI

* [User Guide (S3 CLI)](https://docs.aws.amazon.com/cli/latest/userguide/cli-services-s3.html)
  * [`s3` commands](https://docs.aws.amazon.com/cli/latest/userguide/cli-services-s3-commands.html) provide high-level commands for common operations (create, delete, list, ..)
  * [`s3api` commands](https://docs.aws.amazon.com/cli/latest/userguide/cli-services-s3-apicommands.html) provide direct access to the S3 APIs, and enable some operations that are not available in the s3 commands

:warning: Make sure to remove (or backup) any existing `credentials` files before doing `aws configure`. Otherwise credentials might get mixed up (e.g. existing onelogin settings) and you will get trouble connecting to AWS.

```
$ aws s3 ls
$ aws s3 mb s3://my-bucket
$ aws s3 cp file.ext s3://my-bucket
$ aws s3 cp . s3://my-bucket/somefolder --recursive
$ aws s3 rm s3://my-bucket/file.ext
$ aws s3 ls s3://my-bucket
$ aws s3 sync . s3://my-bucket/somefolder
$ aws s3 rb s3://my-bucket --force
```

The `sync` command can be used to synchronize local with S3, S3 with local, or two S3 buckets.

### CLI on EC2: use IAM Roles

You can also execute the CLI on EC2. **Do not** use `aws configure` on EC2 because it will store your (personal) access keys on that EC2 instance. Use IAM Roles...

When you use the CLI in an EC2 without IAM roles, it will look like this:
```
$ aws s3 ls
Unable to locate credentials. You can configure credentials by running "aws configure".
```

Define a new role in `IAM > Roles > Create Role`:
* Use Case: `EC2`
* Policy: `AmazonS3ReadOnlyAccess`
* Name: `My-EC2ReadS3` or something ...

Attach the new role to the EC2 instance in `EC2 > Actions > Instance Settings > Attach IAM Role`. Now the CLI works:

```
$ aws s3 ls
2020-04-16 19:48:51 roelfie-udemy-aws-test-s3
2020-04-17 12:21:25 roelfie-udemy-test2
```

You can attach or remove policies to/from existing roles to tweak its permissions.

### IAM Roles and Policies

Types of policies:
* IAM > Policies
  * `AWS Managed` (built-in policies, like AmazonS3ReadOnlyAccess)
  * `Customer Managed` (policies created by ourselves)
* Roles > Role
  * Add `inline policy` (not reusable, only applies to current role)

#### Ways to generate policies

* The `IAM > Policies > Create Policy` wizard (in the AWS management console)
* [Policy Generator](https://awspolicygen.s3.amazonaws.com/policygen.html)

#### Policy Simulator

You can [test IAM policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_testing-policies.html) with the [Policy Simulator](https://policysim.aws.amazon.com/).

This basically allows you to select a policy and a set of actions for a specific AWS service (e.g. `GetObject` and `CreateBucket` for S3), click the `Run Simulation` button, and find out what actions are allowed by the policy.

#### CLI Dry Run

Some AWS CLI commands support the `--dry-run` option. This will not actually execute the statement, possibly saving you some money (e.g. in the case of creating an EC2 instance or reading a huge S3 glacier bucket). But it will tell you whether or not you are *allowed* to execute the statement.

```
$ aws ec2 run-instances --dry-run --image-id ami-0fd9bce3a3384b635 --instance-type t2.micro

An error occurred (UnauthorizedOperation) when calling the RunInstances operation: You are not authorized to perform this operation. Encoded authorization failure message: ...
```

With the appropriate permissions (for instance by adding the `AmazonEC2FullAccess` policy to your custom EC2 role; or by adding the `RunInstances` action to a Customer Managed policy) you would get:

```
$ aws ec2 run-instances --dry-run --image-id ami-0fd9bce3a3384b635 --instance-type t2.micro

An error occurred (DryRunOperation) when calling the RunInstances operation: Request would have succeeded, but DryRun flag is set.
```

#### STS Decode

Some error messages returned by the CLI are base64 encoded strings. You can decode them using [decode-authorization-message](https://docs.aws.amazon.com/cli/latest/reference/sts/decode-authorization-message.html) from [STS (Security Token Service)](https://docs.aws.amazon.com/STS/latest/APIReference/Welcome.html):

```
$ aws sts decode-authorization-message --encoded-message LcZRNuOMmgYsufEQs-uEqx-lR1pVvBBgqvtEOVEOH1re0GCiKwzSMnPrlAvTg7T-cUPRpeS4-Qtv66XEh_UPVE5cFcQarRUiu5XhtZ3xx8SAXThN_OiQzLxnZIXo4qbRDZaPSGg491Oa3ez3hBVpbQMJuRXasX4_wEUwirmb5TI-PIpzCEPW1PiZ2DlFzx75Hj2UsmMvnvw3D1PCZcIHKR5WVZDBXtTjMuh2UiY_j2i2hBqjrA6oWDo2DqGr92n-e9uDPlodxoNqXr0X_s8vgbrqSphoxhzRRUPc60ZsmSpIpa8mFtRYaj5vneBvz-B5h1WGxqPb7uYtkHXjWew_RJA5Ar_YoolhlKptuHY9Nk9C8eqiDo1IPL4e1fhORkL8rToz791Qd48wz3w3moxXOvM7kZVNcYMCdGVAN8GToiG_LYxxm9KyqF-WjBYomU6NMdD8YmgCZK3xnHakIaii5yiM2dlXtAgLwlfJd3jk1JwlVgRNcQEWh2LvJPaxbVIf2_Sw0HOKWm68IYCl176ZesJA0QjnhbF94wxPdTyuYraBK0D0XPCGyHyLlyCT521HEwqi9CitdcSuzlFHcRo1nz4WX_nwZii30_TOuP9O8cW3waG2Nf1HPeHA0eGbHnz42AoYlZ84jBCO6_y3Jbj7IK_pGOQjzSccI0wg9puiVgpf4o6oyAEDsw3g-YI5PiJZsjk

An error occurred (AccessDenied) when calling the DecodeAuthorizationMessage operation: User: arn:aws:sts::837063707632:assumed-role/Roelfie-EC2ReadS3/i-0c3040b70a134b709 is not authorized to perform: sts:DecodeAuthorizationMessage
```

You need the proper STS permissions to perform `decode-authorization-message`. With the proper permissions it would have returned a JSON document containing error details.

#### EC2 Instance Metadata

Every EC2 instance has an internal endpoint `http://169.254.169.254/latest/meta-data` where it can lookup metadata about itself. Example of the description of a role in the meta-data:

```
$ curl http://169.254.169.254/latest/meta-data/iam/security-credentials/Roelfie-EC2ReadS3
{
  "Code" : "Success",
  "LastUpdated" : "2020-04-17T14:08:14Z",
  "Type" : "AWS-HMAC",
  "AccessKeyId" : "ASIA4FZRVP61AQ4EUABC",
  "SecretAccessKey" : "I+2Jt5vfr7Z/UnAHW763/ZFKAKJRrfhXTjIeWDI_",
  "Token" : "...",
  "Expiration" : "2020-04-17T20:19:02Z"
}
```

## :white_check_mark: SDK

* [Tools](https://aws.amazon.com/tools/)
* [SDK for Java](https://aws.amazon.com/sdk-for-java/)
* [SDK for Python](https://aws.amazon.com/sdk-for-python/) (Boto3)
* [User Guide (Java)](https://docs.aws.amazon.com/sdk-for-java/v2/developer-guide/welcome.html)
* [User Guide (Boto3)](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)

Some facts
* The AWS CLI uses the Python SDK (boto3).
* Default region in the SDK is `us-east-1`
* For authentication it's recommended to use **default dredential provider chain**; integrates with
  * `~/.aws/credentials` (also used by the CLI) 
  * Instance Profile Credentials using IAM roles (EC2 instances, ..)
  * Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
* SDK implements exponential backoff
  * applies to rate limited APIs
  * retry if API call fails because of too many calls


