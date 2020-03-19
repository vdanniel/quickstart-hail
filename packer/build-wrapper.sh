#!/bin/bash
#
# Wraps the build process for validations, etc
#

# TODO: validate environment variables before execution

REPOSITORY_URL="https://github.com/hail-is/hail.git"

usage(){
cat <<EOF

  usage: build-wrapper.sh [ARGUMENTS]

    --hail-version  [Number Version]      - OPTIONAL.  If omitted, the current HEAD of master branch will be pulled.
    --vep-version   [Number Version]      - OPTIONAL.  If omitted, VEP will not be included.
    --hail-bucket   [Your S3 Bucket Name] - REQUIRED
    --roda-bucket   [RODA S3 Bucket Name] - REQUIRED
    --vpc-id        [VPC ID]              - REQUIRED
    --subnet-id     [Subnet ID]           - REQUIRED
    --var-file      [Full File Path]      - REQUIRED

    Example:

   build-wrapper.sh --hail-version 0.2.33 \\
                    --vep-version 99 \\
                    --roda-bucket hail-vep-pipeline \\
                    --var-file builds/emr-5.29.0.vars \\
                    --vpc-id vpc-99999999 \\
                    --subnet-id subnet-99999999

EOF
}

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --help)
            usage
            shift
            exit 0
            ;;
        --hail-version)
            HAIL_VERSION="$2"
            shift
            shift
            ;;
        --vep-version)
            VEP_VERSION="$2"
            shift
            shift
            ;;
        --roda-bucket)
            RODA_BUCKET="$2"
            shift
            shift
            ;;
        --var-file)
            CORE_VAR_FILE="$2"
            shift
            shift
            ;;
        --vpc-id)
            VPC_ID="$2"
            shift
            shift
            ;;
        --subnet-id)
            SUBNET_ID="$2"
            shift
            shift
            ;;
    esac
done

HAIL_NAME_VERSION="$HAIL_VERSION"  # Used by AMI name

if [ -z "$HAIL_VERSION" ]; then
    HAIL_VERSION=$(git ls-remote "$REPOSITORY_URL" refs/heads/master | awk '{print $1}')
    echo "HAIL_VERSION env var unset.  Setting to HEAD of master branch: $HAIL_VERSION"
    HAIL_NAME_VERSION=master-$(echo "$HAIL_VERSION" | cut -c1-7)
fi

if [ -z "$VEP_VERSION" ] || [ "$VEP_VERSION" == "" ]; then
    VEP_VERSION="none"
else
    # Add vep version to AMI name if enabled
    HAIL_NAME_VERSION="$HAIL_NAME_VERSION-vep-$VEP_VERSION"
fi

export AWS_MAX_ATTEMPTS=600  # Builds time out with default value
packer build --var hail_name_version="$HAIL_NAME_VERSION" \
             --var hail_version="$HAIL_VERSION" \
             --var vep_version="$VEP_VERSION" \
             --var roda_bucket="$RODA_BUCKET" \
             --var vpc_id="$VPC_ID" \
             --var subnet_id="$SUBNET_ID" \
             --var-file="$CORE_VAR_FILE" \
             amazon-linux.json
