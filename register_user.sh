#!/bin/bash

CLUSTER=$1
SERVICE=$2
CONTAINER=$3
USERNAME=$4
DOMAIN=$5
PASSWORD=$6

TASK=$(aws ecs list-tasks --cluster $CLUSTER --service $SERVICE | jq -r '.taskArns[0]')

aws ecs execute-command --cluster $CLUSTER --container $CONTAINER --task $TASK --interactive --command "/home/ejabberd/bin/ejabberdctl register $USERNAME $DOMAIN $PASSWORD"
