# -----------------------------------------------
# This is an autocompletion file for fchenv
# -----------------------------------------------

set -l fchenv_commands help list set reload clear

set -q GOOGLE_ENVIRONMENTS_PATH || set -l GOOGLE_ENVIRONMENTS_PATH ~/.config/gcloud/configurations

complete -x -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a help -d "show help"
complete -x -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a list -d "show environments list"
complete -x -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a set -d "set environment for \t 'gcloud' and 'kubectl'"
complete -x -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a reload -d "reload current [$GOOGLE_CONFIG] environment"
complete -x -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a clear -d "clear variables and context"

complete -x -c fchenv -n "__fish_seen_subcommand_from set" -a "(ls $GOOGLE_ENVIRONMENTS_PATH | cut -d "_" -f 2)"
