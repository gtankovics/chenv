
$GCLOUD_CONFIGS = gcloud config configurations list --format="value(name)"
$CURRENT_CONFIG = gcloud config configurations list --format="value(name)" --filter "is_active=true"

function showHelp {
	write-host -NoNewline "Usage:`n`tchenv [options]"
	write-host -NoNewline "`n`nValid options:
	-h or --help`tShow this help.
	-l or --list`tShow list of valid environments.
	`t`tUse with -d or --details for environments' details.
	-e or --env`tSet the selected environment for 'gcloud' and 'kubectl'.
	`n"	
}

function showList {
	foreach ($item in $GCLOUD_CONFIGS) {
		write-host $item
	}
}

function showListDetails {
	gcloud config configurations list
}

function changeEnvironment([string]$config) {
	if ($config -eq $CURRENT_CONFIG) {
		write-host "$config is the current config`n`nUse`n`tchenv -r or --reload to reload it.`n"
	}
	if ($config -in $GCLOUD_CONFIGS) {
		write-host "$config is valid config."
		gcloud config configuration activate $config
	}
}

changeEnvironment $args[0]