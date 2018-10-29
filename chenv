#!/bin/bash

# set -ex

GPC_CONFIGS=$(gcloud config configurations list | awk '{print$1}' | sed -n '2,$p')

GCP=$(gcloud config configurations list | awk '/True/{print$4}')

if [ -z "$GCP" ]; then
    echo "You don't have any Google Project"
else
    if [ -z $1 ]; then

        echo "Please add configuration name."
        echo "Your configurations:"
        echo "$GPC_CONFIGS"

    else

        for CFG in $GPC_CONFIGS; do
            if [ "$CFG" == $1 ]; then
                SET_PROJECT=1
            fi
        done

        # echo "Set Project: $SET_PROJECT"

        if [ "$SET_PROJECT" == 1 ]; then
                fish -c 'set -eU GOOGLE_APPLICATION_CREDENTIALS'
                gcloud config configurations activate $1
                # export GOOGLE_PROJECT="$(gcloud config configurations list --filter 'is_active=true' --format 'value(properties.core.project)')"
                CLUSTER=$(gcloud container clusters list --filter status=RUNNING --format='value(name)')
                if [ -z "$CLUSTER" ]; then
                    echo "$1 project does not contain any running clusters."
                    kubectl config use-context empty
                else
                    gcloud container clusters get-credentials $CLUSTER
                    # export KUBERNETES_CLUSTER="$CLUSTER"
                fi
            else

                echo -e "You don't have $1 configuration.\nPlease select one configuration from:"
                echo "$GPC_CONFIGS"

        fi

    fi
fi
