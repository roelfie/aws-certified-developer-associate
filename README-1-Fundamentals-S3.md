# Fundamentals - S3

## :white_check_mark: S3

S3 (Simple Cloud Storage Service) is an object storage service.
* [Overview](https://aws.amazon.com/s3/)
* [User Guide](https://docs.aws.amazon.com/s3/)
* [Developer Guide](https://docs.aws.amazon.com/AmazonS3/latest/dev/Welcome.html)
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

### Object versioning
* Set at bucket level (for all files, or none)
* Version is a base64 encoded string (not sequential numbers)
* Benefits: delete protection & easy rollback to previous version
* Unversioned objects (uploaded before enabling versioning) have version 'null'

### Encryption

####

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
* [user policies]() (IAM policies): 
* [resource-based policies](): 
  * Bucket policies
  * Object ACL (Access Control List)
  * Bucket ACL



