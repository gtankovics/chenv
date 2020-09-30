#!/usr/bin/env fish

# -----------------------------------------------
# This is chenv written in fish shell commands
# and uses CLOUDSDK_ variables
# -----------------------------------------------

function _showShortHelp
	echo -e "Please add an argument or use 'help' for usage."
end

function _showLongHelp
	echo -e "Usage:\n\tchenv [options]"
	echo -e "\nValid options:
	-h or --help\tShow this help.
	-l or --list\tShow list of valid environments.
	\t\tUse with -d or --details for environments' details.
	-e or --env\tSet the selected environment for 'gcloud' and 'kubectl'.
	-r or --reload\tReload the current environment.
	-c or --clear\tClear the CLOUDSDK_* variables and unset 'kubectl' context. 
	"
end

function _showList
	if test -n "$argv[1]"
		set -l filter "name:$argv[1]"
		gcloud config configurations list --format='value(name)' --filter=$filter
	else
		gcloud config configurations list --format='value(name)'
	end
end

function _showListWithDetails
	gcloud config configurations list
end

function _setActiveDomainSuffix
	switch "$CLOUDSDK_PROJECT" 
		case "*production*" -o "*educational*" -o "*customer*"
			set -xU ACTIVE_DOMAIN_SUFFIX $PRODUCTION_DOMAIN_SUFFIX
		case "*pilot*"
			set -xU ACTIVE_DOMAIN_SUFFIX $PILOT_DOMAIN_SUFFIX
		case \*
			set -xU ACTIVE_DOMAIN_SUFFIX $DEVELOPMENT_DOMAIN_SUFFIX
	end
end

function _setK8sContext
	set -l _cluster $argv[1]
	gcloud container clusters get-credentials $_cluster
end

function _unSetK8sContext
	kubectl config unset current-context
	set -e CLOUDSDK_CONTAINER_CLUSTER
end

function _clearCloudsdkVariables
	set -l showLogs $argv[1]
	for variable in (set -n | grep "CLOUDSDK_\|GOOGLE_APPLICATION_CREDENTIALS")
		if test -n "$showLogs"
			echo -e "$variable\t\tcleared."
		end
		set -e $variable
	end
end

function _changeEnvironment
	_clearCloudsdkVariables
	set -l _environment $argv[1]
	gcloud config configurations activate $_environment
	set -xU CLOUDSDK_ACTIVE_CONFIG $_environment
	gcloud config list --format='value[separator=" "](core.project,compute.region,compute.zone,container.cluster)' | read _CLOUDSDK_PROJECT _CLOUDSDK_COMPUTE_REGION _CLOUDSDK_COMPUTE_ZONE _CLOUDSDK_CONTAINER_CLUSTER
	# echo "'$_CLOUDSDK_PROJECT' '$_CLOUDSDK_COMPUTE_REGION' '$_CLOUDSDK_COMPUTE_ZONE' '$_CLOUDSDK_CONTAINER_CLUSTER'"
	set -xU CLOUDSDK_PROJECT $_CLOUDSDK_PROJECT
	_setActiveDomainSuffix
	set -xU CLOUDSDK_COMPUTE_REGION $_CLOUDSDK_COMPUTE_REGION
	set -xU CLOUDSDK_COMPUTE_ZONE $_CLOUDSDK_COMPUTE_ZONE
	if test -z "$_CLOUDSDK_CONTAINER_CLUSTER"
		echo "[$CLOUDSDK_ACTIVE_CONFIG] does not have container/cluster property. Searching clusters from cloud."
		set _CLOUDSDK_CONTAINER_CLUSTER (gcloud container clusters list --format='value(name)' --limit 1)
		if test -n "$_CLOUDSDK_CONTAINER_CLUSTER"
			echo "[$_CLOUDSDK_CONTAINER_CLUSTER] use for 'kubectl'"
		end
	else
		echo "[$CLOUDSDK_ACTIVE_CONFIG] has cluster property [$_CLOUDSDK_CONTAINER_CLUSTER] use it for 'kubectl'"
	end
	if test -n "$_CLOUDSDK_CONTAINER_CLUSTER"
		set -xU CLOUDSDK_CONTAINER_CLUSTER $_CLOUDSDK_CONTAINER_CLUSTER
		_setK8sContext $CLOUDSDK_CONTAINER_CLUSTER
		# reset fish_prompt
	else
		echo "There's no cluster in [$CLOUDSDK_PROJECT] project."
		_unSetK8sContext
	end
end

if test -n "$argv"
	switch $argv[1]
		case "help"
			_showLongHelp
		case "list"
			if test -n "$argv[2]"
				switch $argv[2]
					case "details"
						_showListWithDetails
					case "production"
						_showList "production"
					case "educational"
						_showList "educational"
					case "test"
						_showList "test"
					case \*
						echo "Unknown argument(s). $argv[2]"
				end
			else
				_showList
			end
		case "set"
			if test -n "$argv[2]"
				set -l _selectedEnvironment $argv[2]
				set -l _ENVIRONMENTS (gcloud config configurations list --format='value(name)')
				switch $_selectedEnvironment
					case $CLOUDSDK_ACTIVE_CONFIG
						echo -e "[$_selectedEnvironment] is the current environment.\nUse\n\t'chenv -r'\nor\n\t'chenv --reload'\nto reload it."
					case contains $_ENVIRONMENTS
						echo "[$_selectedEnvironment] is valid config. Use it."
						_changeEnvironment $_selectedEnvironment
					case \*
						echo "[$_selectedEnvironment] is not a valid environment."
				end
			else
				echo "Please add environment name."
			end
		case "reload"
			_changeEnvironment $CLOUDSDK_ACTIVE_CONFIG
		case "clear"
			_clearCloudsdkVariables true
			_unSetK8sContext
		case \*
			echo "Unknown arugment(s). $argv"
	end
else
	_showShortHelp
end