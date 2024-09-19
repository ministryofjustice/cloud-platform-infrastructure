#!/usr/bin/env bash

function printHelp {
  echo "Calculate possible /28 prefixes that can be used within a subnet depedning on the subnet IPs and how many contiguous /28 blocks available"
  echo "-h,--help print this help."
  echo "--subnet-id Specify the subnet id to calculate prefixes value."
  echo "--region Use this flag if the subnet not in us-east-1 region"

  echo "###########OUTPUT"
  echo "SUBNET CIDR: will print the subnet CIDR"
  echo "Network Interfaces: how many interfaces in use within the subnet"
  echo "Total IPs: Total IPs depending on the subnet net mask"
  echo "Allocated IPs: This Include all reserved IPs (ENIs primary/secondary IPs, IPs within the Prefixes in use, reserved IPs by AWS 5 IPs https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html )"
  echo "Available IPs: Available IPs that still can use them"
  echo "MAX /28 prefixes: Maximun prefixes the subnet can afford depedning on the subnet total IPs"
  echo "Possible /28 prefixes: How many prefixes can be used within the subnet after removing all IPs in use and calculating contiguous /28 blocks available"
  echo "Prefixes In use: Current prefixes in use"
  echo "Available Prefixes: Available prefixes that can use them depedning on how many possible /28 prefixes"
  echo ''
  echo "Note: Above values will be changed by time as it's calulating the values depending on the current available IPs so if IPs assigned/removed from ENIs or new ENIs created/deleted this will affect on possiple prefixes that can be used"

}


REGION=eu-west-2

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in

    --subnet-id)
      SUBNET_ID=$2
      shift
      shift
      ;;
    --region)
      REGION=$2
      shift
      shift
      ;;  
    -h | --help)
      printHelp
      exit 1
      ;;
  esac
done



SUBNET_ID="${SUBNET_ID:-}"

if [ -z "$SUBNET_ID" ]; then
  echo "You must specify a --subnet-id to calculate max prefixes value."
  exit 1
fi



function subnetDetails {

  ###### Get Subnet CIDR

  SUBNET_CIDR=$(aws --region $REGION ec2 describe-subnets --subnet-ids "${SUBNET_ID}" --query 'Subnets[0].CidrBlock' | jq -r)


  # Get the subnet mask and CIDR 

  subnet_mask=$(echo $SUBNET_CIDR | cut -d/ -f2) 

  CIDR=$(echo $SUBNET_CIDR | cut -d/ -f1) 

  # Calculate the number of host bits
  (( host_bits= 32-$subnet_mask ))

  # # Use 2 to the power of host bits to get the number of IPs
  # there are 5 IPs reserved by default in subnet
  # https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html 

  # (( TOTAL_IPS= (2**$host_bits)-5))

  (( TOTAL_IPS= (2**$host_bits)))

  # SPLIT CIDR DIGITS

  IFS='.' read -r -a CIDR_LIST <<< "$CIDR"

  CIDR_FIRST_DIGIT=${CIDR_LIST[0]}

  CIDR_SECOND_DIGIT=${CIDR_LIST[1]}

  CIDR_THIRD_DIGIT=${CIDR_LIST[2]}

  CIDR_LAST_DIGIT=${CIDR_LIST[3]}


}

