#!/bin/bash

#Cloud uploader to S3 bucket in AWS

############################################################
# Help                                                     #
############################################################
Help() {
   # Display Help
   echo "CloudUploader CLI Version 1.0"
   echo
   echo "Syntax: clouduploader [-h|s||V]"
   echo "options:"
   echo "h     Print this Help."
   echo "s     Initial Setup Up command - Checks current configuration, and allows to change configuration"
   echo "v     "
   echo "V     "
   echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Get the options
while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
   esac
done




#Step 1: Setup and Authenticate





#Setup function
setup() {
    echo "Starting intial Setup"
    checkforinstall
    checkforauthen
}


#Gets current version and installs AWS if not already installed
checkforinstall() {
    AWS_CLI_VERSION=$(aws --version 2>&1 | cut -d " " -f1 | cut -d "/" -f2)
    if [[ "$AWS_CLI_VERSION" == "" ]]; then
        echo "AWS not found, installing latest version..."
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
    else
        echo "AWS already installed... skipping installation"
    fi
}

authentication_setup() {
    read -p "Enter Access Key ID: " AWS_ACCESS_KEY_ID
    read -p "Enter Secret Access Key: " AWS_SECRET_ACCESS_KEY
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
}


checkforauthen() {
    currentuser=$(aws sts get-caller-identity 2>&1 | cut -d "{" -f1 | cut -d "}" -f2)
    echo "Checking current user information..."

    if [[ $currentuser == "" ]]; then
        echo "No current user, please authenticate first"
        authentication_setup
    else
        read -p "Current user is: $currentuser, do you want to change users? y/n" tempANS
        if [[ $tempANS == "y" ]]; then
            authentication_setup
        elif [[ $tempANS == "n" ]]; then
            echo "continuing with current user"
        else
            echo "Invalid input, restart the app to continue..."
        fi
    fi
} 


setup


if [ $? -ne 0 ]; then
    echo "Error occurred."
fi