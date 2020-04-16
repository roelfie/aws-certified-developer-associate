# Fundamentals - ELB, ASG & EBS


## :white_check_mark: Elastic Load Balancing (ELB)

* [Overview](https://aws.amazon.com/elasticloadbalancing/)
* [User Guide](https://docs.aws.amazon.com/elasticloadbalancing/)
* [User Guide (Application Locad Balancer)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
---

Functions of a load balancer:
* Distribute traffic across multiple targets
* [Health check](https://docs.aws.amazon.com/autoscaling/ec2/userguide/healthcheck.html) downstream instances
* [SSL termination](https://avinetworks.com/glossary/ssl-termination/) (encryption / decryption)
* [Sticky sessions](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-sticky-sessions.html)
* High availability across AZs
* Separate public traffic from private traffic

### Overview

Below is a [comparison](https://aws.amazon.com/elasticloadbalancing/features/) of Amazon's load balancers:

|                                   | Application Load Balancer  | Network Load Balancer  | Classic Load Balancer      |
|-----------------------------------|----------------------------|------------------------|----------------------------|
| Layer                             | Layer 7 (application)      | Layer 4 (transport)    |                            |
| Since                             | 2016                       | 2017                   | 2009                       |
| Protocols                         | HTTP, HTTPS                | TCP, UDP, TLS          | TCP, SSL/TLS, HTTP, HTTPS  |
| Websockets                        | v                          | v                      | v                          |
| IP address as target              | v                          | v                      |                            |
| Sticky sessions                   | v                          |                        | v                          |
| Static IP                         |                            | v                      |                            |
| Elastic IP                        |                            | v                      |                            |
| Redirects                         | v                          |                        |                            |
| Fixed response                    | v                          |                        |                            |
| Lambda function as target         | v                          |                        |                            |
| **Content-based routing**         |                            |                        |                            |
| Path-based routing                | v                          |                        |                            |
| Host-based routing                | v                          |                        |                            |
| HTTP header-based routing         | v                          |                        |                            |
| HTTP method-based routing         | v                          |                        |                            |
| Query string param-based routing  | v                          |                        |                            |
| Source IP addr CIDR-based routing | v                          |                        |                            |
| **Security**                      |                            |                        |                            |
| Tag-based IAM permissions         | v                          | v                      |                            |
| Resource-based IAM permissions    | v                          | v                      | v                          |
| User Authentication               | v                          |                        |                            |

All load balancers support:
* SSL or TLS (SSL offloading)
* Health checks
* CloudWatch metrics
* Logging
* Zonal fail-over
* Cross zone load balancing

:warning: All LBs have a static host name. Do never use the underlying IP address!

:warning: LBs can scal, but not instantaneously (contact AWS for a "warm up" if needed)

:warning: HTTP 503 means either no target, or LB has no more capacity

#### Application Load Balancer

The [Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) is the most flexible load balancer that works with EC2 and ECS (Elastic Container Service). It supports HTTP / HTTPS and integrates with EC2 Autoscaling, CloudWatch, Route 53, AWS WAF.

* Content-based routing rules (See table above)
* Latency 400ms
* Load balancer sets the following HTTP headers:
  * `X-Forwarded-For`: Client IP address
  * `X-Forwarded-Port`: Destination port the client used to connect to the LB
  * `X-Forwarded-Proto`: Protocol the client used to connect to the LB (HTTP or HTTPS)
* Request tracing (load balancer injects a `X-Amzn-Trace-Id` HTTP header)
* Balancing across machines
* Balancing across containers (applications on the same machine)
* Good for: Microservices & container based applications (docker, Amazon ECS)
* Port mapping feature to map to dynamic port
* SSL certificate management (through IAM and AWS Certificate Management)

#### Network Load Balancer

The [Network Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) is a high-performance low-latency load balancer. Like the Application Load Balancer, it can be set up to work with EC2 and ECS.

* High performance (millions requests/sec) and ultra-low latency (100ms)
* Handles sudden and volatile traffic patterns
* Integrated with AutoScaling, EC2, Cloud Formation and AWS Certificate Management (ACM)
* Work with: EC2 instances, microservices, containers

#### Classic Load Balancer

The [Classic Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/introduction.html) is deprecated. It is only recommended for applications built within the EC2-Classic network.

### Configuration of an Application Load Balancer for EC2 instances

Example of an AWS EC2 configuration with two instances hosting a web application on port 81:

* www: HTTP request on port 80 (@load balancer DNS name)
  * (security group allowing port 80) -> Application Load Balancer
    * Target Group
      * configured to forward HTTP traffic to port 81 on EC2 instances (in specified AZs)
      * the following EC2 instances are registered in the target group:
        * (security group allowing port 81) EC2 instance 1 (AZ a)
        * (security group allowing port 81) EC2 instance 2 (AZ b)

By default an EC2 instance is given a public IP address. If you want to allow inbound traffic only via the load balancer, configure the EC2 instance's security group as follows:
* Type = Custom TCP rule
* Port range = 81 (example)
* Source
  * Custom
  * In the value you can type in the Name or Id of the load balancer's security group

## :white_check_mark: EC2 Auto Scaling

EC2 Auto Scaling (ASG) allows you to ensure that you have the correct number of instances available to handle the load for your application.
* [Overview](https://aws.amazon.com/autoscaling/)
* [User Guide](https://docs.aws.amazon.com/autoscaling/ec2/userguide)
---

Summary:
* Scale out (add instance) and in (remove instance) as load changes over time
* Based on (CloudWatch) alarms
  * avg. CPU
  * avg. network I/O
  * #requests on the ELB per instance
  * custom metrics (e.g. #connected users)
    * send custom metric from EC2 application to CloudWatch
    * create CloudWatch alarm based on metric
    * use alarm as scaling policy for the ASG
* You can also autoscale based on  schedule (if you know that everyday 5-7pm are peak hrs)
* Specify minimum & maximum #instances
* Automatically register new instance with load balancer
* IAM roles defined on ASG will be inherited by the EC2 instances
* ASG is a free service (you pay for the EC2 instances)
* ASG will restart an instance if it gets terminated
* ASG will terminate an instance if it is unhealthy (and spin up a new one if necessary)

### Creating an Auto Scaling Group (ASG)

* Create / select a launch template (AMI, user data, security group, etc.)
* Create an ASG
  * You can put your ASG behind an ELB by choosing the appropriate target group 

#### Mixing manually created and ASG created instances

:warning: If you use an existing target group, with one or more manually created EC2 instances in it, those EC2 instances will not be managed by the ASG! Suppose your target group originally already contained one EC2 instance. If you create a new ASG with this target group and tell the ASG it should have a minimum of 1 instance, then it will spin up one (additional!) EC2 instance in the target group.
* There are now 2 EC2 instances in the target group
* There is now 1 EC2 instance visible in the ASG
* The load balancer will distribute traffic to the 2 EC2 instances

Bottom line: Using a non-empty target group in a new ASG will lead to confusion.

## :white_check_mark: Elastic Block Store (EBS)

* [Overview](https://aws.amazon.com/ebs)
* [User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonEBS.html)
---

* Network drive (not a physical drive)
* Easily detached from one instance and attached to another
* Locked to an AZ
* You can not move an ESB cross zones, but you _can_ move ESB _snapshots_
* Billing for all the provisioned capacity (GB and IOPS)
* [ESB Volume Types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonEBS.html)
  * SSD
    * gp2: general purpose, recommended for most workloads (boot volumes, virtual desktops, dev/test environments)
    * io1: critical business applications with high throughput (databases)
  * HDD (can not be boot volume)
    * st1: consistent, fast throughput at a low price (big data, data warehouse, log processing)
    * sc1: large volumes of data that is infrequently accessed, low price (backup, archiving)
* EBS Volumes can be [resized](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/requesting-ebs-volume-modifications.html) (for io1, IOPS can also be increased)
* [Snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSSnapshots.html) 
  * backups, changing volume type, volume encryption, etc.
  * smaller than the actual volume (only the actual data is in it)
  * can be scheduled (nightly backups)
* When you create an [encrypted EBS volume](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html)
  * All **data at rest** is encrypted inside volume
  * All **data in flight** (between EC2 instance and EBS) is also encrypted
  * All snapshots are encrypted (as are the volumes created from the snapshots)
  * Fully transparent, minimal impact on latency

### Instance Store vs EBS

There are [two types of root volumes](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/RootDeviceStorage.html) for EC2 instances: 
* Amazon EBS volume (created from an Amazon EBS snapshot)
* [Instance store volume](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ComponentsAMIs.html#storage-for-the-root-device) (created from a template stored in Amazon S3)
  * physically attached to the EC2 instance
  * boots slower
  * better I/O
  * cannot be stopped; only running or terminated
  * instance store lost on EC2 instance termination
  * can't be resized



