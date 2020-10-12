#!/usr/bin/env fish

set -l userBin ~/bin

# copy fchenv
if not test -d $userBin
	mkdir ~/bin
end

echo "copy 'fchenv.sh' to $userBin"
cp fchenv.sh ~/bin/fchenv

echo "create link to file in '/usr/local/bin' folder as 'fchenv'"
if not test -L /usr/local/bin/fchenv
	ln -s $userBin/fchenv /usr/local/bin/fchenv
else
	rm /usr/local/bin/fchenv
	ln -s $userBin/fchenv /usr/local/bin/fchenv
end

if test -f $__fish_config_dir/completions/fchenv.fish
	echo "Remove previous autocomplete"
	rm -f $__fish_config_dir/completions/fchenv.fish
end

echo "Add autocomplete"
cp ./completions/fchenv.fish $__fish_config_dir/completions