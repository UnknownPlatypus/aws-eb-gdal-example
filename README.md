# aws-eb-gdal-example

A way to setup Geodjango for Django 3.2.5 and MySQL 5.7 on Amazon Linux AMI (EC2).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Table of Contents
1. Setup Elasticbeanstalk with an EC2 key pair for SSH permssions
2. Setup an S3 bucket correctly
3. Build GDAL and push it to S3
4. Loading and running in ElasticBeanstalk

## Setup Elasticbeanstalk
When you create an Eb environment, make sure to se the EC2 keypair (Configure -> Security -> Virtual Machine Key Pair) and note the IAM instance profile that you select. This IAM instance will be used in the next step.

## Setup S3
Create (or reuse) an S3 bucket (`eg: s3-bucket-name`) and folder (`eg: path/to/empty/folder`) to hold the built GDAL libraries. Configure the Bucket Policy permissions so that your IAM role can do PUT actions to that folder:
```json
  {
      "Principal": {
          "AWS": "__Full ARN of the above IAM role__"
      },
      "Action": [
          "s3:PutObject",
          "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::__s3-bucket-name/path/to/empty/folder__/*"
  }
```

## Building GDAL
SSH into EC2 machine and build gdal by copy-pasta the `gdal-build-script.sh`. The script uses s3 cp to transfer the builds onto the S3 above.

## Running in EB
Finally, `.ebextension` scripts will pull the libs from S3 and simply run them. Use the example implementation in `.ebextensions/` folder here.
