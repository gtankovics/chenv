# -----------------------------------------------
# This is an autocompletion file for fchenv
# -----------------------------------------------

set -l fchenv_commands "help" "list" "set" "reload" "clear"
set -l fchenv_subcommands_list "details" "prod" "edu" "pilot" "team" "test"

set -q GOOGLE_ENVIRONMENTS_PATH || set -l GOOGLE_ENVIRONMENTS_PATH ~/.config/gcloud/configurations

complete -x -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a help -d "'fchenv' - show help"
complete -x -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a list -d "'fchenv' - show environments list"
complete -x -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a set -d "'fchenv' - set environment for 'gcloud' and 'kubectl'"
complete -x -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a reload -d "'fchenv' - reload current [$GOOGLE_CONFIG] environment"
complete -x -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a clear -d "'fchenv' - clear variables and context"

complete -x -c fchenv -n "__fish_seen_subcommand_from set" -a "(ls $GOOGLE_ENVIRONMENTS_PATH | cut -d "_" -f 2)"
complete -x -c fchenv -n "__fish_seen_subcommand_from list" -a "(fchenv help | grep List)"
