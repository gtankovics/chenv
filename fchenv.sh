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
	\tteam\t\t\tList 'team' environment(s)
	\ttest\t\t\tList 'test' environment(s)
	\n\t\tList parameter understand combination of environments like 'prod,edu'. Separate the environments list with comma (,).\n
	set\tSet the selected environment for 'gcloud' and 'kubectl'.
	reload\tReload the current environment.
	clear\tClear the variables and unset 'kubectl' context and set `default` 'gcloud' profile.
	"
end

function _showReloadHelp
	echo -e "\nUse 'fchenv reload' to reload it."
end

function _showList
	if test -n "$argv[1]"
		set -l filter "name~$argv[1]"
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
    set -xU K8S_CLUSTER_VERSION (kubectl version --output json | jq -r .serverVersion.gitVersion)
end

function _unSetK8sContext
	kubectl config unset current-context
	_clearK8sVariables
end

function _stopK8sProxy
	set -l proxyPid (ps aux | grep "kubectl proxy" | grep -v grep | awk '{print $2}')
	if test -n "$proxyPid"
		kill -9 $proxyPid
		# echo "kubectl proxy stopped. [$proxyPid]"
	end
end

function _startK8sProxy
	kubectl proxy 2 1 > /dev/null &
end

function _restartK8sProxy
	_stopK8sProxy
	_startK8sProxy
	echo "kubectl proxy (re)started."
end

function _setDefaultGcloudProfile
	gcloud config configurations activate default
end

function _clearGoogleVariables
	set -l _showLogs $argv[1]
	for variable in (set -n | grep "^GOOGLE")
		if test -n "$_showLogs"
			echo -e "$variable\t\tcleared."
		end
		set -e $variable
	end
end

function _clearK8sVariables
	set -l _showLogs $argv[1]
	for variable in (set -n | grep "^K8S")
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
	if string match -q -r "[a-z]+-[a-z]+[0-9]-[a-z]{1}" "$_GOOGLE_ZONE"
		set -xU GOOGLE_ZONE $_GOOGLE_ZONE
	else
		set _K8S_CLUSTER_SHORT $_GOOGLE_ZONE 
	end
	if test -z "$_K8S_CLUSTER_SHORT"
		echo "[$GOOGLE_CONFIG] does not have container/cluster property. Searching clusters from cloud."
		set _K8S_CLUSTER_SHORT (gcloud container clusters list --format='value(name)' --limit 1)
		if test -n "$_K8S_CLUSTER_SHORT"
			echo "[$_K8S_CLUSTER_SHORT] use for 'kubectl'"
		end
	else
		echo "[$GOOGLE_CONFIG] has cluster property [$_K8S_CLUSTER_SHORT]."
		set -l _K8S_CLUSTER_STATUS (gcloud container clusters describe $_K8S_CLUSTER_SHORT --format='value(status)')
		switch "$_K8S_CLUSTER_STATUS"
			case "RUNNING" -o "CREATING" -o "UPDATING"
			case "DELETING"
				echo "[$_K8S_CLUSTER_SHORT] is being deleted."
			case "UNKNOWN" -o \*
				echo "Cluster is unknown state. [$_K8S_CLUSTER_STATUS]"
		end
	end
	if test -n "$_K8S_CLUSTER_SHORT"
		set -xU K8S_CLUSTER_SHORT $_K8S_CLUSTER_SHORT
		_setK8sContext $K8S_CLUSTER_SHORT
		_restartK8sProxy
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
				if string match -q "details" "$argv[2]"
						_showListWithDetails
				else
					set -l environmentArguments (string split , $argv[2])
					set -l environments
					for env in $environmentArguments
						switch $env
							case "prod" -o "production"
								set environments $environments (_showList "production")
							case "edu" -o "educational"
								set environments $environments (_showList "educational")
							case "pilot"
								set environments $environments (_showList "pilot")
							case "team"
								set environments $environments (_showList "team")
							case "test"
								set environments $environments (_showList "test")
						end
					end
					if test -n "$environments"
						echo $environments | tr ' ' '\n'
					else
						echo "Unknown argument(s). $argv[2]"
					end
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
			_stopK8sProxy
			_setDefaultGcloudProfile
		case \*
			echo "Unknown arugment(s). $argv"
	end
else
	_showLongHelp
end