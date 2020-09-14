
<#
.SYNOPSIS

.DESCRIPTION
It loads 'gcloud' and 'kubectl' predefined environment.

.PARAMETER list
Show the list of valid environment names. Use with 'detailed' to show the detailed list of environments.

.PARAMETER detailed
Use with 'list' for detailed enviromentslist

.PARAMETER environment
Add the selected environment for use.

.PARAMETER reload
Reactivate the current config.

.EXAMPLE
chenv -list 

Your configurations:
- default
- bc-saas-test-be
- ...

.EXAMPLE
chenv -list -detailed

NAME                    IS_ACTIVE  ACCOUNT                    PROJECT                     COMPUTE_DEFAULT_ZONE    COMPUTE_DEFAULT_REGION
default                 False      
test-be                 True       gtankovics@graphisoft.com  bc-saas-test-be             europe-west1-b          europe-west1

.EXAMPLE
chenv -environment [ENVIRONEMNT_NAME]

Activated [test-be].
Cluster is not specified in selected [test-be] configuration.
Looking for running cluster(s) in [europe-west1-b]...
[bc-saas-test-be] in [europe-west1-b] zone does not have any running clusters.
bc-saas-test-be project does not have any running clusters in any region.
Property "current-context" unset

.LINK
https://github.com/tankovicsg/chenv
#>

param(
	[switch]$list,
	[switch]$detailed,
	[string]$environment,
	[switch]$reload
)

function logInfo($message) {
	Write-host -Message $message
}
function logError($message) {
	Write-host -ForegroundColor "red" -Message $message
}

function setK8sContext($cluster) {
	
}

function setEnvironment($configuration, $activate=$false) {
	if ($activate) {
		logInfo("Activate [$configuration] and set variables.")
		gcloud config configurations activate $configuration
		# $CLOUDSDK_ACTIVE_CONFIG_NAME=$configuration
	}
	Write-Host "Set variables in [$configuration]"
	$CONFIGURATION_DETAILS=$(gcloud config list --format json | ConvertFrom-Json)
	
	$env:CLOUDSDK_CONFIG_PROJECT=$CONFIGURATION_DETAILS.core.project
	$env:CLOUDSDK_COMPUTE_REGION=$CONFIGURATION_DETAILS.compute.region
	$env:CLOUDSDK_COMPUTE_ZONE=$CONFIGURATION_DETAILS.compute.zone
	$env:CLOUDSDK_CONTAINER_CLUSTER=$CONFIGURATION_DETAILS.container.cluster
	
	if ($env:GOOGLE_APPLICATION_CREDENTIALS) {
		Remove-Item env:GOOGLE_APPLICATION_CREDENTIALS
	}
	
	if ($env:CLOUDSDK_CONTAINER_CLUSTER) {
		setK8sContext $env:CLOUDSDK_CONTAINER_CLUSTER
	}
	else {
		$CLUSTER = $(gcloud container clusters list --filter="status=RUNNING" --format="value(name)" --limit 1)
		if ($CLUSTER) {
			logInfo("$CLUSTER is in running state. Use this for 'kubectl'")
			setK8sContext $CLUSTER
		}
	}

}

$CONFIGURATIONS = $(gcloud config configurations list --format="value(name)")
$CURRENT_CONFIGURATION = $(gcloud config configurations list --format="value(name)" --filter="is_active=true")
	
if (! $CONFIGURATIONS) {
	logError("You don't have any gcloud configuration.")
	exit
}

if ($list) {
	if ($detailed) {
		gcloud config configurations list
	}
	else {
		write-host -NoNewline "Your configurations:`n"
		foreach($config in $CONFIGURATIONS){
			logInfo("- $config")
		}
	}
}

if (!$list -and $detailed) {
	Write-Error -Message "Use with '-list' for detailed enviorment configs."
}

if ($environment -and !$list -and !$detailed) {
	if ($environment -in $CONFIGURATIONS) {
		if ($environment -eq $CURRENT_CONFIGURATION) {
			logInfo("[$environment] is the current configuration.`n`nUse 'chenv -reload' for reactivate the config.`n")
		}
		setEnvironment $environment $true
	}
	else {
		logError("[$environment] is not a valid configuration.")
	}
}

if ($reload) {
	setEnvironment $CURRENT_CONFIGURATION
}