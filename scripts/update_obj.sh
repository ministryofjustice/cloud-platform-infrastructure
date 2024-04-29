#!/bin/bash

set -eu

NS_OBJ=$1

OBJ_UID=$(echo $NS_OBJ | jq -r '.metadata.uid')
NS=$(echo $NS_OBJ | jq -r '.metadata.namespace')

SOURCE_CODE=$(jq -r '.metadata.annotations."cloud-platform.justice.gov.uk/source-code"' "$NS.json")
OWNER=$(jq -r '.metadata.annotations."cloud-platform.justice.gov.uk/owner"' "$NS.json")
TEAM_NAME=$(jq -r '.metadata.annotations."cloud-platform.justice.gov.uk/team-name"' "$NS.json")

# add the new values to the object
UPDATED_SOURCE=$(echo $NS_OBJ | jq --arg SOURCE_CODE "$SOURCE_CODE" '.metadata += {"cloud-platform.justice.gov.uk/source-code": $SOURCE_CODE }')

UPDATED_OWNER=$(echo $UPDATED_SOURCE | jq --arg OWNER "$OWNER" '.metadata += {"cloud-platform.justice.gov.uk/owner": $OWNER }')

UPDATED_OBJ=$(echo $UPDATED_OWNER | jq --arg TEAM_NAME "$TEAM_NAME" '.metadata += {"cloud-platform.justice.gov.uk/team-name": $TEAM_NAME }')

echo $UPDATED_OBJ

exit 0

