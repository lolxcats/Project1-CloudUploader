#!/bin/bash

#Cloud uploader to S3 bucket in AWS

# Define ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

############################################################
# Help                                                     #
############################################################
show_help() {
cat << 'EOF'
--------------------------------------------------------------------------

    CloudUploader CLI Version 1.0

    Syntax: clouduploader [-h|-s|-u|-c|-f]
    options:
    h     Print this Help.
    s     Initial Setup Up command - Checks current configuration, and allows to change configuration
    c     Print out current user configuration
    u     Upload to S3 Bucket, needs file name and path to upload
       (clouduploader.sh -u {filepath} {bucket name})
       (ex. clouduploader.sh -u {.\testfile} {s3://bucket-name})
    f     Check to see if file already exists

--------------------------------------------------------------------------

EOF
}

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

#Current user information
function get_currentuser() {
    currentuser=$(aws sts get-caller-identity 2>&1 | cut -d "{" -f1 | cut -d "}" -f2)
    echo "Current User Information:  $currentuser"
}

#File Upload
function uploadfile() {
    if [[ $bucketname == "" ]]; then
        echo -e "${RED}No bucket name specified, Proceeding with default bucket...\n${NC}"
        pickdefaultbucket
        echo -e "${RED}Using bucket: $bucketname...${NC}"
    fi

    if [[ check_file_already_exists ]]; then
        while true; do
            read -rep $"File {$filename} already exists in {$bucketname}.Do you want to overwrite it? [y/n]: " yn
            case $yn in
            [Yy]* ) 
                echo -e "\nOverwriting..."
                aws s3 cp $filepath $bucketname
                break;;
            [Nn]* ) 
                echo "Exiting..."
                break;;
            * ) 
                echo "Please enter y or n";;
            esac
        done
    else
        aws s3 cp $filepath $bucketname
    fi
}

function pickdefaultbucket() {
    bucketname=$(aws s3api list-buckets --query "Buckets[0].Name" --output text | tr -d '"')
    if [[ $bucketname == "" ]]; then
        echo -e "\nNo current available buckets, please create bucket first"
        break
    else
        bucketname="s3://$bucketname"
    fi
}
#Checking for File already existing
function check_file_already_exists() {
    found=$(aws s3 ls s3://$bucketname/$filename)
    if [[ $found != "" ]]; then
        true
    else
        false
    fi
}


############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# No Input Check
if [[ $# -eq 0 ]] ; then
    echo "No argument flags provided, try -h to view the help"
    exit 1
fi

# Parameter Check
while getopts ":hcsf:u:" option; do
   case $option in
      h) # display Help
         show_help
         exit;;
      s) # Initial Configuration
        echo "running command"
         setup
         exit;;
      c) #print current user information
        get_currentuser
        exit;;
      u) # Upload File - requires path argument
        filepath="$2"
        filename=$(basename $filepath)
        bucketname="$3"
        uploadfile
        exit;;
      f) #check to see if file exists
        filepath="$2"
        filename=$(basename $filepath)
        bucketname="$3"
        if [[ check_file_already_exists ]]; then 
            echo "File already exists"
            echo "TEST $found"
        else
            echo "File does not exist"
        fi
        exit;;
      \?) # Invalid option
         echo "Invalid Option"
         exit;;
      : ) #argument missing
        echo -e "\n${RED}Invalid option -$OPTARG requires argument\nView -h for help\n${NC}" 1>&2
        exit;;
   esac
done

#unknown parameter check
if [ $# -ne 0 ]; then
    echo "Error: Invalid parameter"
fi