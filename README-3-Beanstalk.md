# Elastic BeanStalk

## :white_check_mark: Elastic BeanStalk

AWS Elastic BeanStalk (EB) is an easy-to-use service for deploying and scaling web applications and services developed with Java, Node.js, Python, Docker, etc. on familiar servers such as Apache and Nginx.
* [Overview](https://aws.amazon.com/elasticbeanstalk/)
* [Developer Guide](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg)
* IntelliJ IDEA [BeanStalk plugin](https://plugins.jetbrains.com/plugin/7274-aws-elastic-beanstalk-integration)
* [EB CLI](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3.html) - A BeanStalk extension to the AWS CLI (commands start with `eb`)

---

### Applications, Versions, Environments

BeanStalk has three components: 
* Application
* Application version
* Environments

You upload an application to BeanStalk. BeanStalk assigns a version number to it. You can then release it to an environment. And promote it to the next environment (or rollback to the previous version).

When creating a BeanStalk environment with a sample web application, it will [create](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/GettingStarted.CreateApp.html#GettingStarted.CreateApp.AWSresources)
* an EC2 instance
* an EC2 security group
* an S3 bucket (for storing source bundles and configuration)
* CloudWatch alarms
* a CloudFormation stack
* a domain name

### Environment types

There are different [environment types](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.deploy-existing-version.html):
* **Single instance** (default)
  * Good for development
* **Load balanced**
  * Good for web-apps in production
  * Comes with auto-scaling groups and a load balancer
  * You can create this type of environment by choosing the configuration preset `High availability` (instead of the default `Single instance`)
  * You can also create (configuration preset `custom`?) an ASG environment without load balancer; Good for non-web-apps in production (workers)

By default the creation wizard creates a `Single instance` environment, good enough for development purposes. If you want something more advanced, choose 
another configuration preset (under the `Configure more options` button).

### Deployment policies

There are different ways in which you can roll out a new version of your application to an environment, called 'deployment modes' or [deployment policies](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.rolling-version-deploy.html):

* **All-at-once** (default)
  * Quick & no additional costs
  * The only deployment method with downtime
* **Rolling**
  * BeanStalk splits the EC2 instances into *batches*. The new version of an application is deplyed one batch at a time
  * Takes longer than All-at-once
* **Rolling with additional batches**
  * Like `Rolling` but before taking any instance out of service, a new batch of instances is launched
  * Your application will remain available at full capacity at all times
  * Small additional costs
* **Immutable**
  * [Immutable updates](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environmentmgmt-updates-immutable.html) are an alternative to rolling updates
  * BeanStalk creates a new AutoScaling group behind the load balancer to contain the new instances
  * If the immutable update fails, rolling back to the old version only requires the termination of an Auto Scaling group
  * Temporarilly doubles the capacity of your environment
    * Comes with extra costs!
    * Make sure your capacity / quotas support it!

The rollback process always is a manual redeploy (except in the case of Immutable updates, which requires the termination of an ASG).

:warning: The batch size for rolling updates can be configured in the `Rolling updates and deployments` section of your environment's configuration page.

:warning: Rolling updates are not supported on single instance environments.

#### Blue / Green deployment

In a [Blue / Green deployment](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.CNAMESwap.html) you deploy the new version to a separate environment. When the new environment is up & running (and properly tested internally), you swap CNAMEs of the two environments to the new version instantly.
* Minimizes downtime
* Requires DNS change
* Required if you want to update to an incompatible platform version
* Tricky if your environment includes a database; data might get lost!
* Route 53 can be used to setup weighted policies (redirect only 10% of traffic to the new environment)
* Rollback: Swap URL

### Source bundles

Applications are uploaded as [source bundles](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/applications-sourcebundle.html):
* ZIP or WAR
* Stored in the S3 bucket associated with the BeanStalk environment
* max. 512 MB
* You provide code (for instance *.java) and dependency descriptors (gradle or maven file)
* The EC2 instance will resolve the dependencies (and compile code?)
* Optimization: Package all the dependencies inside the ZIP file
* The folder `.ebextensions` contains BeanStalk configurations
  * in YAML or JSON format
  * files end with `*.config`
  * you can add AWS resources, like RDS, ElastiCache, DynamoDB, ..

### BeanStalk & CloudFormation

BeanStalk uses [CloudFormation](https://docs.aws.amazon.com/cloudformation/index.html) under the hood. If you create a BeanStalk environment, you will also find a new CloudFormation stack.

### HTTPS

Serving a BeanStalk application over HTTPS:
* Load SSL certificate onto the (EB) Load Balancer
  * This can be done from the EB console
  * Or programmatically: `.ebextensions/securelistener-alb.config`
* SSL certificate can be provisioned using ACM or the CLI
* Security group must allow inbound HTTPS (port 443) traffic

[Redirect HTTP to HTTPS](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/configuring-https-httpredirect.html)
* Define a rule in the Application Load Balancer
* Make sure health checks are not redirected (or they will report failures)

### Lifecycle Policies
Elastic BeanStalk has the following default [service quotas](https://docs.aws.amazon.com/general/latest/gr/elasticbeanstalk.html#limits_elastic_beanstalk):
* Max. 75 applications
* Max. 1000 Application Versions (in total, across all applications)
* Max. 2000 Configuration Templates
* Max. 200 Environments

If you have uploaded 1000 applications, you won't be able to upload a new application version, unless you delete older versions.

An application version [lifecycle policy](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/applications-lifecycle.html) allows Elastic BeanStalk to automatically delete old application versions. A lifecycle policy can delete application versions based on 
* the total number of application versions (e.g. start deleting once you reach 100 versions)
* the age of application versions (e.g. remove versions older than 90 days)

Example: If you have 20 applications, with the default quota of max. 1000 application versions, you might want to define policies for you applications that start deleting unused versions of an application once you reach 49 versions.

:warning: If BeanStalk removes an application version, it does not remove the corresponding source bundle from the S3 bucket. You have to cleanup S3 manually (or using S3 policies).

:warning: BeanStalk will never delete versions that
* are still deployed in an environment
* are deployed to environments that were terminated less than 10 weeks agao

### Web Applications vs. Workers

Long running tasks should not be executed by the web tier. The web tier should delegate them to a worker tier (other type of BEanStalk environment) via AWS SQS.

When you create a new BeanStalk environment, you can choose between:
* Web Tier: 
  * EC2 + ELB / ASG
  * Handles HTTPs requests
  * Delegates compute-intensive work to the worker tier via SQS
* Worker Tier: 
  * EC2 + SQS
  * Handles SQS messages
  * more info on [worker environments](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html)

### RDS on BeanStalk

How to [decouple an Amazon RDS instance from a BeanStalk environment](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.RDS.html).

You don't want your database to be provisioned by BeanStalk (perhaps in a dev environment, but nowhere else) because your DB lifecycle will be tied to your BeanStalk environment lifecycle (terminate the BeanStalk environment and you will loose your data).

Instead, run your database in Amazon RDS, and configure your BeanStalk application to connect to it on launch (provide a connection string).

