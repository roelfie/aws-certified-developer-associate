# CI/CD

Read the [introduction to DevOps and AWS](https://aws.amazon.com/devops/).

Possible technology stacks for CI/CD on AWS:

Code               | Build / Test  | Deploy / Provision
-------------------|---------------|--------------------------------------
AWS CodeCommit     | AWS CodeBuild | AWS Elastic BeanStalk
GitHub / BitBucket | Jenkins       | AWS CodeDeploy -> EC2 instances fleet

Orchestration of the above components can be done with `AWS CodePipeline`.

## :white_check_mark: CodeCommit

AWS CodeCommit is a source control service that hosts Git-based repositories.
* [Overview](https://aws.amazon.com/codecommit/)
* [User Guide](https://docs.aws.amazon.com/codecommit/)
---

* highly redundant architecture, automatic scaling
* in-transit & at-rest encryption
* trigger an AWS-Lambda, SMS or email in response to events in a repository
* AWS IAM integration
* pay per user per month

You can give someone else access to your repository using an IAM role and AWS STS (AssumeRole API). Never share SSH keys or AWS credentials!

### Comparison to GitHub

Like GitHub, AWS CodeCommit supports:
* Pull requests
* AWS CodeBuild integration
* HTTPS and 

GitHub UI is much more powerful than the CodeCommit UI.

### Notifications

CodeCommit can send notifications to SNS or [AWS Chatbot](https://aws.amazon.com/chatbot/) (Slack) for the following events:
* **Branches and tags**: Created, updated, deleted
* **Pull requests**: Created, updated, status changed, merged
* **Comment added**: on pull request or commit

### Triggers

You can define triggers for (one or more of) the following: 
* create branch
* delete branch
* push to branch
* all repository events

The trigger can be applied to specific branch(es) or all branches.

The trigger can publish an event to an SNS topic or run an AWS Lambda.

### Access Management

In IAM, on the Security Credentials tab of a user, you can configure CodeCommit access:
* upload a public key (for SSH access)
* generate username / password (for HTTPS access)

## :white_check_mark: CodePipeline

A continuous delivery service that integrates with AWS' own CI/CD services and 3rd party services (GitHub, Bitbucket, Jenkins, ..)

* [Overview](https://aws.amazon.com/codepipeline/)
* [User Guide](https://docs.aws.amazon.com/codepipeline/index.html)
---

* A Pipeline is series of Stages
* Each Stage creates >=0 artifacts
* Artifacts are stored in S3 and passed on to the next stage.
* A pipeline requires a Service Role in order to perform its actions (e.g. access S3, CodeCommit, BeanStalk, EC2, ..)

Exam focuses on CodePipeline troubleshooting.
* A CodePipeline stage change triggers a CloudWatch event
* You can choose to publish a CloudWatch event to SNS, for example:
  * stage failed
  * stage cancelled (by user)
* AWS CloudTrail can be used to audit AWS API calls
* Pipeline actions can fail because of insufficient permissions in the IAM Service Role

### CodePipeline configuration

CodePipeline Configuration options
* IAM Service Role
* Artifact store (S3 bucket)
  * AWS can create a default S3 bucket dedicates to this pipeline
  * You can also choose to (re)use an existing S3 bucket
  * Encryption key:
    * AWS managed / Customer managed (KMS)
* Source provider
  * AWS CodeCommit, ECR, S3 / GitHub, BitBucket
  * Change detection: 
    * How to detect conditions under which your pipeline should automatically start (e.g. push code)
    * AWS CloudWatch events (push)
    * AWS CodePipeline (pull) checks periodically for changes
* Build provider
  * AWS CodeBuild / Jenkins
* Deploy provider
  * AWS CloudFormation
  * AWS CodeDeploy
  * AWS Elastic BeanStalk
  * AWS Service Catalog
  * ECS (or ECS Blue/Green)
  * S3

### Actions and action groups

* A Pipeline has 1 or more **Stages**
* A Stage has one or more **Action Groups**
* An Action Group has one or more **Actions**

Actions in the same Action Group are executed *in parallel*.

:warning: If you want an action X to be executed *after manual approval*, place the manual approval and action X in separate action groups!

### Example: Manual approval before deploying to Prod

Define a pipeline with the following stages:
1. Source
   * Action provider = `AWS CodeCommit`
     * Choose the appropriate repository and branch from CodeCommit
     * This action has an 'output' artifact that will be stored in AWS S3
2. DeployTest
   * Action provider = `BeanStalk` (choose application & environment)
     * This action uses an artifact of type 'input' from AWS S3
3. DeployProd
   * Action Group 1
     * Action provider = `Manual Approval` 
     * Optionally provide a URL to the test-environment for approval
   * Action Group 2
     * Action provider = `BeanStalk` (choose application & environment)

:warning: I chose Change detection = `CloudWatch events` but for some reason my pipeline was triggered by CloudWatch events as well as `PollForSourceChanges`. So on each commit the pipeline was triggered twice (and as a result I was asked to manually approve every change twice). Solution: See next section.

:warning: In the CodePipeline settings, I added a notification rule to email all pipeline events (via SNS), but I got no emails at all. The AWSCodePipelineServiceRole did have full access to all SNS topics. The reason it didn't work: Setting up notifications within the pipeline is not sufficient / not needed. You have to [set up a CloudWatch Event Rule](https://docs.aws.amazon.com/codepipeline/latest/userguide/tutorials-cloudwatch-sns-notifications.html) (wih source = AWS CodePipeline, target = SNS topic).

### Disabling PollForSourceChanges

Part of a 'Source' action configuration is how to detect changes in your code repository (and trigger the pipeline). One of the flags used here is `PollForSourceChanges`. This flag has default value `true` even if you choose detection method `AWS CloudWatch Events`. So in the latter situation, two builds are triggered: One for the CloudWatch event and one because of the poller. You can [disable `PollForSourceChanges` with the CLI](https://github.com/awsdocs/aws-codepipeline-user-guide/blob/master/doc_source/update-change-detection.md#update-change-detection-cli-codecommit):

```
$ aws codepipeline get-pipeline --name MyFirstPipeline >pipeline.json
$ vi pipeline.json
  # add the line "PollForSourceChanges": "false" to the "configuration" section
  # remove the "metadata" section
$ aws codepipeline update-pipeline --cli-input-json file://pipeline.json
```

### CodePipeLine Action types

* Source
  * **AWS S3** or **AWS CodeCommit**: 
    * Pipeline starts when it detects a change in the source bucket / source repo (through a CloudWatch event)
  * **GitHub**: 
    * :warning: CodePipeline integration with GitHub Enterprise is not supported
  * **Amazon ECR**: 
    * Docker images
  * **AWS CodeStar connections**:
    * Installing the CodeStar app with a 3rd party code repository allows you to  grant your pipeline access to that 3rd party repo
* Build
  * **AWS CodeBuild**
  * **Jenkins** (requires CodePipeline plugin for Jenkins)
  * **CloudBees**
  * **TeamCity** (JetBrains)
* Test
  * **AWS CodeBuild**
  * **AWS Device Farm**
  * **BlazeMeter**
  * **Ghost Inspector**
  * **Micro Focus StormRunner Load**
  * **Nouvola**
  * **Runscope**
* Deploy
  * **AWS S3**
  * **AWS CloudFormation**
  * **AWS CodeDeploy**
  * **Amazon ECS**
  * **AWS Elastic BeanStalk**
  * **AWS OpsWorks Stacks**
  * **AWS Service Catalog**
  * **Alexa Skills Kit**
  * **XebiaLabs**
* Approval
  * **Amazon SNS**
    * You can include a URL (e.g. of the pre-prod environment) to review
* Invoke
  * **AWS Lambda**



## :white_check_mark: CodeBuild

CodeBuild compiles source code, runs unit tests, and produces artifacts.

* [Overview](https://aws.amazon.com/codebuild/)
* [User Guide](https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html)
---

You can run CodeBuild dirctly (console, CLI or SDK). Or you can include it in the build or test stage of a CodePipeline (using action provider = AWS CodeBuild). 

* Pay per build (with Jenkins you would still pay for the entire day, even if you do just one build a day)
* Leverages Docker
* Integration with KMS (encryption of artifacts), IAM (for )build permissions), VPC (network security) and CloudTrail (API calls logging)
* Source code from GitHub, CodeCommit, CodePipeline, S3
* CloudWatch alarms to detect failed builds
* CloudWatch events / AWS Lambda as glue
* Builds can be reproduced locally (for troubleshooting)
* Support for Java, Python, Node.js (and with Docker it offers support for basically anything)

What it needs to run CodeBuild:
* `buildspec.yml` in the root of your project
  * Use SSM Parameter Store to store secret parameters
  * Phases: install (dependencies) / pre-build / build / post-build (e.g. zip)
  * Also defines artifacts (to upload to S3) and caches 
* Docker image (either AWS managed, or created by ourselves)
* CodeBuild container: Runs on the 'Build' Docker image, runs instructions from `buildspec.yml`
* AWS S3 Cache Bucket (optional)
* AWS S3 Artifacts Bucket (stores the output of the build)

### CodeBuild Agent

With [CodeBuild Agent](https://docs.aws.amazon.com/codebuild/latest/userguide/use-codebuild-agent.html) you can run CodeBuild locally (from a Docker image).

### buildspec.yml

See the [Build specification reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html).

* The buildspec can be included in the source code, but it can also be defined in your build project itself.
* Do not store sensitive information in the `env.variables` section. Use one of: 
  * `env.parameter_store` (EC2 [Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)):. You CodeBuild service role should have action `ssm:GetParameters`. 
  * `env.secrets_manager` (AWS [Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html))
* The environment variable name prefix `CODEBUILD_` is reserved for internal use.

Example `buildspec.yml` (the build will fail if the command in the build phase returns with an error code):
```
version: 0.2

env:
  variables: 
    my-key: "my-value"

phases:
  install:
    runtime-versions:
      nodejs: 12
  pre_build:
    commands:
      - echo "Doing nothing in the pre-build phase."
  build:
    commands:
      - grep -Fq "Congratulations" index.html
```

## :white_check_mark: CodeDeploy

Exam focus:
* `appspec.yml` location and basic structure (File vs. Hooks section)
* How deployment groups work
* Lifecycle event hook order
* ASG vs. tag based deployment

CodeDeploy is a service that automates application deployments to EC2 instances, ECS, serverless Lambda functions or on-premises instances.

* [Overview](https://aws.amazon.com/codedeploy/)
* [User Guide](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html)
---

Equivalent of 3rd party deployment tools like:
* Ansible
* Terraform
* Chef
* Puppet

Strengths of CodeDeploy:
* Avoid downtime (rolling updates)
* Integrates with CodePipeline
* Supports rolling out
  * code
  * AWS Lambda functions
  * packages (like WARs)
  * web & configuration files
  * executables, scripts, multimedia files, ..

### Configuration options
* minimum number of healthy instances for 'success'
* AWS Lambda: Specify how traffic is routed to different versions
* Pre-defined deployment configurations
  * OneAtATime
  * HalfAtATime
  * AllAtOnce
* Failed instances
  * Leave failed instances in failed state
  * First deploy to failed instances (default?)
* Deployment targets:
  * To a set of EC2 instances with certain tag
  * Directly to an ASG
  * Mix of ASG and tags

NB: CodeDeploy does not provision resources. It only does the deployment.

### CodeDeploy agent
To be able to roll out deployments on EC2 each EC2 instance must be running  CodeDeploy Agent:
1. agent polls with AWS CodeDeploy for work to do
2. CodeDeploy sends `appspec.yml`
3. deployable is downloaded from S3 / GitHub / ..
4. agent runs deployment instructions on the EC2 instance
5. status will be reported back to AWS CodeDeploy

In an EC2 cluster, EC2 instances are grouped into *deployment groups* (e.g. dev, test, prod).

### appspec.yml

The [AppSpec file](https://docs.aws.amazon.com/codedeploy/latest/userguide/application-specification-files.html) is used to manage each deployment as a series of lifecycle event hooks ([Reference](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file.html)).


An AppSpec file consists of:
* File section: How to copy from S3 / GitHub to filesystem
* [Hooks section](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html): Depending on the target environment, a different set of lifecycle event hooks apply:
  * [ECS](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-ecs) - [run order](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#reference-appspec-file-structure-hooks-run-order-ecs)
    * Start (*)
    * [Before|After]Install (*)
    * [After]AllowTestTraffic (*)
    * [Before|After]AllowTraffic (*)
    * End (*)
  * [Lambda](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-lambda) - [run order](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#reference-appspec-file-structure-hooks-run-order-lambda)
    * Start (*)
    * [Before|After]AllowTraffic (*)
    * End (*)
  * [EC2](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-server) - [run order](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#reference-appspec-file-structure-hooks-run-order):
    * Start (*)
    * [Before|After]BlockTraffic (**)
    * ApplicationStop
    * DownloadBundle (*)
    * [Before|After]Install (*)
    * ApplicationStart
    * ValidateService
    * [Before|After]AllowTraffic (**)
    * End (*)

Footnotes:
* (*) Can not be scripted (but the Before & After hooks can be scripted)
* (**) Only with Classic LoadBalancer in the deployment group

### Hands-on

1. IAM: Create service roles for CodeDeploy and EC2
   * Create a 'CodeDeploy' Service Role 
   * Create an 'EC2' Service Role (used by EC2 to run the CodeDeploy agent) with access policies:
     * AmazonS3ReadOnlyAccess (download deployable artifacts)
3. EC2: Launch new instance 
   * Amazon Linux 2 AMI (t2.micro)
   * IAM Role: the one created in step 2
   * Security Group: New rule allowing access over HTTP:80
   * Tag: environment=dev (used later on in CodeDeploy deployment groups)
   * Save & launch
4. Installing CodeDeploy Agent
   * SSH into the EC2 instance
   * [Install CodeDeploy agent](https://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent-operations-install.html):
```
sudo yum update
sudo yum install ruby
sudo yum install wget
cd /home/ec2-user
wget https://aws-codedeploy-eu-west-3.s3.eu-west-3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start
sudo service codedeploy-agent status
```
5. S3
   * Create a bucket where CodeDeploy can download its deployables
   * Upload your deployable
6. CodeDeploy
   * Create **application**
     * Compute type: EC2 / on-premises
   * Create **deployment group** (typically dev / test / prod / ..)
     * Group name: dev
     * Service role: The one from step 1
     * Deployment type: In-place (as opposed to Blue/Green)
     * EC2 Instances: key=environment / value=dev
   * Create **deployment**
     * Deployment group from previous step
     * Revision type: The S3 bucket from previous step
     * Revision location: The URL to the object in the S3 bucket



## :white_check_mark: CodeStar

AWS CodeStar is an integrated solution that regroups GitHub, CodeCommit, CodeBuild, CodeDeploy, CloudFormation, CodePipeline, CloudWatch. It provides a unified user interface. It comes with a project management dashboard powered by Atlassian JIRA. No additional costs, you only pay for the AWS resources that you provision with CodeStar.

* [Overview](https://aws.amazon.com/codestar/)
---

CodeStar is not available in eu-west-3 (Paris). But it is available in eu-west-1 (Ireland).

* CI/CD-ready projects for EC2, Lambda and BeanStalk
* Supported languages: HTML5, Java, Node.js, Python, ..
* Issue tracking with JIRA or GitHub issues
* One integrated dashboard, but with limited customization


