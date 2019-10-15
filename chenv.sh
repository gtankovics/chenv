#!/bin/bash

# set -x

GCP_CONFIGS=$(gcloud config configurations list --format="value(name)") 

GCP_CURRENT_CONFIG=$(gcloud config configurations list --filter 'is_active=true' --format 'value(name)')

if [ -z "$GCP_CONFIGS" ]; then
    echo "You don't have any gcloud configurations."
else
    if [ -z $1 ]; then
        echo "Please add configuration name."
        echo "Your configurations:"
        echo "$GPC_CONFIGS"
    else
        if [ $1 == "reset" ]; then
            VALID_PROJECT=true
            SET_PROJECT=true
            SELECTED_CONFIG=$GCP_CURRENT_CONFIG
        else
            SELECTED_CONFIG=$1
        fi
        if [ $1 == $GCP_CURRENT_CONFIG ]; then
            echo "$1 is the current config. "
            if [ ! -z $2 ]; then
                if [ $2 == $K8S_CLUSTER_SHORT ]; then
                    echo "$2 is the current cluster."
                else
                    SET_PROJECT=true
                    for CLUSTER in $(gcloud container clusters list --format='value(name)'); do
                        if [ $CLUSTER == $2 ]; then
                            VALID_CLUSTER=true
                        fi
                    done
                fi
            fi
            VALID_PROJECT=true
        else
            for CFG in $GCP_CONFIGS; do
                if [ "$CFG" == $1 ]; then
                    VALID_PROJECT=true
                    SET_PROJECT=true
                    CLEAR_CREDENTIALS=true
                    break
                fi
            done
        fi
        if [ $VALID_PROJECT ]; then 

            fish -c 'set -U fish_detailed_prompt_reset 1'

            if [ $SET_PROJECT ]; then

                if [ $CLEAR_CREDENTIALS ]; then
                    fish -c 'set -eU GOOGLE_APPLICATION_CREDENTIALS'
                fi
                gcloud config configurations activate $SELECTED_CONFIG
                fish -c 'set -xU GOOGLE_CONFIG_NAME (gcloud config configurations list --filter "is_active=true" --format="value(name)")'

                # this is required because variable export through fish is not available later
                GOOGLE_PROJECT=$(gcloud config list --format="value(core.project)")
                fish -c 'set -xU GOOGLE_PROJECT (gcloud config list --format="value(core.project)")'
                GOOGLE_REGION=$(gcloud config list --format="value(compute.region)")
                fish -c 'set -xU GOOGLE_REGION (gcloud config list --format="value(compute.region)")'
                GOOGLE_ZONE=$(gcloud config list --format="value(compute.zone)")
                fish -c 'set -xU GOOGLE_ZONE (gcloud config list --format="value(compute.zone)")'

                CLUSTERS=($(gcloud container clusters list --filter status=RUNNING --format="value(name)"))

                if [ -z "$CLUSTERS" ]; then
                    echo "$GOOGLE_PROJECT project does not contain any running clusters."
                    kubectl config unset current-context
                    fish -c 'set -xU K8S_CLUSTER (kubectl config current-context 2>&1)'
                else
                    if [ "${#CLUSTERS[@]}" -gt 1 ]; then
                        echo "$GOOGLE_PROJECT has multiple clusters."
                        gcloud container clusters list
                    fi
                    CLUSTER=$(gcloud config list --format='value(container.cluster)')
                    if [ -z $CLUSTER ]; then
                        if [ -z $2 ]; then
                            echo "Cluster not specified in configurations. Use the first cluster. ${CLUSTERS[0]}"
                            CLUSTER=${CLUSTERS[0]}
                        else
                            if [ $VALID_CLUSTER ]; then
                                echo "Use $2 for 'kubectl'"
                                CLUSTER=$2
                            else 
                                echo "$GOOGLE_PROJECT does not contain $2 cluster. 'kubectl' context does not change."
                                echo "Valid clusters ${CLUSTERS}"
                                exit
                            fi
                        fi
                    else 
                        echo "Use $CLUSTER from configuration."
                    fi
                    CLUSTER_ZONE=$(gcloud container clusters list --filter="(name=$CLUSTER)" --format='value(location)')
                    if [ "$GOOGLE_ZONE" != "$CLUSTER_ZONE" ]; then
                        gcloud config set compute/zone $CLUSTER_ZONE --quiet
                        gcloud config set compute/region ${CLUSTER_ZONE%??} --quiet
                        fish -c 'set -xU GOOGLE_ZONE '$CLUSTER_ZONE''
                        fish -c 'set -xU GOOGLE_REGION '${CLUSTER_ZONE%??}''
                    fi
                    gcloud container clusters get-credentials $CLUSTER
                    fish -c 'set -xU K8S_CLUSTER (kubectl config current-context)'
                    fish -c 'set -xU K8S_CLUSTER_SHORT (kubectl config current-context | cut -d "_" -f 4)'
                    fish -c 'set -xU K8S_CLUSTER_VERSION (kubectl version --short | awk "/Server/{print\$3}")'
                fi
            fi
        else
            echo -e "You don't have $1 configuration.\nPlease select one configuration from:"
            echo "$GCP_CONFIGS"
        fi
    fi
fi
