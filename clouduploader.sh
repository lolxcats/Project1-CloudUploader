#!/bin/bash

#Cloud uploader to S3 bucket in AWS

############################################################
# Help                                                     #
############################################################
show_help() {
cat << 'EOF'
    "CloudUploader CLI Version 1.0"

    "Syntax: clouduploader [-h|-s|-u|]"
    "options:"
    "h     Print this Help."
    "s     Initial Setup Up command - Checks current configuration, and allows to change configuration"
    "u     Upload to S3 Bucket, needs file name and path to upload"
    "V     "
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
while getopts ":hs:u:" option; do
   case $option in
      h) # display Help
         show_help
         exit;;
      s) # Initial Configuration
        echo "running command"
         setup
         exit;;
      u) # Upload File - requires path argument
        echo "Uploading file to ${OPTARG}..."
        #UploadFile(filepath)
        exit;;
      \?) # Invalid option
         echo "Invalid Option"
         exit;;
      : ) #argument missing
        echo "Invalid option -$OPTARG requires argument" 1>&2
        exit;;
   esac
done

#unknown parameter check
if [ $# -ne 0 ]; then
    echo "Error: Invalid parameter"
fi
