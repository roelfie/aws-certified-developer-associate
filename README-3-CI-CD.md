# CI/CD

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
* pay per used per month

You can give someone else access to your repository using an IAM role and AWS STS (AssumeRole API). Never share SSH keys are AWS credentials!

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

* [Overview](https://aws.amazon.com/codepipeline/)
* [User Guide](https://docs.aws.amazon.com/codepipeline/index.html)


## :white_check_mark: CodeBuild

* [Overview](https://aws.amazon.com/codebuild/)
* [User Guide](https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html)


## :white_check_mark: CodeDeploy

* [Overview](https://aws.amazon.com/codedeploy/)
* [User Guide](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html)

