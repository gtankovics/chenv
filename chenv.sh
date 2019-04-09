#!/bin/bash

# set -x

GCP_CONFIGS=$(gcloud config configurations list --format="value(name)") 
# GCP_CONFIGS_LEN=$(gcloud config configurations list --format="value(name)" | wc -l) 

GCP_CURRENT_CONFIG=$(gcloud config configurations list --filter 'is_active=true' --format 'value(name)')

if [ -z "$GCP_CONFIGS" ]; then
    echo "You don't have any Google Project"
else
    if [ -z $1 ]; then

        echo "Please add configuration name."
        echo "Your configurations:"
        echo "$GPC_CONFIGS"

    else

        if [ $1 == "reset" ]; then
            SET_PROJECT=true
            SELECTED_CONFIG=$GCP_CURRENT_CONFIG
        else
            SELECTED_CONFIG=$1
        fi
        if [ $1 == $GCP_CURRENT_CONFIG ] && [ "$2" != "reset" ]; then
            echo "$1 is the current config."
        else
            for CFG in $GCP_CONFIGS; do
                if [ "$CFG" == $1 ]; then
                    SET_PROJECT=true
                    break
                fi
            done
        fi
        if [ "$SET_PROJECT" ]; then

                fish -c 'set -eU GOOGLE_APPLICATION_CREDENTIALS'
                gcloud config configurations activate $SELECTED_CONFIG
                fish -c 'set -xU GOOGLE_PROJECT (gcloud config configurations list --filter "is_active=true" --format="value(properties.core.project)")'
                fish -c 'set -xU GOOGLE_CONFIG_NAME (gcloud config configurations list --filter "is_active=true" --format="value(name)")'
                CLUSTER=$(gcloud container clusters list --filter status=RUNNING --format="value(name)" --limit 1)

                # TODO handle multiple clusters

                if [ -z "$CLUSTER" ]; then
                    echo "$1 project does not contain any running clusters."
                    kubectl config use-context n/a
                    fish -c 'set -xU K8S_CLUSTER (kubectl config current-context)'
                    fish -c 'set -xU K8S_CLUSTER_VERSION "n/a"'
                else
                    gcloud container clusters get-credentials $CLUSTER
                    fish -c 'set -xU K8S_CLUSTER (kubectl config current-context)'
                    fish -c 'set -xU K8S_CLUSTER_VERSION (kubectl version --short | awk "/Server/{print\$3}")'
                fi
            else
                echo -e "You don't have $1 configuration.\nPlease select one configuration from:"
                echo "$GCP_CONFIGS"
        fi
    fi
fi
