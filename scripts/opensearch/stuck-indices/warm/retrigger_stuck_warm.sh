#!/bin/bash

set -eu

export USE_SESSION_TOKEN=$1
touch missing_size
rm missing_size

get_cold_size () {
    OBJ=$(cat $1 | jq '.')
    INDEX_NAME=$(echo $OBJ | jq -r '.index')
    CAUSE=$(echo $OBJ | jq -r '.cause')

    if [[ $CAUSE =~ "because another index with the same name already exists in cold storage" ]]; then
        COLD_INDEX_SIZE=$(jq --arg INDEX_NAME "$INDEX_NAME" '.indices[] | select( .index == $INDEX_NAME) | .size' collated_cold_indices)
        WARM_INDEX_SIZE=$(grep $INDEX_NAME all_warm_indices | awk '{ print $2 }')

        echo "$COLD_INDEX_SIZE warm $WARM_INDEX_SIZE"


        if [ -z "$COLD_INDEX_SIZE" ] || [ -z "$WARM_INDEX_SIZE" ]; then
            echo "Either Cold or Warm is missing"
            echo "$INDEX_NAME cold: $COLD_INDEX_SIZE warm: $WARM_INDEX_SIZE" >> missing_size
            if [ -z COLD_INDEX_SIZE ]; then
                curl -X DELETE -L --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/_cold/$INDEX_NAME
            fi
            if [ -z $WARM_INDEX_SIZE ]; then
                curl -X DELETE -L --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/$INDEX_NAME
            fi
            return
        fi

        if ((COLD_INDEX_SIZE < WARM_INDEX_SIZE)); then

            echo "Cold index is tiny $COLD_INDEX_SIZE $WARM_INDEX_SIZE"

            echo "deleting and retriggering tiny cold index $INDEX_NAME $CAUSE"

            curl -X DELETE -L --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/_cold/$INDEX_NAME

            sleep 0.2

            curl -X POST -L --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/_plugins/_ism/retry/$INDEX_NAME

        else
            echo "warm index is tiny $WARM_INDEX_SIZE $COLD_INDEX_SIZE $INDEX_NAME $CAUSE"
            curl -X DELETE -L --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/$INDEX_NAME

            sleep 0.2

            curl -X POST -L --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/_plugins/_ism/retry/$INDEX_NAME
        fi
    fi

}

curl -L --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_cat/indices/_warm?v" | awk '{ print $3 " " $7 }' > all_warm_indices

export -f get_cold_size

parallel -a compacted_failed_cold --recend '}\n' --line-buffer --pipe-part --will-cite --block 30 "get_cold_size {}"

exit 0


