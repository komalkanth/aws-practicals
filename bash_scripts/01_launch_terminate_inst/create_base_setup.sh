#!/usr/bin/bash

REGION="us-east-1"
MYAWSPROFILE="iamadmin-prod"
VPC_NAME="my-base-vpc"
SUBNET_NAME="my-base-subnet"
IGW_NAME="my-base-igw"


# CREATING A FUNCTION THAT IS CHECKING FOR EXISTING VPCS WITH THE NAME "my-base-vpc"
check_my_base_vpc () {
  aws ec2 describe-vpcs --region ${REGION} --profile ${MYAWSPROFILE} --filters Name=tag:Name,Values=${VPC_NAME} --query 'Vpcs[*].VpcId | [0]' --output text
}
BASE_VPC_ID=$(check_my_base_vpc)


# USING ABOVE FUNCTION TO CHECK VPC EXISTS ALREADY.
# CREATE IF IT DOESN'T EXIST
# EXIT THE COMMAND WITH EXIT CODE 1
sleep 1
echo "Checking if a VPC with name '${VPC_NAME}' already exists in ${REGION}..."
if [[ $BASE_VPC_ID == None ]]; then
  echo "Creating Base VPC in ${REGION}..."
  aws ec2 create-vpc \
      --cidr-block 10.99.0.0/16 \
      --region ${REGION} --profile ${MYAWSPROFILE} \
      --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${VPC_NAME}}]" > /dev/null #to hide the output from the shell
  if [[ "$?" == 0 ]]; then
    BASE_VPC_ID=$(check_my_base_vpc)
    echo "Base VPC '${VPC_NAME}' in ${REGION} has been created with VPC ID: ${BASE_VPC_ID}"
  else
    echo "VPC Creation has a problem"
  fi
else
  echo "A VPC with this name already exists"
  # exit 1
fi


# CREATING A FUNCTION THAT IS CHECKING FOR EXISTING VPCS WITH THE NAME "my-base-subnet"
sleep 1
check_my_base_subnet () {
  aws ec2 describe-subnets --region ${REGION} --profile ${MYAWSPROFILE} --filters Name=tag:Name,Values=${SUBNET_NAME} --query 'Subnets[*].SubnetId | [0]' --output text
}
BASE_SUBNET_ID=$(check_my_base_subnet)


# CREATING A BASE PUBLIC SUBNET
sleep 2
echo "Checking if a Subnet with name '${SUBNET_NAME}' already exists in ${REGION}..."
if [[ $BASE_SUBNET_ID == None ]]; then
  echo "Creating Base Subnet in ${REGION} in VPC '${VPC_NAME}'..."
  BASE_VPC_ID=$(check_my_base_vpc)
  aws ec2 create-subnet \
    --vpc-id ${BASE_VPC_ID} \
    --cidr-block 10.99.1.0/24 \
    --region ${REGION} --profile ${MYAWSPROFILE} \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${SUBNET_NAME}}]" > /dev/null #to hide the output from the shell
  if [[ "$?" == 0 ]]; then
    BASE_SUBNET_ID=$(check_my_base_subnet)
    echo "Base Subnet '${SUBNET_NAME}' in ${REGION} has been created with VPC ID: ${BASE_VPC_ID}"
  else
    echo "Subnet Creation has a problem"
  fi
else
  echo "A Subnet with this name already exists"
  # exit 1
fi


# CREATING A FUNCTION THAT IS CHECKING FOR EXISTING IGW WITH THE NAME "my-base-igw"
sleep 1
check_my_base_igw () {
  aws ec2 describe-internet-gateways --region ${REGION} --profile ${MYAWSPROFILE} --filters Name=tag:Name,Values=${IGW_NAME} --query 'InternetGateways[*].InternetGatewayId | [0]' --output text
}
BASE_IGW_ID=$(check_my_base_igw)


# CREATING A BASE IGW AND ASSOCIATE WITH VPC
sleep 2
echo "Checking if a IGW with name '${IGW_NAME}' already exists in ${REGION}..."
if [[ $BASE_IGW_ID == None ]]; then
  echo "Creating Base IGW in ${REGION} in VPC '${VPC_NAME}'..."
  BASE_VPC_ID=$(check_my_base_vpc)
  aws ec2 create-internet-gateway \
    --region ${REGION} --profile ${MYAWSPROFILE} \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${IGW_NAME}}]" > /dev/null #to hide the output from the shell
  if [[ "$?" == 0 ]]; then
    BASE_IGW_ID=$(check_my_base_igw)
    echo "Base IGW '${IGW_NAME}' in ${REGION} has been created with VPC ID: ${BASE_IGW_ID}"
    echo "Attaching the Base IGW to the Base VPC ...."
    aws ec2 attach-internet-gateway \
      --internet-gateway-id ${BASE_IGW_ID} \
      --region ${REGION} --profile ${MYAWSPROFILE} \
      --vpc-id ${BASE_VPC_ID}
  else
    echo "IGW Creation has a problem"
  fi
else
  echo "An IGW with this name already exists"
  echo "Attaching the Base IGW to the Base VPC ...."
  BASE_VPC_ID=$(check_my_base_vpc)
  BASE_IGW_ID=$(check_my_base_igw)
  aws ec2 attach-internet-gateway \
    --internet-gateway-id ${BASE_IGW_ID} \
    --region ${REGION} --profile ${MYAWSPROFILE} \
    --vpc-id ${BASE_VPC_ID}
  # exit 1
fi
