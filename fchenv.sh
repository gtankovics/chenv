#!/usr/bin/env fish

# -----------------------------------------------
# This is chenv written in fish shell commands
# -----------------------------------------------

set -q GCLOUD_ENVIRONMENTS_PATH || set -xU GCLOUD_ENVIRONMENTS_PATH "~/.config/gcloud/configurations"

function _showShortHelp
	echo -e "Please add an argument or use 'help' for usage."
end

function _showLongHelp
	echo -e "Usage:\n\tfchenv [options]"
	echo -e "\nOptions:
	help\tShow this help.
	list\tShow list of valid environments.
	\tExtra options:
	\tdetails\t\t\tList environments with details
	\tprod or production\tList 'production' environment(s)
	\tedu or educational\tList 'educational' environment(s)
	\tpilot\t\t\tList 'pilot' environment(s)
	\tqa\t\t\tList 'qa' environment(s)
	\ttest\t\t\tList 'test' environments
	set\tSet the selected environment for 'gcloud' and 'kubectl'.
	reload\tReload the current environment.
	clear\tClear the variables and unset 'kubectl' context. 
	"
end

function _showReloadHelp
	echo -e "\nUse 'fchenv reload' to reload it."
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
	for line in (gcloud config configurations list --format='table(name,is_active:label=ACTIVE,properties.core.project,properties.compute.zone,properties.compute.region,properties.container.cluster)')
		if string match -q -r ".*True.*" "$line"
			set_color -b yellow
			set_color -o black
			echo $line
			set_color -b normal
			set_color normal
		else
			echo $line
		end
	end
end

function _setActiveDomainSuffix
	set -l _GOOGLE_PROJECT $argv[1]
	switch "$_GOOGLE_PROJECT" 
		case "*production*" -o "*educational*" -o "*customer*"
			set -xU ACTIVE_DOMAIN_SUFFIX $PRODUCTION_DOMAIN_SUFFIX
		case "*pilot*"
			set -xU ACTIVE_DOMAIN_SUFFIX $PILOT_DOMAIN_SUFFIX
		case \*
			set -xU ACTIVE_DOMAIN_SUFFIX $DEVELOPMENT_DOMAIN_SUFFIX
	end
	echo "[r53] updated to [$ACTIVE_DOMAIN_SUFFIX]"
end

function _setK8sContext
	set -l _cluster $argv[1]
	gcloud container clusters get-credentials $_cluster
    set -xU K8S_CLUSTER (kubectl config current-context)
	set -xU K8S_CLUSTER_SHORT (echo $K8S_CLUSTER | cut -d "_" -f 4)
    set -xU K8S_CLUSTER_VERSION (kubectl version --short | awk "/Server/{print\$3}")
end

function _unSetK8sContext
	kubectl config unset current-context
	_clearK8sVariables
end

function _setDefaultGcloudProfile
	gcloud config configurations activate default
end

function _clearGoogleVariables
	set -l _showLogs $argv[1]
	for variable in (set -n | grep "GOOGLE")
		if test -n "$_showLogs"
			echo -e "$variable\t\tcleared."
		else
			set -e $variable
		end
	end
end

function _clearK8sVariables
	set -l _showLogs $argv[1]
	for variable in (set -n | grep "K8S")
		if test -n "$_showLogs"
			echo -e "$variable\t\tcleared."
		end
		set -e $variable
	end
end

function _clearActiveDomainSuffix
	set -l _showLogs $argv[1]
	if test -n "$ACTIVE_DOMAIN_SUFFIX"
		if test -n "$_showLogs"
			echo -e "ACTIVE_DOMAIN_SUFFIX\t\tcleared."
		end
		set -e ACTIVE_DOMAIN_SUFFIX
	end
end

function _clearVariables
	set -l _showLogs $argv[1]
	if test -n "$_showLogs"
		_clearGoogleVariables true
		_clearK8sVariables true
		_clearActiveDomainSuffix true
	else
		_clearGoogleVariables
		_clearK8sVariables
		_clearActiveDomainSuffix
	end
end

function _changeEnvironment
	_clearVariables
	set -l _environment $argv[1]
	gcloud config configurations activate $_environment
	set -xU GOOGLE_CONFIG $_environment
	gcloud config list --format='value[separator=" "](core.project,compute.region,compute.zone,container.cluster)' | read _GOOGLE_PROJECT _GOOGLE_REGION _GOOGLE_ZONE _K8S_CLUSTER_SHORT
	set -xU GOOGLE_PROJECT $_GOOGLE_PROJECT
	_setActiveDomainSuffix $_GOOGLE_PROJECT
	set -xU GOOGLE_REGION $_GOOGLE_REGION
	set -xU GOOGLE_ZONE $_GOOGLE_ZONE
	if test -z "$_K8S_CLUSTER_SHORT"
		echo "[$GOOGLE_CONFIG] does not have container/cluster property. Searching clusters from cloud."
		set _K8S_CLUSTER_SHORT (gcloud container clusters list --format='value(name)' --limit 1)
		if test -n "$_K8S_CLUSTER_SHORT"
			echo "[$_K8S_CLUSTER_SHORT] use for 'kubectl'"
		end
	else
		echo "[$GOOGLE_CONFIG] has cluster property [$_K8S_CLUSTER_SHORT] use it for 'kubectl'"
	end
	if test -n "$_K8S_CLUSTER_SHORT"
		set -xU K8S_CLUSTER_SHORT $_K8S_CLUSTER_SHORT
		_setK8sContext $K8S_CLUSTER_SHORT
	else
		echo "There's no cluster in [$GOOGLE_PROJECT] project in [$GOOGLE_REGION] region."
		_clearK8sVariables true
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
					case "prod" -o "production"
						_showList "production"
					case "edu" -o "educational"
						_showList "educational"
					case "pilot"
						_showList "pilot"
					case "qa"
						_showList "qa"
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
					case $GOOGLE_CONFIG
						echo -e "[$_selectedEnvironment] is the current environment."
						_showReloadHelp
					case contains $_ENVIRONMENTS
						echo "[$_selectedEnvironment] is valid config. Use it."
						_changeEnvironment $_selectedEnvironment
					case \*
						echo "[$_selectedEnvironment] is not a valid environment."
				end
			else
				echo "Select config from:"
				ls $GCLOUD_ENVIRONMENTS_PATH | cut -d "_" -f 2
			end
		case "reload"
			_changeEnvironment $GOOGLE_CONFIG
		case "clear"
			_clearVariables true
			echo "Variables cleared."
			_unSetK8sContext
			_setDefaultGcloudProfile
		case \*
			echo "Unknown arugment(s). $argv"
	end
else
	_showLongHelp
end