function getIPsAndPrefixes {


    ###### List subnet ENIs

    DESCRIBE_NETWORK_INTERFACES=$(aws --region $REGION  ec2 describe-network-interfaces --filters "Name=subnet-id,Values=${SUBNET_ID}")

    INTERFACES_IN_USE=0
    IPS_IN_USE=()
    PREFIXES_IN_USE=()
    IPS_PER_PREFIX=16


    # Get interface details 

    for INTERFACE in $(echo "${DESCRIBE_NETWORK_INTERFACES}" | jq -r '.NetworkInterfaces' | jq -r '.[] | @base64'); 
    do

      INTERFACE=$(echo $INTERFACE | base64 --decode)


      ((INTERFACES_IN_USE++))


      # Get All IPs in use
      ALL_IPS=$(echo $INTERFACE | jq -r '.PrivateIpAddresses')

      if [[ $(echo $ALL_IPS | jq 'length' ) -gt 0 ]]
      then

          for PRIVATE_IP in $(echo $ALL_IPS | jq -c '.[]')
          do
              IPS_IN_USE+=($(echo $PRIVATE_IP | jq -r '.PrivateIpAddress') )
          done

      fi

      # Get All Prefixes in use
      ALL_PREFIXES=$(echo $INTERFACE | jq -r '.Ipv4Prefixes')

      if [[ $(echo $ALL_PREFIXES | jq 'length' ) -gt 0 ]]
      then

          for PREFIX in $(echo $ALL_PREFIXES | jq -c '.[]')
          do
              PREFIXES_IN_USE+=($(echo $PREFIX | jq -r '.Ipv4Prefix') )
          done
          
      fi

    done

    ###### Prefixes in use
    CURRENT_PREFIXES_NUM=${#PREFIXES_IN_USE[@]}

    PRIVATE_IPS_NUM=${#IPS_IN_USE[@]}

    # Allocated IPs
    ((ALLOCATED_IPS=($CURRENT_PREFIXES_NUM*$IPS_PER_PREFIX)+$PRIVATE_IPS_NUM+5))


    # Max Prefixes
    MAX_PREFIXES_NUM=`expr $TOTAL_IPS / $IPS_PER_PREFIX`


}

function availablePrefixes {


    # Get All /28 prefixes in subnet cidr
    POSSIBLE_PREFIXES=()
    AVAILABLE_PREFIXES=()
    BROKEN_PREFIXES_NUM=0

    # Skip 2 prefixes due to there are 5 reserved IPs by AWS so they will miss first and last prefixes
    ((MAX_PREFIXES_NUM=$MAX_PREFIXES_NUM-2))

    for i in $(seq 1 $MAX_PREFIXES_NUM)
    do

        ((CIDR_LAST_DIGIT+=$IPS_PER_PREFIX))

        # Switch to next CIDR block
        if [ ${i} -lt ${MAX_PREFIXES_NUM} -a  ${CIDR_LAST_DIGIT} -gt 255 ] 
        then

          ((CIDR_THIRD_DIGIT+=1))
          CIDR_LAST_DIGIT=0

        fi

        POSSIBLE_PREFIX="$CIDR_FIRST_DIGIT.$CIDR_SECOND_DIGIT.$CIDR_THIRD_DIGIT.$CIDR_LAST_DIGIT"
        POSSIBLE_PREFIXES+=($POSSIBLE_PREFIX)


        # Get only available prefixes that not in use yet
        IN_USE=false

        if [[ ${#PREFIXES_IN_USE[@]} -gt 0 ]]
        then
          
           

            for PREFIX_IN_USE in "${PREFIXES_IN_USE[@]}"
            do
                if [[ $PREFIX_IN_USE == "$POSSIBLE_PREFIX/28" ]] ; then
                    IN_USE=true
                    break
                fi
            done

        fi


        if [[ $IN_USE == false ]]
        then  
   
            ((LOOP_END=$CIDR_LAST_DIGIT+$IPS_PER_PREFIX-1))

              IS_AVAILABLE=true

              # check if any of the prefix IPs are in use, if so then we can not count it as available prefix
              for IP in $(seq $CIDR_LAST_DIGIT $LOOP_END)
              do

                  FULL_IP="$CIDR_FIRST_DIGIT.$CIDR_SECOND_DIGIT.$CIDR_THIRD_DIGIT.$IP"

                  if [[ ${#IPS_IN_USE[@]} -gt 0 ]]
                  then

                    for IP_IN_USE in "${IPS_IN_USE[@]}"
                    do
                        if [ $IP_IN_USE == $FULL_IP ] ; then
                            IS_AVAILABLE=false
                            ((BROKEN_PREFIXES_NUM++))
                            break
                        fi
                    done

                  fi

              done

              if  $IS_AVAILABLE 
              then
                    AVAILABLE_PREFIXES+=($POSSIBLE_PREFIX)
              fi

        fi

   
    done

    ((FREE_IPS=$TOTAL_IPS-$ALLOCATED_IPS))

}

function print {

    echo "SUBNET CIDR": $SUBNET_CIDR

    echo "Network Interfaces: " $INTERFACES_IN_USE

    echo "Total IPs: " $TOTAL_IPS

    echo "Allocated IPs: " $ALLOCATED_IPS

    echo "Available IPs: " $FREE_IPS

    echo "MAX /28 prefixes: " $((($MAX_PREFIXES_NUM+2)))

    echo "Possible /28 prefixes: " $((($MAX_PREFIXES_NUM-$BROKEN_PREFIXES_NUM)))

    echo "Prefixes In use: " $CURRENT_PREFIXES_NUM

    echo "Available Prefixes: " ${#AVAILABLE_PREFIXES[@]}

}

subnetDetails

getIPsAndPrefixes

availablePrefixes

print
