#!/bin/bash

# TO DO
# You might want to Pin your Pools

# Must be run in the directory with the pools (spaces in names in Bash can cause issues)
# tenant_id=$1
# client_id=$2
# client_secret=$3
# subscription_id=$4
# resourceGroup=$5
# workspaceName=$6
accessToken=$1
workspaceUrl=$2


######################################################################################
# Deploy Pools (Add or Update existing)
######################################################################################

replaceSource="./"
replaceDest=""

# Get a list of pool so we know if we need to create or edit
poolList=$(curl -X GET $workspaceUrl/api/2.0/instance-pools/list \
            -H "Authorization:Bearer $accessToken" \
            -H "Content-Type: application/json")

find . -type f -name "*" -print0 | while IFS= read -r -d '' file; do

    
    echo "Processing file: $file"
    filename=${file//$replaceSource/$replaceDest}
    echo "New filename: $filename"


    poolName=$(cat $filename | jq -r .instance_pool_name)
    poolId=$(echo $poolList | jq -r ".instance_pools[] | select(.instance_pool_name == \"$poolName\") | .instance_pool_id")

    echo "poolName: $poolName"
    echo "poolId: $poolId"

    # Test for empty pool id (meaning it does not exist)
    if [ -z "$poolId" ];
    then
       echo "Pool $poolName does not exists in Databricks workspace, Creating..."
       echo "curl $workspaceUrl/api/2.0/instance-pools/create -d $filename"

       curl -X POST $workspaceUrl/api/2.0/instance-pools/create \
            -H "Authorization:Bearer $accessToken" \
            -H "Content-Type: application/json" \
            -d @"$filename" 

    else
       echo "Pool $poolName exists in Databricks workspace, Updating..."
       echo "curl $workspaceUrl/api/2.0/instance-pools/edit -d $filename"

       # need to inject some JSON into the file
       poolDef=$(cat $filename)

       newJSON=$(echo $poolDef | jq ". += {instance_pool_id: \"$poolId\"}")
       echo "New Pool Def"
       echo $newJSON
       echo ""

       curl -X POST $workspaceUrl/api/2.0/instance-pools/edit \
            -H "Authorization:Bearer $accessToken" \
            -H "X-Databricks-Azure-SP-Management-Token: $managementToken" \
            -H "Content-Type: application/json" \
            --data "$newJSON"

    fi      
    echo ""  

done