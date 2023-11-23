#!/bin/bash

#Cloud uploader to S3 bucket in AWS

#Step 1: Setup and Authenticate

#Setup function

setup() {
    #install aws cli
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    sudo installer -pkg AWSCLIV2.pkg -target /

    #authenticate user
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
    aws configure set default.region $AWS_REGION
}


setup