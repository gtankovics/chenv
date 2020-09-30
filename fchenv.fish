# -----------------------------------------------
# This is an autocompletion file for fchenv
# -----------------------------------------------
function __fish_fchenv_complete_environments
	gcloud config configurations list --format='value(name)'
end

set -l fchenv_commands help list set reload clear
complete -f -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a help -d 'show help'
complete -f -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a list -d 'show environments list'
complete -f -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a set -d 'set selected environment'
complete -f -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a reload -d 'reload current environment'
complete -f -c fchenv -n "not __fish_seen_subcommand_from $fchenv_commands" -a clear -d 'clear variables and context'

complete -f -c fchenv -n "__fish_seen_subcommand_from set; and not __fish_seen_subcommand_from (__fish_fchenv_complete_environments)" -a "(__fish_fchenv_complete_environments)"

# az egyes envek részletei kellenének még ide yaml formátumban