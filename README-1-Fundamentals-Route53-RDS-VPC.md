# Fundamentals - Route53, RDS & VPC

## :white_check_mark: Route 53

Route53 is Amazon's DNS service.
* [Overview](https://aws.amazon.com/route53/)
* [User Guide](https://docs.aws.amazon.com/route53/)
* [DNS](https://aws.amazon.com/route53/what-is-dns/)
---

With Route 53 you can
1. register domain names
2. route internet traffic
3. health check your resources


Route 53 connects user to 
* AWS resources (EC2 instances, ELB load balancers, S3 buckets, ..)
* infrastructure outside of AWS

Features:
* [Load balancing]()
* [Health checks](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html)
* [Routing policies](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html)
  * simple
  * failover
  * geolocation
  * geoproximity
  * latency-based
  * multivalue answer
  * weighted


### DNS Records

Route 53 supports many DNS [record types](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/rrsets-working-with.html), the most important being:
* A: URL -> ipv4
* AAAA: URL -> ipv6
* CNAME: URL -> URL
* Alias: URL -> AWS resource
  * Use Alias instead of CNAME to map an AWS resource ([Alias vs. CNAME](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html))

### Making Route 53 the DNS service for an existing domain

[Making Route 53 the DNS service for an inactive domain](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/migrate-dns-domain-inactive.html)

1. AWS Route 53: Create a hosted zone
   * domain = ...
   * type = Public Hosted Zone
2. AWS Route 53: Create DNS records
   * copy over whatever records you'd like to keep from your existing DNS service (e.g. NameSilo)
   * create new records to map to your AWS resources (see below)
3. Domain registrar: Update the domain registration to use Amazon Route 53
   * AWS hosted zone: copy the values of the NS-record (the Route 53 name servers)
   * Registrar (e.g. NameSilo): Change the name servers for the domain to the ones copied above

Mapping your domain to an Application Load Balancer:
* In your Route 53 hosted zone (created above) choose "Create Record Set"
  * domain = mysub.domain.com
  * type = A - IPv4 address
  * Alias = Yes
  * Alias Target = <ALB>


## :white_check_mark: RDS

RDS allows you to set up, operate and scale a relational database.
* [Overview](https://aws.amazon.com/rds/)
* [User Guide](https://docs.aws.amazon.com/rds/)
---

Supported databases:
* Postgres
* MySQL
* Oracle, SQL Server
* MariaDB (fork of MySQL; open source)
* Aurora (AWS cloud optimized RDBMS) has its own [user guide](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html)

Advantages of using RDS over deploying your own database on an EC2 instance:
* OS patching
* Automatic backups
  * daily full snapshot
  * 7 day retention (can be increased to 35 days)
  * real time transaction logs => ability to restore to any point in time
  * manual snapshot also possible
* Monitoring dashboards
* Read replicas (improved read performance)
  * master (writes) and replicas (reads) have different connection strings
  * up to 5 replicas; in the same AZ / cross AZ / cross Region
  * async replication
  * eventually consistent
* Multi AZ setup
  * for disaster recovery / high availability
  * master and stand-by instance
  * synchronous replication
  * automatic failover (in case master fails) seamless (DNS name does not change)
* Maintenance windows for upgrades
* Scaling (vertical and horizontal)
* They are managed services; you can't ssh into them and can't interact directly

### RDS Security

User Guide > [Security in Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.html)

You can [encrypt](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Encryption.html) your RDS instance:
* [At rest](): AWS KMS with AES-256 encryption
* [In-flight](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html) using SSL certificates
  * [Oracle](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Oracle.html#Oracle.Concepts.SSL) use the `SQLNET.SSL_VERSION` option
  * [SQL Server](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/SQLServer.Concepts.General.SSL.Using.html) startup parameter `rds.force_ssl=1`
  * [Postgres](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts.General.SSL) startup parameter `rds.force_ssl=1`
  * [MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.SSLSupport) run statement `ALTER USER 'encrypted_user'@'%' REQUIRE SSL;`
  * [MariaDB](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MariaDB.html#MariaDB.Concepts.SSLSupport) run statement `ALTER USER 'encrypted_user'@'%' REQUIRE SSL;`

Usually deployed in a private subnet. 
* Security groups control what AWS resources can **communicate** with the RDS.
* IAM policies control who can **manage** RDS.
* Log in to database using
  * RBD specific username/password
  * IAM user (MySQL/Aurora only)

### Aurora

User guide > [What is Amazon Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html)

* Compatible with Postgres and MySQL (meaning that you can use a Postgres or MySQL driver to connect)
* Cloud optimized (5x MySQL, 3x Postgres)
* Storage automatically grows in 10GB increments (<=64TB)
* 15 replicas (MySQL only 5), replication is faster!

### Sqlectron

[Sqlectron](https://sqlectron.github.io/) is a lightweight SQL desktop client for
* Postgres
* MySQL
* SQL Server
* Cassandra
* SQLite

## :white_check_mark: ElastiCache

ElastiCache is an in-memory NoSQL database (key-value store).
* [Overview](https://aws.amazon.com/elasticache/)
* [User Guide](https://docs.aws.amazon.com/elasticache/) 
---

NoSQL represents a category of database that can be categorized as follows:
* document (MongoDB)
* key-value (Redis, Memcached, Ehcache)
* graph (Neo4J)
* column-based (Cassandra)

ElastiCache is an in-memory key-value store based on either 
* [Redis](https://redis.io/)
* [Memcached](https://memcached.org/)

ElastiCache supports
* write scaling (sharding)
* read scaling (read replicas)
* Multi AZ with failover

Data stored in Redis survives a reboot (persistence); Data in Memcached does not.

### Use cases
* Cache (offload read workloads of your databases & improve response times)
* session store (makes your application stateless; application can go down without loosing data)

Blog post: [Cache vs. Session store](https://redislabs.com/blog/cache-vs-session-store/)

### Strategies

* Lazy loading
  * In case of a cache miss, the application must query the database, and store the result in the cache.
  * If needed, you have to do extra work to prevent the cache from serving outdated data (e.g. by invalidating).
* Write-through
  * The application writes data to the database as well as the cache. So the cache is always up-to-date.
  * The cache is not necessarilly complete (depending on your implementation).

These are not two muutually exclusive strategies: Lazy loading says that objects are added to the cache _on read_, Write-through says that objects are added to the cache _on write_. Neither case guarantees that the cache is complete at any given point in time. You could combine the two strategies.

## :white_check_mark: VPC

VPC (Virtual Private Cloud) provisions a logically isolated section of the AWS Cloud (a virtual network).
* [Overview](https://aws.amazon.com/vpc/)
* [User guide](https://docs.aws.amazon.com/vpc/)
---

A VPC
* is tied to a region
* can span multiple AZs
* contains one or more subnets

VPCs can be peered (even across accounts) to make it look like they're parte of one big network.

A [subnet](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)
* is tied to an AZ
* can be private or public 
* an AZ can contain multiple subnets (mix of public/private)

Your VPC in region `eu-west-3` may look something like this:
* VPC
  * AZ `eu-west-3a`
    * private subnet
    * public subnet
  * AZ `eu-west-3b`
    * private subnet
    * public subnet
  * AZ `eu-west-3c`
    * private subnet
    * public subnet

Subnets can only communicate with each other if they're in the same VPC.

### Public subnets
* load balancers (ELB)
* static web sites, files (S3)
* public authentication layers

### Private subnets
* application servers (EC2)
* databases (RDS)


