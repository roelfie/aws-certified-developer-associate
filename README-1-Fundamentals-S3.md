# Fundamentals - S3

## :white_check_mark: S3

S3 (Simple Cloud Storage Service) is an object storage service.
* [Overview](https://aws.amazon.com/s3/)
* [Storage classes](https://aws.amazon.com/s3/storage-classes/)
* [S3 Glacier](https://aws.amazon.com/glacier/)
* [User Guide](https://docs.aws.amazon.com/s3/)
* [Developer Guide](https://docs.aws.amazon.com/AmazonS3/latest/dev/Welcome.html)
* [Developer Guide (Glacier)](https://docs.aws.amazon.com/amazonglacier/latest/dev/glacier-select.html)
---

### Buckets and Objects

Buckets
* Objects (files) are stored in buckets
* Buckets are defined at the region level
* Buckets must have a globally (!) unique name 
* Naming convention:
  * lower case
  * no underscore
  * length 3-63
  * not an ip address
  * must start with letter or number

Objects
* An object is a file
* An object has a version ID (if versioning is enabled)
* An object has a key (key value includes the bucket name)
* No folders, but you can use `/` to mimic a folder structure:
  * `<my_bucket>/folder1/folder2/readme.txt`
* max size 5TB
* multi-part upload for object size > 5GB
* An object can have
  * metadata (key-value pairs of type text)
  * tags (max. 10)

#### Object versioning
* Set at bucket level (for all files, or none)
* Version is a base64 encoded string (not sequential numbers)
* Benefits: delete protection & easy rollback to previous version
* Unversioned objects (uploaded before enabling versioning) have version 'null'

### Encryption

Before talking about encryption, we should know about AWS [Key Management Service](https://aws.amazon.com/kms/) (KMS) ([User guide](https://docs.aws.amazon.com/kms/)). This service allows you to create and control encryption keys used (in many other AWS services) to encrypt data.

#### Encrypting data in-transit (in-flight)

Options:
* client-side encryption
* SSL

#### Encrypting data at rest

You can use server-side and client-side [encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingEncryption.html) to protect S3 data at rest.

##### Client-side encryption

[Client-side encryption](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingClientSideEncryption.html) ensures both in-flight and at rest encryption.
* Client encrypts and descrypts data
* Use libraries (Amazon S3 Encryption Client; AWS SDK for Java; ..)
* Options: 
  * Use a Customer Master Key (CMK) stored in AWS KMS
  * Use a master key stored in your own application

##### Server-side encryption
Server-side encryption methods:
* SSE-S3: [Encryption with Amazon S3-Managed keys](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingServerSideEncryption.html).
  * Provide the following header: `"x-amz-server-side-encryption": "AES256"`
  * each object is encrypted with its own key
  * this key itself is encrypted with the S3 master key (which is managed by S3 itself)
* SSE-KMS: [Encryption with CMKs stored in AWS KMS](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingKMSEncryption.html).
  * Provide the following header: `"x-amz-server-side-encryption": "aws-kms"`
  * the CMK must be in the same region as the bucket
  * You can create and choose your own CMK (from AWS KMS); or you can let Amazon S3 automatically create (the first time you ask for server-side encryption) an AWS managed CMK in your AWS account and use that one.
  * S3 only supports symmetric CMKs.
* SSE-C: [Encryption with Customer-Provided keys](https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html).
  * Encryption key is fully managed by the customer (outside AWS)
  * S3 will never store the encryption key, only use it
  * HTTPS required (apparently SSE-S3 and SSE-KMS also work over HTTP)
  * The encryption key must be provided in an HTTP header, for every request
    * `"x-amz-server-side​-encryption​-customer-key"="<256-bit base64-encoded encryption key>"`
    * `"x-amz-server-side​-encryption​-customer-key-MD5"="<base64-encoded 128-bit MD5 digest of key>"` (for message integrity)
    * `"x-amz-server-side​-encryption​-customer-algorithm"="AES256"`

You can specify encryption at object level (when you upload it).
You can also define default encryption for the bucket (in which case you don't specify encryption during object upload).

:warning: server-side encryption in S3 encrypts only the object, not the meta-data!

### Security

This section is about S3 [security](https://docs.aws.amazon.com/AmazonS3/latest/dev/security.html) and [access management](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) in particular.

By default, all S3 resources are private (only accessible to the AWS account that created it). The resource owner can optionally grant access permissions to others by writing an access policy. There are two kinds of access policies:
* [User policies](https://docs.aws.amazon.com/AmazonS3/latest/dev/example-policies-s3.html) 
  * also called IAM policies 
* Resource-based policies
  * [Bucket policies](https://docs.aws.amazon.com/AmazonS3/latest/dev/example-bucket-policies.html)
  * [Access Control Lists (ACL)](https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html)
    * Object ACL
    * Bucket ACL

The exam will focus on [bucket polies and user policies](https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html) and less on ACLs.

#### Bucket policies

* JSON document describing
  * Resources (buckets and objects)
  * Actions (APIs to allow or deny)
  * Effect (Allow / Deny)
  * Principal (the user to apply the policy to)

In the S3 console, in the bucket's Permissions > Bucket Policies, you can find a Policy Generator!

Bucket policy changes are not instantaneous. It can take some time. 

Example: [Preventing uploads of unencrypted objects](https://aws.amazon.com/blogs/security/how-to-prevent-uploads-of-unencrypted-objects-to-amazon-s3/).

#### Security features of S3

* Supports VPC endpoints
* S3 access logs can be stored in another S3 bucket
* API calls can be logged in AWS CloudTrail
* MFA (multi factor authentication)
* Signed URLs (only valid for a period of time)
* Enforce encryption on upload

### S3 Websites

You can setup a [static website](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html) using S3. Make sure the bucket policy allows public reads (to prevent HTTP 403):
* Principal: *
* Action: GetObject
* Effect: Allow

### CORS

CORS ([Cross Origin Resource Sharing](https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html)) allows web application from one domain to interact with resources in a different domain.
* More info on CORS on the [Mozilla developer portal](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

### Consistency model

S3 is a global service. Some operations can take time to be effective globally (eventual consistency).

* Read after write consistency for PUT of new objects 
  * PUT 200 => GET 200
  * only if we did not GET the same object before the PUT (GET 404)
* Eventual consistency for DELETE and PUT of existing objects
  * PUT 200 => PUT 200 => GET 200 ; might return version 1
  * PUT 200 => DELETE => GET 200 ; might still return the original (cached) object

### Performance

#### (Not) randomizing keys 
Behind the scenes, each object is saved in an S3 partition. Until July 2018, the more randomly your keys were distributed, the better partition distribution, the better performance you got. A trick to achieve this key distribution was to prefix keys with random strings (e.g. 4 hex digits).

However since July 2018 performance was improved dramatically, without the need to distribute (=random prefix) keys. For each prefix, you can get 3500 RPS (requests per second) for PUT and [5500 RPS for GET](https://docs.aws.amazon.com/AmazonS3/latest/dev/optimizing-performance.html).

#### Multipart uploads
For performance reasons, if your object is > 100MB, consider [multipart upload](https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html):
* parellizes PUTs for greater throughput
* decreases retry time in case an upload fails

If your object is > 5GB you *must* use multipart.

#### CloudFront & Transfer Acceleration

[CloudFront](https://aws.amazon.com/cloudfront/) is a CDN (Content Delivery Network) that can help to improve performance.

S3 Transfer Acceleration improves long distance S3 uploads and downloads (by uploading to the closest edge, and in the background transfer it to the remote location). 
* [Overview](https://aws.amazon.com/s3/transfer-acceleration/)
* [User Guide](https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html)

#### SSE-KMS throttling

If you use SSE-KMS for encryption, and you write a lot of data to your bucket, performance may degrade. KMS is throttling (not S3) and you can increase the KMS limits to improve performance.

### S3 Glacier Select

S3 Glacier is an S3 storage class for long term archival. Storage is cheap but retrieval can be expensive. Instead of restoring an entire Glacier bucket, [Glacier Select](https://docs.aws.amazon.com/amazonglacier/latest/dev/glacier-select.html) allows you to do simple SQL queries in Glacier (no sub-queries or joins!) to save 80% on costs / 400% performance increase.

Also works with
* CSV, JSON, Parquet files
* GZIP, BZIP2 encryption



