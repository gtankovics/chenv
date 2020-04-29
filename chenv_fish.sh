#!/usr/bin/env fish

set GCLOUD_CONFIGS (gcloud config configurations list --format='value(name)')
set CURRENT_CONFIG (gcloud config configurations list --filter 'is_active=true' --format 'value(name)')

function showHelp
	echo -e "Usage:\n\tchenv [options]"
	echo -e "\nValid options:
	-h or --help\tShow this help.
	-l or --list\tShow list of valid environments.
	\t\tUse with -d or --details for environments' details.
	-e or --env\tSet the selected environment for 'gcloud' and 'kubectl'.
	"
end

function showList
	echo $GCLOUD_CONFIGS
end

function showListDetails
	gcloud config configurations list
end

function changeEnvironment
	set -l config $argv[1]
	switch $config
		case $CURRENT_CONFIG
			echo -e "$config is the current config.\nUse\n\t'chenv -r'\nor\n\t'chenv --reload'\nto reload it."
		case contains $GCLOUD_CONFIGS
			echo "$config is valid config. Use it."
			gcloud config configurations activate $config
			set -xU CLOUDSDK_ACTIVE_CONFIG_NAME $config
			set -xU CLOUDSDK_PROJECT (gcloud config list --format="value(core.project)")
			set -xU CLOUDSDK_COMPUTE_REGION (gcloud config list --format="value(compute.region)")
			set -xU CLOUDSDK_COMPUTE_ZONE (gcloud config list --format="value(compute.zone)")
		case \*
			echo "$argv[1] is not a valid config."
	end
end

if test -n "$argv"
	switch $argv[1]
		case "-h" -o "--help"
			showHelp
		case "-l" -o "--list"
			if test -n "$argv[2]"
				if begin test $argv[2] = "-d"; or test $argv[2] = "--details"; end
					showListDetails
				else
					echo "Unknown argument(s). $argv[2]"
				end
			else
				showList
			end
		case "-e" -o "--env"
			if test -n "$argv[2]"
				changeEnvironment $argv[2]
			else
				echo "Please add environment name."
			end
		case contains $GCLOUD_CONFIGS
			changeEnvironment $argv[1]
		case "-r" -r "--reload"
			changeEnvironment $argv[1]
		case \*
			echo "Unknown arugment(s). $argv"
	end
else
	echo -e "Please add an argument or use 'help' for usage."
end